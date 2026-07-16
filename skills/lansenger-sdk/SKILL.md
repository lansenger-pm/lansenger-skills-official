---
name: lansenger-sdk
version: 1.0.0
description: "蓝信 SDK 编程指南 — 批量操作、并发拉取、数据管道等复杂任务。当 CLI 命令需要逐条执行超过3个对象、需要并发、或需要进程内数据传递时，切换到 SDK 模式。"
metadata:
  requires:
    bins: []
  pip: ["lansenger-sdk"]
---

# lansenger SDK 编程指南

**本技能继承 [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md) 的所有规则。** 认证、配置、安全等通用规则均在其定义，此处不复述。

## 何时用 SDK 而非 CLI

CLI 每条命令都会 spawn 一个新进程、重新初始化 HTTP client、获取 token。对于批量任务，这意味着巨大的开销和失败风险。

### CLI vs SDK 决策矩阵

| 场景特征 | 用 CLI | 用 SDK |
|----------|--------|--------|
| 操作对象数量 | 1–2 个 | **≥3 个** |
| 执行模式 | 逐条执行、逐条检查 | 批量、并发、管道 |
| 数据传递 | 命令间无共享状态 | 前一步结果喂给后一步 |
| 时间跨度 | 单次查询 | 深分页 + 按月拆分 + 断点续传 |
| 错误恢复 | 手动重跑 | 自动重试 + 断点续传 |
| 典型耗时 | < 5 秒 | 可能数分钟 |

**经验法则**：如果你发现自己在写一个 for 循环来调 CLI 命令，或者需要把上一步的 JSON 输出解析后传给下一步，就应该用 SDK。

### 性能对比示例

拉取 10 个聊天的最近消息：

| 方式 | 耗时（估） | 失败风险 |
|------|-----------|----------|
| CLI 逐条（10 次 spawn） | ~15–30 秒 | 高（任一进程失败需手动重试） |
| SDK SyncClient 顺序 | ~2–5 秒 | 低 |
| SDK AsyncClient 并发（Semaphore=5） | ~0.5–1 秒 | 低 |

## 安装

```bash
pip install lansenger-sdk
```

SDK 只依赖 `httpx`，零框架耦合，可在任何 Python 环境运行。

## 客户端初始化

### 三种创建方式

```python
# 方式 1：从环境变量创建（推荐，与 CLI 共享配置）
from lansenger_sdk import LansengerClient, LansengerSyncClient

# 异步客户端（并发批量任务推荐）
client = LansengerClient.from_env(store_path="~/.lansenger/sdk_state.json")

# 同步客户端（简单脚本推荐）
sync_client = LansengerSyncClient.from_env()

# 方式 2：从 CLI 已有 profile 创建（复用 CLI 配置的凭证）
client = LansengerClient.from_store(profile="default")

# 方式 3：直接传参数
client = LansengerClient(
    app_id="your-appid",
    app_secret="your-secret",
    api_gateway_url="https://your-gateway-url",
)
```

**关键**：`from_store()` 会复用 CLI `config set` 配置的凭证和已持久化的 userToken，无需重复配置。

### 异步 vs 同步选择

| 客户端 | 类名 | 适合场景 |
|--------|------|----------|
| **异步** | `LansengerClient` | 并发批量（asyncio.gather）、长期运行服务 |
| **同步** | `LansengerSyncClient` | 简单脚本、非 async 环境 |

`LansengerSyncClient` 的方法签名与 `LansengerClient` 完全一致，只是不需要 `await`。

```python
# 异步（需要 asyncio 事件循环）
result = await client.send_text(chat_id="staff123", content="Hello")

# 同步（直接调用）
result = sync_client.send_text(chat_id="staff123", content="Hello")
```

## Token 管理

SDK 的 Token 管理比 CLI 更自动化：

### appToken — 全自动

```python
# appToken 由 TokenManager 自动获取和刷新，你无需任何操作
client = LansengerClient.from_env()
result = await client.send_text(chat_id="staff123", content="Hello")
# 内部自动：获取 appToken → 缓存 → 2小时后自动刷新
```

### userToken — 自动刷新

