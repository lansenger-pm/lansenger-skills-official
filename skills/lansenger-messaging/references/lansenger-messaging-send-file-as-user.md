# lansenger message send-user-message（用户身份发「文字 + 附件」）

应用**没有机器人能力**时，`send-file` 的私聊发送会失败（`errCode=-10`）。此时改用**用户身份通道**：先用 `media upload-app-v2`（4.5.5）以用户身份上传素材，再用 `message send-user-message`（4.6.3）发一条 `text` 消息，把素材挂在 `msgData.text.mediaType` / `mediaIds` 上。一条消息可同时携带文字说明和附件。

> **没有 `send-file --as-user` 这个参数**：本场景的等价操作固定是 `media upload-app-v2` + `message send-user-message` 两条命令；群聊把第 ② 步换成 `message send-group-message`。

**继承** [`../../lansenger-shared/SKILL.md`](../../lansenger-shared/SKILL.md) 中的所有规则（Shell 规范、帮助优先、认证、权限）。

**安全提醒：** 该通道以**用户本人名义**发出消息。发送前 MUST 与用户确认：收件人、文件、随附文字、发送身份；不得为了绕过身份确认而降级或切换发送身份。

## CRITICAL

- 两步**都必须**传 `--user-token`：4.5.5 上传用 userToken 鉴权，4.6.3 私聊也必须 userToken；`--user-token` 是子命令级参数，**必须放在位置参数之后**。
- `media upload-app-v2` 返回的素材 ID 在 **`message_id`** 字段（历史命名，**不是消息 ID**）：CLI `-j` JSON 用 `.message_id`，SDK 公共方法用 `up.message_id`；SDK 内部 `media.py` 的 `UploadMediaResult.media_id` 不对外暴露。把它当消息 ID 去撤回/引用会失败。
- `--media-type` 传**字符串**：`file` / `image` / `video` / `audio`。传数字 `1/2/3` 是旧 4.5.1 约定，SDK 会就地拒绝（服务端对应 `50052 缺少上传media类型`）。
- 上传前确认应用已开通「上传素材」/媒体上传权限：未开通时 `upload-app-v2` 返回 `errCode=10005: API服务 无权限`，换接口版本不能绕过（4.5.4、4.5.5 都需要该权限，2026-10-30 实机）。
- 群聊不能用 `send-user-message`（4.6.3 仅一对一），改用 `send-group-message`（4.6.2，同样传 `--user-token`）。

## 适用场景

| 场景 | 做法 |
|------|------|
| 应用无机器人能力，给某员工私聊发文件（可带文字） | ✅ 本 reference（4.5.5 上传 + 4.6.3 私聊） |
| 应用有机器人能力，发私聊文件 | 直接用 `send-file` 更省事（自动上传、视频封面处理） |
| 应用无机器人能力，给群发文字 + 附件 | 4.5.5 上传 + `send-group-message --user-token`（见下文「群聊」） |

## 参数

### 第 ① 步：`media upload-app-v2`（4.5.5）

| 参数 | 类型 | 必填 | 描述 |
|------|------|------|------|
| file_path | arg | 是 | 本地文件路径；`image` ≤10MB，其他类型 ≤20MB |
| --media-type / -t | option | 是 | `file` / `image` / `video` / `audio`（字符串；默认 `file`） |
| --user-token | option | 是 | 用户令牌（4.5.5 必需，以用户身份上传） |
| --width / --height / --duration | option | 否 | 视频/音频建议传 |

输出：`-j` JSON 的 `message_id` 字段值 = mediaId。

### 第 ② 步：`message send-user-message`（4.6.3）

| 参数 | 类型 | 必填 | 描述 |
|------|------|------|------|
| receiver_id | arg | 是 | 收件人员工 staffId（不是手机号/邮箱/群 ID） |
| msg_type | arg | 是 | 固定 `text`（附件也走 text，不要传 file/image/video） |
| msg_data | arg | 是 | JSON 字符串，格式见下 |
| --user-token | option | 是 | 用户令牌 |
| --common | option | 否 | 透传参数（如 `{"chat_type":"p2p"}`） |

`msg_data`：`{"text":{"content":"<随附文字>","mediaType":<1视频|2图片|3文件>,"mediaIds":["<mediaId>"]}}`。音频也走 `mediaType=3`（消息体无 audio 类型）；视频 `mediaIds` 必须是 `[视频mediaId, 封面mediaId]` 两个——本通道没有 `--cover-image`，需先用 `--media-type image` 上传封面拿到封面 mediaId，再按 `[视频mediaId, 封面mediaId]` 组装。

