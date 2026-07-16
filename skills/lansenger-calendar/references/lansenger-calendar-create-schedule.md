# lansenger calendar create-schedule

## 前置条件

../lansenger-shared/SKILL.md

## 描述

在日历上创建新的日程（事件）。支持定时事件和全天事件、重复规则、提醒以及参与人。

## 命令示例

```bash
lansenger calendar create-schedule \
  "cal_xxx" "Team Meeting" 1748160000 1748163600 \
  '[{"staffId":"sid001","attendeeFlag":"yes"}]' \
  --desc "Weekly sync" \
  --tz "Asia/Shanghai"
```

```bash
lansenger calendar create-schedule \
  "cal_xxx" "Holiday" 0 0 \
  '[{"staffId":"sid001","attendeeFlag":"yes"},{"staffId":"sid002","attendeeFlag":"no"}]' \
  --all-day yes \
  --date "2026-01-01" \
  --repeat weekly \
  --reminder no \
  --tz "UTC"
```

## 参数

| 参数 | 必填 | 描述 |
|---|---|---|
| calendar_id | 是（arg） | 日历 ID |
| summary | 是（arg） | 日程标题 |
| start_time | 是（arg） | 起始时间（Unix 秒级时间戳） |
| end_time | 是（arg） | 结束时间（Unix 秒级时间戳） |
| attendees | 是（arg） | 对象 JSON 列表：[{"staffId":"xxx","attendeeFlag":"yes"}] |
| --desc / -d | 否 | 日程描述 |
| --all-day | 否 | "yes" 或 "no"（默认 "no"） |
| --date | 否 | 全天事件的日期字符串，如 "2026-01-01" |
| --repeat | 否 | 重复类型：no, daily, weekly, monthly, yearly, work_day, custom（默认 "no"） |
| --reminder | 否 | 提醒类型："yes" 或 "no"（默认 "yes"） |
| --tz | 否 | 时区，如 "Asia/Shanghai"（默认 "Asia/Shanghai"） |
| --user-token | 否 | 用于认证的用户令牌 |
| --user-id | 否 | 用于认证的用户 ID |

## 返回值

```
schedule_id    : string   - 新创建日程的 ID
```

## CRITICAL — 参会人补齐规则

**创建日程时，以下两种人必须出现在 attendees 列表中，否则接口会报错。如果用户没有明确指定，Agent 需要主动将它们补齐。**

| 必须参会的人 | 说明 | 如何获取 |
|------------|------|---------|
| **日历主人** | 即将被创建日程的日历的所有者 | 先调 `lansenger calendar primary` 获取 calendar_id，再通过日历信息获取 owner |
| **当前操作用户** | 正在执行创建操作的人（即 `--user-token` 或 `--user-id` 对应的人） | Agent 维护的当前操作用户身份 |

**补齐规则：**

1. 日历主人：如果用户指定的 attendees 中已包含，保持用户的 `attendeeFlag` 设置；如果不在列表中，追加一条 `{"staffId":"<ownerStaffId>","attendeeFlag":"no"}`。日历主人的 RSVP 默认为「已接受」。
2. 当前操作用户：如果用户指定的 attendees 中已包含，保持用户的 `attendeeFlag` 设置；如果不在列表中，追加一条 `{"staffId":"<当前用户staffId>","attendeeFlag":"no"}`。
3. 如果日历主人和操作用户是同一个人，只保留一条，不要重复。

**Agent 执行步骤：**

1. 获取日历主人的 staffId
2. 获取当前操作用户的 staffId
3. 检查用户指定的 attendees 列表，将两人的 `attendeeFlag` 翻为 `yes`（如果用户已包含）
4. 如果列表中没有这两人，分别补齐
5. 将补齐后的列表传给 `create-schedule` 命令

**不要做的事：**

- 不要设置参会人权限字段——该字段会被重置为"参与人可邀请他人"，传了也无效
- 不要试图通过不传当前操作用户来隐藏自己——当前操作用户一定会出现在最终参会人中

## 重要注意事项

- **时间格式**：`start_time` 和 `end_time` 是 Unix 时间戳，单位为**秒**而非毫秒。传入前请将毫秒时间戳除以 1000。
- **全天事件**：当 `--all-day` 为 "yes" 时，您必须提供 `--date`，且无论 `--tz` 值为何，时区都会自动设置为 UTC。全天事件的 `start_time` 和 `end_time` 参数可设为 0，因为日期字段优先。
- **参与人格式**：create-schedule 的 `attendees` 参数使用包含 `{staffId, attendeeFlag}` 字段的**对象** JSON 列表。这与 `add-attendees` 和 `delete-attendees` 不同，后者接受员工 ID 字符串的纯 JSON 列表。

## 常见错误

- 传入毫秒时间戳而非秒。请始终使用秒。
- 使用全天模式但未提供 `--date`。全天事件需要日期字符串。
- 将参与人员工 ID 作为纯字符串而非对象传递。Create-schedule 期望 `[{"staffId":"xxx","attendeeFlag":"yes"}]`，而非 `["xxx"]`。
- `--all-day` 为 "yes" 时设置了自定义时区。全天事件内部始终使用 UTC。
- **创建日程时 attendees 只传用户指定的人，没有补齐日历主人和当前操作用户** — 接口会报错，Agent 必须先补齐再发送。
