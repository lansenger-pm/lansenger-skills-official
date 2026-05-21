# lansenger calendar primary

## Prerequisite

../lansenger-shared/SKILL.md

## Description

Fetch the primary calendar for a user. Returns the calendar ID, summary, description, permissions, and the user's role.

## Command Examples

```bash
lansenger calendar primary --user-token "ut_xxx" --user-id "uid_xxx"
```

## Parameters

| Parameter | Required | Description |
|---|---|---|
| --user-token | No | User token for authentication |
| --user-id | No | User ID for authentication |

## Return Value

```
calendar_id    : string   - Primary calendar ID
summary        : string   - Calendar title
description    : string   - Calendar description
permissions    : string   - Calendar permissions
role           : string   - User's role on this calendar
```

## Common Mistakes

- Passing both `--user-token` and `--user-id` when only one is needed. Either a user token or a user ID is sufficient; provide whichever your application uses.
- Expecting a list of calendars. This command returns a single primary calendar object, not a list.