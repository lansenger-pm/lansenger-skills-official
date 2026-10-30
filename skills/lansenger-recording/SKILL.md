---
name: lansenger-recording
version: 1.0.0
description: "蓝信智能录音开放能力（4.60）：录音列表与详情查询、提交转写（ASR）与会议纪要（LLM）任务、录音标签、纪要模板。任务异步（无回调，只能轮询详情），提交转写/纪要会重新生成并真实扣减配额。当用户需要查智能录音、转写录音、生成会议纪要、查录音标签或纪要模板时使用。"
metadata:
  requires:
    bins: ["lansenger"]
  cliHelp: "lansenger recording --help"
---

# recording

**本技能继承 [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md) 的所有规则。** Shell 执行纪律、Help-First 原则、认证、权限处理等均在其定义，此处不复述。

**CRITICAL — 鉴权是双 token，提交任务是真实写 + 扣配额。**

- 6 个接口 **MUST 同时携带 query 参数 `app_token` 与 `user_token`**，且两者必须属于**同一个应用**（否则 `-4`）；数据可见范围与组织范围只由 `user_token` 对应的员工决定（不看 `app_token` 组织）。CLI 用 `--as <staff_id>` 从已授权 profile 取该员工 token（天然同应用），或用全局 `--app-token` + `--user-token` 显式传入。
- 自拼 URL 时注意：网关地址 `https://<domain>/open/apigw` 已含 `/open/apigw`，SDK/CLI 端点路径从 `/v1/...` 起，拼接后 **`/open/apigw` 只能出现一次**，重复返回 `-5`。
- `recording transcribe` / `recording summary` 是**真实写操作**：每次受理都会重新生成、覆盖旧结果并**真实扣减配额**（服务端没有 dry-run、没有幂等键）。CLI 默认 **exit 10**，MUST 先向用户说明对哪条录音执行什么操作，用户确认后才加 `--yes`；**禁止看到 exit 10 就自动补 `--yes`**。
- **转写没有在途校验**：`convertState=5` 时再次提交仍返回 `0` 并可能重复扣配额 → 客户端必须自行防抖（如记录已提交的 `recordingId`、按钮置灰），不要连点。纪要有在途校验：处理中返回 `64006`。

## 适用场景

- 查看当前授权员工可见的智能录音（列表、详情）。
- 对某条录音提交转写（ASR），然后轮询详情拿 `convertState`，转写完成后拿到 `transcriptionId`（媒体开放 ID）。
- 对已转写完成的录音生成会议纪要（LLM），可指定纪要模板。
- 查录音标签字典（给录音打标签/筛选时用）、查组织级纪要模板列表（提交纪要时选模板）。
- 轮询异步任务状态。

**不适用**：录音文件本身的下载/播放不在本技能 6 接口内 —— 父页只有一句 `GET /v1/medias/{mediaid}/path/fetch`（必须带该员工本人 `user_token`），返回结构与有效期 wiki 未写明，见下文「相关接口」。

## Reverse Handoff — 何时不用此技能

| 用户意图 | 正确技能 | 原因 |
|---------|---------|------|
| 视频会议录像（vod）列表/下载 | `lansenger-videoconference` | 视频会议录像与智能录音是两套独立 openapi，ID/接口不互通 |
| 下载/播放录音音频文件、转写文本文件 | `lansenger-media` | 本技能只给媒体开放 ID（`audioId` 等），下载走媒体接口（细节 wiki 未写明） |
| 发消息、建群、查员工、日程 | `lansenger-messaging` / `lansenger-group` / `lansenger-staff` / `lansenger-calendar` | 与本模块无关 |

## 核心概念

### 网关与鉴权

