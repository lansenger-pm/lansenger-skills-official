# lansenger message send-link-card

向聊天发送链接卡片消息。

**继承** [`../../lansenger-shared/SKILL.md`](../../lansenger-shared/SKILL.md) 中的所有规则（Shell 规范、帮助优先、认证、权限）。

**安全提醒：** 发送前务必与用户确认收件人和链接详情。请勿发送用户未明确批准的链接。

## 参数

| 参数 | 类型 | 必填 | 描述 |
|-----------|------|----------|-------------|
| chat_id | arg | 是 | 目标聊天 ID |
| title | arg | 是 | 卡片标题文本 |
| link | arg | 是 | 卡片点击后跳转的 URL |
| --desc / -d | option | 否 | 标题下方的描述文本 |
| --icon | option | 否 | 卡片图标 URL |
| --pc-link | option | 否 | PC 客户端单独的 URL |
| --pad-link | option | 否 | Pad/移动端客户端单独的 URL |
| --from-name | option | 否 | 卡片上显示的发送者名称 |
| --from-icon | option | 否 | 卡片上显示的发送者图标 URL |
| --group / -g | option | 否 | 发送到群聊（将 chat_id 视为群 ID） |
| --user-token | option | 否 | 用户令牌。群聊中以用户身份发送（替代 `--sender-id`），私聊中切换 robot→用户身份 |
| --sender-id | option | 否 | 发送者 staffId，用于群聊中指定消息显示身份。与 `--user-token` 至少提供一个（OpenAPI 4.6.2） |

## 示例

```bash
lansenger message send-link-card user_123 "Project Docs" "https://docs.example.com"

lansenger message send-link-card grp_456 "Dashboard" "https://app.example.com" --group --desc "Live metrics view"

lansenger message send-link-card user_123 "Release Notes" "https://blog.example.com/v2" --icon "https://example.com/icon.png" --pc-link "https://pc.example.com"

lansenger message send-link-card grp_456 "Wiki" "https://wiki.example.com" --group --from-name "Dev Team" --from-icon "https://example.com/team.png" --user-token $TOKEN
```

## 常见错误

- 使用群 ID 但未加 `--group` 标志 — 命令会将其视为私聊 ID。
- 目标平台需要不同 URL 时未提供 `--pc-link` 或 `--pad-link` — 所有客户端将使用相同的链接。
- 为 `--icon` 提供了无效的 URL — 卡片将以无图标方式渲染。
- 忘记 `title` 和 `link` 是位置参数而非选项 — 以标志形式传递将失败。

## 返回值

返回已发送消息的消息 ID：

```json
{
  "msg_id": "msg_abc123"
}
```
