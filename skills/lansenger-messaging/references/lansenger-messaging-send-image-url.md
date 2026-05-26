# lansenger message send-image-url

Send an image by URL to a chat.

**Prerequisite:** Read [../lansenger-shared/SKILL.md](../lansenger-shared/SKILL.md) for authentication and token setup.

**Safety:** Always confirm the recipient and image content with the user before sending. Do not send images the user has not explicitly approved.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| chat_id | arg | yes | Target chat ID |
| image_url | arg | yes | URL of the image to send |
| --content / -c | option | no | Text content accompanying the image |
| --group / -g | option | no | Send to a group chat (interprets chat_id as group ID) |
| --user-token | option | no | User token for user-token channel messaging |
| --sender-id | option | no | Sender staff ID |

## Examples

```bash
lansenger message send-image-url user_123 "https://example.com/photo.png"

lansenger message send-image-url grp_456 "https://example.com/dashboard.png" --group --content "Current dashboard view"

lansenger message send-image-url user_123 "https://cdn.example.com/img.jpg" --content "Screenshot" --user-token $TOKEN

lansenger message send-image-url grp_456 "https://example.com/chart.svg" --group --sender-id staff_001
```

## Common Mistakes

- Using a group ID without `--group` flag — the command treats it as a private chat ID.
- Providing a non-accessible image URL — the recipient will see a broken image or download failure.
- Using a local file path instead of a URL — use `send-file` for local files, this command only accepts URLs.
- Forgetting `--content` when context is needed — the image arrives without explanation.

## Return Value

Returns the message ID of the sent message:

```json
{
  "msg_id": "msg_abc123"
}
```