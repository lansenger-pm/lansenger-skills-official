# lansenger message send-group-message

通过群通道向群聊发送消息。

**继承** [`../../lansenger-shared/SKILL.md`](../../lansenger-shared/SKILL.md) 中的所有规则（Shell 规范、帮助优先、认证、权限）。

**安全提醒：** 发送前务必与用户确认群组和消息内容。群消息对所有成员可见 — 未经用户明确批准请勿发送。

## 参数

| 参数 | 类型 | 必填 | 描述 |
|-----------|------|----------|-------------|
| group_id | arg | 是 | 目标群 ID |
| msg_type | arg | 是 | 消息类型（如 text, markdown, image, file, interactive） |
| msg_data | arg | 是 | 包含消息正文数据的 JSON 对象 |
| --user-token | option | 否* | 用户令牌。与 `--sender-id` 至少提供一个（OpenAPI 4.6.2 要求）。以用户身份发消息时使用 |
| --sender-id | option | 否* | 发送者 staffId。与 `--user-token` 至少提供一个。不传 user_token 时以指定 staffId 身份发送 |
| --mention-all | flag | 否 | @提及所有群成员 |
| --mention | option | 否 | 要 @提及的用户 ID 列表（逗号分隔） |
| --mention-bot | option | 否 | 要 @提及的机器人 ID 列表（逗号分隔） |

> **CRITICAL**: 不要在消息内容中手动写 `@姓名`。蓝信 API 会根据 `--mention` 的 staffId / `--mention-bot` 的 botId 自动在消息前拼接 `@名称`。

| --ref-msg-id | option | 否 | 引用消息 openId，用于回复/引用上下文 |
| --outlines | option | 否 | 提纲/话题线索信息 |
| --entry-id | option | 否 | 指定发送身份的入口 ID |

## 示例

```bash
lansenger message send-group-message grp_456 text '{"text":"Team update: sprint completed"}'

lansenger message send-group-message grp_456 text '{"text":"Everyone please check"}' --mention-all

lansenger message send-group-message grp_456 markdown '{"content":"## Report\n- Item A\n- Item B"}' --mention user_123,user_789 --user-token $TOKEN

lansenger message send-group-message grp_456 interactive '{"header":{"title":{"tag":"plain_text","content":"Vote"}},"elements":[{"tag":"action","actions":[{"tag":"button","text":{"tag":"plain_text","content":"Yes"}}]}]}' --sender-id staff_001 --entry-id entry_abc
```

## 常见错误

- 将 `msg_data` 作为纯文本而非 JSON 传递 — 必须是匹配 msg_type 模式的有效 JSON 对象。
- 在私聊中使用 `--mention` 或 `--mention-all` — 这些仅在群聊上下文中有效。
- 既未传 `--user-token` 也未传 `--sender-id` — OpenAPI 4.6.2 要求至少提供一个（除非 App 有机器人能力）。
- 将 `group_id`（位置参数）与 `--chat-id`（其他命令中使用的选项）混淆 — 此命令使用位置参数 group_id。

## 返回值

返回已发送消息的消息 ID：

```json
{
  "msg_id": "msg_abc123"
}
```
