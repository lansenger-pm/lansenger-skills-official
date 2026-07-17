---
name: lansenger-chat
version: 1.4.1
description: "蓝信聊天列表与消息历史：查看聊天列表（私聊+群聊）、拉取聊天消息记录。当用户需要查看聊天记录、浏览聊天列表时使用。"
metadata:
  requires:
    bins: ["lansenger"]
  cliHelp: "lansenger chat --help"
---

# chat

**本技能继承 [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md) 的所有规则。** Shell 执行纪律、Help-First 原则、认证、权限处理等均在其定义，此处不复述。

## Reverse Handoff — 何时不用此技能

| 用户意图 | 正确技能 | 原因 |
|----------|----------|------|
| 发消息/回复消息 | `lansenger-messaging` | chat 管"看"，messaging 管"发" |
| 查员工信息 | `lansenger-staff` | chat list 的 staff_infos 只含 staffId+姓名 |
| OAuth2 获取 userToken | `lansenger-oauth` | 推荐使用 userToken 以获得用户视角数据 |

**CRITICAL — 聊天读取仅组织级应用可用，个人机器人不可用。** 详见 shared「身份能力矩阵」。需要 appToken，`--user-token` 可选但推荐传入。不传 userToken 时以机器人身份调用；传 userToken 时可以读到用户视角的聊天列表和消息内容（如 sender 为真实姓名）。

**CRITICAL — 消息查询时间跨度不宜超过约1个月。超过1个月时，API 只返回最近的数据，更早消息会丢失。需要按月拆分查询才能完整拉取历史数据（见下方"批量操作与限制说明"章节）。**

**CRITICAL — 消息返回的 `sender` 字段是**姓名**（如"张三"），不是 staffId。同名员工无法区分。如需确认发送者身份，需用姓名反查 `staff search`。**

## 核心概念

蓝信聊天读取 API 允许你查看用户的聊天列表和拉取聊天消息历史。用户级资源，推荐传入 `--user-token` 以获取用户视角数据（不传则以机器人身份调用，信息有限）。

### 聊天类型

| 类型值 | 说明 |
|--------|------|
| 0 | 全部聊天（私聊 + 群聊） |
| 1 | 仅私聊 |
| 2 | 仅群聊 |

### 深分页机制

拉取聊天消息时使用 `base_version` 作为游标进行深分页：
- 第一次调用：`--version 0`（默认）
- 后续调用：使用上一次返回的 `last_version` 值作为 `--version`

### 时间参数

时间参数使用 **微秒级 Unix 时间戳**（毫秒 × 1000），例如 `1700000000000000`（≈ 2023-11-15）。

**CRITICAL — 时间跨度不宜超过约1个月。超过1个月时 API 只返回最近的数据，更早消息丢失。需按月拆分查询。**

### 聊天列表字段限制

聊天列表返回的 `staff_infos` 只包含 `staffId` 和 `staffName`，不含部门、职位等信息。如需判断私聊对方的部门/角色，需额外调用 `lansenger staff detail <staffId> --user-token $TOKEN` 补充。

### sender 字段说明

消息返回的 `sender` 字段是**姓名**而非 staffId（如 `"张三"`），同名员工无法区分。API 也会返回 `sender_id`（如果有的话），可用于精确定位发送者。如需确认身份：

1. 若 API 返回了 `sender_id`，直接调用 `lansenger staff detail <sender_id> --user-token $TOKEN` 获取完整信息
2. 若只有 `sender`（姓名），用 `lansenger staff search --keyword "张三" --user-token $TOKEN` 反查，再从结果中确认对应 staffId

### 消息 content 格式说明

不同 msgType 的 `content` 字段格式不同，解析时需按类型区分：