| 项 | 约定 |
|---|---|
| Base URL | `https://<domain>/open/apigw`（示例域名 `apigw-example.domain`） |
| 路径前缀 | `/v1/smart_recording/...`（6 个端点见「参数速查」） |
| 鉴权 | query `app_token` + `user_token`，**均必填、必须同应用** |
| 身份来源 | 只来自 `user_token`；不接受 `open_staff_id` / `orgId` 之类参数 |
| user_token 获取 | OAuth2 授权码流程（见 `lansenger-oauth`）；token 接口相对哪个 base、是否带 `/open/apigw` wiki 未写明 |
| 应用门禁 | 本期不校验 scope；应用需已安装在该员工所属组织（未安装返回什么 errCode wiki 未写明） |

### 响应包与 HTTP 语义

```json
{ "errCode": 0, "errMsg": "ok", "data": {} }
```

- **HTTP 状态码恒为 200**，成败只看 `errCode == 0`。
- 失败时 `errMsg` 末尾带请求追踪号（格式 wiki 未写明），且通常没有 `data`。

### 开放 ID（`<oid>-<id>`）

- `recordingId` / `tagId` / `templateId` 均为开放 ID，形如 `<oid>-<id>`，**不透明、不要解析/不要按 `-` split 取后半段**；路径参数必须原样使用接口返回值。
- 前缀组织必须与 `user_token` 员工所属组织一致，否则 `64007`；格式合法但查不到（伪造/已删除/非本应用/无权限）为 `64000`。
- `audioId` / `transcriptionId` / `summaryId` / `chaptersId` 是**媒体开放 ID**，对应内容未生成时**字段直接不返回**（不是 `null`、不是空串）。

### 状态机（0–5）

| 值 | 含义 |
|----|------|
| 0 | 未知 |
| 1 | 未处理 |
| 2 | 处理中 |
| 3 | 失败 |
| 4 | 已完成 |
| 5 | 重新生成中 |

- 适用于 `recording.state` / `convertState` / `summaryState` / `chapterState`，以及提交接口返回的固定值 `5`。
- `templateState` **不适用**该枚举，取值 wiki 未写明（示例为 `1`，原样透传 int 即可）。
- wiki **只定义了枚举值本身**：`state` 的具体业务含义、`5 → 2 → 4/3` 的迁移序列、停留在 `5` 多久算异常，均**未写明**。客户端只能按**终态 `4`（完成）/ `3`（失败）** 判断，不要依赖中间态。
- 注意 wiki 示例自相矛盾（`state=1` 却 `hasAudio=true`），不要把示例当状态判定依据。

### 时间单位：毫秒与微秒混用

| 字段 | 单位 | 说明 |
|---|---|---|
| `duration`（录音时长） | **毫秒** | `63000` = 63 秒，`3600000` = 1 小时 |
| `recordingMarker` 解码后元素的 `offT`（标记偏移） | **毫秒** | 相对录音开始位置 |
| `createTime` / `modifyTime`（录音、标签、模板） | **微秒** | 例 `1792721267905694` ≈ 2026-10-23 10:07:47.905694 +08:00 |

- 同一响应里 ms 与 µs 混用，换算秒分别 `/1000`、`/1_000_000`。
- 各语言均按 JSON 整数原样透传，**不做单位换算**；µs 时间戳（约 1.79e15）仍在 JS 安全整数范围内，但不要用位运算/32 位截断。
- `timestamp` 类字段不带时区，展示时按 +08:00 处理（wiki 未写明时区，属展示约定）。

### recordingMarker

`recordingMarker` 是 **Base64 编码的 JSON 数组**，解码形如 `[{"offT":60000}]`（`offT` 毫秒）。无标记通常是 `W10=`（`[]` 的编码），**该字段也可能整个不返回** → 统一按 `[]` 处理。

### 分页：两个接口口径不同

| 接口 | 方法 | 分页位置 | 字段名 | 默认 | 上限 | 超上限行为 | 非数字 |
|---|---|---|---|---|---|---|---|
| 录音列表 | POST | body | `page` / **`pageSize`** | 1 / 20 | 100 | **静默按 100 截断** | `-101` |
| 纪要模板 | GET | query | `page` / **`page_size`** | 1 / 20 | 100 | **返回 `45000`**（不截断） | `45000` |

