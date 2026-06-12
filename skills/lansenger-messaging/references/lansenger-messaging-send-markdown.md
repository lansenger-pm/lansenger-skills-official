# lansenger message send-markdown

Send a Markdown-formatted message to a chat.

**Inherits** all rules from [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md) (Shell discipline, Help-First, auth, permissions).

**Safety:** Always confirm the recipient and message content with the user before sending. Do not send messages the user has not explicitly approved.

**Important:** Markdown formatting only works via the `formatText` channel — specifically 4.6.3 (user private chat) and 4.6.2 (group chat). Markdown is **not supported** in bot private chat. Sending Markdown to a bot private chat will render as plain text.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| chat_id | arg | yes | Target chat ID (user ID for private chat, or chat ID) |
| content | arg | yes | Markdown content to send |
| --group / -g | option | no | Send to a group chat (interprets chat_id as group ID) |
| --mention-all | flag | no | Mention all members in the group |
| --mention | option | no | List of user IDs to @mention (comma-separated) |
| --user-token | option | no | User token for user-token channel messaging |
| --sender-id | option | no | Sender staff ID (required for some channels) |

## Examples

```bash
lansenger message send-markdown user_123 "**Bold** and _italic_ text"

lansenger message send-markdown grp_456 "## Heading\n- Item 1\n- Item 2" --group

lansenger message send-markdown grp_456 "See @user_789" --group --mention user_789 --user-token $TOKEN

lansenger message send-markdown user_123 "```python\nprint('hello')\n```" --user-token $TOKEN --sender-id staff_001
```

## Common Mistakes

- Sending Markdown to a bot private chat — Markdown will not render; use plain `send-text` instead.
- Using `--mention` without `--group` — mentions only work in group chats.
- Not escaping special shell characters in Markdown content — wrap content in quotes or use newline escapes.
- Forgetting `--user-token` for user-private-chat channel — Markdown requires the formatText channel which needs a user token.

## Return Value

Returns the message ID of the sent message:

```json
{
  "msg_id": "msg_abc123"
}
```