---
name: lansenger-messaging
version: 1.4.3
description: "蓝信消息策略：4种消息通道（bot私聊/公号私聊/人→人私聊/群聊），消息类型矩阵（text/formatText/appCard/linkCard/oacard/appArticles/approveCard），@mention规则，提醒，CLI命令选择。当用户需要发消息、回消息、撤回消息、更新卡片、发提醒时使用。"
metadata:
  requires:
    bins: ["lansenger"]
  cliHelp: "lansenger message --help"
---

# messaging

**本技能继承 [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md) 的所有规则。** Shell 执行纪律、Help-First 原则、认证、权限处理等均在其定义，此处不复述。

**CRITICAL — 发消息前 MUST 向用户确认：1) 收件人（谁/哪个群） 2) 消息内容 3) 发送身份。禁止未经确认直接发消息。**

## Reverse Handoff — 何时不用此技能

| 用户意图 | 正确技能 | 原因 |
|----------|----------|------|
| 查看聊天记录/历史消息 | `lansenger-chat` | messaging 管"发"，chat 管"看" |
| 查员工信息 | `lansenger-staff` | 通过 staffId 查姓名、部门等 |
| 查群信息 | `lansenger-group` | 群详情、群成员列表 |
| 上传文件到素材库 | `lansenger-media` | 单上传不发消息 |
| OAuth2 获取 userToken | `lansenger-oauth` | userToken 来源 |

**只有用户明确要"发消息"、"回复消息"、"撤回消息"、"更新卡片"或"发提醒"时才用本技能。**

## 四种消息通道 — 场景诊断表

**先选通道，再选命令。** 根据以下三个维度确定通道：

| 决策维度 | 选项 A | 选项 B | 选项 C |
|----------|--------|--------|--------|
| **消息范围** | 单/多人（每人独立私聊） | 群聊（所有人可见） | — |
| **发送身份** | 机器人（bot） | 公号（public account） | 用户本人 |
| **是否需要 userToken** | 否（机器人/公号） | 是（用户本人） | — |

### 通道选择决策树

```
用户要发消息
├── 发给单个/多个用户（每人独立私聊）
│   ├── 以机器人身份 → bot私聊 (4.6.12)，CLI: lansenger message send-text
│   ├── 以公号身份 → 公号私聊 (4.6.1)，CLI: lansenger message send-account-message
│   └── 以用户本人身份 → 人→人私聊 (4.6.3)，CLI: lansenger message send-user-message（需 userToken）
└── 发到群里（所有人可见）
    └── 群聊 (4.6.2)，CLI: lansenger message send-text --group
        ├── 机器人身份（默认，不加 --user-token）
        └── 用户身份（加 --user-token）
```

### 场景诊断速查

| 用户原话 | 通道 | 命令 |
|----------|------|------|
| "帮我给张三发条消息" | bot私聊 | `send-text staff123 "..."` |
| "在技术群里发条公告" | 群聊(bot) | `send-text grp123 "..." --group` |
| "用我自己的身份在群里发" | 群聊(用户) | `send-text grp123 "..." --group --user-token $TOKEN` |
| "给开发部的所有人发通知" | bot私聊(batch) | `send-bot-message ... --dept dept1` |
| "用公号给用户发欢迎消息" | 公号私聊 | `send-account-message ... --account-id xxx` |
| "以我的身份给李四发私聊" | 人→人私聊 | `send-user-message ... --user-token $TOKEN` |

### 私聊通道对比

| | bot私聊 (4.6.12) | 公号私聊 (4.6.1) | 人→人私聊 (4.6.3) |
|---|---|---|---|
| CLI命令 | `send-text` | `send-account-message` | `send-user-message` |
| 发送身份 | Bot | 公号 (Public Acct) | 用户本人 |
| appToken | 必需 | 必需 | 必需 |
| userToken | 可选 | 可选 | **必需** |
| 接收人 | chat_ids / department_ids | chat_ids / department_ids | receiver_id (单人) |
| 支持msgType | text, oacard, linkCard, appCard, verifyCard | text, oacard, linkCard, appCard, verifyCard | text, formatText, appCard 等 |
| @mention | ✗ | ✗ | ✗ |
| 附件 | ✗ | ✗ | ✓ (text类型) |
| Markdown | ✗ | ✗ | ✓ (formatText) |
| 前置条件 | App有bot能力 | App有公号 | 用户OAuth2授权 |

