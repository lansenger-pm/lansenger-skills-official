---
name: lansenger-boardroom
version: 1.0.0
description: "蓝信会议室预定 V2：检索会议室（办公区/楼层/设备/时段筛选），查看当日预订情况，预订/修改/取消会议室（支持单次与重复），扫码确认，我的预订列表。当用户需要预订会议室、查询会议室占用时使用。"
metadata:
  requires:
    bins: ["lansenger"]
  cliHelp: "lansenger boardroom --help"
---

# boardroom

**本技能继承 [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md) 的所有规则。** Shell 执行纪律、Help-First 原则、认证、权限处理等均在其定义，此处不复述。

**CRITICAL — 多数接口需要 `gradingId`（分区ID）， MUST 先执行 `lansenger boardroom gradings` 查询。** 预订是有实际资源占用的操作：预订前 MUST 向用户确认会议室、时间与参会人；`cancel` 触发高风险门禁（exit 10）。

## Reverse Handoff — 何时不用此技能

| 用户意图 | 正确技能 | 原因 |
|---------|---------|------|
| 创建日程/会议提醒（不占会议室） | `lansenger-calendar` | 日程是时间安排，会议室是物理资源占用 |
| 发会议通知给参会人 | `lansenger-messaging` / `lansenger-notice` | 本模块只管理预订本身 |
| 预约非会议室资源 | — | 本模块仅覆盖会议室 |

## 核心概念

### 预订状态机

| status | 含义 | 可执行操作 |
|--------|------|-----------|
| 0 | 审批中 | cancel |
| 1 | 待扫码确认 | confirm-sign / cancel |
| 2 | 扫码超时 | — |
| 3 | 驳回 | — |
| 4 | 撤销 | — |
| 5 | 预定成功 | cancel / edit（仅无需审批的预订） |
| 6 | 完成 | — |

### gradingId 依赖链

`gradings`（查可见分级，取 `id` 即 gradingId）→ `area-offices`（分级下办公区）→ `rooms`（按办公区/楼层/设备筛选）。多数接口缺 `gradingId` 时**报错或静默返回空结果**。

### 时间格式

预订/修改用 `yyyy-MM-dd HH:mm:ss`；`rooms` 的时段筛选用 `yyyy-MM-dd HH:mm`；日期一律 `yyyy-MM-dd`。文档另有「半小时槽位」概念（0=00:00，48=24:00）。

### 文档特有陷阱（实测/文档明示）

- `Fooler` 为 `Floor` 历史拼写（areaOfficeFoolerId 等字段即楼层）。
- 多组枚举 0/1 语义反转：`isVideo` 0=开启 1=不开启、`tableCards` 0=开启 1=关闭、`leaderAttend` 0=出席 1=不出席。
- `noticeTime`（会议提醒）文档未给码值映射表，传文档列举的中文枚举值字符串。
- `user_token` 传入时 body 身份字段被服务端**忽略**（以 user_token 对应用户为准）。

### 高风险门禁

`boardroom cancel` 默认不执行：不带 `--yes` 时退出码 10，处理流程见 shared「高风险写操作门禁」。仅状态 0/1/5 的预订可取消。

## CLI 命令

### 查询

```bash
# 查可见分级（gradingId 来源）
lansenger boardroom gradings

# 查分级下的办公区
lansenger boardroom area-offices g1

# 筛选会议室（按日期可带停用信息）
lansenger boardroom rooms --grading-id g1 --date 2026-07-22 --people 10

# 会议室详情 + 当日预订情况
lansenger boardroom room-detail room1
lansenger boardroom schedule room1 2026-07-22 --grading-id g1

# 我的预订（分页）
lansenger boardroom my-reserves --grading-id g1 --keys "周会"
```

### 预订 / 修改 / 取消 / 确认

```bash
# 预订（必填：会议室ID 会议名称 --grading-id --start --end --notice-time）
lansenger boardroom reserve room1 "项目周会" \
  --grading-id g1 --start "2026-07-22 09:00:00" --end "2026-07-22 10:00:00" \
  --notice-time "会前15分钟" --people 10 --invite "U10001,U10002"

# 重复预订（每周一/三/五，跳过节假日）
lansenger boardroom reserve room1 "项目周会" \
  --grading-id g1 --start "2026-07-22 09:00:00" --end "2026-07-22 10:00:00" \
  --notice-time "会前15分钟" --reserve-type 1 --repeat-type week \
  --repeat-days 1,3,5 --skip 0 --repeat-end "2026-12-31 18:00:00"

# 修改（仅无需审批的预订）
lansenger boardroom edit-reserve res1 room1 "项目周会（改期）" \
  --grading-id g1 --start "2026-07-23 09:00:00" --end "2026-07-23 10:00:00" \
  --notice-time "会前15分钟"

# 取消（门禁：先 --dry-run 预览，再 --yes；仅状态 0/1/5 可取消）
lansenger boardroom cancel res1 --dry-run
lansenger boardroom cancel res1 --yes --reason "会议取消"

# 扫码确认（仅状态 1）
lansenger boardroom confirm-sign res1

# 预订详情（参会人/审批流在 JSON 输出中）
lansenger boardroom reserve-detail res1 --grading-id g1
```

