# lansenger message revoke

Revoke (delete) previously sent messages.

**继承** [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md) 的所有规则（Shell 执行纪律、Help-First 原则、认证、权限处理）。

**Safety:** Always confirm with the user which messages to revoke. Revoking removes messages from the recipient's view — this action cannot be undone.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| message_ids | args | yes | One or more message IDs to revoke (space-separated) |
| --chat-type | option | no | Chat type context (e.g., p2p, group) for the messages |
| --sender-id | option | no | Sender staff ID (required if the original sender identity is needed for auth) |

## Examples

```bash
lansenger message revoke msg_abc123

lansenger message revoke msg_abc123 msg_def456 msg_ghi789

lansenger message revoke msg_abc123 --chat-type p2p

lansenger message revoke msg_abc123 --chat-type group --sender-id staff_001

lansenger message revoke msg_abc123 msg_def456 --chat-type p2p --sender-id staff_001
```

## Common Mistakes

- Revoking a message you did not send — revoke only works for messages sent by the authenticated identity.
- Forgetting `--chat-type` when the API needs it — some revoke endpoints require the chat type to locate the message.
- Not confirming with the user before revoking — revoked messages disappear for recipients and cannot be restored.
- Passing message IDs as comma-separated instead of space-separated — this command takes multiple positional args, not a single list.

## Return Value

Returns confirmation of revocation for each message:

```json
{
  "revoked": ["msg_abc123", "msg_def456"]
}
```