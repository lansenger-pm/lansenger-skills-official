# lansenger calendar list-schedules

## Prerequisite

../lansenger-shared/SKILL.md

## Description

List schedules (events) within a time range on a given calendar.

## Command Examples

```bash
lansenger calendar list-schedules "cal_xxx" 1748160000 1751808000 --user-token "ut_xxx"
```

## Parameters

| Parameter | Required | Description |
|---|---|---|
| calendar_id | Yes (arg) | Calendar ID |
| start_time | Yes (arg) | Start of time range as unix timestamp in seconds |
| end_time | Yes (arg) | End of time range as unix timestamp in seconds |
| --user-token | No | User token for authentication |
| --user-id | No | User ID for authentication |

## Return Value

```
Schedule list with each entry containing:
  schedule_id    : string   - Schedule ID
  summary        : string   - Schedule title
```

## Common Mistakes

- Querying a time range longer than 42 days. The maximum allowed range between `start_time` and `end_time` is 42 days (3,628,800 seconds). Wider ranges will fail.
- Passing millisecond timestamps instead of seconds. Always use seconds.
- Swapping `start_time` and `end_time`. Start must be less than end.