### 群聊通道 (4.6.2)

| | 群聊 |
|---|---|
| CLI命令 | `send-text --group`, `send-markdown --group`, etc. |
| 发送身份 | 由 `--user-token` / `--sender-id` 决定（见下方说明） |
| 接收人 | group_id (`--group`) |
| 支持msgType | **全部** (text, formatText, oacard, appCard, linkCard, appArticles, verifyCard) |
| @mention | ✓ — **仅text & formatText**（`--mention` @人，`--mention-bot` @bot） |
| 附件 | ✓ (text类型) |
| 前置条件 | Bot/用户必须在群内 |

**群聊发送身份规则（OpenAPI 4.6.2）**：`--user-token` 和 `--sender-id` 至少提供一个（App 有机器人能力时两者都可不传）。同时传时 `--user-token` 做认证、`--sender-id` 决定显示身份。

| 传参 | 发送身份 |
|------|---------|
| 不传任何 | Bot（需 App 有机器人能力） |
| 仅 `--user-token` | 用户本人 |
| 仅 `--sender-id` | 以指定 staffId 身份（Bot 通道） |
| 两者都传 | `--user-token` 认证 + `--sender-id` 显示身份 |

> **已知问题**：以助理身份发群消息时，API 可能返回 `errCode=-10`（应用需要开启机器人能力），但消息**实际已成功投递**。建议发送后通过 `chat messages` 验证投递状态。

**CRITICAL — 私聊中不存在群语境，绝对禁止在私聊中使用 @mention/reminder。@mention 只在群聊中有效，且仅限 text 和 formatText 类型。**

**CRITICAL — 不要在消息内容中手动写 `@姓名`！蓝信 API 会根据 `--mention` 传入的 staffId / `--mention-bot` 传入的 botId 自动拼接 @名称到消息前面，Agent 只需传 ID 即可。**

**TIP — `--ref-msg-id`**：发送消息时可传入引用消息的 openId，实现回复/引用上下文。可用于 `send-text`、`send-markdown`、`send-group-message`。

## 消息类型能力矩阵

| msgType | Markdown | @mention | 附件 | 群聊 | 通道 |
|---------|----------|----------|------|------|------|
| text | ✗ | ✓(群聊) | ✓ | ✓ | 全部 |
| formatText | ✓ | ✓(群聊) | ✗ | ✓ | 4.6.3/4.6.2 |
| oacard | ✗ | ✗ | ✗ | ✓ | 全部 |
| appArticles | ✗ | ✗ | ✗ | ✓ | 全部 |
| appCard | ✗(div) | ✗ | ✗ | ✓ | 全部 |
| linkCard | ✗ | ✗ | ✗ | ✓ | 全部 |
| verifyCard | ✗ | ✗ | ✗ | ✓ | 全部 |
| approveCard | ✓ | ✓(群聊) | ✗ | ✓ | 全部 |

**CRITICAL — 视频消息必须同时提供视频文件和封面图片两个 mediaId。mediaIds 数组长度必须为2：[视频mediaId, 封面图片mediaId]。其他类型仅支持单个 mediaId。**

### 媒体类型（App/Bot 接口，OpenAPI 4.5.4）

本技能使用 **App/Bot 文件接口**，媒体类型为字符串：

| 媒体类型 | 字符串值 | 说明 |
|----------|----------|------|
| 文件 | `"file"` | 通用文件 |
| 视频 | `"video"` | 视频文件 |
| 图片 | `"image"` | 图片文件 |
| 音频 | `"audio"` | 音频文件 |

## Shortcuts（推荐优先使用）

以下是对常用操作的高级封装命令。有 Shortcut 的操作优先使用。

