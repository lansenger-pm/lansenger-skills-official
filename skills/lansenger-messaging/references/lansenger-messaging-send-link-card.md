# lansenger message send-link-card

Send a link card message to a chat.

**Inherits** all rules from [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md) (Shell discipline, Help-First, auth, permissions).

**Safety:** Always confirm the recipient and link details with the user before sending. Do not send links the user has not explicitly approved.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| chat_id | arg | yes | Target chat ID |
| title | arg | yes | Card title text |
| link | arg | yes | URL the card links to |
| --desc / -d | option | no | Description text below the title |
| --icon | option | no | Icon URL for the card |
| --pc-link | option | no | Separate URL for PC client |
| --pad-link | option | no | Separate URL for pad/mobile client |
| --from-name | option | no | Sender display name on the card |
| --from-icon | option | no | Sender icon URL on the card |
| --group / -g | option | no | Send to a group chat (interprets chat_id as group ID) |
| --user-token | option | no | User token for user-token channel messaging |
| --sender-id | option | no | Sender staff ID |

## Examples

```bash
lansenger message send-link-card user_123 "Project Docs" "https://docs.example.com"

lansenger message send-link-card grp_456 "Dashboard" "https://app.example.com" --group --desc "Live metrics view"

lansenger message send-link-card user_123 "Release Notes" "https://blog.example.com/v2" --icon "https://example.com/icon.png" --pc-link "https://pc.example.com"

lansenger message send-link-card grp_456 "Wiki" "https://wiki.example.com" --group --from-name "Dev Team" --from-icon "https://example.com/team.png" --user-token $TOKEN
```

## Common Mistakes

- Using a group ID without `--group` flag — the command treats it as a private chat ID.
- Not providing `--pc-link` or `--pad-link` when the target platform needs a different URL — all clients will use the same link.
- Providing an invalid URL for `--icon` — the card will render without an icon.
- Forgetting that `title` and `link` are positional args, not options — passing them as flags will fail.

## Return Value

Returns the message ID of the sent message:

```json
{
  "msg_id": "msg_abc123"
}
```