- **翻页循环条件只能是 `hasMore`**：录音列表的 `hasMore` 按「本页取到的 ID 数」判断，与 `recordings` 条数无关，**可能出现空列表 + `hasMore=true`**；模板列表的 `hasMore` 口径 wiki 未写明（同样按 bool 处理，只用它判断是否继续翻）。
- `total` 两个接口都是**可选字段**（可能不返回），不要假设存在，也不要用它算页数。
- 标签接口**无分页**，一次全量返回。
- 列表接口**没有任何筛选参数**（时间/标签/关键词/设备均无），只能全量翻页 + 本地过滤；返回的是**当时的分页快照**，提交任务后必须调详情拿最新状态。
- 模板 `page_size` 传非数字或 `>100` 直接 `45000`；分页参数传错不会自动纠正（录音列表 `page<=0`→1、`pageSize<=0`→20 除外）。
- 标签/模板可能**静默缺条**（ID 转换服务个别失败时该条不返回），不要假设返回的是全集。

### 异步、前置条件与配额

- `transcribe` / `summary` 提交成功**只代表受理**（返回状态固定 `5`），结果要轮询详情；**本组接口没有回调通知，只能轮询**（父页明确）。
- **纪要前置条件**：`convertState == 4` **且** `hasTranscription == true`，否则 `64007`。
- **每次提交都会重新生成、覆盖结果、真实扣配额**，没有 dry-run。
- 转写**无在途校验**：重复提交仍返回 `0`、可能重复扣配额 → 客户端去重/防抖。
- 纪要**有在途校验**：同一录音纪要处理中返回 `64006`（稍后重试）。
- 配额上限数值、剩余配额查询接口 wiki 未写明（只有 `64005 配额已超限`），无法做配额预警；接口只给「提交失败时告知用户」。
- 章节（`chapterState` / `hasChapters` / `chaptersId`）有状态字段，但 **6 个接口中没有「生成章节」的调用**，触发方 wiki 未定义 → 只能被动等待，不要在文档/代码里臆造入口。

## CLI 命令

> recording 命令组随 CLI 同步发版（Python CLI ≥ 0.18.0 / TypeScript CLI ≥ 1.8.0 / Go CLI ≥ 0.18.0）。本机版本较旧提示找不到命令时，升级 `lansenger` 或改用 SDK。
> 三个 CLI 的 `recording` 组一致：`list` / `detail` / `transcribe` / `summary` / `tags` / `templates`。下面按 **Python CLI** 形态书写，实际以 `lansenger recording --help` 为准。
> 鉴权：示例用 `--as staff_001` 从已授权 profile 取该员工 user_token（app_token 同应用，天然满足「双 token 同应用」）；也可用全局 `--user-token` + `--app-token` 显式传入。`-j` / `--json` 是全局选项，**必须放在子命令之前**。

```bash
# 1) 录音列表（--json 输出完整 data；翻页只看 hasMore）
lansenger -j --as staff_001 recording list --page 1 --page-size 20

# 2) 录音详情（异步任务的轮询入口；缺失字段 Python / TS CLI 显示 -，Go CLI 用零值 0/false）
lansenger -j --as staff_001 recording detail 13107200-VyueOtJzjW8jtoEygvmtomXWWigMjYEL

# 3) 提交转写（高危门：无 --yes → exit 10；--dry-run 只验参不调后端）
lansenger --as staff_001 recording transcribe 13107200-VyueOtJzjW8jtoEygvmtomXWWigMjYEL --dry-run
lansenger --as staff_001 recording transcribe 13107200-VyueOtJzjW8jtoEygvmtomXWWigMjYEL --yes

# 4) 提交会议纪要（可选 --template-id；前置：convertState=4 且 hasTranscription=true）
lansenger --as staff_001 recording summary 13107200-VyueOtJzjW8jtoEygvmtomXWWigMjYEL \
  --template-id 13107200-9f2c1a7b3d4e5f60718293a4b5c6d7e8 --yes

# 5) 录音标签（无分页，全量返回）
lansenger -j --as staff_001 recording tags

# 6) 纪要模板（query 分页 page/page_size；page-size > 100 或非数字 → 45000）
lansenger -j --as staff_001 recording templates --page 1 --page-size 20
```

