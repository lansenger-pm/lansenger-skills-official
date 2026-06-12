# lansenger message send-account-message

Send a message via the account channel (using a specific account identity) to chats or departments.

**继承** [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md) 的所有规则（Shell 执行纪律、Help-First 原则、认证、权限处理）。

**Safety:** Always confirm recipients and message content with the user before sending. Account messages appear as coming from a specific person's account — do not send without explicit user approval, as the message will carry that account's identity.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| msg_type | arg | yes | Message type (e.g., text, markdown, image, file) |
| msg_data | arg | yes | JSON object containing the message body data |
| --chat-id | option | no | List of chat IDs to send to (comma-separated or repeated) |
| --dept | option | no | List of department IDs to broadcast to (comma-separated or repeated) |
| --account-id | option | no | Account ID to send from (specifies the account identity) |
| --entry-id | option | no | Entry ID for the account channel |
| --attach | option | no | Attachment data (JSON) |
| --user-token | option | no | User token |

## Examples

```bash
lansenger message send-account-message text '{"text":"Notification from ops account"}' --chat-id user_123,user_456 --account-id acct_ops

lansenger message send-account-message markdown '{"content":"**Alert**: Server down"}' --dept dept_001 --account-id acct_ops --entry-id entry_abc

lansenger message send-account-message text '{"text":"Document attached"}' --chat-id user_789 --account-id acct_ops --attach '{"file_key":"file_abc","file_name":"report.pdf"}'

lansenger message send-account-message text '{"text":"Weekly summary"}' --chat-id grp_456 --account-id acct_ops --user-token $TOKEN
```

## Common Mistakes

- Passing `msg_data` as plain text instead of JSON — must be a valid JSON object.
- Forgetting `--account-id` — the command will fail or use a default that may not be intended.
- Specifying neither `--chat-id` nor `--dept` — the command has no recipients and will fail.
- Sending an account message without the user's awareness of the account identity being used — recipients see it as coming from that account, which may be misleading.

## Return Value

Returns the message IDs of the sent messages:

```json
{
  "msg_ids": ["msg_abc123", "msg_def456"]
}
```