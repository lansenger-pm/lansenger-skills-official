# lansenger calendar delete-schedule

## 前置条件

../lansenger-shared/SKILL.md

## 描述

从日历中删除一个日程（事件）。

## 严重警告

**此操作不可逆。** 已删除的日程无法恢复。执行此命令前您必须与用户确认。请始终要求用户在执行前核实日历 ID 和日程 ID。

## 命令示例

```bash
lansenger calendar delete-schedule "cal_xxx" "sch_xxx" --user-token "ut_xxx"
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
schedule_id    : string   - 已删除的日程 ID
```

## 常见错误

- 未经用户确认先擅自删除日程。务必获得明确确认。
- 交换 `calendar_id` 和 `schedule_id` 的顺序。日历 ID 在前。
- 以为命令会弹出确认提示。它不会；确认必须在调用此命令之前在应用层面完成。
