---
name: lansenger-shared
version: 1.4.1
description: "认证与配置：appToken/secret 配置、权限处理、安全规则、错误处理 — 所有技能自动加载。首次设置 CLI、config set、Token 或权限报错时使用。"
metadata:
  requires:
    bins: ["lansenger"]
  cliHelp: "lansenger --help"
---

# lansenger CLI 共享规则

本技能会被所有其他子技能自动加载，包含认证、配置、安全等通用规则。

**CRITICAL — 所有其他 Skill 在使用前 MUST 先用 Read 工具读取本文件。**

## 心智模型 — lansenger CLI 是什么

lansenger CLI 是对蓝信 OpenAPI 的命令行封装。每条命令对应一个或一组 API 调用：

- **CLI 命令** → 解析参数 → 调用 SDK → 发送 HTTP 请求到蓝信 API 网关 → 返回结构化结果
- **身份模型**：两级 Token 体系 — `appToken`（应用/机器人身份）+ `userToken`（个人用户身份，可选）
- **凭证存储**：所有凭证保存在 `~/.lansenger/sdk_state.json`（0600 权限），按 profile 隔离，支持多用户 token 存储
- **多用户模式（v0.10.15+）**：`--as <staff_id>` 全局标志自动加载并刷新该用户的 userToken，无需每次手动传 `--user-token`

理解这个模型有助于排查问题：命令失败 → 先检查身份是否正确（该不该带 userToken），再检查凭证是否有效（health check）。

## Shell 执行纪律

**逐条执行，逐条检查。** CLI 每条命令都有副作用（发消息、改配置），一口气跑多条命令可能中间某条静默失败，后续全部跑偏。正确姿势：一条命令 → 检查输出/exit code → 继续。

**引号规则**（zsh/bash）：
- 路径中的 `[]` 必须加引号：`"staff[1]"` 而非 `staff[1]`
- 包含 `$` 的值用单引号：`'$token_value'` 而非 `"$token_value"`（双引号会被 shell 解释为变量）

**每次操作前确认**：
- 发消息前：确认收件人 + 内容 + 发送身份
- 删改操作前：确认目标 + 操作不可逆提示

## Help-First 原则

**不确定参数名、值类型或命令语法时，先跑 `--help`，别猜。** 猜-错-重试循环比一次 help 查询慢得多。

```bash
lansenger --help                      # 所有子命令
lansenger message --help              # 消息域命令
lansenger <domain> <command> --help   # 具体命令
```

**Help 与本文档的关系**：本文档教授"怎么做"和"为什么"，CLI `--help` 提供已安装版本的精确参数。当两者不一致时，**`--help` 更权威**。

## 安装指南

### 推荐：Python CLI（优先使用）

```bash
# 安装 CLI
pip install lansenger-cli

# 安装 Python SDK（如需编程调用）
pip install lansenger-sdk

# 验证安装
lansenger --version
```

### 备选：Go CLI

```bash
go install github.com/lansenger-pm/lansenger-sdk-go/cmd/lansenger@latest
```

### 备选：TypeScript CLI

```bash
npm install -g lansenger-cli
```

## 配置初始化

首次使用需运行 `lansenger config set` 完成应用凭证配置。

**CRITICAL — 凭证按 appID 隔离存储，每个 appID 对应一个 profile。多应用/多机器人场景下，务必通过 `--profile` 指定目标应用，避免用错凭证。**

所有凭证存储在 `~/.lansenger/sdk_state.json`（文件权限 0600），密钥类字段在 `config show` 中脱敏显示（`***`）。

### 凭证字段一览

| 字段 | 是否必填 | 场景 | 环境变量 |
|------|----------|------|----------|
| `app_id` | **必填** | 所有 API 调用都需要 | `LANSENGER_APP_ID` |
| `app_secret` | **必填** | 所有 API 调用都需要 | `LANSENGER_APP_SECRET` |
| `api_gateway_url` | 私有部署时必填 | API 网关地址（默认为蓝信公有云，私有部署需修改） | `LANSENGER_API_GATEWAY_URL` |
| `passport_url` | 需 OAuth2 + 私有部署时填 | OAuth2 授权页地址（公有云自动推断，私有部署需手动设置） | `LANSENGER_PASSPORT_URL` |
| `redirect_uri` | OAuth2 时填 | OAuth2 回调地址（需在蓝信开发者中心配置为可信域名，含协议头和端口号；CLI 默认 http://localhost:8765 也需配置，约10分钟生效） | `LANSENGER_REDIRECT_URI` |
| `encoding_key` | 需接收回调时填 | 回调数据 AES 解密密钥（Base64 编码，来自开发者中心） | `LANSENGER_ENCODING_KEY` |
| `callback_token` | 需接收回调时填 | 回调签名验证 token（未填时回退到 encoding_key） | `LANSENGER_CALLBACK_TOKEN` |

