---
name: lansenger-videoconference
version: 1.0.0
description: "蓝信视频会议开放能力：创建/修改/取消/结束会议，会议列表与状态查询，主持人会控（静音/踢人/转让主持人），成员邀请与进出记录，录像列表与下载链接，组织会议配置。当用户需要开视频会议、预约线上会议、控制会议、取会议录像时使用。"
metadata:
  requires:
    bins: ["lansenger"]
  cliHelp: "lansenger videoconference --help"
---

# videoconference

**本技能继承 [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md) 的所有规则。** Shell 执行纪律、Help-First 原则、认证、权限处理等均在其定义，此处不复述。

**CRITICAL — 创建/取消/结束会议直接影响真实参会人的日程。** 三类操作 MUST 先向用户确认会议主题、时间与参会人清单，确认后才能执行。创建会议的 `member[]` 必须且只能有一个 `role=admin`（主持人），缺失时报 105230。`cancel` 仅对未开始的会议生效（已开始的会议报 105224，用 `stop` 结束）；自拼 URL 时端点是历史拼写 `/meeting/cancle`。errCode 105100/105106 表示组织未开通视频会议开放能力，直接向用户说明前提，禁止重试。

## Reverse Handoff — 何时不用此技能

| 用户意图 | 正确技能 | 原因 |
|---------|---------|------|
| 预订线下会议室 | `lansenger-boardroom` | 会议室是物理资源占用，不是线上会议 |
| 创建应用待办任务 | `lansenger-todo` | 待办是任务管理，不是会议 |
| 发会议通知给参会人 | `lansenger-messaging` / `lansenger-notice` | 本模块只管理会议本身，不含消息发送 |
| 查日历、创建日程 | `lansenger-calendar` | 日程是时间安排，视频会议是独立开放能力 |

## 核心概念

### 网关与前提条件

所有端点走标准应用网关：`{api_gateway_url}/xtra/videoconference/openapi/v1/<endpoint>?app_token=APP_TOKEN`，均为 POST + JSON body（`member/list` 文档标注 GET 但要求带 JSON body，统一按 POST 发送）。

组织侧前提（缺任一项调用即失败，错误 105100/105106，**不要重试**）：

1. 组织已安装视频会议应用（平台 ≥3.6）；
2. EMC 后端已配置该应用的外部标识；
3. 开发者中心已开通「开放能力」并配置服务地址。

### 会议状态机

| status | 含义 | 可执行操作 |
|--------|------|-----------|
| 0 | 未开始 | cancel / modify |
| 1 | 已开始 | stop / 会控 / invite / member 操作 |
| 2 | 全体禁言 | stop / 会控 |
| 3 | 锁定 | stop / 会控 |
| 4 | 已结束 | detail / vod 查询 |
| 5 | 已取消 | detail |

### 关键枚举

| 字段 | 取值 |
|------|------|
| `type`（会议类型） | 0=即时会议，1=预约会议（预约时 `startTime` 必须为未来时间，否则 105204） |
| 成员角色 | `admin`=主持人（唯一）/ `joinHost`=联席主持人 / `participant`=参会人 |
| 成员状态 | 0 呼叫中 / 1 加入中 / 2 未接 / 3 拒接 / 4 被踢除 / 5 在线 / 6 退出 / 7 被移除 / 8 结束最终态 |
| `fetchRange` | `my`/`all`/`person`（person 时 `staffId` 必填） |
| `createSource` | 0=平台客户端，1=第三方创建 |
| `autoRecord` | 0=不自动录制，1=自动录制 |

### 会控 opCode 取值

`member/control` 的 `opCode` **由服务端校验**；SDK 与 CLI 一律原样透传，不在客户端拦截。

以下为已知取值（**仅供参考、可能不全**，以服务端为准）：

`kick` `quit` `join` `handup` `openScreenShare` `closeScreenShare` `openVideo` `closeVideo` `mute` `applyVideo` `shareVideo` `cancelShareVideo` `muteall` `unmuteall` `remove` `call` `enforceOpenVideo` `setJoinHost` `cancelJoinHost` `inviteOpenAudio` `setHost` `grabHost`

### 必填身份字段

`orgId` 为数字型组织 ID，所有接口 MUST 显式传入；多数接口还要求 `operator`（操作人 staffId）。时间均为 epoch 毫秒。

### 会议号 ↔ mid 解析

成员/录像等操作按 `mid` 定位，`fetch_meeting_params(meetingNumber=...)` 返回会议配置（id/type/status/admin）——先用会议号换 `mid` 再做后续操作。

## CLI 命令

> videoconference 域随 CLI 同步发版；若本机 CLI 版本较旧提示找不到命令，升级 `lansenger` 或改用 SDK。

