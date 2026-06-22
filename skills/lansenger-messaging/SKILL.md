---
name: lansenger-messaging
version: 1.2.3
description: "蓝信消息策略：4种消息通道（bot私聊/公号私聊/人→人私聊/群聊），消息类型矩阵（text/formatText/appCard/linkCard/oacard/appArticles），@mention规则，提醒，CLI命令选择。当用户需要发消息、回消息、撤回消息、更新卡片、发提醒时使用。"
metadata:
  requires:
    bins: ["lansenger"]
  cliHelp: "lansenger message --help"
---

# messaging (v1.2)

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
| @mention | ✓ — **仅text & formatText** |
| 附件 | ✓ (text类型) |
| 前置条件 | Bot/用户必须在群内 |

**群聊发送身份规则（OpenAPI 4.6.2）**：`--user-token` 和 `--sender-id` 至少提供一个（App 有机器人能力时两者都可不传）。同时传时 `--user-token` 做认证、`--sender-id` 决定显示身份。

| 传参 | 发送身份 |
|------|---------|
| 不传任何 | Bot（需 App 有机器人能力） |
| 仅 `--user-token` | 用户本人 |
| 仅 `--sender-id` | 以指定 staffId 身份（Bot 通道） |
| 两者都传 | `--user-token` 认证 + `--sender-id` 显示身份 |

**CRITICAL — 私聊中不存在群语境，绝对禁止在私聊中使用 @mention/reminder。@mention 只在群聊中有效，且仅限 text 和 formatText 类型。**

**CRITICAL — 不要在消息内容中手动写 `@姓名`！蓝信 API 会根据 `--mention` 传入的 staffId 自动拼接 @姓名到消息前面，Agent 只需传 staffId 即可。**

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
| `query-groups` | 查询机器人可发消息的群列表 | 见下方「CLI 命令速查」→ `query-groups` |
| `send-reminder` | 对消息发送提醒（弹窗/SMS/电话） | 见下方「CLI 命令速查」→ `send-reminder` |

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

### 查询可发消息的群

```bash
# 查询机器人可发消息的群列表
lansenger message query-groups

# 分页查询
lansenger message query-groups --page 1 --size 50

# JSON 输出
lansenger -j message query-groups
```

### 消息管理

```bash
# 撤回消息
lansenger message revoke msg123 --chat-type bot

# 更新动态卡片
lansenger message update-dynamic-card msg123 --last --status-desc "Approved ✓" --status-colour "#00FF00"
```

### 公号私聊和人→人私聊

```bash
# 公号 → 多人
lansenger message send-account-message text '{"text":"Notice from ops account"}' --chat-id staff1 --chat-id staff2 --account-id acct_ops

# 公号 → 部门
lansenger message send-account-message text '{"text":"Team update"}' --dept dept1 --account-id acct_ops

# 用户 → 用户（需userToken，OAuth2获取）
lansenger message send-user-message staff456 text '{"text":"Private message"}' --user-token $TOKEN

# 用户 → 用户 带 common 配置
lansenger message send-user-message staff456 formatText '{"content":"**Bold** text"}' --user-token $TOKEN --common '{"chat_type":"p2p"}'
```

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
| 不知道Bot能在哪些群发消息 | 用 `query-groups` 查询机器人可发消息的群列表 |
| 私聊中使用 send-reminder | reminder 只在群聊中有效 — 私聊无群语境 |
| 发视频消息只传一个 mediaId | 视频消息 **必须** 用 `--cover-image` 提供封面图片；CLI 会自动上传封面并构造 `[视频mediaId, 封面mediaId]` |

## 卡片类型对比

| 卡片类型 | 多语言 | 动态更新 | headStatus | Pad链接字段 |
|----------|--------|----------|-----------|-------------|
| appCard | ✗ | ✓ | ✓ | --pad-card-link |
| linkCard | ✗ | ✗ | ✗ | --pad-link |
| oacard | ✗ | ✗ | ✗ | --pad-link |
| appArticles | ✗ | ✗ | ✗ | (每条article的padUrl) |