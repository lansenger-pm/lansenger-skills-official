# lansenger calendar delete-schedule

## 前置条件

../lansenger-shared/SKILL.md

## 描述

从日历中删除一个日程（事件）。

## 严重警告

**此操作不可逆。** 已删除的日程无法恢复。`delete-schedule` 是高风险写操作，受 exit 10 门禁保护——缺省调用返回退出码 `10`，必须 `--yes` 才执行。详见 [`../../lansenger-shared/SKILL.md`](../../lansenger-shared/SKILL.md)「高风险写操作门禁」。

## 命令示例

```bash
# 推荐先预览，确认后执行
lansenger calendar delete-schedule "cal_xxx" "sch_xxx" --user-token "ut_xxx" --dry-run
lansenger calendar delete-schedule "cal_xxx" "sch_xxx" --user-token "ut_xxx" --yes
```

## 参数

| 参数 | 必填 | 描述 |
|---|---|---|
| calendar_id | 是（arg） | 日历 ID |
| schedule_id | 是（arg） | 日程 ID |
| --user-token | 否 | 用于认证的用户令牌 |
| --user-id | 否 | 用于认证的用户 ID |
| --yes / -y | 否 | 确认执行高风险删除（门禁要求，不带则退出码 10） |
| --dry-run | 否 | 校验参数并预览将删除的日程，不执行，退出 0 |

## 返回值

```
schedule_id    : string   - 已删除的日程 ID
```

## 常见错误

- 未经用户确认先擅自删除日程。务必获得明确确认。
- 交换 `calendar_id` 和 `schedule_id` 的顺序。日历 ID 在前。
- 缺省调用返回退出码 10（待确认），不是失败。用户确认后追加 `--yes` 执行；可用 `--dry-run` 先预览。
