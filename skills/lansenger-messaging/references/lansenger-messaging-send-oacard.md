# lansenger message send-oacard

Send an OA card message (official announcement card) to a chat.

**Inherits** all rules from [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md) (Shell discipline, Help-First, auth, permissions).

**Safety:** Always confirm the recipient and card content with the user before sending. OA cards are formal — do not send them without explicit user approval.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| chat_id | arg | yes | Target chat ID |
| title | arg | yes | Card title text |
| --head | option | no | Header/headline text |
| --sub-title | option | no | Subtitle text |
| --staff-id | option | no | Staff ID displayed as sender |
| --field | option | no | JSON list of field entries (name/value pairs) |
| --link | option | no | Link entry (name/URL) |
| --pc-link | option | no | Link URL for PC client |
| --pad-link | option | no | Link URL for pad/mobile client |
| --card-action | option | no | JSON object defining card action behavior |
| --group / -g | option | no | Send to a group chat (interprets chat_id as group ID) |
| --user-token | option | no | User token for user-token channel messaging |
| --sender-id | option | no | Sender staff ID |

## Examples

```bash
lansenger message send-oacard user_123 "Policy Update" --head "HR Department" --sub-title "Effective immediately"

lansenger message send-oacard grp_456 "System Maintenance" --group --field '[{"name":"Time","value":"2026-05-22 02:00"},{"name":"Duration","value":"2h"}]' --link '{"name":"Details","url":"https://ops.example.com"}'

lansenger message send-oacard user_123 "Annual Review" --staff-id staff_001 --card-action '{"type":"open_url","url":"https://hr.example.com/review"}' --user-token $TOKEN

lansenger message send-oacard grp_456 "Holiday Notice" --group --pc-link "https://hr.example.com/holidays" --pad-link "https://m.hr.example.com/holidays" --sender-id staff_001
```

## Common Mistakes

- Using a group ID without `--group` flag — the command treats it as a private chat ID.
- Passing `--field` as a plain string instead of JSON — must be a valid JSON array.
- Passing `--card-action` as a plain string instead of JSON — must be a valid JSON object.
- Forgetting `--staff-id` when the OA card needs to show a specific sender — the card may appear with a default/generic sender.
- Mixing up `--link` (single object) with `--field` (array) — `--link` is a single entry, `--field` is a list.

## Return Value

Returns the message ID of the sent message:

```json
{
  "msg_id": "msg_abc123"
}
```