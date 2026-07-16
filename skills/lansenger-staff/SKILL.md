---
name: lansenger-staff
version: 1.2.0
description: "蓝信员工/通讯录查询：基本信息、详细资料、部门祖先、ID映射（手机/邮箱→staffId）、组织扩展字段、员工搜索、组织信息。当用户需要查询员工信息、搜索员工、做ID映射时使用。"
metadata:
  requires:
    bins: ["lansenger"]
  cliHelp: "lansenger staff --help"
---

# staff

**本技能继承 [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md) 的所有规则。** Shell 执行纪律、Help-First 原则、认证、权限处理等均在其定义，此处不复述。

## Reverse Handoff — 何时不用此技能

| 用户意图 | 正确技能 | 原因 |
|----------|----------|------|
| 浏览组织架构/查部门 | `lansenger-department` | staff 管人，department 管部门 |
| 发消息给员工 | `lansenger-messaging` | 查到的 staffId 用于 messaging 的 chat_id 参数 |
| OAuth2 获取 userToken | `lansenger-oauth` | userToken 来源 |

**CRITICAL — 通讯录仅组织级应用可用，个人机器人不可用。** 详见 shared「身份能力矩阵」。
**CRITICAL — `search` 是用户级操作，需传入 `--as staff_id`（推荐）、`--user-token` 或 `--user-id`。其他命令（`basic-info`、`detail`、`ancestors`、`id-mapping`、`org-extra-fields`、`org-info`）以机器人身份即可调用，`--user-token` 可选。**

## 核心概念

蓝信员工/通讯录 API 提供员工信息查询、搜索和 ID 映射。部分操作以机器人身份（appToken）即可执行，部分需要用户级授权。

### ID 映射类型

`id-mapping` 命令支持将外部标识映射为蓝信 staffId：

| id_type 值 | 说明 |
|------------|------|
| `phone` | 手机号 |
| `email` | 邮箱 |
| `login_name` | 登录名 |
| `external_id` | 外部 ID |

### 认证要求

| 命令 | 认证要求 |
|------|---------|
| `basic-info` | appToken（可选 userToken） |
| `detail` | appToken（可选 userToken） |
| `ancestors` | appToken（可选 userToken） |
| `id-mapping` | appToken（可选 userToken） |
| `org-extra-fields` | appToken（可选 userToken） |
| `search` | 必须 userToken 或 userId |
| `org-info` | appToken |

## CLI 命令

### 查看员工基本信息

```bash
# 查看员工基本信息
lansenger staff basic-info staff123

# 带 userToken 查看
lansenger staff basic-info staff123 --user-token "ut1"
```

### 查看员工详细资料

```bash
# 查看员工详细资料（建议带 userToken）
lansenger staff detail staff123 --user-token "ut1"
```

### 查看员工部门祖先链

```bash
# 查看员工所属部门的完整层级链
lansenger staff ancestors staff123

# 带 userToken
lansenger staff ancestors staff123 --user-token "ut1"
```

### ID 映射（手机/邮箱 → staffId）

```bash
# 手机号 → staffId
lansenger staff id-mapping org123 phone "13800138000"

# 邮箱 → staffId
lansenger staff id-mapping org123 email "user@example.com"

# 登录名 → staffId
lansenger staff id-mapping org123 login_name "zhangsan"

# 外部 ID → staffId
lansenger staff id-mapping org123 external_id "emp001"
```

### 查看组织扩展字段

```bash
# 查看组织的自定义扩展字段 ID 列表
lansenger staff org-extra-fields org123

# 分页查看
lansenger staff org-extra-fields org123 --page 1 --size 500
```

### 搜索员工

```bash
# 搜索员工（需要 userToken 或 userId）
lansenger staff search "张三" --user-token "ut1"

# 搜索并限定部门范围
lansenger staff search "张三" --user-token "ut1" --sector dept1 --sector dept2

# 不递归搜索（仅搜索当前层级）
lansenger staff search "张三" --user-token "ut1" --no-recursive

# 使用 userId 而非 userToken
lansenger staff search "张三" --user-id staff456

# 分页搜索
lansenger staff search "张三" --user-token "ut1" --page 1 --size 50

# JSON 输出
lansenger -j staff search "张三" --user-token "ut1"
```

### 查看组织信息

```bash
# 查看组织基本信息
lansenger staff org-info org123
```

## 参数说明

### staff basic-info

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `staff_id` (位置参数) | str | — | 员工 ID（必需） |
| `--user-token` | str | "" | 用户 Token（可选） |

### staff detail

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `staff_id` (位置参数) | str | — | 员工 ID（必需） |
| `--user-token` | str | "" | 用户 Token（推荐传入） |

### staff ancestors

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `staff_id` (位置参数) | str | — | 员工 ID（必需） |
| `--user-token` | str | "" | 用户 Token（可选） |

### staff id-mapping

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `org_id` (位置参数) | str | — | 组织 ID（必需） |
| `id_type` (位置参数) | str | — | ID 类型：phone, email, login_name, external_id（必需） |
| `id_value` (位置参数) | str | — | ID 值（必需） |
| `--user-token` | str | "" | 用户 Token（可选） |

