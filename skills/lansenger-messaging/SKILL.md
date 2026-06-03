---
name: lansenger-messaging
version: 1.2.0
description: "蓝信消息策略：4种消息通道（bot私聊/公号私聊/人→人私聊/群聊），消息类型矩阵（text/formatText/appCard/linkCard/oacard/appArticles），@mention规则，提醒，CLI命令选择。当用户需要发消息、回消息、撤回消息、更新卡片、发提醒时使用。"
metadata:
  requires:
    bins: ["lansenger"]
  cliHelp: "lansenger message --help"
---

# messaging (v1.1)

**CRITICAL — 开始前 MUST 先用 Read 工具读取 [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md)，其中包含认证、权限处理**

**CRITICAL — 发消息前 MUST 向用户确认：1) 收件人（谁/哪个群） 2) 消息内容 3) 发送身份。禁止未经确认直接发消息。**

## 四种消息通道

蓝信有 **私聊** 和 **群聊** 两大类消息通道。私聊有3种子通道，选择错误会导致发送身份不对或功能缺失。

### 通道选择决策树

```
需要发消息
├── 发给单个/多个用户（每人独立私聊）
│   ├── 以机器人身份 → bot私聊 (4.6.12)
│   ├── 以公号身份 → 公号私聊 (4.6.1)
│   └── 以用户本人身份 → 人→人私聊 (4.6.3)
└── 发到群里（所有人可见）
│   └── 群聊 (4.6.2)
│       ├── 机器人身份（默认）
│       └── 用户身份（加 --user-token）
```

### 私聊通道对比

| | bot私聊 (4.6.12) | 公号私聊 (4.6.1) | 人→人私聊 (4.6.3) |
|---|---|---|---|
| CLI命令 | `send-text --user-id` | `send-account-message` | `send-user-message` |
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
| 发送身份 | 无userToken → Bot；有userToken → 用户本人 |
| 接收人 | group_id (`--group`) |
| 支持msgType | **全部** (text, formatText, oacard, appCard, linkCard, appArticles, verifyCard) |
| @mention | ✓ — **仅text & formatText** |
| 附件 | ✓ (text类型) |
| 前置条件 | Bot/用户必须在群内 |

**CRITICAL — 私聊中不存在群语境，绝对禁止在私聊中使用 @mention/reminder。@mention 只在群聊中有效，且仅限 text 和 formatText 类型。**

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

**CRITICAL — 视频消息（mediaType=1）必须同时提供视频文件和封面图片两个 mediaId。mediaIds 数组长度必须为2：[视频mediaId, 封面图片mediaId]。其他类型（image/file）仅支持单个 mediaId。**

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
| `query-groups` | 查询机器人可发消息的群列表 | — |
| `send-reminder` | 对消息发送提醒（弹窗/SMS/电话） | — |

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
lansenger message send-text staff123 "Video" --file /path/to/video.mp4 --cover-image /path/to/cover.jpg --media-type 1

# Bot → 用户 发图片
lansenger message send-text staff123 "Photo" --file /path/to/photo.png --media-type 2

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
lansenger message send-text group123 "@张三 please check" --group --mention staff456

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
lansenger message query-groups --json
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
lansenger message send-reminder msg123 --type 1 --user staff456 --json
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