## 参数速查

| 命令 | 必需参数 | 关键可选参数 |
|------|---------|-------------|
| `boardroom gradings` | — | `--user-id` |
| `boardroom area-offices` | `grading_id` (位置参数) | — |
| `boardroom rooms` | — | `--grading-id` `--area-office-id` `--floor-ids` `--equipment` `--time-start/end` `--date` `--page` `--size` |
| `boardroom room-detail` | `room_id` | — |
| `boardroom schedule` | `room_id` `query_date` (位置参数) `--grading-id` | — |
| `boardroom reserve-detail` | `reserve_room_id` (位置参数) | `--grading-id` |
| `boardroom reserve` | `boardroom_id` `name` (位置参数) `--grading-id` `--start` `--end` `--notice-time` | `--people` `--toastmaster` `--leader` `--invite` `--approvers` `--is-video` `--reserve-type` `--repeat-type/days/end` `--skip` |
| `boardroom edit-reserve` | `reserve_id` `boardroom_id` `name` (位置参数) `--grading-id` `--start` `--end` `--notice-time` | `--edit-type`(1/2) |
| `boardroom cancel` | `reserve_id` (位置参数) | `--reason` `--cancel-type`(1/2/3) `--notify`；门禁 `--yes`/`--dry-run` |
| `boardroom confirm-sign` | `reserve_id` (位置参数) | — |
| `boardroom my-reserves` | `--grading-id` | `--keys` `--start-time` `--end-time` `--room-id` `--page` `--size` |

## 常见错误

| 错误 | 正确做法 |
|------|---------|
| 不查 gradingId 直接调其他接口 | 先 `boardroom gradings` 取 `id` 作为 `--grading-id`；部分接口缺失时静默返回空结果，勿当作"没有会议室" |
| 不确认就 `cancel` | 取消触发门禁（exit 10），需 `--yes` 确认；可用 `--dry-run` 先预览 |
| 取消报错"仅状态 0/1/5 可撤销" | 先 `my-reserves` 或 `reserve-detail` 看状态；已完成(6)/已驳回(3)的预订不可取消 |
| `isVideo`/`tableCards` 传 1 想开启 | 文档语义反转：0=开启 1=不开启/关闭，注意方向 |
| `errCode=10008 API服务 数据不存在` | 会议室模块未对该应用开放（实测 stage 2026-09-18），需在开发者中心开通后重试 |
| 预订时间格式用了 `yyyy-MM-dd HH:mm` | reserve/edit MUST 用 `yyyy-MM-dd HH:mm:ss`（含秒） |
| 修改审批中的预订报错 | 仅无需审批的预订支持修改；审批中的先取消再重订 |
| `noticeTime` 不知道传什么 | 传文档列举的枚举值字符串（如 `会前15分钟`），文档未给码值映射 |

## SDK 用法

### 核心方法

| 方法 | 说明 |
|------|------|
| `fetch_boardroom_gradings()` / `fetch_boardroom_area_offices(grading_id)` | 分级与办公区（gradingId 来源） |
| `fetch_boardroom_list(grading_id=..., ...)` | 会议室检索（分页） |
| `fetch_boardroom_detail(room_id)` / `fetch_boardroom_schedule(room_id, date, grading_id)` | 详情与当日预订 |
| `reserve_boardroom(boardroom_id, name, grading_id, start, end, notice_time, ...)` | 预订（单次/重复） |
| `edit_boardroom_reserve(reserve_id, ...)` / `cancel_boardroom_reserve(reserve_id, ...)` | 修改与取消 |
| `confirm_boardroom_sign(reserve_id)` / `fetch_my_boardroom_reserves(grading_id)` | 确认与我的预订 |

```python
from lansenger_sdk import LansengerSyncClient

client = LansengerSyncClient.from_store(profile="default")
gradings = client.fetch_boardroom_gradings()
gid = gradings.gradings[0]["id"]

rooms = client.fetch_boardroom_list(grading_id=gid, query_date="2026-07-22")
room_id = rooms.items[0]["id"]
schedule = client.fetch_boardroom_schedule(room_id, "2026-07-22", gid)

r = client.reserve_boardroom(
    boardroom_id=room_id, name="项目周会", grading_id=gid,
    reserve_time_start="2026-07-22 09:00:00",
    reserve_time_end="2026-07-22 10:00:00",
    notice_time="会前15分钟", people_number="10",
)
if r.success:
    print(r.reserve_code, r.status)
```

> 更多批量模式（并发、断点续传、深分页）详见 `../lansenger-sdk/SKILL.md`。
