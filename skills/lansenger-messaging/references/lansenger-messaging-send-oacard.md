# lansenger message send-oacard

向聊天发送 OA 卡片消息（官方公告卡片）。

**继承** [`../../lansenger-shared/SKILL.md`](../../lansenger-shared/SKILL.md) 中的所有规则（Shell 规范、帮助优先、认证、权限）。

**安全提醒：** 发送前务必与用户确认收件人和卡片内容。OA 卡片属于正式消息 — 未经用户明确批准，切勿发送。

## 参数

| 参数 | 类型 | 必填 | 描述 |
|-----------|------|----------|-------------|
| chat_id | arg | 是 | 目标聊天 ID |
| title | arg | 是 | 卡片标题文本 |
| --head | option | 否 | 头部/标题文本 |
| --sub-title | option | 否 | 副标题文本 |
| --staff-id | option | 否 | 显示为发送者的员工 ID |
| --field | option | 否 | 字段条目 JSON 列表（name/value 对） |
| --link | option | 否 | 链接条目（name/URL） |
| --pc-link | option | 否 | PC 客户端链接 URL |
| --pad-link | option | 否 | Pad/移动端客户端链接 URL |
| --card-action | option | 否 | 定义卡片操作行为的 JSON 对象 |
| --group / -g | option | 否 | 发送到群聊（将 chat_id 视为群 ID） |
| --user-token | option | 否 | 用户令牌。群聊中以用户身份发送（替代 `--sender-id`），私聊中切换 robot→用户身份 |
| --sender-id | option | 否 | 发送者 staffId，用于群聊中指定消息显示身份。与 `--user-token` 至少提供一个（OpenAPI 4.6.2） |

## 示例

```bash
lansenger message send-oacard user_123 "Policy Update" --head "HR Department" --sub-title "Effective immediately"

lansenger message send-oacard grp_456 "System Maintenance" --group --field '[{"name":"Time","value":"2026-05-22 02:00"},{"name":"Duration","value":"2h"}]' --link '{"name":"Details","url":"https://ops.example.com"}'

lansenger message send-oacard user_123 "Annual Review" --staff-id staff_001 --card-action '{"type":"open_url","url":"https://hr.example.com/review"}' --user-token $TOKEN

lansenger message send-oacard grp_456 "Holiday Notice" --group --pc-link "https://hr.example.com/holidays" --pad-link "https://m.hr.example.com/holidays" --sender-id staff_001
```

> **key=value 格式**：`--field`、`--link` 参数支持 key=value 简写格式，避免命令行传 JSON 的引号问题：
> - `--field "Time=2026-05-22 02:00" --field "Duration=2h"` 代替 `--field '{"name":"Time","value":"2026-05-22 02:00"}'`
> - `--link "Details=https://ops.example.com"` 代替 `--link '{"name":"Details","url":"https://ops.example.com"}'`
> - 同时兼容旧 JSON 格式，json.loads() 失败时自动尝试 key=value 解析

> **Windows PowerShell 注意**：推荐使用 key=value 格式。如需传 JSON，PowerShell 下须用双引号包裹整个参数值，内部双引号用反引号 `` ` `` 转义：
> ```powershell
> lansenger message send-app-card user_123 "Report" --field "[{`"name`":`"Status`",`"value`":`"Done`"}]"
> ```

## 常见错误

- 使用群 ID 但未加 `--group` 标志 — 命令会将其视为私聊 ID。
- 将 `--field` 作为普通字符串而非 JSON 传递 — 必须是有效的 JSON 数组。
- 将 `--card-action` 作为普通字符串而非 JSON 传递 — 必须是有效的 JSON 对象。
- 当 OA 卡片需要显示特定发送者时忘记 `--staff-id` — 卡片可能显示默认/通用发送者。
- 混淆 `--link`（单个对象）与 `--field`（数组）— `--link` 是单个条目，`--field` 是列表。

## 返回值

返回已发送消息的消息 ID：

```json
{
  "msg_id": "msg_abc123"
}
```
