# lansenger message send-account-message

通过账户通道（使用特定账户身份）向聊天或部门发送消息。

**继承** [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md) 中的所有规则（Shell 规范、帮助优先、认证、权限）。

**安全提醒：** 发送前务必与用户确认收件人和消息内容。账户消息显示为来自特定人员的账户 — 未经用户明确批准请勿发送，因为消息将携带该账户的身份信息。

## 参数

| 参数 | 类型 | 必填 | 描述 |
|-----------|------|----------|-------------|
| msg_type | arg | 是 | 消息类型（如 text, markdown, image, file） |
| msg_data | arg | 是 | 包含消息正文数据的 JSON 对象 |
| --chat-id | option | 否 | 要发送到的聊天 ID 列表（逗号分隔或重复指定） |
| --dept | option | 否 | 要广播到的部门 ID 列表（逗号分隔或重复指定） |
| --account-id | option | 否 | 发送来源的账户 ID（指定账户身份） |
| --entry-id | option | 否 | 账户通道的入口 ID |
| --attach | option | 否 | 附件数据（JSON） |
| --user-token | option | 否 | 用户令牌 |

## 示例

```bash
lansenger message send-account-message text '{"text":"Notification from ops account"}' --chat-id user_123,user_456 --account-id acct_ops

lansenger message send-account-message markdown '{"content":"**Alert**: Server down"}' --dept dept_001 --account-id acct_ops --entry-id entry_abc

lansenger message send-account-message text '{"text":"Document attached"}' --chat-id user_789 --account-id acct_ops --attach '{"file_key":"file_abc","file_name":"report.pdf"}'

lansenger message send-account-message text '{"text":"Weekly summary"}' --chat-id grp_456 --account-id acct_ops --user-token $TOKEN
```

## 常见错误

- 将 `msg_data` 作为纯文本而非 JSON 传递 — 必须是有效的 JSON 对象。
- 忘记 `--account-id` — 命令将失败或使用可能不期望的默认值。
- 既未指定 `--chat-id` 也未指定 `--dept` — 命令没有收件人，将会失败。
- 在用户不知晓所用账户身份的情况下发送账户消息 — 收件人看到的消息来自该账户，可能会产生误导。

## 返回值

返回已发送消息的消息 ID 列表：

```json
{
  "msg_ids": ["msg_abc123", "msg_def456"]
}
```
