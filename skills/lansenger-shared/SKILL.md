---
name: lansenger-shared
version: 1.7.4
description: "认证与配置：appToken/secret 配置、权限处理、安全规则、错误处理、SDK 客户端初始化 — 所有技能自动加载。首次设置 CLI、config set、Token 或权限报错时使用。"
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
- **External Token 模式（v0.10.17+）**：通过 `--app-token` 和 `--user-token` 全局参数直接传入 token，无需配置凭证文件，适用于集成场景

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
| `api_gateway_url` | **必填** | API 网关地址（无默认值，必须提供） | `LANSENGER_API_GATEWAY_URL` |
| `passport_url` | 需 OAuth2 + 私有部署时填 | OAuth2 授权页地址（无默认值，必须提供） | `LANSENGER_PASSPORT_URL` |
| `redirect_uri` | OAuth2 时填 | OAuth2 回调地址（需在蓝信开发者中心配置为可信域名，含协议头和端口号；CLI 默认 http://localhost:8765 也需配置，约10分钟生效） | `LANSENGER_REDIRECT_URI` |
| `encoding_key` | 需接收回调时填 | 回调数据 AES 解密密钥（Base64 编码，来自开发者中心） | `LANSENGER_ENCODING_KEY` |
| `callback_token` | 需接收回调时填 | 回调签名验证 token（未填时回退到 encoding_key） | `LANSENGER_CALLBACK_TOKEN` |