**说明**：

- `transcribe` / `summary` 成功输出 `recordingId` + `convertState=5` / `summaryState=5`；**这不代表任务完成**，需轮询 `detail`。
- `--dry-run` 只校验参数并打印拟执行动作，**exit 0 且不调用后端**，适合让用户先确认。
- `--json` 下 exit 10 的信封写入 **stderr**（`type == "confirmation_required"`），见 `lansenger-shared`。
- 列表/模板/标签的表格列：`recording_id name duration(ms) state convert_state summary_state create_time` / `template_id name template_state order` / `tag_id name sort_weight create_time`。
- 表格里 `duration` 显示毫秒原值；`order` 即模板 `orderNumber`（当前核心服务不返回该字段，显示 `-`）。

## 参数速查

`-j/--json` 是**全局选项**：Python CLI 必须放在子命令之前（`lansenger -j recording list`），放在子命令后报 `No such option: -j`；TS / Go CLI 允许写在子命令后。`--json` 键名：**Python CLI 顶层为 snake_case**（`has_more`/`total`/`recordings`，元素是服务端原样 camelCase 字段）；**TS / Go CLI 统一 camelCase**（`hasMore`/`recordingId`）；但所有 CLI 的结果信封字段都是 snake_case：`err_code` / `raw_response`。`hasMore` 仅服务端返回布尔 `true` 时为真（Python CLI 已收紧，不把字符串 `"false"` 当真值）。

| 子命令 | 参数 | 返回 |
|---|---|---|
| `recording list` | `--page` int=1、`--page-size` int=20 | `{recordings, total?, hasMore}`；`recordings` 元素即完整录音对象 |
| `recording detail` | 位置参数 `RECORDING_ID` | `{recording?}`（录音不存在时 `recording` 缺失） |
| `recording transcribe` | 位置参数 `RECORDING_ID`、`--yes`、`--dry-run` | `{recordingId, convertState:5}` |
| `recording summary` | 位置参数 `RECORDING_ID`、`--template-id`、`--yes`、`--dry-run` | `{recordingId, summaryState:5}` |
| `recording tags` | 无参数 | `{tags}` |
| `recording templates` | `--page` int=1、`--page-size` int=20 | `{templates, total?, hasMore}` |

| 端点 | 方法 | 路径（相对 base） |
|---|---|---|
| 获取录音列表 | POST | `/v1/smart_recording/recordings/fetch` |
| 查询录音详情 | GET | `/v1/smart_recording/recordings/{recording_id}/fetch` |
| 提交转写任务 | POST | `/v1/smart_recording/recordings/{recording_id}/transcribe/create` |
| 提交会议纪要任务 | POST | `/v1/smart_recording/recordings/{recording_id}/summary/create` |
| 获取录音标签 | GET | `/v1/smart_recording/tags/fetch` |
| 获取纪要模板 | GET | `/v1/smart_recording/templates/fetch` |

## 轮询建议流程（客户端建议，wiki 未定义间隔）

> ⚠️ **下面整套流程是「客户端建议」，不是 wiki 契约。** wiki 明确：提交接口只返回受理、本组无回调只能轮询详情；但**轮询间隔、最大次数、总超时、`5→2` 是否一定发生、失败重试次数全部未写明**。生产实现需自行拍板并加超时，不要无限轮询。

```text
1. recording list / detail            → 拿到完整 recordingId（完整 <oid>-<id>）
2. 判断 hasAudio：无音频时转写会 64007（无音频/不满足前置），不要提交
3. recording transcribe --yes          → convertState=5（已受理）
4. 轮询 detail，直到 convertState ∈ {4, 3}
   - 4 = 已完成，此时 hasTranscription=true、transcriptionId 出现
   - 3 = 失败，可重新提交（⚠️ 重新提交会再次扣配额）
5. 前置检查：convertState==4 且 hasTranscription==true，否则纪要会 64007
6. recording summary --yes [--template-id] → summaryState=5（已受理）
7. 轮询 detail，直到 summaryState ∈ {4, 3}；4 时 hasSummary=true、summaryId 出现
```

