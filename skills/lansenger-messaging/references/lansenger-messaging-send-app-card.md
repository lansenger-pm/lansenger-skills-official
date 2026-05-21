# lansenger message send-app-card

Send an app card message to a chat.

**Prerequisite:** Read [../lansenger-shared/SKILL.md](../lansenger-shared/SKILL.md) for authentication and token setup.

**Safety:** Always confirm the recipient and card content with the user before sending. Do not send cards the user has not explicitly approved.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| chat_id | arg | yes | Target chat ID |
| body_title | arg | yes | Main title of the card body |
| --head-title | option | no | Header title text |
| --sub-title | option | no | Subtitle text |
| --content | option | no | Body content text |
| --signature | option | no | Signature/app name displayed on the card |
| --card-link | option | no | URL the card links to when clicked |
| --pc-card-link | option | no | Card link URL for PC client |
| --pad-card-link | option | no | Card link URL for pad/mobile client |
| --dynamic | flag | no | Mark the card as dynamic (supports later updates) |
| --staff-id | option | no | Staff ID displayed as sender on the card |
| --head-icon | option | no | Header icon URL |
| --status-desc | option | no | Status description text |
| --status-colour | option | no | Status colour (e.g., green, red, grey) |
| --field | option | no | JSON list of field entries (name/value pairs) |
| --link | option | no | JSON list of link entries (name/URL pairs) |
| --group / -g | option | no | Send to a group chat (interprets chat_id as group ID) |
| --user-token | option | no | User token for user-token channel messaging |
| --sender-id | option | no | Sender staff ID |

## Examples

```bash
lansenger message send-app-card user_123 "Approval Request" --head-title "HR System" --content "Please review" --signature "HR Bot"

lansenger message send-app-card grp_456 "Task Update" --group --dynamic --status-desc "In Progress" --status-colour green

lansenger message send-app-card user_123 "Report" --field '[{"name":"Status","value":"Done"},{"name":"Score","value":"95"}]' --link '[{"name":"View","url":"https://app.example.com"}]'

lansenger message send-app-card grp_456 "Alert" --group --head-icon "https://example.com/alert.png" --staff-id staff_001 --card-link "https://app.example.com/alerts" --user-token $TOKEN
```

## Common Mistakes

- Using a group ID without `--group` flag — the command treats it as a private chat ID.
- Passing `--field` or `--link` as plain strings instead of JSON — must be valid JSON arrays.
- Setting `--dynamic` but not saving the returned msg_id — needed for `update-dynamic-card`.
- Forgetting `--signature` — the card may appear without a clear source/brand.
- Using wrong colour names for `--status-colour` — must match supported values (green, red, grey, etc.).

## Return Value

Returns the message ID of the sent message:

```json
{
  "msg_id": "msg_abc123"
}
```