```bash
# 基本凭证（所有用户必填）
lansenger config set app_id YOUR_APP_ID
lansenger config set app_secret YOUR_APP_SECRET
# api_gateway_url 无默认值，必须手动配置
# lansenger config set api_gateway_url YOUR_GATEWAY_URL

# OAuth2 用户认证（需要获取 userToken 时填写）
# passport_url 需 OAuth2 时必填
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

**CRITICAL — Agent 修改持久化凭证时必须遵循以下 Profile 管理规则：**

1. **先查后建**：修改凭证前，必须先 `lansenger config list-profiles` 检查是否已有与目标 AppID 相同的 profile
2. **有则复用**：如果已存在相同 AppID 的 profile，直接复用该 profile（通过 `--profile` 指定），**绝不修改已有凭证**
3. **无则新建**：如果不存在，才创建新 profile（建议以应用名/机器人名命名）
4. **不修改已有**：不要修改、覆盖、清除已有 profile 的凭证，因为这可能影响其他 Agent 或用户的正常使用

```bash
# 正确的 profile 管理流程
# Step 1: 先查询已有 profile
lansenger config list-profiles
# Step 2: 如果 AppID 已存在对应 profile → 直接复用它
lansenger staff search --profile "existing-profile" ...
# Step 3: 如果不存在 → 创建新 profile
lansenger config set --profile "new-app-name"
```

### 获取凭证

| Bot 类型 | 如何获取 appID + appSecret |
|----------|----------------------------|
| **个人机器人** | 蓝信桌面端 → 通讯录 → 智能机器人 → 个人机器人 → 点击 ℹ️ 图标（手机端不显示凭证） |
| **蓝信应用** | 在蓝信开发者中心创建 — 可能需要组织管理员审批（地址因私有部署而异，请向客户索取） |
| **组织机器人** | 在蓝信开发者中心创建 — 可能需要组织管理员审批（地址因私有部署而异，请向客户索取） |

### 身份能力矩阵

**CRITICAL — 三种身份类型的 API 可用性完全不同。Agent 在调用命令前 MUST 确认当前 profile 的身份类型能否执行该操作。**

| 命令域 | 个人机器人 | 蓝信应用（自建） | 蓝信应用 + 机器人 | 关键说明 |
|--------|:---:|:---:|:---:|------|
| `message send-text/markdown/file/...` (bot私聊) | **Y** | N | **Y** | 只有机器人身份才能发 bot 私聊；蓝信应用无机器人能力不可用 |
| `message send-text --group` (群聊) | **Y** | N | **Y** | 个人机器人已支持进群发消息；蓝信应用非机器人不可用 |
| `message send-group-message` | **Y** | N | **Y** | 同上 |
| `message send-account-message` (公号私聊) | N | **Y** | **Y** | 需要公号能力 |
| `message send-user-message` (人→人私聊) | N | **Y** | **Y** | 需要 userToken + OAuth2 |
| `message revoke` (撤回) | **Y** | **Y** | **Y** | 撤回自己发的消息 |
| `staff *` (通讯录只读) | N | **Y** | **Y** | 仅组织级应用可调通讯录；`search` 需额外 userToken |
| `department *` | N | **Y** | **Y** | 仅组织级应用可浏览组织架构 |
| `calendar *` (日历日程) | N | **Y** | **Y** | 组织级应用均可调用；以 userToken 操作以用户身份，无 userToken 时以机器人身份 |
| `todo *` (待办) | N | **Y** | **Y** | 仅组织级应用 |
| `chat list/messages` (聊天记录) | N | **Y** | **Y** | 仅组织级应用 |
| `group *` (群管理 V2) | N | N | **Y** | 只有机器人能进群，应用无法管理群组 |
| `media upload` | **Y** | **Y** | **Y** | 通用上传 |
| `media upload-app` | **Y** | **Y** | **Y** | App/Bot 上传仅自建应用，ISV 不支持 |
| `media upload-app-v2` | **Y** | **Y** | **Y** | V2 需 userToken，跨平台上传，仅自建应用 |
| `media download/path` | **Y** | **Y** | **Y** | 通用下载 |
| `media download-share` | **Y** | **Y** | **Y** | 按分享 ID 下载（4.5.6） |
| `oauth *` (OAuth2) | N | **Y** | **Y** | 仅组织级应用可发起 OAuth2 |
| `streaming *` (流式消息) | N | **Y** | **Y** | 组织级应用均可 |
| `callback *` (回调解析) | N/A | N/A | N/A | 纯数据侧操作，无身份要求 |
| `bot-command *` (机器人指令) | **Y** | **Y** | **Y** | 管理机器人指令（4.37） |
| `personal-app *` (个人应用) | N | **Y** | **Y** | 管理个人应用（4.38），需 userToken |
| `message approve-card` (审批卡片) | **Y** | **Y** | **Y** | 发送审批卡片（4.6.4.13） |

> **个人机器人总结**：**能收发消息（含群聊）、上传下载文件**。不能查通讯录、不能管群（群管理）、不能操作日历日程、不能发起 OAuth2 授权。
>
> **蓝信应用 vs 蓝信应用+机器人**：两者使用同一个 appID/appSecret，能力几乎完全相同。唯一区别在于**消息通道**——只有机器人身份能发 bot 私聊和群聊消息。所有机器人（个人机器人、组织机器人）均可发群聊。其他所有 API（通讯录、日历、待办、聊天记录、OAuth2、流式消息等）两者完全一致。**目前仅蓝信自建应用支持开启机器人能力。**

### API 权限/能力前置条件

| 操作 | 身份 | 所需权限/能力 | 常见错误 |
|------|------|-------------|---------|
| 发消息（bot私聊） | 机器人 | Bot 消息发送 | — |
| 发文件/图片/视频 | 机器人/助理 | Bot 消息发送 + **机器人能力**（send-file 内部走 Bot 通道上传） | errCode=-10: 应用需要开启机器人能力 |
| 发群消息（机器人） | 机器人 | Bot 消息发送 + 机器人在群内 | — |
| 发群消息（用户身份） | 助理 | Bot 消息发送（底层依赖） | errCode=-10（但消息可能已投递） |
| 人→人私聊 | 助理 | userToken | — |
| 建群 | 机器人/助理 | 群管理 API | errCode=10005: API服务无权限 |
| 解散群 | 机器人（需群管理权限）或助理（群主本人） | 群管理 API 或群主身份 | errCode=10005（Bot 无权限时换助理身份） |
| 群成员管理 | 机器人/助理 | 群管理 API | errCode=10005 |
| 通讯录查询 | 助理 | 通讯录读取 | — |
| 日历操作 | 助理 | 日历 API | — |
| 机器人指令管理 | 机器人 | 机器人能力 | — |

### 开发者中心权限

**CRITICAL — 即使身份类型支持，具体 API 能否调用还取决于开发者中心的权限开关。Agent 遇到权限报错时，应提示用户检查对应权限是否已开启。**

权限在蓝信开发者中心管理，分为基本权限（默认开启）和高级权限（默认关闭）。部分组织可能限制开发者自行访问开发者中心，需联系组织管理员操作。

#### 基本权限（默认开启）

| 权限 | 说明 |
|------|------|
| 获取人员基本信息 | 获取人员的基本信息，用于登录系统/应用 |
| 发送通知消息 | 获取组织的消息通道给人员或群组发送消息 |

#### 高级权限（默认关闭，需手动开启）

| 权限 | 说明 | 影响的 Skill |
|------|------|-------------|
| 通讯录只读权限 | 获取通讯录的读取权限 | `lansenger-staff`、`lansenger-department` |
| 通讯录编辑权限 | 获取通讯录的编辑权限 | `lansenger-staff`（创建/更新/删除员工） |
| 人员敏感信息-手机号 | 获取某个人员手机号信息的权限 | `lansenger-staff`（detail、id-mapping） |
| 人员敏感信息-邮箱 | 获取某个人员邮箱信息的权限 | `lansenger-staff`（detail、id-mapping） |
| 人员敏感信息-身份证号 | 获取某个人员身份证号码的权限 | `lansenger-staff` |
| 人员敏感信息-工号 | 获取某个人员工号信息的权限 | `lansenger-staff` |
| 根据人员唯一属性换取员工ID | 根据手机号/邮箱/员工号换取员工ID | `lansenger-staff`（id-mapping） |
| 应用编辑权限 | 创建应用与更新应用信息的权限 | 开发者中心管理 |
| 群只读权限 | 获取群只读权限 | `lansenger-group`（查询群信息/成员） |
| 群编辑权限 | 获取群编辑权限 | `lansenger-group`（创建/更新/解散/成员变更） |
| 日历日程只读权限 | 获取日历日程只读权限 | `lansenger-calendar`（查询） |
| 日历日程编辑权限 | 获取日历日程编辑权限 | `lansenger-calendar`（创建/更新/删除） |
| 上传素材权限 | 获取上传素材文件权限 | `lansenger-media`（upload、upload-app、upload-app-v2） |
| 工作台模版读权限 | 获取工作台模版读权限 | — |
| 工作台模版写权限 | 获取工作台模版写权限 | — |

> **Agent 指引**：当命令返回权限相关错误时，先检查 shared「身份能力矩阵」确认身份类型支持，再提示用户在开发者中心开启对应高级权限（如无法自行访问，联系组织管理员）。

## SDK 客户端快速初始化

当任务涉及批量操作（≥3 个对象）、并发拉取、或需要进程内数据传递时，应使用 Python SDK 而非逐条调 CLI。初始化、并发控制、断点续传详见 `../lansenger-sdk/SKILL.md`。

核心对应关系：`--app-token` → `LansengerClient(app_token=...)`，`--user-token` → `user_token=...` 传给方法参数，`--as staff_id` → `client.get_user_token(staff_id=...)`，`config set` 凭证复用 → `LansengerClient.from_store(profile="default")`。SDK 的 TokenManager 自动管理 appToken 获取/刷新和 userToken 刷新。

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
| `--app-token <token>` + `--user-token <token>` | External模式 | 集成方直接传入 token，不使用凭证文件，适用于第三方系统集成 |

- 机器人**以自身视角访问资源** — 需传 `--as staff_id` 获取用户视角（如日历、完整聊天详情）
- 机器人**无法代表用户操作** — 发消息以应用名义发送
- 机器人只需 appID + appSecret，无需 OAuth2 授权
- 用户需要 OAuth2 授权获取 userToken（参见 `../lansenger-oauth/SKILL.md`）
- **多用户场景**：每个 staff_id 独立存储 token，用 `--as` 切换即可
- **External Token 模式**：通过 `--app-token` 和 `--user-token` 全局参数直接传入 token，CLI 不管理 token 生命周期，适用于集成场景

### External Token 模式（v0.10.17+）

**适用于第三方系统集成场景**：集成方自行管理 token 获取和刷新，通过命令行参数直接传入。

```bash
# External模式：直接传入app_token，无需配置凭证文件
lansenger --app-token "xxx" message send-text staff123 "Hello"