```bash
# 组织会议配置（可用性探测，建议先执行；缺前提时报 105100/105106）
lansenger videoconference org-conf --org-id 2285568

# 创建即时会议（唯一 admin 主持人）
lansenger videoconference create "项目评审会" 1770998400000 \
  --org-id 2285568 --type 0 --auto-record 1 \
  --members '[{"staffId":"st1","employeeName":"张三","role":"admin"},{"staffId":"st2","employeeName":"李四","role":"participant"}]'

# 创建预约会议（startTime 必须为未来时间）
lansenger videoconference create "项目评审会" 1771084800000 \
  --org-id 2285568 --type 1 \
  --members '[{"staffId":"st1","employeeName":"张三","role":"admin"}]'

# 修改未开始的会议
lansenger videoconference modify mid1 "项目评审会（改期）" 1771171200000 \
  --org-id 2285568 --operator st1 \
  --members '[{"staffId":"st1","employeeName":"张三","role":"admin"}]'

# 查询会议列表 / 批量状态 / 详情
lansenger videoconference list --org-id 2285568 \
  --start-time 1770912000000 --end-time 1770998400000 --fetch-range all
lansenger videoconference status --org-id 2285568 --mids "mid1,mid2"
lansenger videoconference detail mid1 --org-id 2285568 --operator st1

# 会议号换 mid
lansenger videoconference params 88001234 --org-id 2285568 --operator st1

# 取消（仅未开始）/ 结束（已开始）
lansenger videoconference cancel mid1 --org-id 2285568 --operator st1
lansenger videoconference stop mid1 --org-id 2285568 --operator st1

# 会控（opCode 原样透传，服务端校验）/ 邀请 / 成员列表 / 进出记录
lansenger videoconference member-control mid1 st2 muteall --org-id 2285568 --operator st1
lansenger videoconference invite 88001234 --org-id 2285568 --operator st1 \
  --members '[{"staffId":"st2","employeeName":"李四","type":0,"video":1,"audio":1}]'
lansenger videoconference member-list mid1 --org-id 2285568 --operator st1
lansenger videoconference simplerecord mid1 --org-id 2285568 --operator st1

# 录像：列表 + 下载链接（单次最多 3 个 vod）
lansenger videoconference vod-list mid1 --org-id 2285568 --operator st1
lansenger videoconference vod-download --org-id 2285568 --operator st1 \
  --vods '[{"vodId":"v1"},{"vodId":"v2"}]'

# 其他查询：操作记录 / 固定会议室 / 历史会议 / 进行中会议 / 事件订阅
lansenger videoconference record-list --org-id 2285568 \
  --start-time 1770912000000 --end-time 1770998400000
lansenger videoconference fixroom --org-id 2285568 --operator st1
lansenger videoconference history --org-id 2285568 --operator st1
lansenger videoconference active --org-id 2285568 --operator st1
lansenger videoconference subscribe mid1 --org-id 2285568 \
  --events "meeting_status_change,member_join"
```

## 参数速查

| 命令 | 必需参数 | 关键可选参数 |
|------|---------|-------------|
| `videoconference create` | `subject start_time` (位置参数) `--org-id --members` | `--type`(0/1) `--auto-record` `--group-new` `--conf-password` `--control-password` `--mask-type` `--ext-attr` `--join-mute` `--open-mute` `--enable-pre-join` `--user-stop-time` `--invite-admin` |
| `videoconference modify` | `mid subject start_time` (位置参数) `--org-id --operator --members` | `--auto-record` `--type` `--group-new` `--conf-password` `--control-password` `--user-stop-time` |
| `videoconference cancel` | `mid` (位置参数) `--org-id --operator` | 仅未开始的会议 |
| `videoconference stop` | `mid` (位置参数) `--org-id --operator` | 已开始的会议用此结束 |
| `videoconference detail` | `mid` (位置参数) `--org-id --operator` | — |
| `videoconference list` | `--org-id --start-time --end-time` | `--fetch-range`(my/all/person) `--staff-id`(person 必填) `--limit` `--offset` |
| `videoconference record-list` | `--org-id --start-time --end-time` | `--admin` `--create-source`(0/1) `--limit` `--offset` |
| `videoconference simplerecord` | `mid` (位置参数) `--org-id --operator` | `--limit` `--offset` |
| `videoconference fixroom` | `--org-id --operator` | `--limit` `--offset` |
| `videoconference status` | `--org-id --mids`（逗号分隔，非空） | — |
| `videoconference subscribe` | `mid` (位置参数) `--org-id --events` | `--call-back-info` |
| `videoconference params` | `meeting_number` (位置参数) `--org-id --operator` | — |
| `videoconference history` | `--org-id --operator` | `--limit` `--offset` |
| `videoconference active` | `--org-id --operator` | `--limit` `--offset` |
| `videoconference member-control` | `mid staff_id op_code` (位置参数) `--org-id --operator` | opCode 原样透传，取值见上文 |
| `videoconference invite` | `meeting_number` (位置参数) `--org-id --operator --members` | member `type`: 0=平台用户 1=小鱼终端；`video`/`audio` |
| `videoconference member-list` | `mid` (位置参数) `--org-id --operator` | `--limit` `--offset` |
| `videoconference vod-list` | `mid` (位置参数) `--org-id --operator` | — |
| `videoconference vod-download` | `--org-id --operator --vods` | 单次 vods ≤3 |
| `videoconference org-conf` | `--org-id` | `--meeting-number` `--operator` |

