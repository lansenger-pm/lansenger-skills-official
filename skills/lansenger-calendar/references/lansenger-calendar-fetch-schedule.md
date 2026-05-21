# lansenger calendar fetch-schedule

## Prerequisite

../lansenger-shared/SKILL.md

## Description

Fetch details of a single schedule (event) by its calendar ID and schedule ID.

## Command Examples

```bash
lansenger calendar fetch-schedule "cal_xxx" "sch_xxx" --user-token "ut_xxx"
```

## Parameters

| Parameter | Required | Description |
|---|---|---|
| calendar_id | Yes (arg) | Calendar ID |
| schedule_id | Yes (arg) | Schedule ID |
| --user-token | No | User token for authentication |
| --user-id | No | User ID for authentication |

## Return Value

```
schedule_id    : string   - Schedule ID
summary        : string   - Schedule title
description    : string   - Schedule description
all_day        : string   - "yes" or "no"
start_time     : dict     - Start time object with time, date, timeZone fields
end_time       : dict     - End time object with time, date, timeZone fields
creator        : dict     - Creator information
rsvp_status    : string   - RSVP status of the requesting user
```

## Common Mistakes

- Swapping the order of `calendar_id` and `schedule_id`. The calendar ID comes first.
- Using a schedule ID without the corresponding calendar ID. Both are required and must belong together.