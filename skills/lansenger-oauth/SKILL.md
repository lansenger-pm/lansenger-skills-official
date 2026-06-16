---
name: lansenger-oauth
version: 1.5.1
description: "蓝信OAuth2用户授权：构建授权URL、兑换授权码、刷新Token、获取用户信息、解析回调、验证State、本地回调服务器、自动刷新Token。当用户需要获取userToken或进行OAuth2授权流程时使用。"
metadata:
  requires:
    bins: ["lansenger"]
  cliHelp: "lansenger oauth --help"
---

# oauth (v1.5)

**本技能继承 [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md) 的所有规则。** Shell 执行纪律、Help-First 原则、认证、权限处理等均在其定义，此处不复述。

## Reverse Handoff — 何时不用此技能

| 用户意图 | 正确技能 | 原因 |
|----------|----------|------|
| 配置 appID/appSecret | `lansenger config set` | 初始凭证配置，不是 OAuth2 |
| 发消息 | `lansenger-messaging` | OAuth2 只管获取 token，不管发消息 |
| 查员工信息 | `lansenger-staff` | OAuth2 可以获取用户信息，但员工详情用 staff |

**CRITICAL — OAuth2 流程需要配置 passport_url（不同于 api_gateway_url，是单独的域名）。未配置 passport_url 会导致授权 URL 构建失败。**

**CRITICAL — 授权码（code）有效期 5 分钟且只能使用一次。刷新 Token 后旧 refreshToken 立即失效，必须使用新返回的 refreshToken。**

**CRITICAL — Agent MUST 优先使用 `local-callback` 模式，并用 `open` 命令自动在浏览器中打开授权 URL。禁止让用户手动复制 URL 到浏览器（复制时容易带入空格/回车导致失败）。**

## 核心概念

蓝信使用两级认证体系：appToken（机器人身份）和 userToken（用户身份）。userToken 通过 OAuth2 授权流程获取。

### 两级认证

| Token | 用途 | 获取方式 | 有效期 |
|-------|------|---------|--------|
| **appToken** | 机器人身份操作 | appID + appSecret 自动换取 | 2小时，自动刷新 |
| **userToken** | 用户级操作（聊天、通讯录等） | OAuth2 code 换取 | 2小时 |
| **refreshToken** | 续期 userToken | 首次 code 换取时同时获得 | 30天 |

### OAuth2 三步流程

1. **构建授权 URL** → 引导用户在浏览器中授权
2. **解析回调 + 兑换码** → 用授权码换取 userToken + refreshToken
3. **刷新 Token** → 用 refreshToken 续期过期 userToken

### Token 生命周期管理

| Token | 有效期 | 过期后 | 刷新方式 |
|-------|--------|--------|---------|
| **appToken** | 2小时 | SDK/CLI 自动刷新 | 无需手动处理 |
| **userToken** | 2小时 | `--as staff_id` 自动刷新 | 无需手动刷新，CLI 在 `--as` 模式下自动处理 |
| **refreshToken** | 30天 | 需重新 OAuth2 授权 | 无法刷新，过期后必须重新走完整授权流程 |

### Python SDK 自动刷新（UserTokenManager）

Python SDK v1.5+ 提供 `UserTokenManager`，在 `exchange_code` 后自动注册 token，后续调用 `get_user_token()` 时自动检查过期并刷新：

```python
# Async client
client = LansengerClient.from_env()
result = await client.exchange_code("AUTH_CODE")
# tokens auto-registered in UserTokenManager

# Later — auto-refreshes if expired
user_token = await client.get_user_token()

# Sync client
client = LansengerSyncClient.from_env()
result = client.exchange_code("AUTH_CODE")
user_token = client.get_user_token()  # auto-refreshes
```

**关键特性**：

| 特性 | 说明 |
|------|------|
| **refreshToken 单次使用** | 每次刷新后旧 refreshToken 立即失效，UserTokenManager 自动保存新 refreshToken |
| **并发安全** | Python SDK v1.6.3 添加 `asyncio.Lock`，防止并发请求时多次刷新 token 的竞态条件 |
| **refreshToken 持久化** | `refresh_token` 独立于 `user_token` 过期时间加载，重启后不会丢失 |
| **过期检查** | 刷新前先检查 `refresh_token` 过期时间，提供清晰错误信息 |
| **redirect_uri 持久化** | redirect_uri 配置保存到 `sdk_state.json`，CLI 复用 |
| **staff_id 持久化** | 用户 staff_id 保存到 `sdk_state.json`，重启后可复用 |

**批量脚本注意事项**：运行超过2小时的脚本，userToken 可能中途过期。建议：
1. SDK 用户：直接用 `client.get_user_token()` — 自动刷新，无需手动处理
2. CLI 用户：在脚本开始时同时保存 userToken 和 refreshToken，遇到过期时用 refreshToken 刷新

