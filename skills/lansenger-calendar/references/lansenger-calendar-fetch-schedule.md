# lansenger calendar fetch-schedule

## 前置条件

../../lansenger-shared/SKILL.md

## 描述

通过日历 ID 和日程 ID 获取单个日程（事件）的详细信息。

## 命令示例

```bash
lansenger calendar fetch-schedule "cal_xxx" "sch_xxx" --user-token "ut_xxx"
```

## 参数

| 参数 | 必填 | 描述 |
|---|---|---|
| calendar_id | 是（arg） | 日历 ID |
| schedule_id | 是（arg） | 日程 ID |
| --user-token | 否 | 用于认证的用户令牌 |
| --user-id | 否 | 用于认证的用户 ID |

## 返回值

```
schedule_id    : string   - 日程 ID
summary        : string   - 日程标题
description    : string   - 日程描述
all_day        : string   - "yes" 或 "no"
start_time     : dict     - 起始时间对象，含 time、date、timeZone 字段
end_time       : dict     - 结束时间对象，含 time、date、timeZone 字段
creator        : dict     - 创建者信息
rsvp_status    : string   - 请求用户的 RSVP 状态
```

## 常见错误

- 交换 `calendar_id` 和 `schedule_id` 的顺序。日历 ID 在前。
- 使用了日程 ID 但未提供对应的日历 ID。两者都是必需的且必须相互匹配。