## 常见错误

| 错误 | 正确做法 |
|------|---------|
| `105230` 未指定会议管理员 | `members` 必须且只能有一个 `role=admin` |
| `105204` 预约会议时间必须大于当前时间 | `type=1` 时 `startTime` 传未来时间；现在开会用 `type=0` |
| `105224` 会议已开始无法取消 | 已开始的会议改用 `stop` 结束 |
| `105100` 组织未安装适配会议 / `105106` 该组织未配置视频会议 | 组织未开通开放能力，向用户说明前提（装应用 + EMC 外部标识 + 开发者中心开关），不要重试 |
| `105103` 录像下载链接数量超限 | 单次 `vods` 最多 3 个，分批获取 |
| `105102` 无下载权限 | 录像下载受权限控制，提示用户申请权限 |
| `105225` 成员超上限 / `105244` 超组织最大方数 / `105245` 无剩余通话时长 | 组织容量/时长限制，向用户说明，不要盲目重试 |
| `105105` 组织会议最大人数变更需重新入会 | 提示参会人重新入会 |
| 会控 opCode 被拒（`105601`） | opCode 服务端不认识：换用上文已知取值，不要自造操作名 |
| `fetch_range=person` 返回报错 | person 模式必须同时传 `staffId` |
| `mids` 传空数组 | 批量状态查询 `mids` 必须非空 |
| 自拼 URL 404 | 取消会议端点是历史拼写 `/meeting/cancle`，不是 `/meeting/cancel` |
| `member/list` 按 GET 调用失败 | 文档标注 GET 但要求 JSON body，统一按 POST 发送 |

## SDK 用法

| 方法 | 说明 |
|------|------|
| `create_meeting(subject=, start_time=, members=, org_id=, ...)` | 创建会议（即时/预约），返回含 `mid`/`meetingNumber` |
| `modify_meeting(mid=, subject=, start_time=, members=, org_id=, operator=)` | 修改未开始的会议 |
| `cancel_meeting(mid=, org_id=, operator=)` | 取消未开始的会议 |
| `stop_meeting(mid=, org_id=, operator=)` | 结束进行中的会议 |
| `fetch_meeting_detail(mid=, org_id=, operator=)` / `fetch_meeting_list(...)` | 会议详情 / 列表（fetch_range: my/all/person） |
| `fetch_meeting_record_list(..., create_source=)` / `fetch_member_simplerecord(mid=)` | 操作记录 / 成员进出记录 |
| `fetch_fixroom_list(org_id=, operator=)` / `fetch_meeting_status(mids=, org_id=)` | 固定会议室 / 批量状态 |
| `subscribe_meeting_events(mid=, org_id=, events=)` | 订阅会议状态变更事件 |
| `fetch_meeting_params(meeting_number=, org_id=, operator=)` | 会议号换会议配置（取 mid） |
| `fetch_history_meetings(...)` / `fetch_active_meetings(...)` | 历史会议 / 进行中+预约会议（分页） |
| `control_member(mid=, staff_id=, op_code=, operator=, org_id=)` | 主持人会控（opCode 原样透传） |
| `invite_members(meeting_number=, members=, org_id=, operator=)` | 邀请成员加入进行中的会议 |
| `fetch_member_list(mid=, org_id=, operator=)` | 成员列表（分页） |
| `fetch_vod_list(mid=, org_id=, operator=)` / `fetch_vod_download_urls(vods=, org_id=, operator=)` | 录像列表 / 下载链接（≤3） |
| `fetch_org_videoconference_conf(org_id=)` | 组织会议配置（可用性探测，PRS ≥3.8） |

```python
from lansenger_sdk import LansengerSyncClient

client = LansengerSyncClient.from_store(profile="default")

# 先探测组织是否开通
conf = client.fetch_org_videoconference_conf(org_id="2285568")

# 创建即时会议：members 必须且只能有一个 role=admin
members = [
    {"staffId": "st1", "employeeName": "张三", "role": "admin"},
    {"staffId": "st2", "employeeName": "李四", "role": "participant"},
]
r = client.create_meeting(
    subject="项目评审会", start_time=1770998400000,
    members=members, org_id="2285568",
    type=0, auto_record=1,
)
mid = r.mid

# 会议号换 mid（成员/录像操作按 mid 定位）
p = client.fetch_meeting_params(meeting_number="88001234", org_id="2285568", operator="st1")

# 会控：全体静音（opCode 原样透传）
client.control_member(mid=mid, staff_id="st2", op_code="muteall",
                      operator="st1", org_id="2285568")

# 结束会议（未开始用 cancel_meeting）
client.stop_meeting(mid=mid, org_id="2285568", operator="st1")

# 录像下载链接（单次最多 3 个）
vods = client.fetch_vod_list(mid=mid, org_id="2285568", operator="st1")
urls = client.fetch_vod_download_urls(vods=vods.items[:3], org_id="2285568", operator="st1")
```

> 更多批量模式（并发、断点续传、深分页）详见 `../lansenger-sdk/SKILL.md`。