```python
# 客户端建议（非 wiki）：间隔/上限仅示例，wiki 未定义轮询契约。
import time

def wait_terminal(client, recording_id, user_token, field="convertState", interval=10, max_tries=180):
    for _ in range(max_tries):
        d = client.fetch_recording_detail(recording_id=recording_id, user_token=user_token)
        if not d.success:
            if d.err_code == 64007:   # ID 格式/组织不符，重试无意义
                raise RuntimeError("recording id invalid")
            raise RuntimeError(f"detail failed: errCode={d.err_code}")
        rec = d.recording or {}
        state = rec.get(field)
        if state in (4, 3):
            return state          # 4=已完成；3=失败（可重新提交，会再扣配额）
        time.sleep(interval)      # 间隔是客户端建议，wiki 未定义
    raise TimeoutError("polling timeout")  # 超时策略同样是客户端建议
```

## 错误码

| errCode | 含义 | 出现接口 | 处理建议 |
|---|---|---|---|
| `-1` | 缺少 `APP_TOKEN` | 全部 6 个 | 检查全局 `--app-token` / 配置 |
| `-2` | 缺少 `USER_TOKEN` | 全部 6 个 | 本组接口必须带 user_token；用 `--as` 或 `--user-token` |
| `-3` | 无效的 `APP_TOKEN` | 全部 6 个 | token 不存在/过期，刷新后重试 |
| `-4` | 无效的 `USER_TOKEN` | 全部 6 个 | user_token 无效/过期，**或与 app_token 不属于同一应用** → 用同一应用的两个 token |
| `-5` | API 请求路径错误 | 全部 6 个 | 网关地址已含 `/open/apigw`，URL 里只出现一次 |
| `-101` | JSON 反序列化错误 | 列表 / 转写 / 纪要 | 请求体不是合法 JSON（列表分页参数为非数字也归此） |
| `45000` | 请求参数错误 | 模板 | `page`/`page_size` 非数字或 `page_size > 100`（模板不截断，直接报错） |
| `10000` | 内部错误 | 全部 6 个 | 下游 RPC 失败等；稍后重试（重试策略 wiki 未定义） |
| `10005` | 无权限 | 列表 / 详情 / 转写 / 纪要 | 当前员工无权访问该录音，换有权限的员工 token |
| `10006` | API 服务版本检查失败 | 转写 / 纪要 | 并发修改导致数据版本冲突；是否可安全重试 wiki 未写明，建议稍后重试 |
| `64000` | 录音不存在 | 详情 / 转写 / 纪要 | ID 合法但反解不出（伪造/已删除/非本应用/无权限）；向用户说明，不要重试 |
| `64003` | 纪要模板不存在 | 纪要 | `templateId` 格式正确、组织匹配但核心查不到（伪造/已删除） |
| `64005` | 录音配额已超限 | 转写 / 纪要 | 每提交一次扣一次配额；向用户说明配额已用尽，不要重试 |
| `64006` | 操作繁忙，请稍后重试 | 纪要 | 该录音纪要任务处理中（在途校验）；稍后用 detail 确认状态 |
| `64007` | 录音参数不合法 | 详情 / 转写 / 纪要 | ID 格式或组织前缀不符；**或业务前置不满足**（无音频、转写未完成等） |

> 失败响应只有 `errCode` + `errMsg`，`errMsg` 末尾带追踪号（格式 wiki 未写明）。`errCode==0` 但 `data.recording` 缺失表示「该录音不存在/不可见」，**不要**自行映射成 `64000`。

## SDK 用法