| Shortcut | 说明 | 详细文档 |
|----------|------|---------|
| `send-text` | 发文本消息（私聊/群聊） | [`references/lansenger-messaging-send-text.md`](references/lansenger-messaging-send-text.md) |
| `send-markdown` | 发Markdown消息（私聊/群聊） | [`references/lansenger-messaging-send-markdown.md`](references/lansenger-messaging-send-markdown.md) |
| `send-file` | 发文件消息 | [`references/lansenger-messaging-send-file.md`](references/lansenger-messaging-send-file.md) |
| `send-image-url` | 从URL发图片 | [`references/lansenger-messaging-send-image-url.md`](references/lansenger-messaging-send-image-url.md) |
| `send-link-card` | 发链接卡片 | [`references/lansenger-messaging-send-link-card.md`](references/lansenger-messaging-send-link-card.md) |
| `send-app-card` | 发应用卡片（支持动态更新） | [`references/lansenger-messaging-send-app-card.md`](references/lansenger-messaging-send-app-card.md) |
| `send-oacard` | 发OA审批卡片 | [`references/lansenger-messaging-send-oacard.md`](references/lansenger-messaging-send-oacard.md) |
| `send-app-articles` | 发多图文消息 | [`references/lansenger-messaging-send-app-articles.md`](references/lansenger-messaging-send-app-articles.md) |
| `send-bot-message` | Bot批量发消息（多人/多群） | [`references/lansenger-messaging-send-bot-message.md`](references/lansenger-messaging-send-bot-message.md) |
| `send-group-message` | 群聊发消息（带@mention） | [`references/lansenger-messaging-send-group-message.md`](references/lansenger-messaging-send-group-message.md) |
| `send-account-message` | 公号发消息 | [`references/lansenger-messaging-send-account-message.md`](references/lansenger-messaging-send-account-message.md) |
| `send-user-message` | 人→人私聊发消息（需userToken） | [`references/lansenger-messaging-send-user-message.md`](references/lansenger-messaging-send-user-message.md) |
| `update-dynamic-card` | 更新动态卡片 | [`references/lansenger-messaging-update-dynamic-card.md`](references/lansenger-messaging-update-dynamic-card.md) |
| `revoke` | 撤回消息 | [`references/lansenger-messaging-revoke.md`](references/lansenger-messaging-revoke.md) |
| `send-reminder` | 对消息发送提醒（弹窗/SMS/电话） | 见下方「CLI 命令速查」→ `send-reminder` |
| `approve-card` | 发送审批卡片（4.6.4.13） | 见下方「审批卡片」章节 |
| `update-approve-card` | 更新审批卡片状态（4.6.4.12） | 见下方「审批卡片」章节 |

## CLI 命令速查

### Bot私聊发消息

```bash
# Bot → 用户 文本
lansenger message send-text staff123 "Hello"

# Bot → 用户 Markdown
lansenger message send-markdown staff123 "**Bold**"

# Bot → 用户 带附件
lansenger message send-text staff123 "Report" --file /path/to/file.pdf

# Bot → 用户 发视频（必须提供封面图片）
lansenger message send-text staff123 "Video" --file /path/to/video.mp4 --cover-image /path/to/cover.jpg --media-type video

# Bot → 用户 发图片
lansenger message send-text staff123 "Photo" --file /path/to/photo.png --media-type image

# Bot → 多人（每人独立私聊）
lansenger message send-bot-message text '{"text":{"content":"Notice"}}' --chat-id staff1 --chat-id staff2

# Bot → 多人含部门
lansenger message send-bot-message text '{"text":{"content":"Notice"}}' --chat-id staff1 --dept dept1
```

### 群聊发消息

```bash
# Bot → 群 文本
lansenger message send-text group123 "Hello" --group

# Bot → 群 Markdown
lansenger message send-markdown group123 "**Bold**" --group

# Bot → 群 @all（仅text/formatText）
lansenger message send-text group123 "Important!" --group --mention-all

# Bot → 群 @指定人（仅text/formatText）
# CRITICAL: 不要在消息内容中写 @名字！蓝信 API 会根据 --mention 的 staffId 自动拼接 @姓名
lansenger message send-text group123 "please check" --group --mention staff456

# 用户 → 群（需userToken）
lansenger message send-text group123 "I'll handle it" --group --user-token "ut1"

# 群聊发带@mention的完整消息
lansenger message send-group-message group123 text '{"text":{"content":"Important"}}' --mention-all --mention staff456
```

### 卡片消息

