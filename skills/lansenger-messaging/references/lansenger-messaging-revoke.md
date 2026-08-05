# lansenger message revoke

撤回（删除）先前发送的消息。

**继承** [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md) 中的所有规则（Shell 规范、帮助优先、认证、权限）。

**安全提醒：** 务必与用户确认要撤回哪些消息。撤回操作会从收件人视角移除消息 — 此操作不可撤销。

`message revoke` 是**高风险写操作**，受 exit 10 门禁保护——缺省调用返回退出码 `10`，必须 `--yes` 才执行。详见 [`../../lansenger-shared/SKILL.md`](../../lansenger-shared/SKILL.md)「高风险写操作门禁」。

## 参数

| 参数 | 类型 | 必填 | 描述 |
|-----------|------|----------|-------------|
| message_ids | args | 是 | 一个或多个要撤回的消息 ID（空格分隔） |
| --chat-type | option | 否 | 消息的聊天类型上下文（如 p2p, group） |
| --sender-id | option | 视 chat-type 而定 | 发送者 staffId。**chat-type 为 staff/group 时必填**（OpenAPI 4.6.7），bot/account/notification 时不需要 |
| --yes / -y | option | 否 | 确认执行高风险撤回（门禁要求，不带则退出码 10） |
| --dry-run | option | 否 | 校验参数并预览将撤回的消息，不执行，退出 0 |

## 示例

推荐先 `--dry-run` 预览，用户确认后再 `--yes` 执行：

```bash
# 1. 预览将撤回的消息（退出 0，不执行）
lansenger message revoke msg_abc123 --dry-run

# 2. 用户确认后执行
lansenger message revoke msg_abc123 --yes

# 批量撤回
lansenger message revoke msg_abc123 msg_def456 msg_ghi789 --yes

# 指定 chat-type（staff/group 时需 --sender-id）
lansenger message revoke msg_abc123 --chat-type p2p --yes
lansenger message revoke msg_abc123 --chat-type group --sender-id staff_001 --yes
lansenger message revoke msg_abc123 msg_def456 --chat-type p2p --sender-id staff_001 --yes
```

## 常见错误

- 撤回非自己发送的消息 — 撤回仅对认证身份发送的消息有效。
- API 需要时忘记 `--chat-type` — 某些撤回接口需要聊天类型来定位消息。
- `--chat-type=staff` 或 `--chat-type=group` 时未提供 `--sender-id` — OpenAPI 4.6.7 要求这两种类型必须传 senderId，否则撤回失败。
- 撤回前未与用户确认 — 撤回的消息对收件人不可见且无法恢复。
- 以逗号分隔而非空格分隔传递消息 ID — 此命令接受多个位置参数，而非单个列表。

## 返回值

返回每条消息的撤回确认：

```json
{
  "revoked": ["msg_abc123", "msg_def456"]
}
```
