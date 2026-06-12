---
name: lansenger-staff
version: 1.0.0
description: "蓝信员工/通讯录查询：基本信息、详细资料、部门祖先、ID映射（手机/邮箱→staffId）、组织扩展字段、员工搜索、组织信息。当用户需要查询员工信息、搜索员工、做ID映射时使用。"
metadata:
  requires:
    bins: ["lansenger"]
  cliHelp: "lansenger staff --help"
---

# staff (v1)

**本技能继承 [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md) 的所有规则。** Shell 执行纪律、Help-First 原则、认证、权限处理等均在其定义，此处不复述。

## Reverse Handoff — 何时不用此技能

| 用户意图 | 正确技能 | 原因 |
|----------|----------|------|
| 浏览组织架构/查部门 | `lansenger-department` | staff 管人，department 管部门 |
| 发消息给员工 | `lansenger-messaging` | 查到的 staffId 用于 messaging 的 chat_id 参数 |
| OAuth2 获取 userToken | `lansenger-oauth` | userToken 来源 |

**CRITICAL — `search` 是用户级操作，必须传入 `--user-token` 或 `--user-id`。其他命令（`basic-info`、`detail`、`ancestors`、`id-mapping`、`org-extra-fields`、`org-info`）以机器人身份即可调用，`--user-token` 可选。**

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
# 查看员工详细资料（需要 userToken）
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
lansenger staff search "张三" --user-token "ut1" --json
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