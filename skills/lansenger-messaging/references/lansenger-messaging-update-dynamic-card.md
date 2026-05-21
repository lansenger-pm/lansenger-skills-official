# lansenger message update-dynamic-card

Update a previously sent dynamic app card message.

**Prerequisite:** Read [../lansenger-shared/SKILL.md](../lansenger-shared/SKILL.md) for authentication and token setup.

**Safety:** Always confirm the updated content with the user before modifying a sent card. Dynamic card updates change the visible content for all recipients who received the original card.

**Important:** This command only works on cards that were originally sent with `--dynamic` flag via `send-app-card`.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| msg_id | arg | yes | Message ID of the original dynamic card to update |
| --last | flag | no | Mark this as the last update (card becomes static, no further updates allowed) |
| --status-desc | option | no | Updated status description text |
| --status-colour | option | no | Updated status colour (e.g., green, red, grey) |
| --link | option | no | JSON list of updated link entries (name/URL pairs) |

## Examples

```bash
lansenger message update-dynamic-card msg_abc123 --status-desc "Completed" --status-colour green

lansenger message update-dynamic-card msg_abc123 --status-desc "Failed" --status-colour red --last

lansenger message update-dynamic-card msg_abc123 --link '[{"name":"View Result","url":"https://app.example.com/result"}]'

lansenger message update-dynamic-card msg_abc123 --status-desc "In Review" --status-colour grey --link '[{"name":"Details","url":"https://app.example.com/details"},{"name":"History","url":"https://app.example.com/history"}]'
```

## Common Mistakes

- Trying to update a card that was not sent with `--dynamic` — only dynamic cards can be updated.
- Using `--last` when you intend to update again later — after `--last`, no further updates are allowed.
- Passing `--link` as a plain string instead of JSON — must be a valid JSON array.
- Not saving the original msg_id from `send-app-card` — you need it to call this command.

## Return Value

Returns confirmation of the update:

```json
{
  "msg_id": "msg_abc123",
  "updated": true
}
```