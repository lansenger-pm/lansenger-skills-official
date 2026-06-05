---
name: lansenger-oauth
version: 1.1.0
description: "蓝信OAuth2用户授权：构建授权URL、兑换授权码、刷新Token、获取用户信息、解析回调、验证State。当用户需要获取userToken或进行OAuth2授权流程时使用。"
metadata:
  requires:
    bins: ["lansenger"]
  cliHelp: "lansenger oauth --help"
---

# oauth (v1.1)

**CRITICAL — 开始前 MUST 先用 Read 工具读取 [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md），其中包含认证、权限处理、安全规则。**

**CRITICAL — OAuth2 流程需要配置 passport_url（不同于 api_gateway_url，是单独的域名）。未配置 passport_url 会导致授权 URL 构建失败。**

**CRITICAL — 授权码（code）有效期 5 分钟且只能使用一次。刷新 Token 后旧 refreshToken 立即失效，必须使用新返回的 refreshToken。**

**CRITICAL — redirect_uri 域名必须在蓝信开发者后台的信任域名列表中。非信任域名无法接收回调，localhost 也不被信任。用户需手动从浏览器地址栏复制 code 给 Agent。**

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
| **appToken** | 2小时 | CLI 自动刷新 | 无需手动处理 |
| **userToken** | 2小时 | 需手动刷新 | `lansenger oauth refresh-token <refreshToken>` |
| **refreshToken** | 30天 | 需重新 OAuth2 授权 | 无法刷新，过期后必须重新走完整授权流程 |

**批量脚本注意事项**：运行超过2小时的脚本，userToken 可能中途过期。建议：
1. 在脚本开始时同时保存 userToken 和 refreshToken
2. 遇到 token 过期错误时，用 refreshToken 刷新并继续
3. refreshToken 也过期（>30天），则需重新走 OAuth2 授权

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

蓝信 OAuth2 需要用户在浏览器手动操作，不支持 localhost 回调：

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

## 常见错误

| 错误 | 正确做法 |
|------|---------|
| 用 appToken 替代 userToken | appToken 是机器人身份，userToken 通过 OAuth2 获取 |
| 未配置 passport_url | OAuth2 需要 passport_url（与 api_gateway_url 不同的域名） |
| 兑换码超过5分钟或重复使用 | 授权码5分钟有效且只能使用一次 |
| 刷新后继续用旧 refreshToken | 刷新后旧 refreshToken 立即失效，必须用新返回的 |
| 不验证回调 state（CSRF 风险） | 始终用 `validate-state` 验证回调 state |
| redirect_uri 域名不在信任列表 | 必须在蓝信开发者后台配置信任域名（地址因私有部署而异） |
| 不验证回调 state（CSRF 风险） | 始终用 `validate-state` 验证回调 state |
| 期望 localhost 自动接收回调 | 蓝信不支持 localhost 回调，用户需手动从浏览器复制 code |
| 只保存 userToken 不保存 refreshToken | refreshToken 是续期的唯一途径，必须同时保存 |
| 批量脚本不考虑 token 中途过期 | 运行超2小时的脚本需实现 refresh_token 自动刷新逻辑 |