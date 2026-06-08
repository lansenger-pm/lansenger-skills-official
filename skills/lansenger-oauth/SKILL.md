---
name: lansenger-oauth
version: 1.3.0
description: "蓝信OAuth2用户授权：构建授权URL、兑换授权码、刷新Token、获取用户信息、解析回调、验证State、本地回调服务器、自动刷新Token。当用户需要获取userToken或进行OAuth2授权流程时使用。"
metadata:
  requires:
    bins: ["lansenger"]
  cliHelp: "lansenger oauth --help"
---

# oauth (v1.2)

**CRITICAL — 开始前 MUST 先用 Read 工具读取 [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md），其中包含认证、权限处理、安全规则。**

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
| **userToken** | 2小时 | SDK UserTokenManager 自动刷新（提前5分钟） | SDK: `client.get_user_token()` 自动刷新；CLI: 手动 `lansenger oauth refresh-token` |
| **refreshToken** | 30天 | 需重新 OAuth2 授权 | 无法刷新，过期后必须重新走完整授权流程 |

### SDK 自动刷新（UserTokenManager）

SDK v1.5+ 提供 `UserTokenManager`，在 `exchange_code` 后自动注册 token，后续调用 `get_user_token()` 时自动检查过期并刷新：

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

**关键**：refreshToken 是单次使用的（每次刷新后旧 token 立即失效），UserTokenManager 自动保存新 refreshToken。

**批量脚本注意事项**：运行超过2小时的脚本，userToken 可能中途过期。建议：
1. SDK 用户：直接用 `client.get_user_token()` — 自动刷新，无需手动处理
2. CLI 用户：在脚本开始时同时保存 userToken 和 refreshToken，遇到过期时用 refreshToken 刷新

```bash
# 刷新过期 userToken
lansenger oauth refresh-token "RT_xxx" --json
# 返回新的 userToken + 新 refreshToken（旧 refreshToken 立即失效！）

# 批量脚本中的刷新模式
NEW_TOKENS=$(lansenger oauth refresh-token "$REFRESH_TOKEN" --json)
NEW_USER_TOKEN=$(echo "$NEW_TOKENS" | jq -r '.user_token')
NEW_REFRESH_TOKEN=$(echo "$NEW_TOKENS" | jq -r '.refresh_token')
```

### OAuth2 授权流程对 Agent 场景

有两种方式完成授权：

**方式一：本地回调服务器（推荐，Agent MUST 优先使用）**

```bash
# Agent 应自动执行以下两步，无需用户手动复制链接：
# Step 1: 启动 local-callback（自动监听 localhost 回调）
lansenger oauth local-callback --port 8765 --json

# Step 2: 从 --json 输出中提取 authorize_url，自动在浏览器打开
open "$(lansenger oauth local-callback --port 8765 --json | jq -r '.authorize_url')"
# macOS 用 open，Linux 用 xdg-open，Windows 用 start

# 流程：
# → 自动启动本地 HTTP 服务器
# → Agent 自动在浏览器打开授权 URL
# → 用户在蓝信手机端扫码授权
# → 浏览器重定向到 localhost:8765（即使页面报错，code 已被捕获）
# → 自动兑换 code 获取 userToken + refreshToken
```

**方式二：手动复制 code**

蓝信 OAuth2 需要用户在浏览器手动操作：

1. Agent 构建授权 URL：`lansenger oauth authorize-url "https://trusted-domain.com/callback"`
2. 用户在浏览器打开该 URL 并授权
3. 用户从浏览器地址栏手动复制 `code=XXX&state=YYY` 给 Agent
4. Agent 解析并兑换：`lansenger oauth parse-callback "code=XXX&state=YYY"` → `lansenger oauth exchange-code "XXX"`

**限制**：redirect_uri 域名必须在蓝信开发者后台信任列表中。如果没有可信回调服务器，可用任意信任域名（页面会报错但 URL 中仍含 code），用户复制 code 即可。

### passport_url 与 api_gateway_url

这两个是**不同的域名**：
- `passport_url`：OAuth2 授权页面所在域名（如 `https://passport-xxx.domain`）
- `api_gateway_url`：API 调用域名（因私有部署而异）

## CLI 命令

### 构建授权 URL

```bash
# 构建基本授权 URL
lansenger oauth authorize-url "https://myapp.com/callback"

# 指定 scope
lansenger oauth authorize-url "https://myapp.com/callback" --scope "basic_userinfor"

# 指定 state 参数（CSRF 防护）
lansenger oauth authorize-url "https://myapp.com/callback" --state "random-state-string"
```

### 兑换授权码

```bash
# 用授权码换取 Token
lansenger oauth exchange-code "AUTH_CODE_HERE"

# 兑换时指定 redirect_uri（需与授权 URL 中一致）
lansenger oauth exchange-code "AUTH_CODE_HERE" --redirect-uri "https://myapp.com/callback"

# JSON 输出
lansenger oauth exchange-code "AUTH_CODE_HERE" --json
```

### 刷新 Token

```bash
# 用 refreshToken 获取新 userToken
lansenger oauth refresh-token "REFRESH_TOKEN_HERE"

# 指定 scope
lansenger oauth refresh-token "REFRESH_TOKEN_HERE" --scope "basic_userinfor"

# JSON 输出
lansenger oauth refresh-token "REFRESH_TOKEN_HERE" --json
```

### 获取用户信息

```bash
# 用 userToken 获取用户信息
lansenger oauth user-info "USER_TOKEN_HERE"

# JSON 输出
lansenger oauth user-info "USER_TOKEN_HERE" --json
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
lansenger oauth local-callback --json

# 自定义超时（默认120秒）
lansenger oauth local-callback --timeout 300
```

原理：启动本地 HTTP 服务器监听 `http://localhost:<port>`，浏览器授权后重定向到该地址，服务器自动捕获 code。即使 localhost 不在蓝信信任域名列表中，浏览器仍会重定向到该 URL（页面可能报错，但 URL 中包含 code 参数），本地服务器从 URL 中提取 code 并自动兑换。

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
| 期望 localhost 自动接收回调 | 用 `local-callback` 启动本地 HTTP 服务器捕获 |
| 让用户手动复制 URL 到浏览器 | **禁止**——手动复制容易带入空格/回车导致失败；Agent MUST 用 `open`/`xdg-open` 自动打开 |
| 只保存 userToken 不保存 refreshToken | refreshToken 是续期的唯一途径，必须同时保存；SDK UserTokenManager 自动保存 |
| 批量脚本不考虑 token 中途过期 | SDK 用户用 `get_user_token()` 自动刷新；CLI 用户手动 `refresh-token` |
| 刷新后继续用旧 refreshToken | 刷新后旧 refreshToken 立即失效，必须用新返回的 |