```bash
# 刷新过期 userToken
lansenger -j oauth refresh-token "RT_xxx"
# 返回新的 userToken + 新 refreshToken（旧 refreshToken 立即失效！）

# 批量脚本中的刷新模式
NEW_TOKENS=$(lansenger -j oauth refresh-token "$REFRESH_TOKEN")
NEW_USER_TOKEN=$(echo "$NEW_TOKENS" | jq -r '.user_token')
NEW_REFRESH_TOKEN=$(echo "$NEW_TOKENS" | jq -r '.refresh_token')
```

### OAuth2 授权流程对 Agent 场景

有两种方式完成授权：

**方式一：本地回调服务器（推荐，Agent MUST 优先使用）**

```bash
# Agent 应自动执行以下两步，无需用户手动复制链接：
# Step 1: 启动 local-callback（自动监听 localhost 回调）
lansenger -j oauth local-callback --port 8765

# Step 2: 从 --json 输出中提取 authorize_url，自动在浏览器打开
open "$(lansenger -j oauth local-callback --port 8765 | jq -r '.authorize_url')"
# macOS 用 open，Linux 用 xdg-open，Windows 用 start

# 流程：
# → 自动启动本地 HTTP 服务器
# → Agent 自动在浏览器打开授权 URL
# → 用户在蓝信手机端扫码授权
# → 浏览器重定向到 localhost:8765（前提：已配置 http://localhost:8765 到信任域名）
# → 自动兑换 code 获取 userToken + refreshToken
```

**方式二：手动复制 code**

蓝信 OAuth2 需要用户在浏览器手动操作：

1. Agent 构建授权 URL：`lansenger oauth authorize-url "https://trusted-domain.com/callback"`
2. 用户在浏览器打开该 URL 并授权
3. 用户从浏览器地址栏手动复制 `code=XXX&state=YYY` 给 Agent
4. Agent 解析并兑换：`lansenger oauth parse-callback "code=XXX&state=YYY"` → `lansenger oauth exchange-code "XXX"`

**redirect_uri 要求**：
1. **必须是可信域名** — redirect_uri 域名必须在蓝信开发者后台信任列表中，非可信域名会直接报错，无法获取 code
2. **协议头必须一致** — 如使用 `https`，redirect_uri 和信任域名配置中都必须带 `https`；端口号可选，如有端口号则必须一致
3. **必须拼接有效路径** — 如果只写域名（如 `https://myapp.com`），授权后蓝信会直接跳转到该页面，URL 中的 code 参数会丢失。正确做法是拼接一个符合路由规则但实际不存在的页面路径（如 `https://myapp.com/oauth/callback`、`https://myapp.com/#/cb`），这样页面会报404但 URL 中仍保留 code，用户可从地址栏复制
4. **CLI 默认值** — `http://localhost:8765` 也需要配置到信任域名中，配置后约10分钟生效

### passport_url 与 api_gateway_url

这两个是**不同的域名**：
- `passport_url`：OAuth2 授权页面所在域名（如 `https://passport-xxx.domain`）
- `api_gateway_url`：API 调用域名（因私有部署而异）

## CLI 命令

### 构建授权 URL

```bash
# 构建授权 URL（redirect_uri 自动从配置加载）
lansenger oauth authorize-url

# 指定 redirect_uri
lansenger oauth authorize-url "https://myapp.com/callback"

# 指定 scope
lansenger oauth authorize-url "https://myapp.com/callback" --scope "basic_userinfor"

# 指定 state 参数（CSRF 防护）
lansenger oauth authorize-url "https://myapp.com/callback" --state "random-state-string"
```

**redirect_uri 持久化**：CLI 会自动保存 redirect_uri，下次调用 `authorize-url` 时可省略参数。

### 兑换授权码

```bash
# 用授权码换取 Token
lansenger oauth exchange-code "AUTH_CODE_HERE"

# 兑换时指定 redirect_uri（需与授权 URL 中一致）
lansenger oauth exchange-code "AUTH_CODE_HERE" --redirect-uri "https://myapp.com/callback"

# JSON 输出
lansenger -j oauth exchange-code "AUTH_CODE_HERE"
```

### 刷新 Token

```bash
# 用 refreshToken 获取新 userToken
lansenger oauth refresh-token "REFRESH_TOKEN_HERE"

# 指定 scope
lansenger oauth refresh-token "REFRESH_TOKEN_HERE" --scope "basic_userinfor"

# JSON 输出
lansenger -j oauth refresh-token "REFRESH_TOKEN_HERE"
```

### 获取用户信息

```bash
# 用 userToken 获取用户信息
lansenger oauth user-info "USER_TOKEN_HERE"

# JSON 输出
lansenger -j oauth user-info "USER_TOKEN_HERE"
```

### 解析回调参数

```bash
# 解析 OAuth2 回调 URL 的查询字符串
lansenger oauth parse-callback "code=XXX&state=YYY"
```

### 验证 State（CSRF 防护）

