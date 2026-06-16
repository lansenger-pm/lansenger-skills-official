# lansenger message send-file

向聊天发送文件附件。

**继承** [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md) 中的所有规则（Shell 规范、帮助优先、认证、权限）。

**安全提醒：** 发送前务必与用户确认收件人和文件内容。请勿发送用户未明确批准的文件。

## 参数

| 参数 | 类型 | 必填 | 描述 |
|-----------|------|----------|-------------|
| chat_id | arg | 是 | 目标聊天 ID |
| file_path | arg | 是 | 要发送文件的本地路径 |
| --content / -c | option | 否 | 附带文件的文本内容 |
| --media-type | option | 否 | 媒体类型：video, image, audio, file（若省略则默认为 file，App/Bot 接口） |
| --cover-image | option | 否 | 封面图片路径（发送视频文件时必填） |
| --group / -g | option | 否 | 发送到群聊（将 chat_id 视为群 ID） |
| --user-token | option | 否 | 用户令牌。群聊中以用户身份发送（替代 `--sender-id`），私聊中切换 robot→用户身份 |
| --sender-id | option | 否 | 发送者 staffId，用于群聊中指定消息显示身份。与 `--user-token` 至少提供一个（OpenAPI 4.6.2） |

## 示例

```bash
lansenger message send-file user_123 /path/to/report.pdf

lansenger message send-file grp_456 /path/to/image.png --group --content "Screenshot of the dashboard"

lansenger message send-file user_123 /path/to/video.mp4 --media-type video --cover-image /path/to/cover.jpg --user-token $TOKEN

lansenger message send-file grp_456 /path/to/data.csv --group --sender-id staff_001
```

## 常见错误

- 使用群 ID 但未加 `--group` 标志 — 命令会将其视为私聊 ID。
- 提供了不存在的文件路径 — 命令将因文件未找到错误而失败。
- 需要上下文说明时忘记 `--content` — 文件发送时没有附带说明。
- 使用了错误的 `--media-type` — 可能导致接收方渲染异常。

## 返回值

返回已发送消息的消息 ID：

```json
{
  "msg_id": "msg_abc123"
}
```
