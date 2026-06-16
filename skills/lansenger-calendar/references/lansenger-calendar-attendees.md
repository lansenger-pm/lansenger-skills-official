# lansenger calendar attendees / add-attendees / delete-attendees

## 前置条件

../lansenger-shared/SKILL.md

## 描述

管理日程的参与人。提供三个子命令：

- **attendees**：分页获取日程的参与人列表。
- **add-attendees**：向日程添加参与人。
- **delete-attendees**：从日程中移除参与人。

## 命令示例

### attendees（获取）

```bash
lansenger calendar attendees "cal_xxx" "sch_xxx" --user-token "ut_xxx"
```

```bash
lansenger calendar attendees "cal_xxx" "sch_xxx" --page 2 --size 50 --user-id "uid_xxx"
```

### add-attendees

```bash
lansenger calendar add-attendees "cal_xxx" "sch_xxx" '["sid001","sid002"]' --user-token "ut_xxx"
```

### delete-attendees

```bash
lansenger calendar delete-attendees "cal_xxx" "sch_xxx" '["sid001"]' --user-token "ut_xxx"
```

## 参数

### attendees（获取）

| 参数 | 必填 | 描述 |
|---|---|---|
| calendar_id | 是（arg） | 日历 ID |
| schedule_id | 是（arg） | 日程 ID |
| --user-token | 否 | 用于认证的用户令牌 |
| --user-id | 否 | 用于认证的用户 ID |
| --page / -p | 否 | 页码（默认 1） |
| --size / -s | 否 | 每页条数（默认 500） |

### add-attendees

| 参数 | 必填 | 描述 |
|---|---|---|
| calendar_id | 是（arg） | 日历 ID |
| schedule_id | 是（arg） | 日程 ID |
| attendees | 是（arg） | 员工 ID 字符串的 JSON 列表：["sid1","sid2"] |
| --user-token | 否 | 用于认证的用户令牌 |
| --user-id | 否 | 用于认证的用户 ID |

### delete-attendees

| 参数 | 必填 | 描述 |
|---|---|---|
| calendar_id | 是（arg） | 日历 ID |
| schedule_id | 是（arg） | 日程 ID |
| attendees | 是（arg） | 员工 ID 字符串的 JSON 列表：["sid1","sid2"] |
| --user-token | 否 | 用于认证的用户令牌 |
| --user-id | 否 | 用于认证的用户 ID |

## 返回值

### attendees（获取）

```
total          : int      - 参与人总数
（带分页的参与人列表）
```

### add-attendees

```
schedule_id    : string   - 更新后的日程 ID
```

### delete-attendees

```
schedule_id    : string   - 更新后的日程 ID
```

## 常见错误

- **格式差异**：`add-attendees` 和 `delete-attendees` 接受员工 ID **字符串**的纯 JSON 列表（`["sid001","sid002"]`），而非对象。这与 `create-schedule` 不同，后者期望包含 `{staffId, attendeeFlag}` 字段的对象。对 add/delete 使用对象格式将导致解析错误。
- 交换 `calendar_id` 和 `schedule_id` 的顺序。日历 ID 始终在前。
- 向 add/delete 命令传入参与人对象而非纯字符串。
