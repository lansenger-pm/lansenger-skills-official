# lansenger message send-file

Send a file attachment to a chat.

**Prerequisite:** Read [../lansenger-shared/SKILL.md](../lansenger-shared/SKILL.md) for authentication and token setup.

**Safety:** Always confirm the recipient and file content with the user before sending. Do not send files the user has not explicitly approved.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| chat_id | arg | yes | Target chat ID |
| file_path | arg | yes | Local path to the file to send |
| --caption / -c | option | no | Text caption accompanying the file |
| --media-type | option | no | Media type hint (e.g., image, video, document) |
| --group / -g | option | no | Send to a group chat (interprets chat_id as group ID) |
| --user-token | option | no | User token for user-token channel messaging |
| --sender-id | option | no | Sender staff ID |

## Examples

```bash
lansenger message send-file user_123 /path/to/report.pdf

lansenger message send-file grp_456 /path/to/image.png --group --caption "Screenshot of the dashboard"

lansenger message send-file user_123 /path/to/video.mp4 --media-type video --user-token $TOKEN

lansenger message send-file grp_456 /path/to/data.csv --group --sender-id staff_001
```

## Common Mistakes

- Using a group ID without `--group` flag — the command treats it as a private chat ID.
- Providing a non-existent file path — the command will fail with a file-not-found error.
- Forgetting `--caption` when context is needed — the file arrives without explanation.
- Using wrong `--media-type` — may cause incorrect rendering on the recipient side.

## Return Value

Returns the message ID of the sent message:

```json
{
  "msg_id": "msg_abc123"
}
```