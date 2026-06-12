# lansenger message send-group-message

Send a message to a group chat via the group channel.

**Inherits** all rules from [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md) (Shell discipline, Help-First, auth, permissions).

**Safety:** Always confirm the group and message content with the user before sending. Group messages are visible to all members — do not send without explicit user approval.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| group_id | arg | yes | Target group ID |
| msg_type | arg | yes | Message type (e.g., text, markdown, image, file, interactive) |
| msg_data | arg | yes | JSON object containing the message body data |
| --user-token | option | no | User token for user-token channel |
| --sender-id | option | no | Sender staff ID |
| --mention-all | flag | no | Mention all group members |
| --mention | option | no | List of user IDs to @mention (comma-separated) |
| --outlines | option | no | Outlines/threading info |
| --entry-id | option | no | Entry ID specifying the sending identity |

## Examples

```bash
lansenger message send-group-message grp_456 text '{"text":"Team update: sprint completed"}'

lansenger message send-group-message grp_456 text '{"text":"Everyone please check"}' --mention-all

lansenger message send-group-message grp_456 markdown '{"content":"## Report\n- Item A\n- Item B"}' --mention user_123,user_789 --user-token $TOKEN

lansenger message send-group-message grp_456 interactive '{"header":{"title":{"tag":"plain_text","content":"Vote"}},"elements":[{"tag":"action","actions":[{"tag":"button","text":{"tag":"plain_text","content":"Yes"}}]}]}' --sender-id staff_001 --entry-id entry_abc
```

## Common Mistakes

- Passing `msg_data` as plain text instead of JSON — must be a valid JSON object matching the msg_type schema.
- Using `--mention` or `--mention-all` for a private chat — these only work in group context.
- Forgetting `--sender-id` when the group channel requires it — the message may fail or appear from a default identity.
- Confusing `group_id` (arg) with `--chat-id` (option used in other commands) — this command uses a positional group_id argument.

## Return Value

Returns the message ID of the sent message:

```json
{
  "msg_id": "msg_abc123"
}
```