---
name: lansenger-shared
version: 1.0.0
description: "Authentication, config setup, error handling, security rules — auto-loaded by all other skills. Use when first setting up lansenger CLI, running auth login, handling permission or token errors, or needing to update the CLI."
metadata:
  requires:
    bins: ["lansenger"]
---

# lansenger CLI 共享规则

本技能指导你如何通过 `lansenger` CLI 操作蓝信平台资源，以及有哪些注意事项。

**CRITICAL — 所有其他 Skill 在使用前 MUST 先用 Read 工具读取本文件（`../lansenger-shared/SKILL.md`），其中包含认证、权限处理、安全规则。**

## 配置初始化

首次使用需运行 `lansenger config set` 完成应用凭证配置。

**CRITICAL — 凭证按 appID 隔离存储，每个 appID 对应一个 profile。多应用/多机器人场景下，务必通过 `--profile` 指定目标应用，避免用错凭证。**

所有凭证存储在 `~/.lansenger/sdk_state.json`（文件权限 0600），密钥类字段在 `config show` 中脱敏显示（`***`）。

### 凭证字段一览

| 字段 | 是否必填 | 场景 | 环境变量 |
|------|----------|------|----------|
| `app_id` | **必填** | 所有 API 调用都需要 | `LANSENGER_APP_ID` |
| `app_secret` | **必填** | 所有 API 调用都需要 | `LANSENGER_APP_SECRET` |
| `api_gateway_url` | **必填** | API 网关地址（私有部署需修改，默认为蓝信公共云） | `LANSENGER_API_GATEWAY_URL` |
| `passport_url` | 需 OAuth2 时填 | OAuth2 授权页地址（私有部署需修改） | `LANSENGER_PASSPORT_URL` |
| `encoding_key` | 需接收回调时填 | 回调数据 AES 解密密钥（Base64 编码，来自开发者中心） | `LANSENGER_ENCODING_KEY` |
| `callback_token` | 需接收回调时填 | 回调签名验证 token（未填时回退到 encoding_key） | `LANSENGER_CALLBACK_TOKEN` |

```bash
# 基本凭证（所有用户必填）
lansenger config set app_id YOUR_APP_ID
lansenger config set app_secret YOUR_APP_SECRET
lansenger config set api_gateway_url https://apigw.lx.qianxin.com/open/apigw

# OAuth2 用户认证（需要获取 userToken 时填写）
lansenger config set passport_url https://passport.lx.qianxin.com

# 回调接收（需要解析/验签回调 Webhook 时填写）
lansenger config set encoding_key YOUR_ENCODING_KEY
lansenger config set callback_token YOUR_CALLBACK_TOKEN

# 查看当前配置
lansenger config show
```

### 多应用/多机器人配置

CLI 支持多 profile，每个 profile 对应一个 appID（一个应用或一个机器人）。建议用 appID 或应用名作为 profile 名称：

```bash
# 配置第一个应用（个人机器人）
lansenger config set --profile "my-personal-bot"
# 输入 app_id: xxx1, app_secret: xxx1

# 配置第二个应用（蓝信应用）
lansenger config set --profile "my-lansenger-app"
# 输入 app_id: xxx2, app_secret: xxx2

# 配置第三个应用（组织机器人）
lansenger config set --profile "org-bot"
# 输入 app_id: xxx3, app_secret: xxx3

# 切换应用
lansenger message send-text staff123 "Hello" --profile "my-personal-bot"
lansenger calendar primary --profile "my-lansenger-app" --user-token "ut1"

# 查看所有已配置的 profile
lansenger config list

# 查看某个 profile 的配置
lansenger config show --profile "my-personal-bot"
```

### 获取凭证

| Bot 类型 | 如何获取 appID + appSecret |
|----------|----------------------------|
| **个人机器人** | 蓝信桌面端 → 通讯录 → 智能机器人 → 个人机器人 → 点击 ℹ️ 图标（手机端不显示凭证） |
| **蓝信应用** | 在蓝信开发者中心创建 — 可能需要组织管理员审批（地址因私有部署而异，请向客户索取） |
| **组织机器人** | 在蓝信开发者中心创建 — 可能需要组织管理员审批（地址因私有部署而异，请向客户索取） |

## 认证

### 两种 Token

| Token | 用途 | 获取方式 | 有效期 |
|-------|------|---------|--------|
| **appToken** | 所有 API 调用必须 | 自动管理，appID + appSecret 换取 | 2小时，自动刷新 |
| **userToken** | 特定用户级操作（日历、员工查询等） | OAuth2 流程获取 | 2小时，可刷新 |

**关键规则**：
- **appToken 自动管理** — CLI 内部自动获取和刷新，你不需要手动操作
- **userToken 需 OAuth2 授权** — 涉及用户级数据时必须传入 `--user-token` 参数

### Token 传递方式

CLI 命令通过参数传递 token：

```bash
# appToken 自动管理，无需传递
lansenger message send-text staff123 "Hello"

# userToken 通过 --user-token 参数传递
lansenger calendar primary --user-token "userToken123"
lansenger staff detail staff456 --user-token "userToken123"
```

### 身份选择原则

- **无 --user-token** → 以 **应用/机器人身份** 操作，访问机器人自身资源
- **有 --user-token** → 以 **用户身份** 操作，访问用户自己的资源（日历、聊天记录等）

**关键差异**：
- 机器人**看不到用户资源** — 无法访问用户日历、聊天记录等个人资源
- 机器人**无法代表用户操作** — 发消息以应用名义发送
- 机器人只需 appID + appSecret，无需 OAuth2 授权
- 用户需要 OAuth2 授权获取 userToken（参见 `../lansenger-oauth/SKILL.md`）