| 消息类型 | content 格式 | plain_text 提取方式 |
|---------|-------------|-------------------|
| text | `{"text": "xxx"}` | `content.text` |
| formatText | `{"formatText": {"content": "xxx"}}` | `content.formatText.content` |
| image | `{"text": "", "attachments": [...], "mediaIds": [...]}` | 图片消息，mediaIds[0] 为图片 mediaId |
| video | `{"text": "", "attachments": [...], "mediaIds": [videoId, coverId]}` | 视频消息，mediaIds 为 [视频mediaId, 封面图mediaId] |
| file | `{"text": "", "attachments": [...], "mediaIds": [...]}` | 文件消息，mediaIds[0] 为文件 mediaId |
| voice | `{"text": "", "mediaIds": [...]}` | 语音消息，mediaIds[0] 为语音 mediaId |
| appCard | `{"appCard": {...}}` | 需按 div 结构逐段提取 |
| linkCard | `{"linkCard": {...}}` | `.linkCard.title` + `.linkCard.desc` |
| oacard | `{"oacard": {...}}` | 需按 oaCard 结构提取 |
| 其他 | 字符串或嵌套dict | 直接取字符串或需自定义解析 |

**Python SDK 提取方法**：Python SDK v1.5+ 的 `ChatMessageInfo` 提供 `plain_text()` 方法，自动处理所有格式并返回纯文本字符串：

```python
# Python SDK
msg = chat_messages[0]  # ChatMessageInfo 对象
text = msg.plain_text()  # 自动提取纯文本，无论 content 是哪种格式

# CLI --json 输出后用 jq 提取
# text 类型: .content.text
# formatText 类型: .content.formatText.content
```

### 从消息中提取 mediaId 并重新下载附件

聊天记录中的图片、视频、文件、语音消息都包含 mediaId。提取后可调用 `media download` 或 `media download-to-file` 重新下载：

```bash
# Step 1：拉取聊天消息（获取 content 中的 mediaIds）
lansenger -j --app-token "xxx" chat messages --staff-id staff123 --user-token "yyy"

# Step 2：从返回的 JSON 中提取 mediaIds
# 例如：content = {"text": "", "mediaIds": ["13107200-abc..."]}

# Step 3：用 mediaId 下载附件
lansenger --app-token "xxx" media download-to-file "13107200-abc..." /path/to/save/file.pdf --user-token "yyy"
```

> **注意**：视频消息的 mediaIds 数组长度为 2：`[视频mediaId, 封面图mediaId]`。下载视频时用 mediaIds[0]。

## CLI 命令

### 查看聊天列表

```bash
# 查看全部聊天
lansenger chat list --user-token "ut1"

# 仅查看私聊
lansenger chat list --type 1 --user-token "ut1"

# 仅查看群聊并搜索关键词
lansenger chat list --type 2 --keyword "项目" --user-token "ut1"

# 按时间范围过滤
lansenger chat list --start 1700000000000000 --end 1710000000000000 --user-token "ut1"
```

### 拉取聊天消息

```bash
# 拉取私聊消息（与某人的聊天）
lansenger chat messages --staff-id staff123 --user-token "ut1"

# 拉取群聊消息
lansenger chat messages --group-id group456 --user-token "ut1"

# 拉取最近50条消息
lansenger chat messages --staff-id staff123 --size 50 --user-token "ut1"

# 深分页：使用上次返回的 last_version
lansenger chat messages --staff-id staff123 --version "123456" --user-token "ut1"

# 按时间范围和发送者过滤
lansenger chat messages --group-id group456 --start 1700000000000000 --end 1710000000000000 --sender-id staff789 --user-token "ut1"

# JSON 输出（便于结构化解析）
lansenger -j chat messages --staff-id staff123 --user-token "ut1"

# --json 输出示例
# [
#   {
#     "msgType": "text",
#     "content": {"text": "你好"},
#     "sender": "张三",
#     "sender_id": "staff123",
#     "createTime": 1700000000000000,
#     "version": "v1"
#   }
# ]

# 自动按月拆分拉取（跨多个月时使用）
lansenger chat messages --staff-id staff123 --start 1700000000000000 --end 1715000000000000 --split-month --user-token "ut1"

# 显示拉取进度
lansenger chat messages --staff-id staff123 --split-month --progress --user-token "ut1"
```