```bash
# 链接卡片
lansenger message send-link-card staff123 "Article Title" "https://example.com"

# 应用卡片（支持动态更新）
lansenger message send-app-card staff123 "Approval" --dynamic --card-link "https://..."

# OA审批卡片
lansenger message send-oacard staff123 "Leave Approval" --head "OA审批" --staff-id staff456 --field '{"key":"Type","value":"Annual Leave"}'

# 多图文
lansenger message send-app-articles staff123 '{"title":"News","url":"https://..."}'
```

### 消息管理

```bash
# 撤回消息
lansenger message revoke msg123 --chat-type bot

# 更新动态卡片
lansenger message update-dynamic-card msg123 --last --status-desc "Approved ✓" --status-colour "#00FF00"
```

### 公号私聊

```bash
# 公号 → 多人
lansenger message send-account-message text '{"text":"Notice from ops account"}' --chat-id staff1 --chat-id staff2 --account-id acct_ops

# 公号 → 部门
lansenger message send-account-message text '{"text":"Team update"}' --dept dept1 --account-id acct_ops
```

### 人→人私聊

用户以自己身份给第三方发私聊消息，使用应用 appToken + userToken。

**CRITICAL — send-user-message 的 `--user-token` 是子命令级参数，必须放在位置参数（receiver_id、msg_type、msg_data）之后。** **所有域命令（message/staff/calendar/chat/group/media）的 `--user-token` 都是子命令级参数，必须放在位置参数之后。**

**CRITICAL — msg_data JSON 格式**：
- text 类型：`{"text":{"content":"消息内容"}}`（text 字段是对象，不是字符串）
- formatText 类型：`{"formatText":{"formatType":1,"text":"Markdown 内容"}}`
- 如果 formatText 返回 errCode=40060（Stage 环境可能不支持），降级为 text 类型发送纯文本

```bash
# 发普通文本消息
lansenger message send-user-message staff456 text '{"text":{"content":"你好，这是消息内容"}}' --user-token $TOKEN

# 发 Markdown 消息
lansenger message send-user-message staff456 formatText '{"formatText":{"formatType":1,"text":"**重要通知**\n\n请今天下班前完成审批"}}' --user-token $TOKEN --common '{"chat_type":"p2p"}'

# 发文件附件
lansenger message send-file staff456 /path/to/report.pdf --user-token $TOKEN

# 发文件附件带说明文字（caption）
lansenger message send-file staff456 /path/to/report.pdf --user-token $TOKEN --content "这是本周的周报"

# 发图片
lansenger message send-file staff456 /path/to/photo.png --media-type image --user-token $TOKEN

# 发图片带说明文字
lansenger message send-file staff456 /path/to/screenshot.png --media-type image --user-token $TOKEN --content "这是系统截图"

# 发视频（必须提供封面图）
lansenger message send-file staff456 /path/to/demo.mp4 --media-type video --cover-image /path/to/cover.jpg --user-token $TOKEN
```

> **前置条件**：`send-file` 内部通过 Bot 通道上传文件（`upload-app`），即使以助理身份发送（传 `--user-token`），应用也**必须开启机器人能力**。如未开启，将返回 `errCode=-10: 应用需要开启机器人能力`。

> **注意**：`send-user-message` 用于发文本和 Markdown，`send-file` 用于发文件/图片/视频附件。两者不支持合并为一条消息 — 如需同时发 Markdown + 文件，分两条消息发送。

### 发送提醒

```bash
# 对消息发送弹窗提醒
lansenger message send-reminder msg123 --type 1 --user staff456

# 对消息发送SMS提醒
lansenger message send-reminder msg123 --type 2 --user staff456 --user staff789

# 对消息发送电话提醒
lansenger message send-reminder msg123 --type 3 --user staff456

# JSON 输出
lansenger -j message send-reminder msg123 --type 1 --user staff456
```

## 常见错误

