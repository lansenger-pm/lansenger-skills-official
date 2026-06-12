---
name: lansenger-calendar
version: 1.1.2
description: "蓝信日历/日程（4.23）：主日历查询、日程CRUD、参会人管理、参会人元数据更新。注意：日历容器CRUD暂不开放，仅日程操作可用。涉及创建/修改日程必须先确认用户意图（新建 vs 编辑已有）。"
metadata:
  requires:
    bins: ["lansenger"]
  cliHelp: "lansenger calendar --help"
---

# calendar (4.23)

**本技能继承 [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md) 的所有规则。** Shell 执行纪律、Help-First 原则、认证、权限处理等均在其定义，此处不复述。

## Reverse Handoff — 何时不用此技能

| 用户意图 | 正确技能 | 原因 |
|----------|----------|------|
| OAuth2 获取 userToken | `lansenger-oauth` | 日历操作需要 userToken |

**CRITICAL — 日历容器CRUD（4.23.1-8）暂不开放，仅日程操作（4.23.9-18）可用。用户口语中的"日历"通常指"日程"，请自动将"查日历"映射为"查日程"。**

**CRITICAL — 所有日程操作需 appToken + 至少一个 userToken 或 userId。无 userToken/userId → 使用机器人自身日历。**

**CRITICAL — 创建/删除/修改日程为高风险操作，执行前 MUST 向用户确认。**

**CRITICAL — 删除/修改日程后若需二次查询验证，MUST 等待至少 2 秒后再查询，防止数据同步延迟。**

## 核心概念

- **日历（Calendar）**：日程容器。每个用户有主日历（primary calendar），机器人也有自身日历。
- **日程（Schedule/Event）**：日历中的单条日程，含起止时间、标题、参会人等。支持单次和重复日程。
- **全天日程（allDay）**：只按日期占位，无具体时间。使用 `date` 字段 + `timeZone=UTC`，不填 `time`。
- **参会人（Attendee）**：日程参与者。创建日程时用 `[{staffId, attendeeFlag}]` 对象列表；增删参会人时用纯 staffId 字符串列表。
- **RSVP状态**：参会人对日程邀请的回复（接受/拒绝/待定）。

## 认证要求

所有日历端点需要 `appToken` AND 至少一个 `userToken` 或 `userId`：

| 方式 | 效果 |
|------|------|
| `--user-token` | 以授权用户身份操作（查看用户日历、以用户名义创建日程） |
| `--user-id` | 以指定用户 openId 操作 |
| 均无 | 使用机器人自身日历 |

## CLI 命令

### 查询主日历

```bash
# 用户身份
lansenger calendar primary --user-token "ut1"

# 指定用户ID
lansenger calendar primary --user-id "staffOpenId"

# 机器人自身
lansenger calendar primary
```

返回：`calendar_id`, `summary`, `description`, `permissions`, `role`

详细文档：[`references/lansenger-calendar-primary.md`](references/lansenger-calendar-primary.md)

### 创建日程

```bash
# 基本创建
lansenger calendar create-schedule calOpenId "项目周会" 1656468000 1656475200 '[{"staffId":"staff1","attendeeFlag":"yes"}]' --user-token "ut1"

# 全天日程
lansenger calendar create-schedule calOpenId "Company Holiday" 0 0 '[{"staffId":"staff1","attendeeFlag":"yes"}]' --all-day yes --date 2024-01-15 --user-token "ut1"

# 重复日程
lansenger calendar create-schedule calOpenId "每周同步" 1656468000 1656475200 '[{"staffId":"staff1","attendeeFlag":"yes"}]' --repeat week --user-token "ut1"
```

详细文档：[`references/lansenger-calendar-create-schedule.md`](references/lansenger-calendar-create-schedule.md)

### 查询日程

```bash
lansenger calendar fetch-schedule calOpenId schOpenId --user-token "ut1"
```

返回：`schedule_id`, `summary`, `description`, `all_day`, `start_time`, `end_time`, `creator`, `rsvp_status`

### 删除日程

```bash
lansenger calendar delete-schedule calOpenId schOpenId --user-token "ut1"
```

### 更新日程

```bash
# 修改日程标题
lansenger calendar update-schedule calOpenId schOpenId --summary "新标题" --user-token "ut1"

# 修改日程描述
lansenger calendar update-schedule calOpenId schOpenId --desc "新描述" --user-token "ut1"

# 修改重复日程仅当前这次
lansenger calendar update-schedule calOpenId schOpenId --summary "新标题" --op modify_current --current-time 1656468000 --user-token "ut1"

# 修改日程时间
lansenger calendar update-schedule calOpenId schOpenId --start-time '{"time":"1656468000","date":"","timeZone":"Asia/Shanghai"}' --end-time '{"time":"1656475200","date":"","timeZone":"Asia/Shanghai"}' --user-token "ut1"

# JSON 输出
lansenger calendar update-schedule calOpenId schOpenId --summary "新标题" --user-token "ut1" --json
```

