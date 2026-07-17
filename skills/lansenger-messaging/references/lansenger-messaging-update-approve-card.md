# lansenger message update-approve-card

更新先前发送的审批卡片消息的状态和按钮。

**继承** [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md) 中的所有规则（Shell 规范、帮助优先、认证、权限）。

**安全提醒：** 修改已发送卡片前务必与用户确认更新内容。审批卡片更新会改变所有收到原始卡片的收件人可见的内容。

## 参数

| 参数 | 类型 | 必填 | 描述 |
|-----------|------|----------|-------------|
| msg_id | arg | 是 | 要更新的审批卡片消息 ID |
| --head-status | option | 否 | 更新后的状态描述文本 |
| --head-status-colour | option | 否 | 更新后的状态颜色（如 green, red, orange） |
| --buttons | option | 否 | 更新后的按钮组 JSON 数组 |
| --user-token | option | 否 | 用户令牌（以用户身份更新时使用） |

## 示例

```bash
# 更新审批卡片状态
lansenger message update-approve-card msg_abc123 \
  --head-status "已通过" \
  --head-status-colour "green"

# 更新审批卡片按钮
lansenger message update-approve-card msg_abc123 \
  --buttons '[{"text":"已审批","buttonTheme":3,"state":2}]'

# 更新状态和按钮
lansenger message update-approve-card msg_abc123 \
  --head-status "已拒绝" \
  --head-status-colour "red" \
  --buttons '[{"text":"已拒绝","buttonTheme":2,"state":2}]'
```

## 常见错误

- 未保存 `approve-card` 返回的原始 msg_id — 调用此命令时需要它。
- `--buttons` 格式错误 — 必须是有效的 JSON 数组。
- 尝试更新非审批卡片类型的消息 — 此命令仅对审批卡片生效。

## 返回值

返回更新确认信息：

```json
{
  "msg_id": "msg_abc123",
  "updated": true
}
```
