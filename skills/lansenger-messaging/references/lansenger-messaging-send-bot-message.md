# lansenger message send-bot-message

通过 Bot 通道向指定聊天或部门发送消息。

**继承** [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md) 中的所有规则（Shell 规范、帮助优先、认证、权限）。

**安全提醒：** 发送前务必与用户确认收件人和消息内容。Bot 消息以应用 Bot 身份发送 — 未经用户明确批准请勿发送。

## 参数

| 参数 | 类型 | 必填 | 描述 |
|-----------|------|----------|-------------|
| msg_type | arg | 是 | 消息类型（如 text, markdown, image, file, interactive） |
| msg_data | arg | 是 | 包含消息正文数据的 JSON 对象 |
| --chat-id | option | 否 | 要发送到的聊天 ID 列表（逗号分隔或重复指定） |
| --dept | option | 否 | 要广播到的部门 ID 列表（逗号分隔或重复指定） |
| --user-token | option | 否 | 用户令牌（在特定上下文中覆盖应用令牌） |
| --entry-id | option | 否 | Bot 入口 ID（指定使用哪个 Bot 身份） |
| --group / -g | option | 否 | 将聊天 ID 视为群 ID |

## 示例

```bash
lansenger message send-bot-message text '{"text":"Hello from the bot"}' --chat-id user_123,user_456

lansenger message send-bot-message interactive '{"header":{"title":{"tag":"plain_text","content":"Approval"}},"elements":[{"tag":"div","text":{"tag":"plain_text","content":"Please approve"}}]}' --chat-id grp_789 --group

lansenger message send-bot-message text '{"text":"Maintenance notice"}' --dept dept_001,dept_002 --entry-id bot_entry_abc

lansenger message send-bot-message markdown '{"content":"**Bold** announcement"}' --chat-id grp_456 --group --user-token $TOKEN
```

## 常见错误

- 将 `msg_data` 作为纯文本而非 JSON 传递 — 必须是匹配 msg_type 模式的有效 JSON 对象。
- 群 ID 未带 `--group` 使用 `--chat-id` — 群 ID 将被误解为私聊 ID。
- 既未指定 `--chat-id` 也未指定 `--dept` — 命令没有收件人，将会失败。
- 存在多个 Bot 身份时忘记 `--entry-id` — 可能由错误的 Bot 发送消息。

## 返回值

返回已发送消息的消息 ID 列表：

```json
{
  "msg_ids": ["msg_abc123", "msg_def456"]
}
```
