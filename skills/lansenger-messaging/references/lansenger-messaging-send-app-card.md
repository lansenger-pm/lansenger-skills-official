# lansenger message send-app-card

向聊天发送应用卡片消息。

**继承** [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md) 中的所有规则（Shell 规范、帮助优先、认证、权限）。

**安全提醒：** 发送前务必与用户确认收件人和卡片内容。请勿发送用户未明确批准的卡片。

## 参数

| 参数 | 类型 | 必填 | 描述 |
|-----------|------|----------|-------------|
| chat_id | arg | 是 | 目标聊天 ID |
| body_title | arg | 是 | 卡片正文主标题 |
| --head-title | option | 否 | 头部标题文本 |
| --sub-title | option | 否 | 副标题文本 |
| --content | option | 否 | 正文内容文本 |
| --signature | option | 否 | 卡片上显示的签名/应用名称 |
| --card-link | option | 否 | 卡片点击后跳转的 URL |
| --pc-card-link | option | 否 | PC 客户端卡片链接 URL |
| --pad-card-link | option | 否 | Pad/移动端客户端卡片链接 URL |
| --dynamic | flag | 否 | 将卡片标记为动态卡片（支持后续更新） |
| --staff-id | option | 否 | 卡片上显示的发送者员工 ID |
| --head-icon | option | 否 | 头部图标 URL |
| --status-desc | option | 否 | 状态描述文本 |
| --status-colour | option | 否 | 状态颜色（如 green, red, grey） |
| --field | option | 否 | 字段条目 JSON 列表（name/value 对） |
| --link | option | 否 | 链接条目 JSON 列表（name/URL 对） |
| --group / -g | option | 否 | 发送到群聊（将 chat_id 视为群 ID） |
| --user-token | option | 否 | 用户令牌。群聊中以用户身份发送（替代 `--sender-id`），私聊中切换 robot→用户身份 |
| --sender-id | option | 否 | 发送者 staffId，用于群聊中指定消息显示身份。与 `--user-token` 至少提供一个（OpenAPI 4.6.2） |

## 示例

```bash
lansenger message send-app-card user_123 "Approval Request" --head-title "HR System" --content "Please review" --signature "HR Bot"

lansenger message send-app-card grp_456 "Task Update" --group --dynamic --status-desc "In Progress" --status-colour green

lansenger message send-app-card user_123 "Report" --field '[{"name":"Status","value":"Done"},{"name":"Score","value":"95"}]' --link '[{"name":"View","url":"https://app.example.com"}]'

lansenger message send-app-card grp_456 "Alert" --group --head-icon "https://example.com/alert.png" --staff-id staff_001 --card-link "https://app.example.com/alerts" --user-token $TOKEN
```

> **key=value 格式**：`--field`、`--link`、`--fields` 参数支持 key=value 简写格式，避免命令行传 JSON 的引号问题：
> - `--field "Status=Done" --field "Score=95"` 代替 `--field '{"name":"Status","value":"Done"}'`
> - `--link "View=https://app.example.com"` 代替 `--link '{"name":"View","url":"https://app.example.com"}'`
> - 同时兼容旧 JSON 格式，json.loads() 失败时自动尝试 key=value 解析

> **Windows PowerShell 注意**：PowerShell 环境下建议优先使用 key=value 格式，避免 JSON 引号转义问题。

## 常见错误

- 使用群 ID 但未加 `--group` 标志 — 命令会将其视为私聊 ID。
- 将 `--field` 或 `--link` 作为普通字符串而非 JSON 传递 — 必须是有效的 JSON 数组。
- 设置了 `--dynamic` 但未保存返回的 msg_id — 调用 `update-dynamic-card` 时需要此 ID。
- 忘记 `--signature` — 卡片可能显示时缺少清晰的来源/品牌标识。
- 为 `--status-colour` 使用了错误的颜色名称 — 必须匹配支持的值（green, red, grey 等）。

## 返回值

返回已发送消息的消息 ID：

```json
{
  "msg_id": "msg_abc123"
}
```
