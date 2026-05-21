---
name: lansenger-oauth
version: 1.0.0
description: "蓝信OAuth2用户授权：构建授权URL、兑换授权码、刷新Token、获取用户信息、解析回调、验证State。当用户需要获取userToken或进行OAuth2授权流程时使用。"
metadata:
  requires:
    bins: ["lansenger"]
  cliHelp: "lansenger oauth --help"
---

# oauth (v1)

**CRITICAL — 开始前 MUST 先用 Read 工具读取 [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md），其中包含认证、权限处理、安全规则。**

**CRITICAL — OAuth2 流程需要配置 passport_url（不同于 api_gateway_url，是单独的域名）。未配置 passport_url 会导致授权 URL 构建失败。**

**CRITICAL — 授权码（code）有效期 5 分钟且只能使用一次。刷新 Token 后旧 refreshToken 立即失效，必须使用新返回的 refreshToken。**

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