---
name: lansenger-notice
version: 1.0.0
description: "蓝信通知系统：通过官方账号发送通知（文本/链接内容、手机号/staffId+部门两种投放、确认/转发/回复标志、提醒策略、附件），查询组织官方账号列表。当用户需要发送正式通知/公告、需要已读确认时使用。"
metadata:
  requires:
    bins: ["lansenger"]
  cliHelp: "lansenger notice --help"
---

# notice

**本技能继承 [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md) 的所有规则。** Shell 执行纪律、Help-First 原则、认证、权限处理等均在其定义，此处不复述。

**CRITICAL — 发送通知必须先有 `accountCode`（官方账号 CODE）。** 不确定时 MUST 先执行 `lansenger notice accounts` 查询，再发送。通知与即时消息不同：**无撤回/删除接口**，发送前 MUST 向用户确认标题、内容与接收范围。

## Reverse Handoff — 何时不用此技能

| 用户意图 | 正确技能 | 原因 |
|---------|---------|------|
| 给个人/群发即时消息 | `lansenger-messaging` | 通知是官方账号的正式公告，不是聊天消息 |
| 对已发消息加急提醒 | `lansenger-messaging` | `message send-reminder`，与本模块的提醒策略无关 |
| 创建待办任务 | `lansenger-todo` | 待办有状态流转与执行人，通知没有 |
| 发送后可能需要撤回 | `lansenger-messaging` | 通知模块无撤回接口，撤回状态（3）无法通过接口产生 |

## 核心概念

### 两种内容类型

| contentType | 必填字段 |
|-------------|---------|
| 1=文本 | `--content` |
| 2=链接 | `--link` |

### 两种投放目标

| userType | 参数 | 上限 |
|----------|------|------|
| 1=手机号 | `--release-phones` / `--cc-phones`（逗号分隔） | 各 10 个 |
| 2=staffId/部门 | `--release-range`（JSON 数组）+ `--cc-staff-ids` | 各 200 个 |

`release_range` 数组元素：`{"objId":"dept-1","objName":"研发部","objType":2}`，`objType`：1=人，2=部门。

### 身份字段与 user_token

`--create-mobile`（userType=1）/ `--create-user-id`（userType=2）：带 `--as` 或 `--user-token` 时可省略，否则必填。

### 提醒策略（全部可选）

`--remind-status 1` 开启提醒；`--remind-msg-type` 提醒渠道（mobile,sms,app 逗号分隔）；`--at-once 1` 立即提醒；`--remind-after` 后续提醒类型（never/unOperate/count）；`--remind-range` 提醒范围（all/receiver/partialRemind/notReminder）。

> **实测（stage 2026-09-17）**：服务端对缺失 `remindStatus`、以及 range 对象内缺失/为 null 的 `ccRangeList` 均无空值保护，会报 `errCode=-1 unknown exception`。SDK/CLI 已自动兜底（`remindStatus=0`、`ccRangeList=[]` 强制下发），无需手动处理；自拼请求体 MUST 同时带上这两个字段。

### 通知状态

`noticeStatus`：1=草稿，2=已发送，3=已撤回（本模块无法产生）。`confirmStatus`：0=没人确认，1=部分确认，2=全部确认。

## CLI 命令

### 发送通知

```bash
# 先查官方账号（code 列即 accountCode）
lansenger notice accounts --org-id org001

# 发送文本通知（手机号投放）
lansenger notice send "关于系统升级的通知" ACC001 \
  --content "系统将于本周六进行升级维护" \
  --release-phones "13800138000,13800138001" \
  --create-mobile "13800138000" \
  --confirm-flag 1

# 链接通知（staffId/部门投放）
lansenger notice send "新版本发布" ACC001 \
  --content-type 2 --link "https://example.com/release" \
  --user-type 2 \
  --release-range '[{"objId":"dept-1","objName":"研发部","objType":2}]' \
  --cc-staff-ids "staff-002" \
  --create-user-id "staff-001"
```

### 查询官方账号

```bash
lansenger notice accounts --org-id org001
lansenger -j notice accounts --org-id org001
```

## 参数说明

