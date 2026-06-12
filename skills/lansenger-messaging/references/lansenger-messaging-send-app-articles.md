# lansenger message send-app-articles

Send an app articles message (multi-article card) to a chat.

**Inherits** all rules from [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md) (Shell discipline, Help-First, auth, permissions).

**Safety:** Always confirm the recipient and article content with the user before sending. Do not send articles the user has not explicitly approved.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| chat_id | arg | yes | Target chat ID |
| articles | arg | yes | JSON list of article objects (each with title, url, and optional desc/icon) |
| --group / -g | option | no | Send to a group chat (interprets chat_id as group ID) |
| --user-token | option | no | User token for user-token channel messaging |
| --sender-id | option | no | Sender staff ID |

## Examples

```bash
lansenger message send-app-articles user_123 '[{"title":"News 1","url":"https://news.example.com/1"},{"title":"News 2","url":"https://news.example.com/2"}]'

lansenger message send-app-articles grp_456 '[{"title":"Weekly Report","url":"https://app.example.com/report","desc":"Team metrics"},{"title":"Action Items","url":"https://app.example.com/actions"}]' --group

lansenger message send-app-articles user_123 '[{"title":"Feature","url":"https://docs.example.com","icon":"https://example.com/icon.png"}]' --user-token $TOKEN --sender-id staff_001
```

## Common Mistakes

- Passing articles as separate arguments instead of a single JSON list — the `articles` arg must be one JSON array string.
- Using a group ID without `--group` flag — the command treats it as a private chat ID.
- Providing invalid JSON for `articles` — must be a properly formatted JSON array of objects, each with at least `title` and `url`.
- Forgetting to quote the JSON string — shell parsing will break on spaces and special characters.

## Return Value

Returns the message ID of the sent message:

```json
{
  "msg_id": "msg_abc123"
}
```