```python
# 方式 1：复用 CLI 已持久化的 userToken（from_store 自动加载）
client = LansengerClient.from_store(profile="default")
user_token = await client.get_user_token(staff_id="staff_001")
result = await client.fetch_chat_list(user_token=user_token)

# 方式 2：OAuth2 授权后注册 token（自动刷新）
token_result = await client.exchange_code(code="auth_code")
# exchange_code 内部已自动调用 set_user_tokens()，后续自动刷新

# 方式 3：手动设置 token（适合从外部传入）
client.set_user_tokens(
    user_token="ut_xxx",
    refresh_token="rt_xxx",
    expires_in=7200,
    staff_id="staff_001",
)
```

**与 CLI 的对应关系**：

| CLI | SDK |
|-----|-----|
| `--as staff_001` | `client.get_user_token(staff_id="staff_001")` |
| `--user-token "ut_xxx"` | `user_token="ut_xxx"` 传给方法参数 |
| `--app-token "xxx"` | `LansengerClient(app_token="xxx")` |

## 四种批量模式

### 模式 1：顺序批量（SyncClient）

最简单，适合 10–50 个对象的批量操作。

```python
from lansenger_sdk import LansengerSyncClient

client = LansengerSyncClient.from_store(profile="default")

# 批量查员工详情
staff_ids = ["staff1", "staff2", "staff3", "staff4", "staff5"]
results = []
for sid in staff_ids:
    result = client.fetch_staff_basic_info(staff_id=sid)
    if result.success:
        results.append(result)
    else:
        print(f"查询 {sid} 失败: {result.error}")

print(f"成功 {len(results)}/{len(staff_ids)}")
```

### 模式 2：并发批量（AsyncClient + Semaphore）

适合 50+ 个对象，或需要最小化总耗时。

```python
import asyncio
from lansenger_sdk import LansengerClient

async def batch_fetch_staff(staff_ids: list[str], max_concurrent: int = 5):
    client = LansengerClient.from_store(profile="default")
    semaphore = asyncio.Semaphore(max_concurrent)  # 限流，建议 ≤5

    async def fetch_one(staff_id: str):
        async with semaphore:
            return await client.fetch_staff_basic_info(staff_id=staff_id)

    results = await asyncio.gather(*[fetch_one(sid) for sid in staff_ids])
    await client.close()

    success = [r for r in results if r.success]
    failed = [(staff_ids[i], results[i].error) for i, r in enumerate(results) if not r.success]
    return success, failed

# 运行
staff_ids = ["staff1", "staff2", ..., "staff100"]
success, failed = asyncio.run(batch_fetch_staff(staff_ids))
```

**并发控制要点**：
- `Semaphore` 值建议 ≤5，避免触发 API 限流
- 每次调用间隔无需手动 sleep（Semaphore 已限流）
- 必须在结束时 `await client.close()` 释放 HTTP 连接

### 模式 3：深分页 + 按月拆分（完整历史拉取）

CLI 的 `--split-month` 在 SDK 中的等效实现：

```python
import asyncio
import calendar as cal_mod
from datetime import datetime
from lansenger_sdk import LansengerClient

def split_months(start_us: int, end_us: int) -> list[tuple[int, int]]:
    """将时间范围按月拆分，返回 [(月起始微秒, 月结束微秒), ...]"""
    results = []
    start_dt = datetime.fromtimestamp(start_us / 1_000_000) if start_us else datetime(2020, 1, 1)
    end_dt = datetime.fromtimestamp(end_us / 1_000_000)
    year, month = start_dt.year, start_dt.month
    while (year, month) <= (end_dt.year, end_dt.month):
        last_day = cal_mod.monthrange(year, month)[1]
        ms_start = int(datetime(year, month, 1).timestamp() * 1_000_000)
        ms_end = int(datetime(year, month, last_day, 23, 59, 59).timestamp() * 1_000_000)
        results.append((ms_start, ms_end))
        month += 1
        if month > 12:
            month = 1
            year += 1
    return results

async def fetch_all_messages(
    client: LansengerClient,
    staff_id: str = "",
    group_id: str = "",
    start_time: int = 0,
    end_time: int = 0,
    user_token: str = "",
):
    """完整历史拉取：按月拆分 + 深分页翻取"""
    all_messages = []
    months = split_months(start_time, end_time)

    for i, (ms_start, ms_end) in enumerate(months):
        cursor = "0"
        page = 0
        while True:
            result = await client.fetch_chat_messages(
                staff_id=staff_id,
                group_id=group_id,
                base_version=cursor,
                start_time=ms_start,
                end_time=ms_end,
                user_token=user_token,
            )
            if not result.success:
                print(f"月 {i+1} 第 {page+1} 页失败: {result.error}")
                break

            all_messages.extend(result.messages or [])
            page += 1

            if not (result.messages and getattr(result, "has_more", False)):
                break
            cursor = str(getattr(result, "last_version", ""))

        print(f"月 {i+1}/{len(months)}: {page} 页, 累计 {len(all_messages)} 条")

    return all_messages
```