| 操作 | Python（`LansengerSyncClient`） | TypeScript（`LansengerClient` 实例） | Go（`*LansengerClient`） |
|---|---|---|---|
| 录音列表 | `fetch_recording_list(page=, page_size=)` | `client.fetchSmartRecordingList({ page, pageSize })` | `FetchRecordingList(ctx, page, pageSize)` |
| 录音详情 | `fetch_recording_detail(recording_id=)` | `client.fetchSmartRecordingDetail({ recordingId })` | `FetchRecordingDetail(ctx, recordingID)` |
| 提交转写 | `create_transcription_task(recording_id=)` | `client.createSmartRecordingTranscriptionTask({ recordingId })` | `CreateTranscriptionTask(ctx, recordingID)` |
| 提交纪要 | `create_summary_task(recording_id=, template_id=)` | `client.createSmartRecordingSummaryTask({ recordingId, templateId })` | `CreateSummaryTask(ctx, recordingID, templateID)` |
| 录音标签 | `fetch_recording_tags()` | `client.fetchSmartRecordingTags()` | `FetchRecordingTags(ctx)` |
| 纪要模板 | `fetch_recording_templates(page=, page_size=)` | `client.fetchSmartRecordingTemplates({ page, pageSize })` | `FetchRecordingTemplates(ctx, page, pageSize)` |

> TypeScript 也可用模块函数 `fetchRecordingList(config, appToken, { page, pageSize, user_token: USER_TOKEN })` 等，但必须显式传 `(config, appToken)` 并在第三个参数带 `user_token`（`USER_TOKEN` 与下文 TypeScript client 示例里的 `await client.getUserToken()` 同一来源，或直接用 OAuth2 授权结果），且不经过 client 的 token 管道；一般场景直接用 `LansengerClient.fromStore()` 实例方法更省事。

- SDK **只做单次调用**，不内建轮询/重试/等待；轮询请按上文的客户端建议自己写循环。
- 结果对象沿用各 SDK 惯例：`success / err_code / error / raw_response`；列表结果含 `recordings`/`tags`/`templates`、`total`（可选）、`has_more`；详情结果含 `recording`；提交结果含 `recording_id` + `convert_state` / `summary_state`。
- 鉴权：`app_token` 由各 SDK 自动处理；`user_token` **不是每种语言都自动注入**——Python / TypeScript 需逐调用显式传 `user_token`（取值见上方示例），Go 先取 client 自带 token（`NewClientWithToken` / `SetUserTokens` / `Config.UserToken`），再回退进程级 `SetDefaultUserToken`（CLI `--as` 用的就是它）。

```python
from lansenger_sdk import LansengerSyncClient

client = LansengerSyncClient.from_store(profile="default")
# 本组 6 个接口必须带员工 user_token。from_store 会把 credential store 里的
# user token 注册到 get_user_token()，逐调用显式传入（也可建 client 时传 user_token=）。
user_token = client.get_user_token()

# 1) 列表：翻页只看 has_more（可能空页 + has_more=True）
page = client.fetch_recording_list(page=1, page_size=20, user_token=user_token)
if not page.recordings:
    raise RuntimeError("no recording visible to this staff member")
rid = page.recordings[0]["recordingId"]          # 完整 <oid>-<id>，原样透传

# 2) 详情：异步任务的轮询入口；字段缺失按 missing 处理
detail = client.fetch_recording_detail(recording_id=rid, user_token=user_token)
rec = detail.recording or {}

# 3) 提交转写（真实写 + 扣配额；无 dry-run，调用前先确认）
if rec.get("hasAudio") and not rec.get("hasTranscription"):
    client.create_transcription_task(recording_id=rid, user_token=user_token)
    # 轮询 detail 直到 convertState ∈ {4, 3}（客户端建议，间隔 wiki 未定义）

# 4) 提交纪要（前置：convertState==4 且 hasTranscription==true）
client.create_summary_task(recording_id=rid, template_id=None, user_token=user_token)

# 5) 标签 / 6) 纪要模板
tags = client.fetch_recording_tags(user_token=user_token)
templates = client.fetch_recording_templates(page=1, page_size=20, user_token=user_token)
```

