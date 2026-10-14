# lansenger message send-authorization-request

向用户或部门发送授权请求消息（OpenAPI 4.6.4.14）。当前唯一授权类型为**位置请求授权**。

**继承** [`../../lansenger-shared/SKILL.md`](../../lansenger-shared/SKILL.md) 中的所有规则（Shell 规范、帮助优先、认证、权限）。

**版本前提：** CLI ≥ 0.17.0、Python SDK ≥ 1.13.0。低于该版本命令/方法不存在。

**CRITICAL — 授权请求会向收件人发起授权申请弹窗，MUST 先与用户确认收件人与用途。** 授权请求只是发起申请；位置数据要等用户授权后才会通过下方通道上报。

## 参数

| 参数 | 类型 | 必填 | 描述 |
|-----------|------|----------|-------------|
| --chat-id | option | 是 | 收件人 staffId（员工） |

> 完整参数（如按部门发送）以 `lansenger message send-authorization-request --help` 为准（Help-First）。

## 示例

```bash
# 向单个员工发送位置请求授权
lansenger message send-authorization-request --chat-id staff_001

# JSON 输出
lansenger -j message send-authorization-request --chat-id staff_001
```

## 消息体

授权请求是独立的消息体类型 `authorizationReq`：

| 字段 | 类型 | 说明 |
|------|------|------|
| `authorizationType` | int | 授权类型；`1` = 位置请求授权（当前唯一取值） |

## 授权后的位置上报通道

用户授权后，位置数据通过以下两条通道之一回流——**取决于机器人形态**：

| 机器人形态 | 位置上报通道 |
|------------|--------------|
| 个人机器人 | 无需订阅，直接通过长连接接收位置回调事件（`report_location`） |
| 组织机器人 | 需在开发者中心订阅「位置上报事件」并配置回调地址，否则收不到位置回调 |

回调事件的解析与类别映射见 [`../../lansenger-callback/SKILL.md`](../../lansenger-callback/SKILL.md)（类别 `location` → 事件 `report_location`）。

## SDK 用法

```python
from lansenger_sdk import LansengerClient

client = LansengerClient(...)

# 按人发送
await client.send_authorization_request(chat_ids=["staff_001"])

# 按部门发送
await client.send_authorization_request(department_ids=["dept_001"])
```

## 常见错误

- 以为发完授权请求就能拿到位置 — 授权请求只发起授权；数据需用户确认后经上表通道回流。
- 组织机器人未订阅「位置上报事件」 — 未订阅时收不到位置回调，须在开发者中心补齐订阅与回调地址。
- 给个人机器人也去配订阅 — 个人机器人无需订阅，直接通过长连接接收 `report_location`。
- 传入其它 `authorizationType` — 目前仅 `1`（位置请求授权）有效。
- 未经确认直接群发授权请求 — 该消息会打扰收件人，先确认收件人与用途。
- CLI/SDK 版本过低 — 需要 CLI ≥ 0.17.0、Python SDK ≥ 1.13.0。

## 返回值

命令成功时输出本次授权请求消息的发送结果（`-j` 输出 JSON）；失败时按平台错误码返回。

```json
{
  "msgId": "msg_abc123",
  "authorizationType": 1
}
```
