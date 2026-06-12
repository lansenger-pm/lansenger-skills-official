---
name: lansenger-todo
version: 1.0.0
description: "蓝信待办任务管理：创建、更新、查询、删除待办任务，管理执行人，查看状态统计。当用户需要创建/查询/管理待办任务时使用。"
metadata:
  requires:
    bins: ["lansenger"]
  cliHelp: "lansenger todo --help"
---

# todo (v1)

**本技能继承 [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md) 的所有规则。** Shell 执行纪律、Help-First 原则、认证、权限处理等均在其定义，此处不复述。

## Reverse Handoff — 何时不用此技能

| 用户意图 | 正确技能 | 原因 |
|----------|----------|------|
| 发送待办提醒消息 | `lansenger-messaging` | todo 管待办条目，messaging 管发消息通知 |

**CRITICAL — 创建/删除待办属于高风险操作，执行前 MUST 向用户确认操作目标和内容。**

## 核心概念

蓝信统一待办 API 提供待办任务的完整生命周期管理。以机器人身份（appToken）即可调用，可选传 `--user-token`。

### 任务状态码

| 状态码 | 含义 |
|--------|------|
| 11 | 待阅（pending-read） |
| 12 | 已阅（read） |
| 21 | 待办（pending-do） |
| 22 | 已办（done） |

### 任务类型码

| 类型码 | 含义 |
|--------|------|
| 1 | 通知（notification） |
| 2 | 审批（approval） |

### 执行人管理

- 创建时通过 `executor_ids` 指定执行人列表
- 后续可通过 `add-executors`/`delete-executors` 增删执行人
- 可通过 `executor-status` 更新单个执行人状态
- 可通过 `executor-list` 查看执行人列表

### 删除权限

只有发送者（创建者）才能删除待办任务。

## CLI 命令

### 创建待办

```bash
# 创建通知类待办
lansenger todo create "请审批报销单" "https://app.com/a/1" "https://pc.app.com/a/1" "staff1,staff2" org123

# 创建审批类待办
lansenger todo create "审批申请" "https://app.com/a/2" "https://pc.app.com/a/2" "staff3" org123 --type 2

# 创建带描述的待办
lansenger todo create "请审批报销单" "https://app.com/a/1" "https://pc.app.com/a/1" "staff1" org123 --desc "报销金额500元"

# 创建带来源ID的待办（用于后续按来源查询）
lansenger todo create "审批" "https://app.com" "https://pc.app.com" "staff1" org123 --source-id "approval-123"
```

### 更新待办内容

```bash
# 更新待办标题和链接
lansenger todo update task123 "新标题" "https://app.com/new" "https://pc.app.com/new" org123

# 更新带描述
lansenger todo update task123 "新标题" "https://app.com/new" "https://pc.app.com/new" org123 --desc "更新内容"
```

### 更新待办状态

```bash
# 标记为已办
lansenger todo update-status task123 22 org123

# 标记为已阅
lansenger todo update-status task123 12 org123

# 标记为待办
lansenger todo update-status task123 21 org123 --staff-id staff1
```

### 删除待办

```bash
# 删除待办（仅创建者可删）
lansenger todo delete task123 org123

# 指定发送者身份
lansenger todo delete task123 org123 --staff-id sender1
```

### 查看待办列表

```bash
# 查看组织的所有待办
lansenger todo list org123

# 按执行人过滤
lansenger todo list org123 --staff-id staff1

# 按状态过滤
lansenger todo list org123 --status 21,22

# 按应用过滤
lansenger todo list org123 --app-ids app1,app2

# JSON 输出
lansenger todo list org123 --json
```

### 按来源ID查询

```bash
# 通过 sourceId 查询待办
lansenger todo fetch-by-source "approval-123" org123
```

### 按任务ID查询

```bash
# 通过 todotaskId 查询待办
lansenger todo fetch-by-id task123 org123
```

### 查看状态统计

```bash
# 查看某人的待办状态统计
lansenger todo status-counts staff1 org123

# 按应用和状态过滤
lansenger todo status-counts staff1 org123 --app-id app1 --status 21,22
```

### 管理执行人

```bash
# 添加执行人
lansenger todo add-executors "staff4,staff5" org123 --task-id task123

# 删除执行人
lansenger todo delete-executors "staff4" org123 --task-id task123

# 更新执行人状态
lansenger todo executor-status '[{"executorId":"staff1","status":"22"}]' org123 --task-id task123

# 查看执行人列表
lansenger todo executor-list task123 org123

# 查看执行人列表（按状态过滤）
lansenger todo executor-list task123 org123 --status 21

# 查看执行人列表（指定员工）
lansenger todo executor-list task123 org123 --staff-id staff1
```

## 参数说明