### 查询日程列表（时间范围）

```bash
# 注意：start_time/end_time 为秒级时间戳，时间范围 ≤ 42天
lansenger calendar list-schedules calOpenId 1705276800 1707940800 --user-token "ut1"
```

### 参会人管理

```bash
# 查看参会人
lansenger calendar attendees calOpenId schOpenId --user-token "ut1"

# 添加参会人（注意：纯 staffId 字符串列表，非对象）
lansenger calendar add-attendees calOpenId schOpenId '["staff1","staff2"]' --user-token "ut1"

# 删除参会人
lansenger calendar delete-attendees calOpenId schOpenId '["staff2"]' --user-token "ut1"

# 重复日程添加参会人（仅影响当前实例）
lansenger calendar add-attendees calOpenId schOpenId '["staff3"]' --op modify_current --current-time 1656468000 --user-token "ut1"
```

### 重复日程操作参数（OpenAPI 4.23.16/18）

对于重复日程的参会人增删操作，可使用以下参数控制影响范围：

| 参数 | 说明 | 可选值 |
|------|------|--------|
| `--op` / `--operation-type` | 操作类型 | `modify_all`（默认，影响所有实例）, `modify_current`（仅当前实例）, `modify_future`（当前及后续实例） |
| `--current-time` | 当前时间戳（秒），配合 `modify_current` 使用 | Unix 秒级时间戳 |

### 更新参会人元数据

```bash
# 更新RSVP状态
lansenger calendar attendee-meta calOpenId schOpenId --rsvp accept --user-token "ut1"

# 更新颜色标记
lansenger calendar attendee-meta calOpenId schOpenId --color "#FF347AFC" --user-token "ut1"

# 更新可见性
lansenger calendar attendee-meta calOpenId schOpenId --permissions private --user-token "ut1"

# 更新忙/闲状态
lansenger calendar attendee-meta calOpenId schOpenId --busy-free busy --user-token "ut1"

# 更新提醒时间（多个偏移分钟数）
lansenger calendar attendee-meta calOpenId schOpenId --remind-times '[5,15]' --user-token "ut1"
```

## startTime/endTime 格式

| 场景 | time 字段 | date 字段 | timeZone |
|------|-----------|-----------|----------|
| 非全天 | Unix秒级时间戳 | 留空 | 默认 `Asia/Shanghai` |
| 全天 (allDay=yes) | 不填 | `2024-01-15` | **必须为 `UTC`** |

**CRITICAL — start_time/end_time 参数为 Unix 秒级时间戳，不是毫秒，不是时间字符串。涉及时间转换时务必使用外部工具处理，禁止手动计算。**

## attendees 格式差异

| 操作 | 格式 | 示例 |
|------|------|------|
| `create-schedule` | 对象列表 | `[{"staffId":"xxx","attendeeFlag":"yes"}]` |
| `add-attendees` / `delete-attendees` | 纯字符串列表 | `["staff1","staff2"]` |

**CRITICAL — 增删参会人用纯 staffId 列表，不要传 attendeeFlag 对象。**

## 常见错误

| 错误 | 正确做法 |
|------|---------|
| 传毫秒时间戳 | 使用秒级时间戳（除以1000） |
| 全天日程填time字段 | 全天只填date + timeZone=UTC |
| 增删参会人传对象列表 | 增删用纯字符串列表 |
| 不传userToken查日程 | 日历操作必须传 --user-token 或 --user-id |
| 用户说"日历"就查Calendar容器 | 用户意图通常是"日程"，用 list-schedules |
| 时间范围超42天 | 拆分多次查询，每次 ≤ 42天 |
| 修改重复日程不指定 --op | 默认 modify_all 影响所有实例；仅改当前用 modify_current + --current-time |

## 参数速查

| 命令 | 必需参数 | 关键可选参数 |
|------|---------|-------------|
| `primary` | 无 | --user-token, --user-id |
| `create-schedule` | calendar_id, summary, start_time, end_time, attendees | --desc, --all-day, --date, --repeat, --reminder, --tz, --user-token, --user-id |
| `fetch-schedule` | calendar_id, schedule_id | --user-token, --user-id |
| `delete-schedule` | calendar_id, schedule_id | --user-token, --user-id |
| `list-schedules` | calendar_id, start_time, end_time | --user-token, --user-id |
| `attendees` | calendar_id, schedule_id | --page, --size, --user-token, --user-id |
| `add-attendees` | calendar_id, schedule_id, attendees (JSON) | --user-token, --user-id, --op, --current-time |
| `delete-attendees` | calendar_id, schedule_id, attendees (JSON) | --user-token, --user-id, --op, --current-time |
| `update-schedule` | calendar_id, schedule_id | --summary, --desc, --op, --current-time, --reminder, --repeat, --rule, --expire, --all-day, --permissions, --start-time, --end-time, --user-token, --user-id |
| `attendee-meta` | calendar_id, schedule_id | --rsvp, --color, --permissions, --busy-free, --remind-times, --user-token, --user-id |