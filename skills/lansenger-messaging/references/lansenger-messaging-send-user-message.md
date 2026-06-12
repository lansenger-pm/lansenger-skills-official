# lansenger message send-user-message

Send a message directly to a user via the user messaging channel.

**继承** [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md) 的所有规则（Shell 执行纪律、Help-First 原则、认证、权限处理）。

**4.6.3 通道发送，必须传 `--user-token`（通过 lansenger-oauth 获取）。**

**Safety:** Always confirm the recipient and message content with the user before sending.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| receiver_id | arg | yes | Receiver user/staff ID |
| msg_type | arg | yes | Message type (e.g., text, markdown, image, file, interactive) |
| msg_data | arg | yes | JSON object containing the message body data |
| --user-token | option | **yes** | 4.6.3 通道必须传 userToken（OAuth2 获取） |
| --common | option | no | JSON object for common message config (e.g., chat_type, sender info) |
| --uuid | option | no | Unique message ID for deduplication |

## Examples

```bash
lansenger message send-user-message user_123 text '{"text":"Hi"}' --user-token $TOKEN

lansenger message send-user-message user_123 markdown '{"content":"**Important**: Please review"}' --user-token $TOKEN

lansenger message send-user-message user_123 interactive '{"header":{"title":{"tag":"plain_text","content":"Action needed"}},"elements":[{"tag":"div","text":{"tag":"plain_text","content":"Click below"}}]}' --user-token $TOKEN --common '{"chat_type":"p2p"}'

lansenger message send-user-message user_123 text '{"text":"Unique notification"}' --user-token $TOKEN --uuid "notif-001"
```

## Common Mistakes

- 不传 `--user-token` — 4.6.3 通道必须传，否则认证失败
- Passing `msg_data` as plain text instead of JSON — must be a valid JSON object.
- Using a group ID as `receiver_id` — this is for 1:1 private chat only; use `send-group-message` for groups.
- Providing invalid JSON for `--common` — must be a properly formatted JSON object.

## Return Value

Returns the message ID of the sent message:

```json
{
  "msg_id": "msg_abc123"
}
```