```typescript
import { LansengerClient } from "lansenger-sdk-ts";

// 鉴权沿用 SDK 现有管道（profile 里读 app/token；app_token + user_token 同应用）
const client = LansengerClient.fromStore("default");
// 本组 6 个接口必须带员工 user_token：从 credential store 取，逐调用显式传入
// （client 方法不会自动注入；文件首行的 profile 与 CLI 的 --as 对应关系见 lansenger-sdk）。
const userToken = await client.getUserToken();

// 1) 列表：翻页只看 hasMore（可能空页 + hasMore=true）
const list = await client.fetchSmartRecordingList({ page: 1, pageSize: 20, user_token: userToken });
const rid = list.recordings?.[0]?.recordingId;          // 完整 <oid>-<id>，原样透传

// 2) 详情：异步任务的轮询入口；recording 可能为 null，字段缺失按 missing 处理
const detail = await client.fetchSmartRecordingDetail({ recordingId: rid!, user_token: userToken });

// 3) 提交转写（真实写 + 扣配额；本组无 dry-run，调用前先确认）
if (detail.recording?.hasAudio && !detail.recording.hasTranscription) {
  await client.createSmartRecordingTranscriptionTask({ recordingId: rid!, user_token: userToken });
  // 轮询 detail 直到 convertState ∈ {4, 3}（客户端建议，间隔 wiki 未定义）
}

// 4) 提交纪要（前置：convertState === 4 && hasTranscription === true）
await client.createSmartRecordingSummaryTask({ recordingId: rid!, user_token: userToken });

// 5) 标签 / 6) 纪要模板
const tags = await client.fetchSmartRecordingTags({ user_token: userToken });
const templates = await client.fetchSmartRecordingTemplates({ page: 1, pageSize: 20, user_token: userToken });
```

```go
// 本组 6 个接口必须带员工 user_token：库调用方用 NewClientWithToken(appToken, userToken)，
// 或用 NewClient + SetUserTokens(...)；SetDefaultUserToken(...) 仅作进程级兜底。
client := lansenger.NewClientWithToken(appToken, userToken)

// 列表：翻页只看 HasMore（可能空列表 + HasMore=true）
list, err := client.FetchRecordingList(ctx, 1, 20)
if err != nil {
    return err
}
if len(list.Recordings) == 0 {
    return fmt.Errorf("no recordings")   // 需 import "fmt"
}
rid := list.Recordings[0].RecordingID   // 完整 <oid>-<id>，原样透传

detail, err := client.FetchRecordingDetail(ctx, rid)
if err != nil {
    return err
}
// Recording 是指针：详情可能缺失（errCode==0 但无录音），必须先判 nil
if detail.Recording != nil && detail.Recording.HasAudio && !detail.Recording.HasTranscription {
    // 真实写 + 扣配额，调用前先确认
    if _, err := client.CreateTranscriptionTask(ctx, rid); err != nil {
        return err
    }
}

// 前置：ConvertState==4 && HasTranscription==true
_, err = client.CreateSummaryTask(ctx, rid, "")   // 空 templateID = 用录音绑定模板
tags, err := client.FetchRecordingTags(ctx)
templates, err := client.FetchRecordingTemplates(ctx, 1, 20)
```

> 更完整的字段表、每接口错误码与坑，见 [`references/lansenger-recording-endpoints.md`](references/lansenger-recording-endpoints.md)。
> 批量拉取、并发、断点续传等模式详见 `../lansenger-sdk/SKILL.md`。

## 相关接口（不在本 6 接口内）

- **录音文件下载**：`GET /v1/medias/{mediaid}/path/fetch`，**必须携带该员工本人的 `user_token`**（只带 app_token 取不到内容）；`mediaid` 取自详情里的 `audioId` / `transcriptionId` / `summaryId` / `chaptersId`。返回结构、下载链接有效期、是否 302 均**wiki 未写明**；具体用法见 `lansenger-media`。
- **章节生成**：有 `chapterState` / `hasChapters` / `chaptersId`，但 6 个接口里没有生成章节的入口，触发方 **wiki 未定义**。
- **录音打标签/改标签**：只有「获取录音标签」（字典）与录音对象的 `tagIds`，**没有写标签接口**（wiki 未列出）。