```bash
# 验证回调中的 state 是否与预期一致
lansenger oauth validate-state "callback_state_value" "expected_state_value"
```

### 本地回调服务器（一键授权+兑换）

```bash
# 默认端口 8765，自动兑换 code
lansenger oauth local-callback

# 指定端口
lansenger oauth local-callback --port 9000

# 仅捕获 code，不自动兑换
lansenger oauth local-callback --no-exchange

# JSON 输出
lansenger -j oauth local-callback

# 自定义超时（默认120秒）
lansenger oauth local-callback --timeout 300
```

原理：启动本地 HTTP 服务器监听 `http://localhost:<port>`，浏览器授权后重定向到该地址，服务器自动捕获 code。**前提**：必须先将 `http://localhost:<port>`（如 `http://localhost:8765`）配置到蓝信开发者后台信任域名中，否则会报错无法获取 code。

**重要提示**：`local-callback` 必须后台运行（添加 `&` 或使用后台启动），前台运行会阻塞终端无法同时打开浏览器。正确流程：后台启动 local-callback → 提取 URL → open 打开浏览器 → 等待回调完成。

### 授权后的 Token 使用（v0.10.15+）

`local-callback` 和 `exchange-code` 完成后，userToken + refreshToken 会**自动按 staff_id 存入当前 profile**。之后所有需要 userToken 的命令**无需手动传 `--user-token`**，直接用 `--as <staff_id>` 即可自动加载并刷新：

```bash
# 授权一次，之后全部用 --as
lansenger calendar primary --as staff_001
lansenger staff search "张三" --as staff_001
lansenger chat list --as staff_001

# 查看已授权的所有用户
lansenger config list-users

# 查看完整 token 信息（含过期时间）
lansenger config list-users --show-tokens
```

- `--as` 是全局标志，放在子命令之前
- Token 过期时 CLI 自动用 refreshToken 刷新
- 如需为多个用户授权，只需重复 OAuth2 流程（每个用户独立存储）
- 手动 `--user-token` 仍然可用，**优先级高于 `--as`**

## 参数说明

### oauth authorize-url

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `redirect_uri` (位置参数) | str | — | 授权回调 URI（必需，域名必须在应用信任列表中） |
| `--scope` / `-s` | str | "basic_userinfor" | OAuth2 scope |
| `--state` | str | "" | CSRF 防护的 state 参数 |

### oauth exchange-code

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `code` (位置参数) | str | — | 授权码（必需，5分钟有效，一次性） |
| `--redirect-uri` | str | "" | 与授权 URL 中相同的 redirect_uri |

### oauth refresh-token

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `refresh_token` (位置参数) | str | — | 刷新令牌（必需） |
| `--scope` / `-s` | str | "" | Scope |

### oauth user-info

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `user_token` (位置参数) | str | — | 用户 Token（必需） |

### oauth parse-callback

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `query_string` (位置参数) | str | — | 回调 URL 的查询字符串（必需） |

### oauth validate-state

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `callback_state` (位置参数) | str | — | 回调中的 state 值（必需） |
| `expected_state` (位置参数) | str | — | 预期的 state 值（必需） |

### oauth local-callback

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `--port` / `-p` | int | 8765 | 本地 HTTP 服务器端口 |
| `--scope` / `-s` | str | "basic_userinfor" | OAuth2 scope |
| `--state` | str | "" | CSRF state（空则自动生成） |
| `--exchange` / `--no-exchange` | bool | True | 是否自动兑换 code 为 userToken |
| `--timeout` / `-t` | int | 120 | 等待回调最大秒数 |

## 常见错误

| 错误 | 正确做法 |
|------|---------|
| 用 appToken 替代 userToken | appToken 是机器人身份，userToken 通过 OAuth2 获取 |
| 未配置 passport_url | OAuth2 需要 passport_url（与 api_gateway_url 不同的域名） |
| 兑换码超过5分钟或重复使用 | 授权码5分钟有效且只能使用一次 |
| redirect_uri 域名不在信任列表 | 必须在蓝信开发者后台配置信任域名（地址因私有部署而异） |
| 不验证回调 state（CSRF 风险） | 始终用 `validate-state` 验证回调 state |
| 期望 localhost 自动接收回调 | 用 `local-callback` 启动本地 HTTP 服务器捕获，但需先配置 `http://localhost:<port>` 到信任域名 |
| 让用户手动复制 URL 到浏览器 | **禁止**——手动复制容易带入空格/回车导致失败；Agent MUST 用 `open`/`xdg-open` 自动打开 |
| 只保存 userToken 不保存 refreshToken | refreshToken 是续期的唯一途径，必须同时保存；SDK UserTokenManager 自动保存 |
| 批量脚本不考虑 token 中途过期 | SDK 用户用 `get_user_token()` 自动刷新；CLI 用户手动 `refresh-token` |
| 刷新后继续用旧 refreshToken | 刷新后旧 refreshToken 立即失效，必须用新返回的 |