## 示例

```bash
TOKEN="$LANSENGER_USER_TOKEN"   # 或按 lansenger-oauth 流程获取

# ① 以用户身份上传（4.5.5）：取 JSON 的 message_id，值即 mediaId
MEDIA_ID=$(lansenger -j media upload-app-v2 /path/to/report.pdf --media-type file --user-token "$TOKEN" | jq -r '.message_id')

# ② 一条消息同时带文字 + 附件（4.6.3）
lansenger message send-user-message staff456 text \
  "{\"text\":{\"content\":\"随附文件说明\",\"mediaType\":3,\"mediaIds\":[\"$MEDIA_ID\"]}}" \
  --user-token "$TOKEN"
```

SDK 等价（`LansengerSyncClient`；`LansengerClient` 异步版同名方法加 `await`）：

```python
from lansenger_sdk import LansengerConfig, LansengerSyncClient

config = LansengerConfig.create(app_id=APP_ID, app_secret=APP_SECRET,
                                api_gateway_url=API_GATEWAY_URL, passport_url=PASSPORT_URL)
client = LansengerSyncClient.from_config(config)   # 或用 from_store(profile="default")

# 先按姓名/邮箱确认收件人的 staffId（需要 userToken）
hits = client.search_staff("张三", user_token=TOKEN)
receiver_id = hits.staff_info[0].get("staffId")

up = client.upload_app_media_v2("/path/to/report.pdf", media_type="file", user_token=TOKEN)
if not up.success:
    raise RuntimeError(up.error)

msg_data = {"text": {"content": "随附文件说明", "mediaType": 3, "mediaIds": [up.message_id]}}
res = client.send_user_message(receiver_id, "text", msg_data, user_token=TOKEN)
if not res.success:
    raise RuntimeError(res.error)

print(res.message_id)   # 消息 ID
```

## 群聊（应用无机器人能力）

`send-user-message` 仅支持一对一；群聊改用 `message send-group-message`（4.6.2），`msg_data` 形状相同：

```bash
MEDIA_ID=$(lansenger -j media upload-app-v2 /path/to/report.pdf --media-type file --user-token "$TOKEN" | jq -r '.message_id')
lansenger message send-group-message <group_id> text \
  "{\"text\":{\"content\":\"随附文件说明\",\"mediaType\":3,\"mediaIds\":[\"$MEDIA_ID\"]}}" \
  --user-token "$TOKEN"
```

## 常见错误

| 错误 | 正确做法 |
|------|---------|
| 用 `send-file` 发 → `errCode=-10` | `send-file` 的私聊发送步骤走 Bot 私聊通道，依赖机器人能力；改用本通道 |
| 上传报 `10005 API服务 无权限`（4.5.4 / 4.5.5 都一样） | 应用未开通「上传素材」/媒体上传权限：先去开发者中心给应用开通；换 `upload-app-v2` 不能绕过权限（2026-10-30 实机） |
| `--media-type 3`（传数字） | 传字符串 `file` / `image` / `video` / `audio`；数字是旧 4.5.1 约定，SDK 直接拒绝（50052） |
| 把上传返回的 `message_id` 当消息 ID 用 | 该字段值是 **mediaId**；消息 ID 是第 ② 步返回的 `message_id` |
| userToken 过期/无效 | userToken 有效期 2 小时（refreshToken 30 天）；重新授权后再发 |
| 群 ID 当 receiver_id | 4.6.3 仅一对一：群聊用 `send-group-message` |

## 返回值

`send-user-message` 返回 `UserMessageResult`：`success`、`message_id`（消息 ID）、`error`；CLI `-j` JSON 为同名键。

## 发送后复核

接口成功不等于已送达。可按会话历史复核（需要 userToken）：

```python
msgs = client.fetch_chat_messages(staff_id=receiver_id, page_size=20, user_token=TOKEN)
for c in msgs.messages or []:
    content = c.content or {}
    print(c.message_type, c.sender,
          content.get("text"), content.get("attachments"),
          content.get("mediaIds"), content.get("fileUrls"))
```

读侧 `content` 形状（2026-10-30 实机）：`text` 是**字符串**（媒体消息为空串）、`attachments` 是附件**文件名列表**、`mediaIds` 是素材 ID 列表、`fileUrls` 是约 1 小时有效的签名下载直链。别把发送侧 `text` 的对象形状（`{"text":{"content":...}}`）套到读侧。
