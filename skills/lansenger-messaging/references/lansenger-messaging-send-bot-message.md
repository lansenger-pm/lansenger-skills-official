# lansenger message send-bot-message

Send a message via the bot channel to specified chats or departments.

**Inherits** all rules from [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md) (Shell discipline, Help-First, auth, permissions).

**Safety:** Always confirm recipients and message content with the user before sending. Bot messages are sent from the application bot identity — do not send without explicit user approval.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| msg_type | arg | yes | Message type (e.g., text, markdown, image, file, interactive) |
| msg_data | arg | yes | JSON object containing the message body data |
| --chat-id | option | no | List of chat IDs to send to (comma-separated or repeated) |
| --dept | option | no | List of department IDs to broadcast to (comma-separated or repeated) |
| --user-token | option | no | User token (overrides app token for specific contexts) |
| --entry-id | option | no | Bot entry ID (specifies which bot identity to use) |
| --group / -g | option | no | Interpret chat IDs as group IDs |

## Examples

```bash
lansenger message send-bot-message text '{"text":"Hello from the bot"}' --chat-id user_123,user_456

lansenger message send-bot-message interactive '{"header":{"title":{"tag":"plain_text","content":"Approval"}},"elements":[{"tag":"div","text":{"tag":"plain_text","content":"Please approve"}}]}' --chat-id grp_789 --group

lansenger message send-bot-message text '{"text":"Maintenance notice"}' --dept dept_001,dept_002 --entry-id bot_entry_abc

lansenger message send-bot-message markdown '{"content":"**Bold** announcement"}' --chat-id grp_456 --group --user-token $TOKEN
```

## Common Mistakes

- Passing `msg_data` as plain text instead of JSON — must be a valid JSON object matching the msg_type schema.
- Using `--chat-id` without `--group` for group IDs — group IDs will be misinterpreted as private chat IDs.
- Specifying neither `--chat-id` nor `--dept` — the command has no recipients and will fail.
- Forgetting `--entry-id` when multiple bot identities exist — the wrong bot may send the message.

## Return Value

Returns the message IDs of the sent messages:

```json
{
  "msg_ids": ["msg_abc123", "msg_def456"]
}
```