### 模式 4：断点续传

适合长时间拉取任务，中断后可恢复：

```python
import json
import os
from lansenger_sdk import LansengerClient

PROGRESS_FILE = "fetch_progress.json"

def load_progress() -> dict:
    if os.path.exists(PROGRESS_FILE):
        with open(PROGRESS_FILE) as f:
            return json.load(f)
    return {}

def save_progress(progress: dict):
    with open(PROGRESS_FILE, "w") as f:
        json.dump(progress, f, ensure_ascii=False, indent=2)

async def fetch_with_checkpoint(
    client: LansengerClient,
    chat_targets: list[dict],  # [{"staff_id": "xxx"}, {"group_id": "yyy"}]
    start_time: int,
    end_time: int,
    user_token: str = "",
):
    """断点续传拉取多个聊天的消息"""
    progress = load_progress()
    all_messages = {}

    for target in chat_targets:
        key = target.get("staff_id") or target.get("group_id")
        # 跳过已完成的
        if progress.get(key, {}).get("done"):
            print(f"跳过 {key}（已完成）")
            continue

        cursor = progress.get(key, {}).get("last_version", "0")
        messages = []

        while True:
            result = await client.fetch_chat_messages(
                staff_id=target.get("staff_id", ""),
                group_id=target.get("group_id", ""),
                base_version=cursor,
                start_time=start_time,
                end_time=end_time,
                user_token=user_token,
            )
            if not result.success:
                print(f"{key} 失败: {result.error}，进度已保存")
                save_progress(progress)
                return all_messages

            messages.extend(result.messages or [])
            progress[key] = {
                "last_version": str(getattr(result, "last_version", "")),
                "count": len(messages),
                "done": not getattr(result, "has_more", False),
            }
            save_progress(progress)  # 每页保存一次

            if not getattr(result, "has_more", False):
                break
            cursor = str(getattr(result, "last_version", ""))

        all_messages[key] = messages
        print(f"{key}: {len(messages)} 条")

    return all_messages
```

## 错误处理与重试

SDK 的 Result 对象提供 `success`、`error`、`retryable` 字段：

```python
import asyncio
from lansenger_sdk import LansengerClient

async def fetch_with_retry(client, max_retries=3, **kwargs):
    """带指数退避的重试封装"""
    for attempt in range(max_retries):
        result = await client.fetch_chat_messages(**kwargs)
        if result.success:
            return result

        # retryable=True 表示可重试（网络错误、服务器5xx）
        retryable = getattr(result, "retryable", False)
        if not retryable or attempt == max_retries - 1:
            return result  # 不可重试或已用完重试次数

        wait = 2 ** attempt  # 1s, 2s, 4s
        print(f"第 {attempt+1} 次失败（可重试），{wait}s 后重试: {result.error}")
        await asyncio.sleep(wait)

    return result
```

**retryable 判断规则**：
- `retryable=True`：网络超时、HTTP 5xx、连接错误
- `retryable=False`（默认）：API 业务错误（errCode != 0）、参数错误、权限不足

## 连接复用

AsyncClient 在单个进程内复用 HTTP 连接，这是 SDK 比 CLI 快的核心原因：