| 错误 | 正确做法 |
|------|---------|
| 私聊中使用 @mention | @mention 只在群聊中有效 — 私聊无群语境 |
| `send-text` 发Markdown内容 | 用 `send-markdown` 发Markdown |
| `send-markdown` 带附件 | 分两步：先 `send-markdown`，再 `send-file` |
| `send-user-message` 不传 userToken | 4.6.3 通道必须传 `--user-token` |
| appCard 群聊中用 --mention-all | appCard/linkCard/appArticles **不支持** @mention，reminder参数被静默忽略 |
| Bot发群聊消息但Bot不在群里 | Bot必须先加入群聊才能发消息 |
| 群聊不加 `--group` 参数 | 群聊必须加 `--group` 或使用 `send-group-message` |
| 私聊中使用 send-reminder | reminder 只在群聊中有效 — 私聊无群语境 |
| 发视频消息只传一个 mediaId | 视频消息 **必须** 用 `--cover-image` 提供封面图片；CLI 会自动上传封面并构造 `[视频mediaId, 封面mediaId]` |
| 身份发送失败后换身份重试 | **严禁降级或换身份**。用户身份发就用用户身份，机器人身份发就用机器人身份。失败就如实告知用户，不允许切换身份重试 |

### AppCard 样式与字段陷阱

| 陷阱 | 正确做法 |
|------|----------|
| `font-size: 14px` | 用 `pt` 单位，范围 12pt-36pt。px 会被企业 API 拒绝 |
| `text-indent: 0`（无单位） | 写 `text-indent: 0em`（必须带单位） |
| `font-size` 用在 fields/links/signature 中 | 仅 bodyTitle、bodySubTitle、bodyContent 支持 font-size；fields 仅支持 color；links.title 仅支持 color + text-align |
| headStatusInfo.description 写纯文本 | 支持单个 `<div style="color:#FFB116">文字</div>` 控制颜色，<30 字节，不可嵌套 div |
| headStatusInfo.colour 用于文字颜色 | colour 是状态圆点颜色（如 #FFB116）；文字颜色由 description 内的 div style 控制，二者独立 |
| AppArticles 用 `description` 字段 | 用 `summary` 字段。`description` 会被 API 静默忽略 |
| 消息内容超过 ~4000 字符 | 拆分为多条消息发送 |

## 审批卡片（4.6.4.13）

审批卡片（approveCard）是一种特殊的卡片类型，支持以下高级特性：
- @mention/reminder（群聊中支持）
- 按钮组（支持回调、跳转链接）
- 按钮权限控制（permittedStaffs/prohibitedStaffs）
- 卡片到期时间（expireTime）
- 卡片状态动态更新（4.6.4.12）

### 发送审批卡片

```bash
# 基本审批卡片
lansenger message approve-card "申请标题" "**申请内容**\n详细说明" --chat-id staff123

# 审批卡片带字段和按钮
lansenger message approve-card "报销申请" "**金额**：¥1000\n**事由**：差旅费" \
  --chat-id staff123 \
  --head-title "审批通知" \
  --fields '[{"key":"申请人","value":"张三"},{"key":"部门","value":"技术部"}]' \
  --buttons '[{"text":"同意","buttonTheme":1,"link":"https://..."},{"text":"拒绝","buttonTheme":2}]' \
  --card-link "https://example.com/approve?id=123"

# 群聊发送审批卡片
lansenger message approve-card "全员审批" "**事项**：年度预算审批" \
  --chat-id group123 \
  --group \
  --mention-all \
  --expire-time 86400

# 审批卡片带状态
lansenger message approve-card "订单审核" "**订单号**：ORD-20240101" \
  --chat-id staff123 \
  --head-status "待审核" \
  --head-status-colour "orange"
```

> **key=value 格式**：`--field`、`--link`、`--fields` 参数支持 key=value 简写格式，避免命令行传 JSON 的引号问题：
> - `--field "Status=Done" --field "Score=95"` 代替 `--field '{"name":"Status","value":"Done"}'`
> - `--link "View=https://app.example.com"` 代替 `--link '{"name":"View","url":"https://app.example.com"}'`
> - 同时兼容旧 JSON 格式，json.loads() 失败时自动尝试 key=value 解析

> **Windows PowerShell 注意**：如果仍需传 JSON 格式，PowerShell 下双引号会被解析器吃掉。建议优先使用上面的 key=value 格式。

### 更新审批卡片状态

