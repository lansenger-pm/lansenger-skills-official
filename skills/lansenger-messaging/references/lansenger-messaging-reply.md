# lansenger message reply

对指定消息添加或取消表情回复（OpenAPI 4.6.17）。

**继承** [`../../lansenger-shared/SKILL.md`](../../lansenger-shared/SKILL.md) 中的所有规则（Shell 规范、帮助优先、认证、权限）。

**版本前提：** CLI ≥ 0.17.0、Python SDK ≥ 1.13.0。低于该版本命令/方法不存在。

## 参数

| 参数 | 类型 | 必填 | 描述 |
|-----------|------|----------|-------------|
| msg_id | arg | 是 | 要回复的消息 ID |
| --emoji | option | 回复时必填 | 表情标识，取值见下方「可用表情」 |
| --cancel | flag | 否 | 取消已有表情回复（对应 `replyType=2`）；**取消也必须同时给 `--emoji`**——平台靠它判断取消哪一个（缺失回 `40060 …emojiId is empty`） |

### 可用表情（emojiId）

| emojiId | 含义 |
|---------|------|
| `TYPE_THUMB` | 点赞 |
| `TYPE_OK` | 收到 |
| `TYPE_ADD_ONE` | +1 |
| `TYPE_FIREWORK` | 烟火 |
| `TYPE_LOVE` | 爱心 |
| `TYPE_DOUBT` | 问号 |

## 示例

```bash
# 点赞
lansenger message reply msg_abc123 --emoji TYPE_THUMB

# 收到
lansenger message reply msg_abc123 --emoji TYPE_OK

# 取消表情回复
lansenger message reply msg_abc123 --emoji TYPE_OK --cancel
```

## 接口对应关系

`POST /v1/messages/reply/create?app_token=APP_ACCESS_TOKEN&user_token=USER_TOKEN`

请求体（JSON）：

| 字段 | 类型 | 说明 |
|------|------|------|
| `replyType` | int | `1` = 回复（缺省），`2` = 取消回复 |
| `msgId` | string | 消息 ID |
| `emojiId` | string | 表情标识，取值见「可用表情」 |

## SDK 用法

```python
from lansenger_sdk import LansengerClient

client = LansengerClient(...)

# 表情回复
await client.reply_message(msg_id="msg_abc123", emoji_id="TYPE_OK")

# 取消表情回复
await client.reply_message(msg_id="msg_abc123", emoji_id="TYPE_OK", reply_type=2)
```

同步客户端与模块级函数：

```python
from lansenger_sdk import reply_message

# 同步客户端
sync_client.reply_message(msg_id="msg_abc123", emoji_id="TYPE_OK")

# 模块级函数
await reply_message(msg_id="msg_abc123", emoji_id="TYPE_OK")
```

## 常见错误

| 错误码 | 说明 |
|--------|------|
| `10000` | API 服务不可得 |
| `-1` | 缺少 APP_TOKEN |
| `40060` | 消息为空或格式错误 |

- 传入列表外的 `emojiId` — 仅支持 `TYPE_THUMB` / `TYPE_OK` / `TYPE_ADD_ONE` / `TYPE_FIREWORK` / `TYPE_LOVE` / `TYPE_DOUBT`。
- 想取消回复却只换一个 emoji — 取消必须走 `replyType=2`（CLI 为 `--emoji … --cancel`），且取消同样要带 `emojiId`；只给 `--cancel` 会被平台拒绝（`40060`）。
- 消息 ID 为空或格式不对 — 返回 `40060`，务必从回调/发消息结果中取真实 `msgId`。
- 不带 APP_TOKEN 调用 — 返回 `-1`，先确认认证配置（见 shared「认证」）。
- CLI/SDK 版本过低 — 需要 CLI ≥ 0.17.0、Python SDK ≥ 1.13.0。

## 返回值

命令成功时输出本次表情回复的结果（`-j` 输出 JSON）；失败时返回上表错误码。

```json
{
  "msgId": "msg_abc123",
  "emojiId": "TYPE_OK",
  "replyType": 1
}
```
