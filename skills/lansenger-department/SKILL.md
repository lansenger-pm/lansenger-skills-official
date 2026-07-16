---
name: lansenger-department
version: 1.1.1
description: "蓝信部门/组织架构导航：部门详情、子部门列表、部门员工列表。当用户需要浏览组织架构、查看部门信息时使用。"
metadata:
  requires:
    bins: ["lansenger"]
  cliHelp: "lansenger department --help"
---

# department

**本技能继承 [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md) 的所有规则。** Shell 执行纪律、Help-First 原则、认证、权限处理等均在其定义，此处不复述。

## Reverse Handoff — 何时不用此技能

| 用户意图 | 正确技能 | 原因 |
|----------|----------|------|
| 查员工信息 | `lansenger-staff` | department 管部门结构，staff 管人 |
| 发消息到部门 | `lansenger-messaging` | 部门成员列表只是查询结果，发消息用 messaging |

## 核心概念

蓝信部门 API 提供组织架构导航能力：查看部门详情、获取子部门列表、查看部门下的员工。仅组织级应用（appToken）可用，可选传 `--user-token`。个人机器人不可用。详见 shared「身份能力矩阵」。

### 根部门 ID

浏览组织架构的起点是根部门，其 ID 通常为 `"524288-0"`。从根部门开始，通过 `children` 递归遍历整棵组织树。

### 分页机制

`staffs` 命令支持分页，默认 page=1、page_size=100。如果返回 `has_more=True`，继续增加 page 值拉取下一页。

## CLI 命令

### 查看部门详情

```bash
# 查看部门详情
lansenger department detail dept123

# 查看根部门详情（组织架构起点）
lansenger department detail 524288-0

# 带标签过滤
lansenger department detail dept123 --tag-id tag456

# 带 userToken
lansenger department detail dept123 --user-token "ut1"
```

### 查看子部门列表

```bash
# 查看子部门
lansenger department children dept123

# 查看根部门的子部门（开始遍历组织架构）
lansenger department children 524288-0

# 带 userToken
lansenger department children dept123 --user-token "ut1"

# JSON 输出
lansenger -j department children 524288-0
```

### 查看部门员工列表

```bash
# 查看部门员工（默认100条）
lansenger department staffs dept123

# 分页查看
lansenger department staffs dept123 --page 1 --size 50

# 查看更多页
lansenger department staffs dept123 --page 2 --size 100

# 带 userToken
lansenger department staffs dept123 --user-token "ut1"

# JSON 输出
lansenger -j department staffs dept123
```

## 参数说明

### department detail

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `department_id` (位置参数) | str | — | 部门 ID（必需） |
| `--user-token` | str | "" | 用户 Token（可选） |
| `--tag-id` | str | "" | 标签 ID 过滤 |

### department children

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `department_id` (位置参数) | str | — | 部门 ID（必需） |
| `--user-token` | str | "" | 用户 Token（可选） |

### department staffs

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `department_id` (位置参数) | str | — | 部门 ID（必需） |
| `--user-token` | str | "" | 用户 Token（可选） |
| `--page` / `-p` | int | 1 | 页码 |
| `--size` / `-s` | int | 100 | 每页条数 |

## 常见错误

| 错误 | 正确做法 |
|------|---------|
| 不知道根部门 ID | 从 `"524288-0"` 开始浏览组织架构 |
| 只看第一页就认为获取了全部员工 | 检查 `has_more` 字段，有则继续翻页 |
| 期望 children 返回员工信息 | children 只返回子部门，员工需用 `staffs` 命令 |
| department_id 不传位置参数 | detail/children/staffs 的 department_id 是必需位置参数 |