```bash
# 更新审批卡片状态
lansenger message update-approve-card msg123 \
  --head-status "已通过" \
  --head-status-colour "green"

# 更新审批卡片按钮
lansenger message update-approve-card msg123 \
  --buttons '[{"text":"已审批","buttonTheme":3,"state":2}]'
```

### 审批卡片参数说明

| 参数 | 说明 |
|------|------|
| `--body-title` | 卡片正文标题（必填） |
| `--body-content` | 卡片正文内容（支持Markdown，必填） |
| `--chat-id` | 接收人（用户或群组ID） |
| `--group` | 发送到群组 |
| `--head-title` | 卡片头部标题 |
| `--head-icon-link` | 头部图标URL |
| `--head-status` | 状态描述文本 |
| `--head-status-colour` | 状态颜色 |
| `--fields` | 表单字段（JSON数组） |
| `--buttons` | 按钮组（JSON数组） |
| `--card-link` | 卡片跳转链接 |
| `--card-link-pc` | PC端跳转链接 |
| `--card-link-pad` | Pad端跳转链接 |
| `--expire-time` | 过期时间（秒，0=默认7天，最大30天） |
| `--mention-all` | @全体成员（群聊） |
| `--mention` | @指定用户（群聊） |
| `--mention-bot` | @指定机器人（群聊） |
| `--user-token` | 用户token（以用户身份发送） |
| `--sender-id` | 发送者ID（群聊） |

## 卡片类型对比

| 卡片类型 | 多语言 | 动态更新 | headStatus | Pad链接字段 | 按钮权限 | 到期时间 |
|----------|--------|----------|-----------|-------------|---------|---------|
| appCard | ✗ | ✓ | ✓ | --pad-card-link | ✗ | ✗ |
| linkCard | ✗ | ✗ | ✗ | --pad-link | ✗ | ✗ |
| oacard | ✗ | ✗ | ✗ | --pad-link | ✗ | ✗ |
| appArticles | ✗ | ✗ | ✗ | (每条article的padUrl) | ✗ | ✗ |
| approveCard | ✗ | ✓ | ✓ | --card-link-pad | ✓ | ✓ |

## SDK 用法

当需要群发通知到多个群、或批量发送不同消息时，用 SDK 并发发送。详见 `../lansenger-sdk/SKILL.md`。

**SDK 消息类型选择规则**：
- 蓝信只有 `text` 类型支持文件附件，`formatText`（Markdown）**不支持**附件
- 如需发送 Markdown + 文件，必须分两条消息：先 `send_markdown`，再 `send_file`
- SDK 的 `send_text` 方法支持 `file_path` 参数（附件），`send_markdown` 不支持

### 核心方法

`LansengerClient` 提供以下消息发送方法：

| 方法 | 说明 | 关键参数 |
|------|------|---------|
| `send_text` | 发送文本消息（支持附件） | `chat_id`, `content`, `file_path`, `media_type`, `cover_image_path`, `reminder_all`, `reminder_user_ids`, `reminder_bot_ids`, `is_group`, `user_token`, `sender_id`, `ref_msg_id` |
| `send_markdown` | 发送 Markdown 消息 | `chat_id`, `content`, `reminder_all`, `reminder_user_ids`, `reminder_bot_ids`, `is_group`, `user_token`, `sender_id`, `ref_msg_id` |
| `send_file` | 发送文件附件 | `chat_id`, `file_path`, `caption`, `media_type`, `cover_image_path`, `is_group`, `user_token`, `sender_id` |
| `send_image_url` | 从 URL 发送图片 | `chat_id`, `image_url`, `caption`, `is_group`, `user_token`, `sender_id` |
| `send_link_card` | 发送链接卡片 | `chat_id`, `title`, `link`, `description`, `icon_link`, `pc_link`, `is_group`, `user_token`, `sender_id` |
| `send_app_articles` | 发送多图文消息 | `chat_id`, `articles`(List[Dict]), `is_group`, `user_token`, `sender_id` |
| `send_app_card` | 发送应用卡片 | `chat_id`, `body_title`, `head_title`, `body_sub_title`, `body_content`, `fields`, `links`, `is_dynamic`, `head_status_info`, `is_group`, `user_token`, `sender_id` |
| `send_oacard` | 发送 OA 审批卡片 | `chat_id`, `title`, `head`, `sub_title`, `fields`, `link`, `is_group`, `user_token`, `sender_id` |
| `send_approve_card` | 发送审批卡片（交互按钮） | `body_title`, `body_content`, `chat_id`, `head_status_describe`, `head_status_colour`, `buttons`, `is_group`, `user_token`, `sender_id` |
| `update_dynamic_card` | 更新动态卡片 | `msg_id`, `head_status_info`, `links`, `is_last_update` |
| `update_approve_card` | 更新审批卡片状态 | `msg_id`, `head_status_describe`, `head_status_colour`, `buttons` |
| `revoke_message` | 撤回消息 | `message_ids`(List[str]), `chat_type`, `sender_id` |
| `send_user_message` | 人→人私聊发消息 | `receiver_id`, `msg_type`, `msg_data`, `user_token`, `common`, `uuid` |
| `send_group_message` | 群聊发消息（完整能力） | `group_id`, `msg_type`, `msg_data`, `user_token`, `sender_id`, `reminder_all`, `reminder_user_ids`, `reminder_bot_ids`, `ref_msg_id` |
| `send_bot_message` | Bot 批量发消息 | `msg_type`, `msg_data`, `chat_ids`, `user_token`, `entry_id`, `is_group`, `ref_msg_id` |
| `send_reminder` | 发送弹窗/SMS/电话提醒 | `msg_id`, `reminder_types`(List[int]), `user_id_list`(List[str]) |