## 参数说明

### chat list

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `--type` / `-t` | int | 0 | 聊天类型：0=全部, 1=私聊, 2=群聊 |
| `--keyword` / `-k` | str | "" | 搜索关键词（仅 type=1 或 type=2 时有效） |
| `--start` | int | 0 | 起始时间（微秒级时间戳，0=不限制，返回所有历史聊天） |
| `--end` | int | 0 | 结束时间（微秒级时间戳，0=不限制） |
| `--user-token` | str | "" | 用户 Token（推荐传入，获取用户视角数据） |

### chat messages

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `--staff-id` | str | "" | 私聊对方 staffId |
| `--group-id` | str | "" | 群 openId |
| `--size` / `-s` | int | 100 | 每页条数（最大 100） |
| `--version` | str | "0" | 深分页游标，首次调用传 0 |
| `--start` | int | 0 | 起始时间（微秒级时间戳，0=不限制） |
| `--end` | int | 0 | 结束时间（微秒级时间戳，0=不限制） |
| `--sender-id` | str | "" | 按发送者 staffId 过滤 |
| `--split-month` | flag | false | 自动按月拆分拉取（时间跨度超过1个月时必须使用） |
| `--progress` | flag | false | 显示拉取进度（配合 --split-month 使用） |
| `--json` | flag | false | JSON 格式输出，便于结构化解析 |
| `--user-token` | str | "" | 用户 Token（推荐传入，获取用户视角数据） |

**注意**：`--staff-id` 和 `--group-id` 二选一，必须提供其中一个。

## 批量操作与限制说明

拉取大量聊天历史时，必须遵循以下最佳实践：

### 消息查询时间范围限制

消息查询时间范围不宜超过1个月，超过1个月需按月拆分查询（API只返回最近数据）。使用 `--split-month` 选项可自动按月拆分拉取，无需手动计算月份边界：

```bash
# 手动按月拆分
# 第1个月
lansenger chat messages --staff-id staff123 --start 1700000000000000 --end 1703000000000000 --user-token $TOKEN
# 第2个月
lansenger chat messages --staff-id staff123 --start 1703000000000000 --end 1706000000000000 --user-token $TOKEN

# 自动按月拆分（推荐）
lansenger chat messages --staff-id staff123 --start 1700000000000000 --end 1715000000000000 --split-month --user-token $TOKEN

# 自动拆分 + 显示进度
lansenger chat messages --staff-id staff123 --start 1700000000000000 --end 1715000000000000 --split-month --progress --user-token $TOKEN
```

### 深分页逐页翻取

```bash
# 第1页
lansenger chat messages --staff-id staff123 --version 0 --size 100 --user-token $TOKEN
# 返回 last_version="v1"

# 第2页
lansenger chat messages --staff-id staff123 --version v1 --size 100 --user-token $TOKEN
# 返回 last_version="v2"

# 继续...直到返回数据条数 < size 或无 last_version
```

### 断点续传

建议将每个聊天的拉取进度（`last_version`）保存到文件，中断后可恢复：

```json
// progress.json 示例
{
  "staff123": {"last_version": "v5", "month": "2026-01", "count": 500},
  "group456": {"last_version": "v3", "month": "2026-02", "count": 300}
}
```

### 并发控制与限流

- 建议每次 API 调用间隔 ≥ 50ms，避免被限流
- 参考耗时：单聊天单月约 0.2–0.5 秒（视消息密度）
- 不要并行请求超过 5 个聊天

## 常见错误