### 权限不足处理

遇到权限相关错误时，根据错误信息采取对应方案：

1. **检查 appID/appSecret 是否正确** — `lansenger config show` 确认凭证
2. **检查 app 是否开通对应 scope** — 在蓝信开发者后台查看权限配置
3. **用户级操作需要 userToken** — 确认是否遗漏了 `--user-token` 参数

常见错误信息及处理：

| 错误 | 原因 | 解决方案 |
|------|------|---------|
| `appToken 获取失败` | appID/appSecret 错误 | 检查 `lansenger config show`，确认凭证 |
| `权限不足 / scope 缺失` | app 未开通对应权限 | 在蓝信开发者后台开通对应 scope（地址因私有部署而异） |
| `需要 userToken` | 访问用户级资源但未传 token | 添加 `--user-token` 参数（参见 lansenger-oauth） |
| `token 过期` | userToken 过期 | 通过 OAuth2 重新获取或刷新 |

## Profile 管理（多应用/多机器人）

CLI 支持多 profile（多套凭证），每个 profile 对应一个 appID。适用于多应用/多机器人场景：

```bash
# 默认使用 "default" profile
lansenger message send-text staff123 "Hello"

# 指定 profile（即指定使用哪个 appID 的凭证）
lansenger message send-text staff123 "Hello" --profile "org-bot"

# 查看所有已配置 profile
lansenger config list

# 查看某个 profile 详情
lansenger config show --profile "my-personal-bot"
```

**CRITICAL — 多应用场景下，不同 appID 对应不同机器人/应用身份。切换 profile 即切换身份，务必确认 profile 与目标身份一致。**

## 输出格式

```bash
# 默认：格式化表格输出
lansenger calendar primary

# JSON 输出（适合 Agent 解析）
lansenger calendar primary --json

# 简写
lansenger calendar primary -j
```

**Agent 建议**：始终使用 `--json` 输出，便于结构化解析。

## 安全规则

- **禁止输出密钥**（appSecret、accessToken）到终端明文
- **写入/删除操作前必须确认用户意图** — 发消息、删日程、移除群成员等操作需要先确认
- **禁止猜测参数格式** — 不确定参数结构时，先查看 `lansenger <domain> --help`

## 高风险操作防护

以下操作属于高风险，执行前 **MUST 向用户确认**：

| 操作 | 命令 | 风险等级 |
|------|------|---------|
| 发消息给他人 | `lansenger message send-text/send-markdown/...` | 中 — 消息对他人可见 |
| 删除日程 | `lansenger calendar delete-schedule` | 高 — 不可恢复 |
| 移除群成员 | `lansenger group remove-member` | 高 — 影响他人 |
| 删除待办 | `lansenger todo delete` | 高 — 不可恢复 |
| 撤回消息 | `lansenger message revoke` | 中 — 影响他人 |

**规则**：遇到以上操作时，先向用户展示操作细节（目标、内容），等待用户明确确认后再执行。

## 常见错误处理

### 网络错误

```bash
# 检查 API 网关连通性
lansenger health check
```

如果 health check 失败，检查：
1. `api_gateway_url` 配置是否正确（因私有部署而异，默认为蓝信公共云地址）
2. 网络是否能访问蓝信 API

### 凭证错误

```bash
# 快速验证凭证是否有效
lansenger health check
```

返回成功则凭证有效，失败则检查 appID/appSecret。

## 命令探索

```bash
lansenger --help                               # 查看所有子命令
lansenger message --help                       # 查看消息域命令
lansenger calendar --help                      # 查看日历域命令
lansenger <domain> <command> --help            # 查看具体命令参数
```

## 更新与版本

```bash
# Python CLI
pip install --upgrade lansenger-cli

# Go CLI
go install github.com/lansenger-pm/lansenger-sdk-go/cmd/lansenger@latest

# TypeScript CLI
npm install -g lansenger-cli

# 查看版本
lansenger --version
```

## 能力索引

根据用户需求，必须读取对应业务域的详细文档来学习明确的可用能力与使用方式：

| 域 | Skill | 说明 |
|----|-------|------|
| 消息策略 | `../lansenger-messaging/SKILL.md` | 4种消息通道选择、消息类型矩阵、@mention规则 |
| 聊天读取 | `../lansenger-chat/SKILL.md` | 查看聊天列表、拉取聊天消息 |
| 群组管理 | `../lansenger-group/SKILL.md` | 创建群、群信息、群成员、群列表 |
| 通讯录/员工 | `../lansenger-staff/SKILL.md` | 员工信息查询、搜索、ID映射 |
| 部门 | `../lansenger-department/SKILL.md` | 组织架构导航、部门详情、部门员工 |
| 日历/日程 | `../lansenger-calendar/SKILL.md` | 主日历、日程CRUD、参会人管理 |
| 待办 | `../lansenger-todo/SKILL.md` | 创建/查询/更新/删除待办任务 |
| OAuth2 | `../lansenger-oauth/SKILL.md` | 用户授权流程、userToken获取 |
| 流式消息 | `../lansenger-streaming/SKILL.md` | AI Agent 实时消息推送 |
| 回调事件 | `../lansenger-callback/SKILL.md` | Webhook 事件解析、AES解密、签名验证 |
| 媒体文件 | `../lansenger-media/SKILL.md` | 上传/下载文件、图片、视频、音频 |