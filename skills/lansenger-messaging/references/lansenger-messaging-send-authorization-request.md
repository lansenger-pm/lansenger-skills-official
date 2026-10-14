# lansenger message send-authorization-request

向**某位员工**发送授权请求消息（OpenAPI 4.6.4.14）。该消息体类型**只支持「机器人 → 员工私聊」通道**；当前唯一授权类型为**位置请求授权**。

**继承** [`../../lansenger-shared/SKILL.md`](../../lansenger-shared/SKILL.md) 中的所有规则（Shell 规范、帮助优先、认证、权限）。

**版本前提：** CLI ≥ 0.17.0、Python SDK ≥ 1.13.0。低于该版本命令/方法不存在。

**CRITICAL — 授权请求会向收件人发起授权申请弹窗，MUST 先与用户确认收件人与用途。** 授权请求只是发起申请；位置数据要等用户授权后才会通过下方通道上报。

## 参数

| 参数 | 类型 | 必填 | 描述 |
|-----------|------|----------|-------------|
| chat_id | 位置参数 | 是 | 收件人 staffId（员工）；该 msgType 只支持机器人 → 员工私聊 |

> 没有「按部门发送」：真机实测走账号通道会被平台拒绝（`50084 非法的msgType||authorizationReq msgType only support bot-to-staff private chat`），因此只接受一个员工 `chatId`。

## 示例

```bash
# 向单个员工发送位置请求授权（仅机器人 → 员工私聊）
lansenger message send-authorization-request staff_001

# JSON 输出
lansenger -j message send-authorization-request staff_001
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

# 机器人 → 员工私聊（唯一可用通道；返回 SendMessageResult）
await client.send_authorization_request("staff_001")
```

## 常见错误

- 以为发完授权请求就能拿到位置 — 授权请求只发起授权；数据需用户确认后经上表通道回流。
- 组织机器人未订阅「位置上报事件」 — 未订阅时收不到位置回调，须在开发者中心补齐订阅与回调地址。
- 给个人机器人也去配订阅 — 个人机器人无需订阅，直接通过长连接接收 `report_location`。
- 传入其它 `authorizationType` — 目前仅 `1`（位置请求授权）有效。
- 未经确认直接群发授权请求 — 该消息会打扰收件人，先确认收件人与用途。
- 想发给部门/多人 — 平台只支持机器人 → 员工私聊单人私发，账号通道会回 `50084`；需要多人时逐个发（或先建群再发群消息）。
- 服务端版本过低 — 真机实测部分测试租户回 `40060 …invalid authorizationType` 或 `50084 …invalid message type: authorizationReq`（服务端尚未部署该消息体类型），参数写法本身没错，换到已部署的线上环境再试。
- CLI/SDK 版本过低 — 需要 CLI ≥ 0.17.0、Python SDK ≥ 1.13.0。

## 返回值

命令成功时输出本次授权请求消息的发送结果（`-j` 输出 JSON）；失败时按平台错误码返回。

```json
{
  "msgId": "msg_abc123",
  "authorizationType": 1
}
```
