# lansenger message send-text

Send a plain text message to a chat.

**继承** [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md) 的所有规则（Shell 执行纪律、Help-First 原则、认证、权限处理）。

**Safety:** Always confirm the recipient and message content with the user before sending. Do not send messages the user has not explicitly approved.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| chat_id | arg | yes | Target chat ID (user ID for private chat, or chat ID) |
| content | arg | yes | Text content to send |
| --file / -f | option | no | Path to a text file whose content is sent as the message body |
| --group / -g | option | no | Send to a group chat (interprets chat_id as group ID) |
| --mention-all | flag | no | Mention all members in the group |
| --mention | option | no | List of user IDs to @mention (comma-separated) |
| --media-type | option | no | Media type: video, image, audio, file (defaults to file if omitted, App/Bot interface) |
| --cover-image | option | no | Cover image path (required when sending video with --file) |
| --user-token | option | no | User token for user-token channel messaging |
| --sender-id | option | no | Sender staff ID (required for some channels) |

## Examples

```bash
lansenger message send-text user_123 "Hello, this is a test message"

lansenger message send-text grp_456 "Meeting at 3pm" --group --mention-all

lansenger message send-text user_123 "Check this out" --mention user_789,user_012

lansenger message send-text grp_456 "Status update" --group --user-token $TOKEN --sender-id staff_001

lansenger message send-text user_123 "" --file /path/to/message.txt

lansenger message send-text user_123 "See this clip" --file /path/to/video.mp4 --media-type video --cover-image /path/to/cover.jpg
```

## Common Mistakes

- Using a group ID without `--group` flag — the command treats it as a private chat ID.
- Passing `--mention` without `--group` — mentions only work in group chats.
- Forgetting `--sender-id` when using channels that require it — the message will fail to send.
- Using `--file` and a content argument simultaneously — the file content overrides the argument.

## Return Value

Returns the message ID of the sent message:

```json
{
  "msg_id": "msg_abc123"
}
```