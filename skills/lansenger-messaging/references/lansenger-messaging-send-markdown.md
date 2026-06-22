# lansenger message send-markdown

向聊天发送 Markdown 格式的消息。

**继承** [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md) 中的所有规则（Shell 规范、帮助优先、认证、权限）。

**安全提醒：** 发送前务必与用户确认收件人和消息内容。请勿发送用户未明确批准的消息。

**重要：** Markdown 格式仅通过 `formatText` 通道生效 — 具体为 4.6.3（用户私聊）和 4.6.2（群聊）。Bot 私聊**不支持** Markdown。向 Bot 私聊发送 Markdown 将以纯文本形式渲染。

## 参数

| 参数 | 类型 | 必填 | 描述 |
|-----------|------|----------|-------------|
| chat_id | arg | 是 | 目标聊天 ID（私聊时为用户 ID，或聊天 ID） |
| content | arg | 是 | 要发送的 Markdown 内容 |
| --group / -g | option | 否 | 发送到群聊（将 chat_id 视为群 ID） |
| --mention-all | flag | 否 | @提及群内所有成员 |
| --mention | option | 否 | 要 @提及的用户 ID 列表（逗号分隔） |
| --mention-bot | option | 否 | 要 @提及的机器人 ID 列表（逗号分隔） |

> **CRITICAL**: 不要在消息内容中手动写 `@姓名`。蓝信 API 会根据 `--mention` 的 staffId / `--mention-bot` 的 botId 自动在消息前拼接 `@名称`。

| --ref-msg-id | option | 否 | 引用消息 openId，用于回复/引用上下文 |
| --user-token | option | 否 | 用户令牌。群聊中以用户身份发送（替代 `--sender-id`），私聊中切换 robot→用户身份 |
| --sender-id | option | 否 | 发送者 staffId，用于群聊中指定消息显示身份。与 `--user-token` 至少提供一个（OpenAPI 4.6.2） |

## 示例

```bash
lansenger message send-markdown user_123 "**Bold** and _italic_ text"

lansenger message send-markdown grp_456 "## Heading\n- Item 1\n- Item 2" --group

lansenger message send-markdown grp_456 "See" --group --mention user_789 --user-token $TOKEN

lansenger message send-markdown user_123 "```python\nprint('hello')\n```" --user-token $TOKEN --sender-id staff_001
```

## 常见错误

- 向 Bot 私聊发送 Markdown — Markdown 不会渲染；请改用普通的 `send-text`。
- 未在群聊中使用 `--mention` — @提及仅在群聊中有效。
- 未对 Markdown 内容中的特殊 Shell 字符进行转义 — 请用引号包裹内容或使用换行转义。
- 在用户私聊通道中忘记 `--user-token` — Markdown 需要 formatText 通道，该通道需要用户令牌。

## 返回值

返回已发送消息的消息 ID：

```json
{
  "msg_id": "msg_abc123"
}
```
