# lansenger calendar attendees / add-attendees / delete-attendees

## Prerequisite

../lansenger-shared/SKILL.md

## Description

Manage attendees on a schedule. Three sub-commands are available:

- **attendees**: Fetch the attendee list for a schedule with pagination.
- **add-attendees**: Add attendees to a schedule.
- **delete-attendees**: Remove attendees from a schedule.

## Command Examples

### attendees (fetch)

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

## Parameters

### attendees (fetch)

| Parameter | Required | Description |
|---|---|---|
| calendar_id | Yes (arg) | Calendar ID |
| schedule_id | Yes (arg) | Schedule ID |
| --user-token | No | User token for authentication |
| --user-id | No | User ID for authentication |
| --page / -p | No | Page number (default 1) |
| --size / -s | No | Page size (default 500) |

### add-attendees

| Parameter | Required | Description |
|---|---|---|
| calendar_id | Yes (arg) | Calendar ID |
| schedule_id | Yes (arg) | Schedule ID |
| attendees | Yes (arg) | JSON list of staff ID strings: ["sid1","sid2"] |
| --user-token | No | User token for authentication |
| --user-id | No | User ID for authentication |

### delete-attendees

| Parameter | Required | Description |
|---|---|---|
| calendar_id | Yes (arg) | Calendar ID |
| schedule_id | Yes (arg) | Schedule ID |
| attendees | Yes (arg) | JSON list of staff ID strings: ["sid1","sid2"] |
| --user-token | No | User token for authentication |
| --user-id | No | User ID for authentication |

## Return Value

### attendees (fetch)

```
total          : int      - Total number of attendees
(attendee list with pagination)
```

### add-attendees

```
schedule_id    : string   - ID of the updated schedule
```

### delete-attendees

```
schedule_id    : string   - ID of the updated schedule
```

## Common Mistakes

- **Format difference**: `add-attendees` and `delete-attendees` accept a plain JSON list of staff ID **strings** (`["sid001","sid002"]`), NOT objects. This is different from `create-schedule`, which expects objects with `{staffId, attendeeFlag}` fields. Using the object format with add/delete will cause a parsing error.
- Swapping the order of `calendar_id` and `schedule_id`. The calendar ID always comes first.
- Passing attendee objects instead of plain strings to add/delete commands.