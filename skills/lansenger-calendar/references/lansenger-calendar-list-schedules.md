# lansenger calendar list-schedules

## 前置条件

../../lansenger-shared/SKILL.md

## 描述

列出给定日历上指定时间范围内的日程（事件）。

## 命令示例

```bash
lansenger calendar list-schedules "cal_xxx" 1748160000 1751808000 --user-token "ut_xxx"
```

## 参数

| 参数 | 必填 | 描述 |
|---|---|---|
| calendar_id | 是（arg） | 日历 ID |
| start_time | 是（arg） | 时间范围的起始时间（Unix 秒级时间戳） |
| end_time | 是（arg） | 时间范围的结束时间（Unix 秒级时间戳） |
| --user-token | 否 | 用于认证的用户令牌 |
| --user-id | 否 | 用于认证的用户 ID |

## 返回值

```
日程列表，每条记录包含：
  schedule_id    : string   - 日程 ID
  summary        : string   - 日程标题
```

## 常见错误

- 查询时间范围超过 42 天。`start_time` 和 `end_time` 之间的最大允许范围为 42 天（3,628,800 秒）。更宽的范围将失败。
- 传入毫秒时间戳而非秒。请始终使用秒。
- 交换 `start_time` 和 `end_time`。起始时间必须小于结束时间。