# External模式：同时传入app_token和user_token
lansenger --app-token "xxx" calendar primary --user-token "yyy"

# External模式下，--profile参数被忽略（不读取凭证文件）
lansenger --app-token "xxx" --profile "default" message send-text staff123 "Hello"
```

**注意事项**：
- External 模式下，CLI 不会自动刷新 token，集成方需自行管理 token 生命周期
- `--app-token` 是开启 External 模式的开关，只要提供了 `--app-token`，就进入 External 模式
- `--user-token` 在 External 模式下是可选的，根据具体 API 是否需要决定是否传入
- External 模式下，`--as` 参数无效（不读取持久化的 userToken）

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
| **`errCode=51011`（建群申请等待审核）** | 组织开启了建群审核 | **非报错，正常业务流程。告知用户"申请已提交，等待管理员审核"** |

**CRITICAL — 权限错误处理原则**：
- 接口调用失败（权限不足、scope 缺失、token 过期等）时，**如实告知用户**错误信息和原因
- **严禁静默重试** — 不要在用户不知情的情况下自动重试
- **严禁换身份/换通道重试** — 选定的身份失败后，不得切换到另一身份或另一通道重试
- **严禁换方式重试** — 不得改变调用方式（如从 SDK 换 CLI、从群聊换私聊）来绕过权限
- 应用权限可能被管理员在后台随时调整，遇到权限错误是正常的业务情况，应如实反馈

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

发消息、删日程、移除群成员、删除待办、撤回消息等操作执行前 MUST 向用户确认。详见各子技能的具体 CRITICAL 规则。

## 快速连通性检查

一次调用验证所有凭证有效性：

```bash
# 验证 appToken（应用/机器人身份）
lansenger -j health check

