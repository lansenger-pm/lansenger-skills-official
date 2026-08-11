# lansenger message send-user-message

通过用户消息通道直接向用户发送消息。

**继承** [`../../lansenger-shared/SKILL.md`](../../lansenger-shared/SKILL.md) 中的所有规则（Shell 规范、帮助优先、认证、权限）。

**通道 4.6.3 — 模拟真实用户身份；`--user-token` 为必填（通过 lansenger-oauth 获取）。**

**安全提醒：** 发送前务必与用户确认收件人和消息内容。

**CRITICAL — `--user-token` 是子命令级参数，必须放在位置参数（receiver_id、msg_type、msg_data）之后。**

**CRITICAL — msg_data JSON 格式**：
- text 类型：`{"text":{"content":"消息内容"}}`（text 字段是对象，不是字符串）
- formatText 类型：`{"formatText":{"formatType":1,"text":"Markdown 内容"}}`
- 如果 formatText 返回 errCode=40060（Stage 环境可能不支持），降级为 text 类型发送纯文本

## 参数

| 参数 | 类型 | 必填 | 描述 |
|-----------|------|----------|-------------|
| receiver_id | arg | 是 | 接收者用户/员工 ID |
| msg_type | arg | 是 | 消息类型（如 text, formatText, image, file, interactive） |
| msg_data | arg | 是 | 包含消息正文数据的 JSON 对象 |
| --user-token | option | **是** | 必填 — 通道 4.6.3 必须使用 userToken（OAuth2）认证（子命令级参数，放在位置参数之后） |
| --common | option | 否 | 通用消息配置的 JSON 对象（如 chat_type、发送者信息） |
| --uuid | option | 否 | 用于去重的唯一消息 ID |

## 示例

```bash
lansenger message send-user-message user_123 text '{"text":{"content":"Hi"}}' --user-token $TOKEN

lansenger message send-user-message user_123 formatText '{"formatText":{"formatType":1,"text":"**Important**: Please review"}}' --user-token $TOKEN

lansenger message send-user-message user_123 interactive '{"header":{"title":{"tag":"plain_text","content":"Action needed"}},"elements":[{"tag":"div","text":{"tag":"plain_text","content":"Click below"}}]}' --user-token $TOKEN --common '{"chat_type":"p2p"}'

lansenger message send-user-message user_123 text '{"text":{"content":"Unique notification"}}' --user-token $TOKEN --uuid "notif-001"
```

## 常见错误

- 缺少 `--user-token` — 通道 4.6.3 需要它；调用将因认证错误而失败
- 将 `msg_data` 作为纯文本而非 JSON 传递 — 必须是有效的 JSON 对象
- 将群 ID 用作 `receiver_id` — 此命令仅用于一对一私聊；群聊请使用 `send-group-message`
- 为 `--common` 提供了无效的 JSON — 必须是格式正确的 JSON 对象

## 返回值

返回已发送消息的消息 ID：

```json
{
  "msg_id": "msg_abc123"
}
```
