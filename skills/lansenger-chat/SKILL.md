---
name: lansenger-chat
version: 1.0.0
description: "蓝信聊天列表与消息历史：查看聊天列表（私聊+群聊）、拉取聊天消息记录。当用户需要查看聊天记录、浏览聊天列表时使用。"
metadata:
  requires:
    bins: ["lansenger"]
  cliHelp: "lansenger chat --help"
---

# chat (v1)

**CRITICAL — 开始前 MUST 先用 Read 工具读取 [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md)，其中包含认证、权限处理、安全规则。**

**CRITICAL — 聊天读取是用户级操作，必须传入 `--user-token` 参数（通过 OAuth2 获取）。机器人身份无法访问用户的聊天列表和消息记录。**

## 核心概念

蓝信聊天读取 API 允许你查看用户的聊天列表和拉取聊天消息历史。这两个操作都属于用户级资源，必须使用 userToken。

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

时间参数使用 **微秒级 Unix 时间戳**（毫秒 × 1000），例如 `1700000000000000`。

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
lansenger chat messages --staff-id staff123 --user-token "ut1" --json
```

## 参数说明

### chat list

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `--type` / `-t` | int | 0 | 聊天类型：0=全部, 1=私聊, 2=群聊 |
| `--keyword` / `-k` | str | "" | 搜索关键词（仅 type=1 或 type=2 时有效） |
| `--start` | int | 0 | 起始时间（微秒级时间戳） |
| `--end` | int | 0 | 结束时间（微秒级时间戳） |
| `--user-token` | str | "" | 用户 Token（必需） |

### chat messages

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `--staff-id` | str | "" | 私聊对方 staffId |
| `--group-id` | str | "" | 群 openId |
| `--size` / `-s` | int | 100 | 每页条数（最大 100） |
| `--version` | str | "0" | 深分页游标，首次调用传 0 |
| `--start` | int | 0 | 起始时间（微秒级时间戳） |
| `--end` | int | 0 | 结束时间（微秒级时间戳） |
| `--sender-id` | str | "" | 按发送者 staffId 过滤 |
| `--user-token` | str | "" | 用户 Token（必需） |

**注意**：`--staff-id` 和 `--group-id` 二选一，必须提供其中一个。

## 常见错误

| 错误 | 正确做法 |
|------|---------|
| 不传 `--user-token` 试图查看聊天 | 聊天是用户级资源，必须传 `--user-token` |
| 用 appToken 代替 userToken | appToken 是机器人身份，无法访问用户聊天记录 |
| 第一次拉消息就传非零 `--version` | 首次调用必须传 `--version 0` 或省略 |
| `--staff-id` 和 `--group-id` 同时传入 | 二选一，私聊用 `--staff-id`，群聊用 `--group-id` |
| keyword 在 type=0（全部）时使用 | keyword 仅在 type=1 或 type=2 时有效 |
| 传秒级时间戳而非微秒级 | 时间参数必须用微秒级（毫秒 × 1000） |