# lansenger message send-approve-card

向聊天发送审批卡片消息（支持@mention、按钮组、权限控制、到期时间）。

**继承** [`../../lansenger-shared/SKILL.md`](../../lansenger-shared/SKILL.md) 中的所有规则（Shell 规范、帮助优先、认证、权限）。

**安全提醒：** 发送前务必与用户确认审批内容和接收人。审批卡片涉及业务流程，需格外谨慎。

## 参数

| 参数 | 类型 | 必填 | 描述 |
|-----------|------|----------|-------------|
| body_title | arg | 是 | 卡片正文标题 |
| body_content | arg | 是 | 卡片正文内容（支持 Markdown） |
| --chat-id | option | 是 | 接收人（用户或群组 ID） |
| --group / -g | option | 否 | 发送到群组 |
| --head-title | option | 否 | 卡片头部标题 |
| --head-icon-link | option | 否 | 头部图标 URL |
| --head-status | option | 否 | 状态描述文本 |
| --head-status-colour | option | 否 | 状态颜色（如 green, red, orange） |
| --fields | option | 否 | 表单字段 JSON 数组：`[{"key":"字段名","value":"值"}]` |
| --buttons | option | 否 | 按钮组 JSON 数组：`[{"text":"按钮文本","buttonTheme":1,"link":"URL"}]` |
| --card-link | option | 否 | 卡片跳转链接 |
| --card-link-pc | option | 否 | PC 端跳转链接 |
| --card-link-pad | option | 否 | Pad 端跳转链接 |
| --expire-time | option | 否 | 过期时间（秒，0=默认7天，最大30天） |
| --mention-all | option | 否 | @全体成员（群聊） |
| --mention | option | 否 | @指定用户（群聊，逗号分隔） |
| --mention-bot | option | 否 | @指定机器人（群聊，逗号分隔） |
| --user-token | option | 否 | 用户令牌（以用户身份发送时使用） |
| --sender-id | option | 否 | 发送者 staffId（群聊） |

## 示例

```bash
# 基本审批卡片
lansenger message approve-card "申请标题" "**申请内容**\n详细说明" --chat-id staff_123

# 审批卡片带字段和按钮
lansenger message approve-card "报销申请" "**金额**：¥1000\n**事由**：差旅费" \
  --chat-id staff_123 \
  --head-title "审批通知" \
  --fields '[{"key":"申请人","value":"张三"},{"key":"部门","value":"技术部"}]' \
  --buttons '[{"text":"同意","buttonTheme":1,"link":"https://..."},{"text":"拒绝","buttonTheme":2}]' \
  --card-link "https://example.com/approve?id=123"

# 群聊发送审批卡片
lansenger message approve-card "全员审批" "**事项**：年度预算审批" \
  --chat-id group_456 \
  --group \
  --mention-all \
  --expire-time 86400

# 审批卡片带状态
lansenger message approve-card "订单审核" "**订单号**：ORD-20240101" \
  --chat-id staff_123 \
  --head-status "待审核" \
  --head-status-colour "orange"
```

> **key=value 格式**：`--field`、`--link`、`--fields` 参数支持 key=value 简写格式，避免命令行传 JSON 的引号问题：
> - `--field "Status=Done" --field "Score=95"` 代替 `--field '{"name":"Status","value":"Done"}'`
> - `--link "View=https://app.example.com"` 代替 `--link '{"name":"View","url":"https://app.example.com"}'`
> - 同时兼容旧 JSON 格式，json.loads() 失败时自动尝试 key=value 解析

> **Windows PowerShell 注意**：推荐使用 key=value 格式。如需传 JSON，PowerShell 下须用双引号包裹整个参数值，内部双引号用反引号 `` ` `` 转义：
> ```powershell
> lansenger message send-app-card user_123 "Report" --field "[{`"name`":`"Status`",`"value`":`"Done`"}]"
> ```

## 常见错误

- 未指定 `--chat-id` — 必须指定接收人。
- `--fields` 或 `--buttons` 格式错误 — 必须是有效的 JSON 数组。
- 在私聊中使用 `--mention-all` 或 `--mention` — @提及仅在群聊中有效。
- `--expire-time` 超过最大限制（30天）— 最大支持 2592000 秒。

## 返回值

返回已发送消息的消息 ID：

```json
{
  "msg_id": "msg_abc123"
}
```
