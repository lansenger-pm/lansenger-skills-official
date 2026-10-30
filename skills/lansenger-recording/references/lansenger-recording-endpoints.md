# lansenger recording 6 接口 · 字段与错误码明细

> 来源：蓝信内网 Wiki「4.60 智能录音」父页与 6 个子页（2026-10-26 版本）。本文只陈述 wiki 已写明的事实；wiki 未写的语义标注「wiki 未定义」，客户端经验标注「客户端建议」。
> 前置规则见 [`../../lansenger-shared/SKILL.md`](../../lansenger-shared/SKILL.md)；场景与流程见 [`../SKILL.md`](../SKILL.md)。

## 公共约定

| 项 | 约定 |
|---|---|
| Base URL | `https://<domain>/open/apigw`（示例域名 `apigw-example.domain`） |
| 鉴权 | 所有接口 query 必带 `app_token` + `user_token`，且两者必须属于同一应用（否则 `-4`） |
| 响应 | HTTP 恒 200；`{"errCode":0,"errMsg":"ok","data":{}}`；失败只有 errCode+errMsg（errMsg 末尾带追踪号，格式 wiki 未写明） |
| 开放 ID | `<oid>-<id>` 不透明，路径参数原样透传；前缀组织须与 user_token 员工组织一致（否则 `64007`） |
| 时间 | `duration`、`recordingMarker.offT` 为**毫秒**；`createTime`/`modifyTime` 为**微秒** |
| 状态 | 0 未知 / 1 未处理 / 2 处理中 / 3 失败 / 4 已完成 / 5 重新生成中；`templateState` 不适用（取值未写明） |
| 可见范围 | `user_token` 员工本人可见的录音；组织范围取该员工所属组织，不是 app_token 组织 |

## 4.60.1 获取录音列表

`POST /v1/smart_recording/recordings/fetch`

请求：query `app_token`、`user_token`；body（JSON）`page`（int，默认 1，`<=0` 按 1）、`pageSize`（int，默认 20，`<=0` 按 20，`>100` **静默按 100 截断**，非数字 → `-101`）。

响应 `data`：

| 字段 | 类型 | 必返 | 说明 |
|---|---|---|---|
| `recordings` | array | 是 | 元素与 4.60.2 的 `recording` 完全一致（含 `recordingMarker`、`tagIds`） |
| `total` | int | 否 | 总数，可选字段，可能不返回 |
| `hasMore` | bool | 是 | 是否还有下一页 |

错误码：`-1` `-2` `-3` `-4` `-5` `-101` `10000` `10005`。

坑：

- 翻页条件只能是 `hasMore`（按本页取到的 ID 数判断，**可能出现空列表 + hasMore=true**），不能看 `recordings` 条数。
- 页内个别录音可能被跳过（刚删除、状态异常、无权限），属正常，不要因条数少停止翻页。
- **无任何筛选参数**；列表是快照，提交任务后需调详情拿最新状态。
- 示例字段与枚举语义不自洽（`state=1` 却 `hasAudio=true`），不要拿示例做状态判定。

## 4.60.2 查询录音详情

`GET /v1/smart_recording/recordings/{recording_id}/fetch`

请求：query `app_token`、`user_token`；path `recording_id`（完整 `<oid>-<id>`，组织前缀须与员工组织一致）。

响应 `data.recording`：

| 字段 | 类型 | 必返 | 说明 |
|---|---|---|---|
| `recordingId` | string | 是 | 原样回显 |
| `name` / `sn` / `deviceName` | string | 否 | 名称 / 设备序列号 / 设备名 |
| `duration` | int | 否 | **毫秒** |
| `state` / `convertState` / `summaryState` / `chapterState` | int | 是 | 见 0–5 枚举；`state` 具体含义 wiki 未定义 |
| `shared` | int | 否 | 是否共享；**当前核心服务不返回该字段** |
| `createTime` / `modifyTime` | long | 否 | **微秒** |
| `tagIds` | array | 否 | 录音标签开放 ID 列表 |
| `templateId` | string | 否 | 绑定的纪要模板开放 ID |
| `recordingMarker` | string | 否 | Base64(JSON 数组)，`[{"offT":60000}]`，`offT` 毫秒；无标记常为 `W10=`；字段可能不返回 → 按 `[]` |
| `audioId` / `transcriptionId` / `summaryId` / `chaptersId` | string | 否 | 媒体开放 ID；**未生成时字段不返回**（不是 null） |
| `hasAudio` / `hasTranscription` / `hasSummary` / `hasChapters` | bool | 是 | 对应内容是否已生成 |

错误码：`-1` `-2` `-3` `-4` `-5` `10000` `10005` `64000`（不存在/不可见） `64007`（ID 格式或组织不符）。**无 `-101`**（无 body）。

坑：`data.recording` 允许缺失（录音不存在时），与 `64000` 语义重叠（wiki 未定义以哪个为准）；`audioId` 等按 missing 解析；`shared`、`templateState`、`orderNumber` 不可依赖。

## 4.60.3 提交转写任务（ASR）

`POST /v1/smart_recording/recordings/{recording_id}/transcribe/create`

请求：query `app_token`、`user_token`；path `recording_id`；**无 body**（带非法 JSON → `-101`）。**调用即重新生成**，无论此前是否已转写。

响应 `data`：`recordingId`（string，必返）、`convertState`（int，必返，固定 `5`）。

错误码：`-1` `-2` `-3` `-4` `-5` `-101` `10000` `10005` `10006`（并发版本冲突） `64000` `64005`（转写配额超限） `64007`（ID 格式/组织不符，**或无音频、不满足转写条件**）。

坑：

