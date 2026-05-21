# lansenger calendar delete-schedule

## Prerequisite

../lansenger-shared/SKILL.md

## Description

Delete a schedule (event) from a calendar.

## CRITICAL Warning

**This operation is irreversible.** Deleted schedules cannot be recovered. You MUST confirm with the user before executing this command. Always ask the user to verify the calendar ID and schedule ID before proceeding.

## Command Examples

```bash
lansenger calendar delete-schedule "cal_xxx" "sch_xxx" --user-token "ut_xxx"
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
schedule_id    : string   - ID of the deleted schedule
```

## Common Mistakes

- Deleting a schedule without confirming with the user first. Always get explicit confirmation.
- Swapping the order of `calendar_id` and `schedule_id`. The calendar ID comes first.
- Assuming the command will prompt for confirmation. It does not; confirmation must happen at the application level before calling this command.