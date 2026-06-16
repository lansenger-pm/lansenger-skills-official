---
name: lansenger-group
version: 1.2.0
description: "蓝信群组管理：创建群、查看群信息、群成员列表、群列表、成员检查、更新群设置、添加/移除成员、解散群。当用户需要管理群组时使用。"
metadata:
  requires:
    bins: ["lansenger"]
  cliHelp: "lansenger group --help"
---

# group (v1.1)

**本技能继承 [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md) 的所有规则。** Shell 执行纪律、Help-First 原则、认证、权限处理等均在其定义，此处不复述。

## Reverse Handoff — 何时不用此技能

| 用户意图 | 正确技能 | 原因 |
|----------|----------|------|
| 在群里发消息 | `lansenger-messaging` | group 管群结构，messaging 管发消息 |
| 查群成员的详细信息 | `lansenger-staff` | group members 返回成员列表，详情用 staff |
| 查看群聊天记录 | `lansenger-chat` | group 不管消息记录 |

**CRITICAL — 添加/移除群成员属于高风险操作，执行前 MUST 向用户确认操作目标和具体人员。**

**CRITICAL — 群管理 V2 全部 API 需要「蓝信应用 + 机器人能力」，个人机器人不可用。** 详见 shared「身份能力矩阵」。

## 核心概念

蓝信群组 V2 API 提供群组的完整生命周期管理：创建、查询、更新设置、成员增删。以应用/机器人身份（appToken）执行，少数操作可选传 `--user-token` 以用户身份执行。

### 创建群约束

- 创建群时如果提供 `--staff` 列表，最少需要 **3 人**
- 可同时通过 `--staff` 添加指定员工，通过 `--dept` 添加部门全体成员
- 机器人身份不能添加部门成员（需传 `--as staff_id` 或 `--user-token`）

### 群管理权限

- 更新群信息/转让群主需要应用具备机器人能力
- 更新群成员时，机器人身份不能添加部门成员

## CLI 命令

### 创建群

```bash
# 创建基本群
lansenger group create "项目讨论组" org123

# 创建群并指定群主
lansenger group create "项目讨论组" org123 --owner staff456

# 创建群并添加成员和描述
lansenger group create "项目讨论组" org123 --staff staff1 --staff staff2 --staff staff3 --desc "项目讨论"

# 创建群并添加部门成员（需要 userToken）
lansenger group create "项目讨论组" org123 --dept dept1 --user-token "ut1"
```

### 查看群信息

```bash
# 查看群详情
lansenger group info group456

# 查看群详情（带 userToken）
lansenger group info group456 --user-token "ut1"
```

### 查看群成员

```bash
# 查看群成员（默认100条）
lansenger group members group456

# 分页查看
lansenger group members group456 --page 1 --size 50

# 带 userToken 查看
lansenger group members group456 --user-token "ut1"
```

### 群列表

```bash
# 查看机器人所在的所有群
lansenger group list

# 分页查看
lansenger group list --page 0 --size 50

# 查看用户所在的群
lansenger group list --user-token "ut1"
```

### 检查成员是否在群内

```bash
# 检查某人是否在群内
lansenger group check group456 --staff-id staff789

# 检查机器人自己是否在群内（不传 --staff-id）
lansenger group check group456
```

### 更新群信息

```bash
# 修改群名
lansenger group update group456 --name "新群名"

# 修改群描述
lansenger group update group456 --desc "新描述"

# 转让群主（必须传 userToken）
lansenger group update group456 --owner newOwner123 --user-token "ut1"

# 同时修改多个属性
lansenger group update group456 --name "项目V2" --desc "更新描述" --user-token "ut1"
```

### 更新群成员

```bash
# 添加成员
lansenger group update-members group456 --add staff1 --add staff2

# 移除成员
lansenger group update-members group456 --remove staff3

# 添加部门成员（需要 userToken）
lansenger group update-members group456 --add-dept dept1 --user-token "ut1"

# 同时添加和移除
lansenger group update-members group456 --add staff4 --remove staff5

# JSON 输出
lansenger -j group update-members group456 --add staff1
```

### 解散群

```bash
# 解散群（高风险操作，必须先确认）
lansenger group dismiss group456

# 以用户身份解散
lansenger group dismiss group456 --user-token "ut1"
```

## 参数说明

### group dismiss

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `group_id` (位置参数) | str | — | 群 ID（必需） |
| `--user-token` | str | "" | 用户 Token |

### group create

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `name` (位置参数) | str | — | 群名称（必需） |
| `org_id` (位置参数) | str | — | 组织 ID（必需） |
| `--owner` | str | "" | 群主 staffId |
| `--desc` / `-d` | str | "" | 群描述 |
| `--avatar` | str | "" | 头像 ID |
| `--staff` | list | None | 添加的员工 ID 列表（最少 3 人） |
| `--dept` | list | None | 添加的部门 ID 列表 |
| `--user-token` | str | "" | 用户 Token |

### group info

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `group_id` (位置参数) | str | — | 群 ID（必需） |
| `--user-token` | str | "" | 用户 Token |

### group members

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `group_id` (位置参数) | str | — | 群 ID（必需） |
| `--user-token` | str | "" | 用户 Token |
| `--page` / `-p` | int | 0 | 页偏移 |
| `--size` / `-s` | int | 100 | 每页条数 |

### group list

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `--user-token` | str | "" | 用户 Token |
| `--page` / `-p` | int | 0 | 页偏移 |
| `--size` / `-s` | int | 100 | 每页条数 |

### group check

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `group_id` (位置参数) | str | — | 群 ID（必需） |
| `--user-token` | str | "" | 用户 Token |
| `--staff-id` | str | "" | 要检查的 staffId（不传则检查机器人自身） |

### group update

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `group_id` (位置参数) | str | — | 群 ID（必需） |
| `--name` | str | "" | 新群名 |
| `--desc` | str | "" | 新描述 |
| `--owner` | str | "" | 新群主 ID（必须传 --user-token） |
| `--user-token` | str | "" | 用户 Token |

### group update-members

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `group_id` (位置参数) | str | — | 群 ID（必需） |
| `--add` | list | None | 添加的员工 ID 列表 |
| `--remove` | list | None | 移除的员工 ID 列表 |
| `--add-dept` | list | None | 添加的部门 ID 列表（需 userToken） |
| `--user-token` | str | "" | 用户 Token |

## 常见错误

| 错误 | 正确做法 |
|------|---------|
| 创建群时 --staff 不足 3 人 | --staff 列表最少 3 人，不足则不传 --staff |
| 机器人身份用 --dept 添加部门成员 | 必须传 `--user-token` 以用户身份添加部门成员 |
| 转让群主不传 --user-token | 转让群主操作必须传 `--user-token` |
| 不确认就添加/移除群成员 | 添加/移除成员属于高风险操作，必须先确认 |
| 不确认就解散群 | 解散群属于高风险操作（不可恢复），必须先确认 |
| 群名/org_id 不传位置参数 | `create` 的 name 和 org_id 是必需位置参数 |
| group_id 不传位置参数 | `info`/`members`/`check`/`update`/`update-members` 的 group_id 是必需位置参数 |