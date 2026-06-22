# lansenger message send-text

向聊天发送纯文本消息。

**继承** [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md) 中的所有规则（Shell 规范、帮助优先、认证、权限）。

**安全提醒：** 发送前务必与用户确认收件人和消息内容。请勿发送用户未明确批准的消息。

## 参数

| 参数 | 类型 | 必填 | 描述 |
|-----------|------|----------|-------------|
| chat_id | arg | 是 | 目标聊天 ID（私聊时为用户 ID，或聊天 ID） |
| content | arg | 是 | 要发送的文本内容 |
| --file / -f | option | 否 | 文本文件路径，其内容将作为消息正文发送 |
| --group / -g | option | 否 | 发送到群聊（将 chat_id 视为群 ID） |
| --mention-all | flag | 否 | @提及群内所有成员 |
| --mention | option | 否 | 要 @提及的用户 ID 列表（逗号分隔） |
| --mention-bot | option | 否 | 要 @提及的机器人 ID 列表（逗号分隔） |

> **CRITICAL**: 不要在消息内容中手动写 `@姓名`。蓝信 API 会根据 `--mention` 的 staffId / `--mention-bot` 的 botId 自动在消息前拼接 `@名称`。

| --ref-msg-id | option | 否 | 引用消息 openId，用于回复/引用上下文 |
| --media-type | option | 否 | 媒体类型：video, image, audio, file（若省略则默认为 file，App/Bot 接口） |
| --cover-image | option | 否 | 封面图片路径（使用 --file 发送视频时必填） |
| --user-token | option | 否 | 用户令牌。群聊中以用户身份发送（替代 `--sender-id`），私聊中切换 robot→用户身份 |
| --sender-id | option | 否 | 发送者 staffId，用于群聊中指定消息显示身份。与 `--user-token` 至少提供一个（OpenAPI 4.6.2） |

## 示例

```bash
lansenger message send-text user_123 "Hello, this is a test message"

lansenger message send-text grp_456 "Meeting at 3pm" --group --mention-all

lansenger message send-text user_123 "Check this out" --mention user_789,user_012

lansenger message send-text grp_456 "Status update" --group --user-token $TOKEN --sender-id staff_001

lansenger message send-text user_123 "" --file /path/to/message.txt

lansenger message send-text user_123 "See this clip" --file /path/to/video.mp4 --media-type video --cover-image /path/to/cover.jpg
```

## 常见错误

- 使用群 ID 但未加 `--group` 标志 — 命令会将其视为私聊 ID。
- 未在群聊中使用 `--mention` — @提及仅在群聊中有效。
- 群聊中既未传 `--user-token` 也未传 `--sender-id` — OpenAPI 4.6.2 要求至少提供一个（除非 App 有机器人能力）。
- 同时使用 `--file` 和 content 参数 — 文件内容会覆盖参数内容。

## 返回值

返回已发送消息的消息 ID：

```json
{
  "msg_id": "msg_abc123"
}
```
