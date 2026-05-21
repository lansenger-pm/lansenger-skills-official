# lansenger message send-user-message

Send a message directly to a user via the user messaging channel.

**Prerequisite:** Read [../lansenger-shared/SKILL.md](../lansenger-shared/SKILL.md) for authentication and token setup.

**Safety:** Always confirm the recipient and message content with the user before sending. Do not send messages the user has not explicitly approved.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| receiver_id | arg | yes | Receiver user/staff ID |
| msg_type | arg | yes | Message type (e.g., text, markdown, image, file, interactive) |
| msg_data | arg | yes | JSON object containing the message body data |
| --user-token | option | no | User token for authentication |
| --common | option | no | JSON object for common message config (e.g., chat_type, sender info) |
| --uuid | option | no | Unique message ID for deduplication |

## Examples

```bash
lansenger message send-user-message user_123 text '{"text":"Direct message from the system"}'

lansenger message send-user-message user_123 markdown '{"content":"**Important**: Please review"}' --user-token $TOKEN

lansenger message send-user-message user_123 interactive '{"header":{"title":{"tag":"plain_text","content":"Action needed"}},"elements":[{"tag":"div","text":{"tag":"plain_text","content":"Click below"}}]}' --common '{"chat_type":"p2p"}'

lansenger message send-user-message user_123 text '{"text":"Unique notification"}' --uuid "notif-2026-05-21-001"
```

## Common Mistakes

- Passing `msg_data` as plain text instead of JSON — must be a valid JSON object matching the msg_type schema.
- Using a group ID as `receiver_id` — this command is for direct user messages only; use `send-group-message` for groups.
- Forgetting `--user-token` when required by the channel — the message will fail with an auth error.
- Providing invalid JSON for `--common` — must be a properly formatted JSON object.

## Return Value

Returns the message ID of the sent message:

```json
{
  "msg_id": "msg_abc123"
}
```