- 异步：提交成功只代表受理（`convertState=5`），需轮询详情到 `4`/`3`；`3` 可重新提交。
- **没有在途校验**：`convertState=5` 时重复提交仍返回 `0` 并被受理，**可能重复扣配额**，只有 `64005` 能兜底；客户端必须自行去重/防抖。
- 业务校验与配额扣减在智能录音核心服务，网关不预检只透传错误码。

## 4.60.4 提交会议纪要任务（LLM）

`POST /v1/smart_recording/recordings/{recording_id}/summary/create`

请求：query `app_token`、`user_token`；path `recording_id`；body（JSON，可选）`templateId`（纪要模板开放 ID，不传则用录音自身绑定模板）。**调用即重新生成**。

响应 `data`：`recordingId`（必返）、`summaryState`（必返，固定 `5`）。

错误码：`-1` `-2` `-3` `-4` `-5` `-101` `10000` `10005` `10006` `64000` `64003`（模板不存在） `64005`（纪要配额超限） `64006`（该录音纪要处理中） `64007`（ID/模板格式或组织不符，**或转写未完成等前置不满足**）。

坑：

- **前置条件**：`convertState == 4` **且** `hasTranscription == true`，否则 `64007`。
- 异步：提交成功后 `summaryState=5`，轮询详情到 `4`/`3`。
- `templateId` 错误分层：格式/组织错 → `64007`；格式对、组织对但查不到（伪造/已删除）→ `64003`。
- **有在途校验**：同录音纪要处理中返回 `64006`（转写没有）。
- 不传 `templateId` 时用录音绑定模板；录音未绑模板时的行为 wiki 未写明。

## 4.60.5 获取录音标签

`GET /v1/smart_recording/tags/fetch`

请求：query `app_token`、`user_token`；**无分页参数**（一次全量返回）。

响应 `data.tags[]`：`tagId`（string，必返）、`name`（string）、`sortWeight`（float）、`createTime` / `modifyTime`（long，微秒）。

错误码：`-1` `-2` `-3` `-4` `-5` `10000`（含 ID 转换服务整体不可用）。**无 `10005`、无 `-101`**。

坑：标签无分组概念；个别标签 ID 转换失败时**该条静默不返回**（不能假设全集）；排序规则（`sortWeight` 升/降序）wiki 未写明；无分页，标签多时响应可能较大。

## 4.60.6 获取纪要模板

`GET /v1/smart_recording/templates/fetch`

请求：query `app_token`、`user_token`；query 分页 `page`（默认 1）、**`page_size`**（默认 20，`<=0` 按 20，**`>100` 或非数字 → `45000`，不截断**）。注意字段名是 snake_case，与 4.60.1 的 `pageSize` 不同。

响应 `data`：

| 字段 | 类型 | 必返 | 说明 |
|---|---|---|---|
| `templates[].templateId` | string | 是 | 模板开放 ID，可直接用于 4.60.4 |
| `templates[].name` / `description` / `prompt` | string | 否 | 模板名称/描述/提示词 |
| `templates[].state` | int | 否 | **当前核心服务不返回** |
| `templates[].templateState` | int | 否 | 业务字段，**取值未写明** |
| `templates[].orderNumber` | int | 否 | **当前核心服务不返回** |
| `templates[].createTime` / `modifyTime` | long | 否 | 微秒 |
| `total` | int | 否 | 总数，可选 |
| `hasMore` | bool | 是 | 是否还有下一页（口径 wiki 未写明） |

错误码：`-1` `-2` `-3` `-4` `-5` `45000`（分页参数非数字或 `page_size>100`） `10000`。**无 `10005`、无 `-101`**。

坑：列表与详情合并在同一接口返回；可见范围是**组织级**（授权用户所属组织），与标签的员工级不同；个别模板静默丢条；`templateId` 组织前缀是否必须与员工组织一致 wiki 未写明（4.60.4 的 64007 覆盖模板组织不符）。

## 错误码汇总（6 接口合并）

| errCode | errMsg | 出现接口 | 触发条件 |
|---|---|---|---|
| `-1` | 缺少 APP_TOKEN | 全部 | 未带 app_token |
| `-2` | 缺少 USER_TOKEN | 全部 | 未带 user_token |
| `-3` | 无效的 APP_TOKEN | 全部 | app_token 不存在/过期/无效 |
| `-4` | 无效的 USER_TOKEN | 全部 | user_token 无效/过期，或与 app_token 非同一应用 |
| `-5` | API 请求路径错误 | 全部 | URL 中 `/open/apigw` 重复 |
| `-101` | JSON 反序列化错误 | 列表/转写/纪要 | 请求体非法 JSON（含列表分页参数非数字） |
| `45000` | 请求参数错误 | 模板 | `page`/`page_size` 非数字或 `page_size > 100` |
| `10000` | 内部错误 | 全部 | 下游 RPC 失败等 |
| `10005` | 无权限 | 列表/详情/转写/纪要 | 当前人员无权访问该录音 |
| `10006` | API 服务版本检查失败 | 转写/纪要 | 并发修改导致数据版本冲突（能否重试 wiki 未写明） |
| `64000` | 录音不存在 | 详情/转写/纪要 | ID 合法但反解不出（伪造/已删除/非本应用/无权限） |
| `64003` | 纪要模板不存在 | 纪要 | templateId 格式正确、组织匹配但查不到 |
| `64005` | 录音配额已超限 | 转写/纪要 | 核心扣减转写/纪要配额时判定 |
| `64006` | 操作繁忙，请稍后重试 | 纪要 | 该录音纪要任务处理中 |
| `64007` | 录音参数不合法 | 详情/转写/纪要 | ID/模板格式或组织不符；或业务前置不满足 |