### staff org-extra-fields

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `org_id` (位置参数) | str | — | 组织 ID（必需） |
| `--user-token` | str | "" | 用户 Token（可选） |
| `--page` / `-p` | int | 1 | 页码 |
| `--size` / `-s` | int | 1000 | 每页条数（最大 100000） |

### staff search

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `keyword` (位置参数) | str | — | 搜索关键词（必需） |
| `--user-token` | str | "" | 用户 Token（与 --user-id 二选一） |
| `--user-id` | str | "" | 用户 ID（与 --user-token 二选一） |
| `--recursive` / `--no-recursive` | bool | True | 是否递归搜索子部门 |
| `--sector` | list | None | 限定搜索的部门 ID 列表 |
| `--page` / `-p` | int | None | 页码 |
| `--size` / `-s` | int | None | 每页条数（最大 100） |

### staff org-info

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `org_id` (位置参数) | str | — | 组织 ID（必需） |
| `--user-token` | str | "" | 用户 Token（可选） |

## 常见错误

| 错误 | 正确做法 |
|------|---------|
| `search` 不传 userToken 或 userId | search 必须传 `--user-token` 或 `--user-id` |
| id-mapping 用错 id_type | id_type 只支持 phone, email, login_name, external_id |
| id-mapping 不传 org_id | org_id 是必需位置参数 |
| search --size 超过 100 | search 每页最大 100 条 |
| org-extra-fields --size 超过 100000 | 每页最大 100000 条 |

## SDK 用法

当需要批量查询多个员工信息、或批量做 ID 映射时，用 SDK 替代逐条 CLI 调用。详见 `../lansenger-sdk/SKILL.md`。

### 核心方法

`LansengerClient` / `LansengerSyncClient` 提供与 CLI 一一对应的员工/通讯录方法：

| SDK 方法 | 对应 CLI 命令 | 关键参数 |
|----------|--------------|---------|
| `fetch_staff_basic_info(staff_id="xxx")` | `staff basic-info` | `staff_id`，可选 `user_token` |
| `fetch_staff_detail(staff_id="xxx", user_token="ut")` | `staff detail` | `staff_id`，推荐传 `user_token` |
| `fetch_staff_id_mapping(org_id="xxx", id_type="mobile", id_value="13800138000")` | `staff id-mapping` | `org_id`、`id_type`（mobile/mail/login/external_id/employ_id）、`id_value` |
| `search_staff(keyword="张三", user_token="ut")` | `staff search` | `keyword`，`user_token` 或 `user_id`（必需），可选 `recursive`、`sector_ids`、`page`、`page_size` |
| `fetch_department_ancestors(staff_id="xxx")` | `staff ancestors` | `staff_id`，可选 `user_token` |

### 批量查询员工详情（模式 1：顺序批量）

适合 10–50 个员工，使用 `SyncClient` 简单 for 循环：

```python
from lansenger_sdk import LansengerSyncClient

client = LansengerSyncClient.from_store(profile="default")

staff_ids = ["staff1", "staff2", "staff3", "staff4", "staff5"]
results = []
for sid in staff_ids:
    result = client.fetch_staff_detail(staff_id=sid, user_token="ut1")
    if result.success:
        results.append(result)
    else:
        print(f"查询 {sid} 失败: {result.error}")

print(f"成功 {len(results)}/{len(staff_ids)}")
```

### 批量并发查询（100+ 员工）

适合 100+ 员工，使用 `AsyncClient` + `asyncio.gather` + `Semaphore` 限流：

```python
import asyncio
from lansenger_sdk import LansengerClient

async def batch_fetch_staff_detail(staff_ids: list[str], user_token: str = "", max_concurrent: int = 5):
    client = LansengerClient.from_store(profile="default")
    semaphore = asyncio.Semaphore(max_concurrent)  # 限流，建议 ≤5

    async def fetch_one(staff_id: str):
        async with semaphore:
            return await client.fetch_staff_detail(staff_id=staff_id, user_token=user_token)

    results = await asyncio.gather(*[fetch_one(sid) for sid in staff_ids])
    await client.close()

    success = [r for r in results if r.success]
    failed = [(staff_ids[i], results[i].error) for i, r in enumerate(results) if not r.success]
    return success, failed

# 运行
staff_ids = ["staff1", "staff2", ..., "staff100"]
success, failed = asyncio.run(batch_fetch_staff_detail(staff_ids, user_token="ut1"))
```

**并发控制要点**：
- `Semaphore` 值建议 ≤5，避免触发 API 限流
- 必须在结束时 `await client.close()` 释放 HTTP 连接
- `search_staff` 因需要 userToken/userId，批量时建议统一传入同一个 `user_token`

> 更多 SDK 用法（深分页、断点续传、错误重试等）详见 [`../lansenger-sdk/SKILL.md`](../lansenger-sdk/SKILL.md)。