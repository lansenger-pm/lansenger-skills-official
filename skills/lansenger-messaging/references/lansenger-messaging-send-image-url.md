# lansenger message send-image-url

向聊天发送通过 URL 引用的图片。

**继承** [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md) 中的所有规则（Shell 规范、帮助优先、认证、权限）。

**安全提醒：** 发送前务必与用户确认收件人和图片内容。请勿发送用户未明确批准的图片。

## 参数

| 参数 | 类型 | 必填 | 描述 |
|-----------|------|----------|-------------|
| chat_id | arg | 是 | 目标聊天 ID |
| image_url | arg | 是 | 要发送图片的 URL |
| --content / -c | option | 否 | 附带图片的文本内容 |
| --group / -g | option | 否 | 发送到群聊（将 chat_id 视为群 ID） |
| --user-token | option | 否 | 用户令牌。群聊中以用户身份发送（替代 `--sender-id`），私聊中切换 robot→用户身份 |
| --sender-id | option | 否 | 发送者 staffId，用于群聊中指定消息显示身份。与 `--user-token` 至少提供一个（OpenAPI 4.6.2） |

## 示例

```bash
lansenger message send-image-url user_123 "https://example.com/photo.png"

lansenger message send-image-url grp_456 "https://example.com/dashboard.png" --group --content "Current dashboard view"

lansenger message send-image-url user_123 "https://cdn.example.com/img.jpg" --content "Screenshot" --user-token $TOKEN

lansenger message send-image-url grp_456 "https://example.com/chart.svg" --group --sender-id staff_001
```

## 常见错误

- 使用群 ID 但未加 `--group` 标志 — 命令会将其视为私聊 ID。
- 提供了不可访问的图片 URL — 接收方将看到损坏的图片或下载失败。
- 使用了本地文件路径而非 URL — 本地文件请使用 `send-file`，此命令仅接受 URL。
- 需要上下文说明时忘记 `--content` — 图片发送时没有附带说明。

## 返回值

返回已发送消息的消息 ID：

```json
{
  "msg_id": "msg_abc123"
}
```