```python
# ✅ 正确：创建一次 client，复用连接
client = LansengerClient.from_store(profile="default")
for sid in staff_ids:
    result = await client.fetch_staff_basic_info(staff_id=sid)
await client.close()

# ❌ 错误：每次操作都创建新 client（等于自己造 CLI 的开销）
for sid in staff_ids:
    c = LansengerClient.from_store(profile="default")
    await c.fetch_staff_basic_info(staff_id=sid)
    await c.close()
```

**共享 HTTP client**（高级场景，适合嵌入 async 框架）：

```python
import httpx
from lansenger_sdk import LansengerClient

# 创建一个共享的 httpx client（可配置连接池大小）
shared_http = httpx.AsyncClient(
    timeout=30.0,
    limits=httpx.Limits(max_connections=20, max_keepalive_connections=10),
)

client = LansengerClient.from_env()
client.attach_http_client(shared_http)  # SDK 不会关闭外部传入的 client

# ... 批量操作 ...

await client.close()  # 只关闭 SDK 内部资源，不关闭 shared_http
await shared_http.aclose()  # 手动关闭共享 client
```

## 常见批量场景速查表

| 场景 | 推荐 CLI 或 SDK | 核心方法 |
|------|----------------|----------|
| 拉取 1 个聊天的消息 | CLI `chat messages` | — |
| 批量拉取 N 个聊天消息 | **SDK 模式 2** | `fetch_chat_messages` + asyncio.gather |
| 拉取完整历史（跨多月） | **SDK 模式 3** | `fetch_chat_messages` + 按月拆分 + 深分页 |
| 群发通知到 5 个群 | CLI（逐条） | — |
| 群发通知到 50+ 个群 | **SDK 模式 2** | `send_text(is_group=True)` + Semaphore |
| 查 1 个员工信息 | CLI `staff basic-info` | — |
| 批量查 20 个员工详情 | **SDK 模式 1** | `fetch_staff_basic_info` 循环 |
| 批量查 100+ 员工 | **SDK 模式 2** | `fetch_staff_basic_info` + asyncio.gather |
| 查今日日程 | CLI `calendar list-schedules` | — |
| 拉取多月日程 + 待办汇总 | **SDK 模式 1** | `fetch_schedule_list` + `fetch_todo_task_list` |
| 批量上传 10 个文件 | **SDK 模式 2** | `upload_media` + asyncio.gather |
| 断点续传拉取历史 | **SDK 模式 4** | `fetch_chat_messages` + JSON 进度文件 |

## 多语言 SDK 备注

本指南以 Python SDK 为准。其他语言 SDK 的核心 API 对应关系：

| 概念 | Python | Go | TypeScript |
|------|--------|----|------------|
| 异步客户端 | `LansengerClient` | `lansenger.NewClient()` | `LansengerClient` |
| 同步客户端 | `LansengerSyncClient` | （Go 天然同步） | — |
| 并发模型 | `asyncio.gather` | goroutine + `sync.WaitGroup` | `Promise.all` |
| 限流 | `asyncio.Semaphore` | buffered channel | `p-limit` 等库 |
| 连接复用 | `httpx.AsyncClient` | `http.Client`（默认复用） | `fetch` / `undici` |

**Go 注意**：Go SDK 天然是同步阻塞调用，并发用 goroutine + channel 限流。方法签名与 Python 一致，参数名用驼峰命名。

**TypeScript 注意**：TS SDK 方法返回 `Promise`，并发用 `Promise.all` + 限流库。方法签名与 Python 一致，参数名用驼峰命名。

## 常见错误

| 错误 | 原因 | 解决方案 |
|------|------|---------|
| `No credentials found for profile` | from_store 找不到 profile | 先用 CLI `lansenger config set` 配置，或改用 `from_env()` |
| `No userToken available` | 未进行 OAuth2 授权 | 先 `exchange_code()` 或 `set_user_tokens()` |
| `refreshToken has expired` | refreshToken 过期（30天） | 重新走 OAuth2 授权流程 |
| 并发请求被限流 | Semaphore 值过大 | 降到 ≤5，增加重试 |
| 内存溢出（消息太多） | 一次性加载所有数据 | 分批处理，每批写文件后释放 |
| `Event loop is already running` | 在 async 环境中用 SyncClient | 改用 `LansengerClient`（异步） |