> **注意**：SDK 参数使用 `reminder_*` 命名（如 `reminder_all`、`reminder_user_ids`），对应 CLI 的 `--mention-all`、`--mention`。这是 @提及功能，与 `send_reminder`（弹窗提醒）不同。

```python
# 私聊文本
await client.send_text(chat_id="staff123", content="Hello")
# 群聊文本
await client.send_text(chat_id="group123", content="Notice", is_group=True)
# 私聊 Markdown
await client.send_markdown(chat_id="staff123", content="**Bold**")
# 发送文件
await client.send_file(chat_id="staff123", file_path="/path/to/file.pdf")
# 群聊发消息（完整能力）
await client.send_group_message(group_id="group123", msg_type="text", msg_data={"text": {"content": "Hello"}}, user_token="ut")
```

### 批量群发通知

向多个群并发发送同一条通知，用 `asyncio.gather` + `Semaphore(5)` 控制并发：

```python
import asyncio
from lansenger_sdk import LansengerClient

async def broadcast_notice(client: LansengerClient, group_ids: list[str], content: str):
    sem = asyncio.Semaphore(5)

    async def send_to_group(group_id: str):
        async with sem:
            return await client.send_text(
                chat_id=group_id,
                content=content,
                is_group=True,
                reminder_all=True,
            )

    results = await asyncio.gather(
        *[send_to_group(gid) for gid in group_ids],
        return_exceptions=True,
    )
    return results

# 用法
# group_ids = ["group1", "group2", "group3"]
# results = await broadcast_notice(client, group_ids, "系统维护通知：今晚 22:00-23:00")
```

### 批量发送不同消息

向不同收件人发送不同内容的消息：

```python
import asyncio
from lansenger_sdk import LansengerClient

async def send_batch_messages(client: LansengerClient, tasks: list[dict]):
    """tasks 示例:
    [
        {"chat_id": "staff1", "content": "张三，你的审批已通过", "is_group": False},
        {"chat_id": "group1", "content": "项目组周会改到周五", "is_group": True},
        {"chat_id": "staff2", "content": "李四，请查收报告", "is_group": False},
    ]
    """
    sem = asyncio.Semaphore(5)

    async def send_one(task: dict):
        async with sem:
            return await client.send_text(
                chat_id=task["chat_id"],
                content=task["content"],
                is_group=task.get("is_group", False),
                user_token=task.get("user_token"),
            )

    results = await asyncio.gather(
        *[send_one(t) for t in tasks],
        return_exceptions=True,
    )
    return results
```

**注意**：并发发送时 Semaphore 值建议 ≤5，避免触发 API 限流。详见 `../lansenger-sdk/SKILL.md` 的"模式 2：并发批量"。