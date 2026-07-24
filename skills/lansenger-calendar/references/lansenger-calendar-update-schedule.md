# lansenger calendar update-schedule

## 前置条件

../lansenger-shared/SKILL.md

## 描述

更新日历上已存在的日程。支持修改标题、描述、时间、重复规则、提醒等。对于重复日程，可选择影响所有实例、仅当前实例或当前及后续实例。

## 命令示例

```bash
lansenger calendar update-schedule \
  "cal_xxx" "sch_xxx" \
  --summary "New Title" \
  --desc "Updated description" \
  --user-token $TOKEN
```

```bash
lansenger calendar update-schedule \
  "cal_xxx" "sch_xxx" \
  --start-time '{"time":"1748160000","date":"","timeZone":"Asia/Shanghai"}' \
  --end-time '{"time":"1748163600","date":"","timeZone":"Asia/Shanghai"}' \
  --user-token $TOKEN
```

```bash
lansenger calendar update-schedule \
  "cal_xxx" "sch_xxx" \
  --summary "Only this instance" \
  --op modify_current \
  --current-time 1748160000 \
  --user-token $TOKEN
```

## 参数

| 参数 | 必填 | 描述 |
|---|---|---|
| calendar_id | 是（arg） | 日历 ID |
| schedule_id | 是（arg） | 日程 ID |
| --summary | 否 | 日程新标题 |
| --desc / -d | 否 | 日程新描述 |
| --start-time | 否 | 新起始时间 JSON 对象：`{"time":"秒级时间戳","date":"日期","timeZone":"时区"}` |
| --end-time | 否 | 新结束时间 JSON 对象：`{"time":"秒级时间戳","date":"日期","timeZone":"时区"}` |
| --all-day | 否 | "yes" 或 "no" |
| --date | 否 | 全天事件的日期字符串，如 "2026-01-01" |
| --repeat | 否 | 重复类型：no, day, week, month, year, work_day, custom |
| --rule | 否 | 自定义重复规则 JSON |
| --expire | 否 | 重复结束日期 |
| --reminder | 否 | 提醒类型："yes" 或 "no" |
| --permissions | 否 | 日程权限 |
| --tz | 否 | 时区，如 "Asia/Shanghai" |
| --op / --operation-type | 否 | 重复日程操作类型：modify_all（默认）, modify_current, modify_future |
| --current-time | 否 | 当前时间戳（秒），配合 modify_current 使用 |
| --user-token | 否 | 用于认证的用户令牌 |
| --user-id | 否 | 用于认证的用户 ID |

## 返回值

```
schedule_id    : string   - 更新后的日程 ID
```

## 常见错误

- 传入毫秒时间戳而非秒。请始终使用秒。
- 修改重复日程时不指定 `--op`，默认影响所有实例。
- `--op=modify_current` 时忘记传 `--current-time`。
- 全天日程修改时未传 `--date` 或设置了非 UTC 时区。