### todo create

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `title` (位置参数) | str | — | 任务标题（必需） |
| `link` (位置参数) | str | — | 任务链接 URL（必需） |
| `pc_link` (位置参数) | str | — | PC 端链接 URL（必需） |
| `executor_ids` (位置参数) | str | — | 执行人 ID 列表（逗号分隔，必需） |
| `org_id` (位置参数) | str | — | 组织 ID（必需） |
| `--type` / `-t` | int | 1 | 类型：1=通知, 2=审批 |
| `--source-id` | str | "" | 来源 ID（用于去重和后续查询） |
| `--desc` / `-d` | str | "" | 任务描述 |
| `--sender-id` | str | "" | 发送者 staffId |
| `--user-token` | str | "" | 用户 Token |

### todo update

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `todotask_id` (位置参数) | str | — | 待办任务 ID（必需） |
| `title` (位置参数) | str | — | 新标题（必需） |
| `link` (位置参数) | str | — | 新链接 URL（必需） |
| `pc_link` (位置参数) | str | — | 新 PC 链接 URL（必需） |
| `org_id` (位置参数) | str | — | 组织 ID（必需） |
| `--desc` / `-d` | str | "" | 新描述 |
| `--user-token` | str | "" | 用户 Token |

### todo update-status

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `todotask_id` (位置参数) | str | — | 待办任务 ID（必需） |
| `status` (位置参数) | str | — | 状态码：11/12/21/22（必需） |
| `org_id` (位置参数) | str | — | 组织 ID（必需） |
| `--staff-id` | str | "" | 执行人 staffId |
| `--user-token` | str | "" | 用户 Token |

### todo delete

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `todotask_id` (位置参数) | str | — | 待办任务 ID（必需） |
| `org_id` (位置参数) | str | — | 组织 ID（必需） |
| `--staff-id` | str | "" | 发送者 staffId |
| `--user-token` | str | "" | 用户 Token |

### todo list

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `org_id` (位置参数) | str | — | 组织 ID（必需） |
| `--user-token` | str | "" | 用户 Token |
| `--app-ids` | str | None | 应用 ID 列表（逗号分隔） |
| `--staff-id` | str | "" | 按执行人过滤 |
| `--status` | str | None | 状态列表（逗号分隔，如 21,22） |

### todo fetch-by-source

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `source_id` (位置参数) | str | — | 来源 ID（必需） |
| `org_id` (位置参数) | str | — | 组织 ID（必需） |
| `--staff-id` | str | "" | 执行人 staffId |
| `--user-token` | str | "" | 用户 Token |

### todo fetch-by-id

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `todotask_id` (位置参数) | str | — | 待办任务 ID（必需） |
| `org_id` (位置参数) | str | — | 组织 ID（必需） |
| `--staff-id` | str | "" | 执行人 staffId |
| `--user-token` | str | "" | 用户 Token |

### todo status-counts

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `staff_id` (位置参数) | str | — | 员工 ID（必需） |
| `org_id` (位置参数) | str | — | 组织 ID（必需） |
| `--app-id` | str | "" | 应用 ID |
| `--status` | str | None | 状态列表（逗号分隔） |
| `--user-token` | str | "" | 用户 Token |

### todo executor-status

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `executor_status_list` (位置参数) | str | — | 执行人状态 JSON（如 `[{"executorId":"x","status":"22"}]`） |
| `org_id` (位置参数) | str | — | 组织 ID（必需） |
| `--task-id` | str | "" | 待办任务 ID |
| `--user-token` | str | "" | 用户 Token |

### todo add-executors

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `executor_ids` (位置参数) | str | — | 执行人 ID 列表（逗号分隔，必需） |
| `org_id` (位置参数) | str | — | 组织 ID（必需） |
| `--task-id` | str | "" | 待办任务 ID |
| `--user-token` | str | "" | 用户 Token |

### todo delete-executors

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `executor_ids` (位置参数) | str | — | 执行人 ID 列表（逗号分隔，必需） |
| `org_id` (位置参数) | str | — | 组织 ID（必需） |
| `--task-id` | str | "" | 待办任务 ID |
| `--user-token` | str | "" | 用户 Token |

### todo executor-list

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `todotask_id` (位置参数) | str | — | 待办任务 ID（必需） |
| `org_id` (位置参数) | str | — | 组织 ID（必需） |
| `--staff-id` | str | "" | 员工 staffId |
| `--status` | str | None | 状态列表（逗号分隔） |
| `--user-token` | str | "" | 用户 Token |

## 常见错误

| 错误 | 正确做法 |
|------|---------|
| 传数字状态码而非字符串 | 状态码为字符串：11, 12, 21, 22 |
| 非创建者尝试删除待办 | 只有发送者（创建者）才能删除 |
| executor_ids 不传逗号分隔 | 多个执行人用逗号分隔，如 "staff1,staff2" |
| executor-status 不传 JSON 格式 | 必须传 JSON 数组格式 |
| 创建时不传 link/pc_link | link 和 pc_link 是必需参数 |
| 不确认就创建/删除待办 | 创建/删除属于高风险操作，必须先确认 |