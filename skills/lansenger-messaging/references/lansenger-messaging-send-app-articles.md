# lansenger message send-app-articles

向聊天发送应用文章消息（多文章卡片）。

**继承** [`../../lansenger-shared/SKILL.md`](../../lansenger-shared/SKILL.md) 中的所有规则（Shell 规范、帮助优先、认证、权限）。

**安全提醒：** 发送前务必与用户确认收件人和文章内容。请勿发送用户未明确批准的文章。

## 参数

| 参数 | 类型 | 必填 | 描述 |
|-----------|------|----------|-------------|
| chat_id | arg | 是 | 目标聊天 ID |
| articles | arg | 是 | 文章对象 JSON 列表（每个对象含 title、url，可选 desc/icon） |
| --group / -g | option | 否 | 发送到群聊（将 chat_id 视为群 ID） |
| --user-token | option | 否 | 用户令牌。群聊中以用户身份发送（替代 `--sender-id`），私聊中切换 robot→用户身份 |
| --sender-id | option | 否 | 发送者 staffId，用于群聊中指定消息显示身份。与 `--user-token` 至少提供一个（OpenAPI 4.6.2） |

## 示例

```bash
lansenger message send-app-articles user_123 '[{"title":"News 1","url":"https://news.example.com/1"},{"title":"News 2","url":"https://news.example.com/2"}]'

lansenger message send-app-articles grp_456 '[{"title":"Weekly Report","url":"https://app.example.com/report","summary":"Team metrics"},{"title":"Action Items","url":"https://app.example.com/actions"}]' --group

lansenger message send-app-articles user_123 '[{"title":"Feature","url":"https://docs.example.com","imgUrl":"https://example.com/icon.png"}]' --user-token $TOKEN --sender-id staff_001
```

## 常见错误

- 将 articles 作为多个独立参数而非单个 JSON 列表传递 — `articles` 参数必须是一个 JSON 数组字符串。
- 使用群 ID 但未加 `--group` 标志 — 命令会将其视为私聊 ID。
- 为 `articles` 提供了无效的 JSON — 必须是格式正确的 JSON 对象数组，每个对象至少包含 `title` 和 `url`。
- 忘记对 JSON 字符串加引号 — Shell 解析会因空格和特殊字符而出错。

## 返回值

返回已发送消息的消息 ID：

```json
{
  "msg_id": "msg_abc123"
}
```
