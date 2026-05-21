# lansenger calendar create-schedule

## Prerequisite

../lansenger-shared/SKILL.md

## Description

Create a new schedule (event) on a calendar. Supports timed and all-day events, recurrence, reminders, and attendees.

## Command Examples

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

## Parameters

| Parameter | Required | Description |
|---|---|---|
| calendar_id | Yes (arg) | Calendar ID |
| summary | Yes (arg) | Schedule title |
| start_time | Yes (arg) | Start time as unix timestamp in seconds |
| end_time | Yes (arg) | End time as unix timestamp in seconds |
| attendees | Yes (arg) | JSON list of objects: [{"staffId":"xxx","attendeeFlag":"yes"}] |
| --desc / -d | No | Schedule description |
| --all-day | No | "yes" or "no" (default "no") |
| --date | No | Date string for all-day events, e.g. "2026-01-01" |
| --repeat | No | Repeat type: no, daily, weekly, monthly, yearly, work_day, custom (default "no") |
| --reminder | No | Reminder type: "yes" or "no" (default "yes") |
| --tz | No | Time zone, e.g. "Asia/Shanghai" (default "Asia/Shanghai") |
| --user-token | No | User token for authentication |
| --user-id | No | User ID for authentication |

## Return Value

```
schedule_id    : string   - ID of the newly created schedule
```

## IMPORTANT Notes

- **Time format**: `start_time` and `end_time` are unix timestamps in **seconds**, not milliseconds. Divide millisecond timestamps by 1000 before passing them.
- **All-day events**: When `--all-day` is "yes", you must provide `--date` and the timezone is automatically set to UTC regardless of the `--tz` value. The `start_time` and `end_time` arguments can be set to 0 for all-day events since the date field takes precedence.
- **Attendees format**: The `attendees` argument for create-schedule uses a JSON list of **objects** with `{staffId, attendeeFlag}` fields. This is different from `add-attendees` and `delete-attendees`, which accept a plain JSON list of staff ID strings.

## Common Mistakes

- Passing millisecond timestamps instead of seconds. Always use seconds.
- Using all-day mode without providing `--date`. All-day events require a date string.
- Passing attendee staff IDs as plain strings instead of objects. Create-schedule expects `[{"staffId":"xxx","attendeeFlag":"yes"}]`, not `["xxx"]`.
- Setting a custom timezone when `--all-day` is "yes". All-day events always use UTC internally.