| 错误 | 正确做法 |
|------|---------|
| 不传 `--user-token` 试图查看用户视角聊天 | 传 `--user-token` 获取用户视角的聊天数据（否则只能看到机器人视角的有限信息） |
| 用 appToken 代替 userToken | 不传 `--user-token` 即使用 appToken（机器人身份），也是合法调用，但建议传 userToken 以获得完整信息 |
| 第一次拉消息就传非零 `--version` | 首次调用必须传 `--version 0` 或省略 |
| `--staff-id` 和 `--group-id` 同时传入 | 二选一，私聊用 `--staff-id`，群聊用 `--group-id` |
| keyword 在 type=0（全部）时使用 | keyword 仅在 type=1 或 type=2 时有效 |
| 传秒级时间戳而非微秒级 | 时间参数必须用微秒级（毫秒 × 1000） |
| 时间跨度超过1个月 | **必须按月拆分**，超过1个月历史数据会丢失；使用 `--split-month` |
| 以为 sender 是 staffId | sender 是**姓名**，不是 staffId，同名员工无法区分；结合 `sender_id` 或用 `staff search` 反查 |
| 需要对方部门/职位但只看 chat list | chat list 的 staff_infos 只含 staffId+staffName，需额外调 `staff detail` |

## SDK 用法

当需要批量拉取多个聊天的消息、或拉取跨多月的历史记录时，用 SDK 替代逐条 CLI 调用。详见 `../lansenger-sdk/SKILL.md`。

### 核心方法

```python
from lansenger_sdk import LansengerClient, LansengerSyncClient

# 异步
client = LansengerClient.from_store(profile="default")
chat_list = await client.fetch_chat_list(chat_type=0, user_token="ut1")
messages = await client.fetch_chat_messages(staff_id="staff123", start_time=1700000000000000, user_token="ut1")

# 同步
sync_client = LansengerSyncClient.from_store(profile="default")
chat_list = sync_client.fetch_chat_list(chat_type=0, user_token="ut1")
messages = sync_client.fetch_chat_messages(staff_id="staff123", start_time=1700000000000000, user_token="ut1")
```

### 批量并发拉取多个聊天

```python
import asyncio
from lansenger_sdk import LansengerClient

async def batch_fetch_all_chats():
    client = LansengerClient.from_store(profile="default")
    user_token = await client.get_user_token(staff_id="staff_001")

    # 获取聊天列表
    chat_list = await client.fetch_chat_list(user_token=user_token)
    if not chat_list.success:
        return

    # 构建目标列表
    targets = [{"staff_id": s.staff_id} for s in chat_list.staff_infos]
    targets += [{"group_id": g.group_id} for g in chat_list.group_infos]

    # 并发拉取（限流 5）
    semaphore = asyncio.Semaphore(5)
    async def fetch_one(target):
        async with semaphore:
            return await client.fetch_chat_messages(
                staff_id=target.get("staff_id", ""),
                group_id=target.get("group_id", ""),
                start_time=1770912000000000,  # 今日零点
                user_token=user_token,
            )

    results = await asyncio.gather(*[fetch_one(t) for t in targets])
    await client.close()

    total = sum(len(r.messages or []) for r in results if r.success)
    print(f"成功 {sum(1 for r in results if r.success)}/{len(results)}, 共 {total} 条")

asyncio.run(batch_fetch_all_chats())
```

### 深分页 + 按月拆分（完整历史）

CLI 的 `--split-month` 在 SDK 中需要手动实现按月拆分逻辑。完整代码模板详见 `../lansenger-sdk/SKILL.md` 的"模式 3：深分页 + 按月拆分"。

### 断点续传

长时间拉取任务支持中断后恢复，进度保存到 JSON 文件。详见 `../lansenger-sdk/SKILL.md` 的"模式 4：断点续传"。

### plain_text() 提取消息文本

SDK 的 `ChatMessageInfo` 对象提供 `plain_text()` 方法，自动处理所有消息格式：

```python
messages = result.messages
for msg in messages:
    text = msg.plain_text()  # 自动提取纯文本，无论 content 是 text/formatText/附件
    print(f"{msg.sender}: {text}")
```