# 验证 userToken（用户身份，需先 OAuth2 授权）
lansenger -j staff search --keyword "test" --as staff_001
```

## Pre-flight 检查清单

首次使用或遇到问题时，逐项检查：

- [ ] `lansenger --version` ≥ 0.10.19
- [ ] `api_gateway_url` 配置正确（测试: `lansenger health check`）
- [ ] appID/appSecret 有效（测试: `lansenger health check`）
- [ ] userToken 有效（测试: `lansenger calendar primary --as staff_001`）
- [ ] 应用是否开启机器人能力（影响 send-file / 群消息）
- [ ] App 是否有群管理 API 权限（影响 group create/dismiss/update-members）

## 常见错误处理

### 网络错误

```bash
# 检查 API 网关连通性
lansenger health check
```

如果 health check 失败，检查：
1. `api_gateway_url` 配置是否正确（无默认值，必须提供）
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
| 消息策略 | `../lansenger-messaging/SKILL.md` | 4种消息通道选择、消息类型矩阵、@mention规则、审批卡片 |
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
| 机器人指令 | `../lansenger-bot-command/SKILL.md` | 管理机器人指令（4.37） |
| 个人应用 | `../lansenger-personal-app/SKILL.md` | 管理个人应用/机器人（4.38） |
| SDK 编程 | `../lansenger-sdk/SKILL.md` | 批量操作、并发控制、断点续传、连接复用 |
| External模式 | `../lansenger-external/SKILL.md` | 显式传入app_token/user_token的集成模式 |