```bash
# 基本凭证（所有用户必填）
lansenger config set app_id YOUR_APP_ID
lansenger config set app_secret YOUR_APP_SECRET
# api_gateway_url 默认为蓝信公有云地址，私有部署需手动设置
# lansenger config set api_gateway_url YOUR_PRIVATE_GATEWAY_URL

# OAuth2 用户认证（需要获取 userToken 时填写）
# passport_url 私有部署需手动设置
# lansenger config set passport_url YOUR_PRIVATE_PASSPORT_URL

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
lansenger config list-profiles

# 删除指定 profile（如为当前 active 则自动切换到 default）
lansenger config delete-profile my-bot

# 查看某个 profile 的配置
lansenger config show --profile "my-personal-bot"

# 清除某个 profile 的凭证
lansenger config clear --profile "my-personal-bot"

# 清除所有 profile（删除整个 state 文件）
lansenger config clear --all
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
| **userToken** | 特定用户级操作（日历、员工查询等） | OAuth2 流程获取 | 2小时，Python SDK自动刷新 |

**关键规则**：
- **appToken 自动管理** — CLI 内部自动获取和刷新，你不需要手动操作
- **userToken 自动刷新** — Python SDK v1.5+ 的 `UserTokenManager` 在过期前5分钟自动刷新；CLI 仍需手动 `lansenger oauth refresh-token`

### Token 传递方式

```bash
# 默认：appToken 自动管理，无需传递任何参数（以 app/bot 身份运行）
lansenger message send-text staff123 "Hello"

# 需以用户身份操作时，用 --as 自动加载已持久化的 token
lansenger calendar primary --as staff_001
lansenger staff search "张三" --as staff_001
lansenger chat list --as staff_001

# 或手动传 --user-token（优先级高于 --as）
lansenger calendar primary --user-token "userToken123"
```

### 身份选择原则

**默认不带身份参数 → 以 app/bot 身份运行。** `--as` 和 `--user-token` 仅在需要以用户身份操作时使用。

| 方式 | 身份 | 何时使用 |
|------|------|----------|
| 不传（默认） | app/bot | 机器人发消息、管群组等 — **大部分场景都是这个** |
| `--as <staff_id>` | 指定用户 | 需以用户身份操作（日历、查聊天、员工搜索等），自动加载已持久化的 token |
| `--user-token <token>` | 手动指定用户 | 临时以用户身份操作，**优先级高于 `--as`** |

- 机器人**以自身视角访问资源** — 需传 `--as staff_id` 获取用户视角（如日历、完整聊天详情）
- 机器人**无法代表用户操作** — 发消息以应用名义发送
- 机器人只需 appID + appSecret，无需 OAuth2 授权
- 用户需要 OAuth2 授权获取 userToken（参见 `../lansenger-oauth/SKILL.md`）
- **多用户场景**：每个 staff_id 独立存储 token，用 `--as` 切换即可

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
lansenger config list-profiles

# 删除指定 profile
lansenger config delete-profile org-bot

# 查看某个 profile 详情
lansenger config show --profile "my-personal-bot"

# 清除某个 profile 的凭证
lansenger config clear --profile "org-bot"

# 清除所有 profile
lansenger config clear --all
```

**CRITICAL — 多应用场景下，不同 appID 对应不同机器人/应用身份。切换 profile 即切换身份，务必确认 profile 与目标身份一致。**

## 多用户 Token 管理（v0.10.15+）

CLI 支持在同一个 profile 下为多个用户（staff_id）存储独立的 userToken。一次 OAuth2 授权，之后全部通过 `--as` 自动加载：

```bash
# OAuth2 授权后会按 staff_id 自动存入当前 profile（参见 lansenger-oauth）
lansenger oauth local-callback

# 列出当前 profile 下所有已授权用户
lansenger config list-users

# 查看完整 token 信息
lansenger config list-users --show-tokens

# 以指定用户身份执行任何需要 userToken 的命令
lansenger calendar primary --as staff_001
lansenger staff search "张三" --as staff_001
lansenger chat list --as staff_001
```

- `--as` 是全局标志，放在子命令之前
- 每个 staff_id 的 token 独立存储，互不干扰
- Token 过期时 CLI 自动刷新（需有 refreshToken）
- 手动 `--user-token` 仍然可用，**优先级高于 `--as`**（同时传时 `--user-token` 生效）
- 不想使用已持久化的 staff_id 时，直接传 `--user-token` 即可

> **子 skill 编写规范**：各子 skill 的示例命令中，需要 userToken 时优先展示 `--as staff_xxx` 方式，将 `--user-token` 作为备选在注释中说明。

## 输出格式

**CRITICAL — `--json/-j` 是全局选项，必须放在最前面（子命令之前），不能放在命令末尾。**

```bash
# ✅ 正确：全局 flag 在最前面
lansenger -j calendar primary
lansenger --json health check

# ❌ 错误：放在命令末尾（会报 "No such option: --json"）
lansenger calendar primary --json
lansenger health check -j

# ✅ 正确：环境变量方式（不依赖参数位置）
LANSENGER_JSON=1 lansenger calendar primary
```

**Agent 建议**：始终使用 JSON 输出，便于结构化解析。推荐用 `lansenger -j <子命令>` 或 `LANSENGER_JSON=1`。

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

## 技能核心配置

> **推荐**：本技能优先使用 **Python SDK 和 CLI**，其他语言（Go、TypeScript）作为备选。

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