### notice send

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `title` (位置参数) | str | — | 通知标题（必需） |
| `account_code` (位置参数) | str | — | 官方账号 CODE（必需） |
| `--content` / `-c` | str | "" | 文本内容（contentType=1 时必需） |
| `--link` | str | "" | 链接（contentType=2 时必需） |
| `--location` | str | "" | 通知地址 |
| `--content-type` / `-t` | int | 1 | 1=文本，2=链接 |
| `--user-type` / `-u` | int | 1 | 1=手机号，2=staffId/部门 |
| `--release-phones` | str | "" | 接收手机号，逗号分隔，≤10（userType=1 必需） |
| `--cc-phones` | str | "" | 抄送手机号，≤10 |
| `--release-range` | str | "" | 接收范围 JSON 数组（userType=2 必需），≤200 |
| `--cc-staff-ids` | str | "" | 抄送 staffId，逗号分隔，≤200 |
| `--create-mobile` | str | "" | 操作者手机号（userType=1；有 user_token 可省） |
| `--create-user-id` | str | "" | 创建人 staffId（userType=2；有 user_token 可省） |
| `--confirm-flag` | int | — | 需要确认：1=是，0=否（省略时服务端默认 1） |
| `--forward-flag` | int | — | 允许转发：1=是，0=否 |
| `--reply-flag` | int | — | 允许回复：1=是，0=否 |
| `--anonymous-flag` | int | — | 允许匿名回复：1=是，0=否 |
| `--remind-status` | int | — | 是否提醒：1=是，0=否 |
| `--remind-msg-type` | str | "" | 提醒渠道：mobile,sms,app（逗号分隔） |
| `--at-once` | int | — | 是否立即提醒 |
| `--remind-after` | str | "" | never / unOperate / count |
| `--remind-max-count` | int | — | 最大提醒次数（remind-after=count 时） |
| `--remind-interval` | int | — | 提醒间隔数值 |
| `--remind-interval-unit` | str | "" | 间隔单位：minutes / hour / day |
| `--remind-range` | str | "" | all / receiver / partialRemind / notReminder |
| `--remind-exclude` | str | "" | 不提醒的 staffId，逗号分隔 |
| `--resources` | str | "" | 附件 JSON 数组：`[{"fileName":"a.pdf","resourceId":"res-1","fileType":"application/pdf","fileSize":1024}]` |
| `--extend-id` | str | "" | 接入方的通知关联 ID |
| `--user-token` | str | "" | 用户 Token |

### notice accounts

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `--org-id` | str | "" | 组织 ID |
| `--user-token` | str | "" | 用户 Token |

## 常见错误

| 错误 | 正确做法 |
|------|---------|
| 服务端报 `errCode=-1 unknown exception` | 服务端对缺失 `remindStatus` 或 range 内 `ccRangeList` 无空值保护（实测）；SDK 已兜底，若自拼请求体 MUST 显式带上这两者 |
| `notice accounts` 不传 `--org-id` 返回空列表 | 实测 orgId 实际必传（文档标「否」），向用户要组织 ID |
| 应用报 `errCode=3381 无官方账号权限` | 应用未被授权该官方账号，需在开发者中心为应用配置可用的官方账号后再发 |
| 没查 accountCode 就发送 | 先 `notice accounts` 查 `code`，再作为第二个位置参数传入 |
| 发错后想撤回 | 通知模块无撤回接口；发送前 MUST 与用户确认标题、内容、接收范围 |
| userType 与范围参数不匹配 | userType=1 用 `--release-phones`，userType=2 用 `--release-range`，二者不混用 |
| 缺 `--create-mobile`/`--create-user-id` 报错 | 无 user_token 时按 userType 必填；或改用 `--as staffId` 自动注入 |
| 服务端报错信息像多条拼接 | 本模块多个参数校验失败的错误信息会无分隔符直接拼接，逐项排查参数 |
| 手机号/staffId 超上限 | 手机号接收/抄送各 ≤10；staffId/部门接收/抄送各 ≤200，超限发送前即报错 |

## SDK 用法

### 核心方法

| 方法 | 说明 |
|------|------|
| `send_notice(title, content_type, account_code, user_type, ...)` | 发送通知，返回 `NoticeSendResult`（`notice_code`/`notice_status`/`confirm_status` 等） |
| `fetch_notice_accounts(org_id="...")` | 查询官方账号列表，返回 `NoticeAccountListResult` |

```python
from lansenger_sdk import LansengerSyncClient

client = LansengerSyncClient.from_store(profile="default")
accounts = client.fetch_notice_accounts(org_id="org-001")
code = accounts.accounts[0]["code"]

result = client.send_notice(
    title="关于系统升级的通知", content_type=1, account_code=code,
    user_type=1, content="系统将于本周六进行升级维护",
    release_phones=["13800138000", "13800138001"],
    create_mobile="13800138000",
    confirm_flag=1,
)
if result.success:
    print(result.notice_code, result.notice_status)
```

> 更多批量模式（并发、断点续传、深分页）详见 `../lansenger-sdk/SKILL.md`。
