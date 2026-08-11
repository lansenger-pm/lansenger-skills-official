# lansenger message send-reminder

向指定用户发送消息提醒（弹窗/SMS/电话）。

**继承** [`../../lansenger-shared/SKILL.md`](../../lansenger-shared/SKILL.md) 中的所有规则（Shell 规范、帮助优先、认证、权限）。

**安全提醒：** 发送前务必与用户确认提醒内容和接收人。电话提醒会产生实际通话费用，需格外谨慎。

## 参数

| 参数 | 类型 | 必填 | 描述 |
|-----------|------|----------|-------------|
| msg_id | arg | 是 | 要提醒的消息 ID |
| --type / -t | option | 是 | 提醒类型：1=弹窗提醒, 2=SMS提醒, 3=电话提醒 |
| --user | option | 否 | 接收提醒的用户 ID（可多次指定） |
| --user-token | option | 否 | 用户令牌（以用户身份发送时使用） |

## 示例

```bash
# 对消息发送弹窗提醒
lansenger message send-reminder msg_abc123 --type 1 --user staff_456

# 对消息发送SMS提醒给多个用户
lansenger message send-reminder msg_abc123 --type 2 --user staff_456 --user staff_789

# 对消息发送电话提醒
lansenger message send-reminder msg_abc123 --type 3 --user staff_456

# JSON 输出
lansenger -j message send-reminder msg_abc123 --type 1 --user staff_456
```

## 常见错误

- `--type` 参数值不在 1-3 范围内 — 仅支持弹窗(1)、SMS(2)、电话(3)三种类型。
- 电话提醒可能产生费用 — 电话提醒会向用户拨打电话，可能产生实际费用，使用前务必确认。
- 未指定 `--user` — 必须指定至少一个接收提醒的用户。

## 返回值

返回提醒发送结果：

```json
{
  "success": true,
  "msg_id": "msg_abc123",
  "reminded_users": ["staff_456"]
}
```
