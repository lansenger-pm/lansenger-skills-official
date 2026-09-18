---
name: lansenger-questionnaire
version: 1.0.0
description: "蓝信问卷系统：创建/发布/撤回/结束/删除问卷，批量管理题目（16 种题型），查询官方账号与我创建/我参与的问卷列表（分页），答卷记录查询与导出。当用户需要创建问卷、发布调查、统计答卷时使用。"
metadata:
  requires:
    bins: ["lansenger"]
  cliHelp: "lansenger questionnaire --help"
---

# questionnaire

**本技能继承 [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md) 的所有规则。** Shell 执行纪律、Help-First 原则、认证、权限处理等均在其定义，此处不复述。

**CRITICAL — 创建/发布/答卷类接口必须先有 `accountCode`（官方账号 CODE）。** 不确定时 MUST 先执行 `lansenger questionnaire accounts` 查询。发布是有对外影响的操作：发布前 MUST 向用户确认标题、题目与发布范围；`delete` / `delete-question` 触发高风险门禁（exit 10）。

## Reverse Handoff — 何时不用此技能

| 用户意图 | 正确技能 | 原因 |
|---------|---------|------|
| 发正式通知/公告（无需答题） | `lansenger-notice` | 通知单向告知，问卷需要收集答卷 |
| 给个人/群发即时消息 | `lansenger-messaging` | 问卷是官方账号发起的调查活动 |
| 创建待办任务 | `lansenger-todo` | 待办是任务流转，不是调查 |
| 统计投票结果（简单场景） | `lansenger-messaging` + 人工 | 只有一两个问题时，发消息收集可能更轻 |

## 核心概念

### 问卷状态机

| status | 含义 | 可执行操作 |
|--------|------|-----------|
| 1 | 草稿 | save-questions / publish / delete |
| 2 | 进行中 | withdraw / finish |
| 3 | 已撤回 | publish / delete |
| 4 | 已结束 | delete |
| 5 | 待发布 | publish（需审批流时） |

### 官方账号依赖

`save` / `publish` / 答卷类接口需要 `accountCode`；未传或不存在时报 **3104 官方账号不存在**（不是参数缺失提示）。

### 题目 JSON 结构（16 种题型）

题目以 **camelCase JSON dict 透传**，`--questions` 接收 JSON 数组。必填三字段：`questionName` / `questionType` / `requiredFlag`；单选/多选/图片投票/打分题需 `questionOptionList`。**完整字段说明（含填空设置、打分设置、选项字段）见 [`references/lansenger-questionnaire-questions.md`](references/lansenger-questionnaire-questions.md)。**

### 高风险门禁

`questionnaire delete` 与 `questionnaire delete-question` 默认不执行：不带 `--yes` 时退出码 10，处理流程见 shared「高风险写操作门禁」。**禁止**看到 exit 10 就自动补 `--yes`。

## CLI 命令

### 创建与编辑（状态 1 草稿）

```bash
# 查官方账号（code 列即 accountCode）
lansenger questionnaire accounts

# 创建问卷（--code 传已有 code 时为覆盖更新）
lansenger questionnaire save "2026年度员工满意度调查" ACC001 --welcome "欢迎参加"

# 批量存题（--questions 为 JSON 数组，结构见 references）
lansenger questionnaire save-questions QN001 --questions '[
  {"questionName":"您对当前工作环境是否满意？","questionType":"radio","requiredFlag":1,
   "questionOptionList":[{"optionName":"非常满意","optionOrder":1},{"optionName":"一般","optionOrder":2}]}]'

# 删除题目（门禁：先 --dry-run 预览，再 --yes）
lansenger questionnaire delete-question Q0001 --dry-run
lansenger questionnaire delete-question Q0001 --yes
```

### 发布与生命周期

```bash
# 发布（内部范围，指定人员）
lansenger questionnaire publish QN001 --scope 1 --staff-ids "U10001,U10002"

# 公开发布，允许匿名，不限答题次数
lansenger questionnaire publish QN001 --scope 2 --answer-limit -1 --anonym-flag 1

# 撤回为草稿 / 提前结束 / 删除（门禁）
lansenger questionnaire withdraw QN001
lansenger questionnaire finish QN001
lansenger questionnaire delete QN001 --dry-run
lansenger questionnaire delete QN001 --yes
```

### 查询

```bash
lansenger questionnaire detail QN001          # 完整详情（含题目，需管理员权限）
lansenger questionnaire brief QN001           # 简要详情（无题目，无权限要求）
lansenger questionnaire answer-url QN001      # 答题地址
lansenger questionnaire copy QN001            # 复制为新草稿
lansenger questionnaire created-list ACC001 --status 2
lansenger questionnaire my-created org001 --title "满意度"
lansenger questionnaire participated org001 --status 4
lansenger questionnaire query-codes --codes "QN001,QN002"
```

### 答卷分析

```bash
lansenger questionnaire answers ACC001 QN001          # 答卷记录（分页）
lansenger questionnaire answer-detail ACC001 AR001    # 单份答卷详情（含答案 map）
lansenger questionnaire last-answer-detail QN001      # 我最后一次答题详情
lansenger questionnaire answer-data ACC001 QN001      # 导出用分页数据（含 answerMap）
lansenger questionnaire last-answer-record QN001      # 我最后一次答题记录
```

### 资源

```bash
# 取预签名上传地址；随后 PUT 上传文件并带 Content-MD5 头
lansenger questionnaire upload-url "logo.png" d41d8cd9... 10240
```

## 参数速查

| 命令 | 必需参数 | 关键可选参数 |
|------|---------|-------------|
| `questionnaire save` | `title` `account_code` (位置参数) | `--code`（更新）`--welcome` `--bye` `--create-user-id` |
| `questionnaire save-questions` | `questionnaire_code` `--questions`(JSON) | `--create-user-id` |
| `questionnaire delete-question` | `question_code` | `--create-user-id`；门禁 `--yes`/`--dry-run` |
| `questionnaire publish` | `questionnaire_code` | `--scope`(1/2) `--staff-ids` `--phones` `--answer-limit`(1/-1) `--message-flag` `--anonym-flag` `--publish-user-id` |
| `questionnaire withdraw` / `finish` / `delete` | `questionnaire_code` | `--operate-user-id`；delete 有门禁 |
| `questionnaire detail` / `brief` / `answer-url` / `copy` | `questionnaire_code` | `--operate-user-id`（brief 无） |
| `questionnaire query-codes` | `--codes` | `--include-deleted`(0/1) |
| `questionnaire accounts` | — | `--user-id` |
| `questionnaire created-list` | `account_code` | `--page` `--size` `--status` |
| `questionnaire my-created` / `participated` | `org_id` | `--page` `--size` `--status` `--title`(my-created) |
| `questionnaire answers` / `answer-data` | `account_code` `questionnaire_code` | `--page` `--size` |
| `questionnaire answer-detail` | `account_code` `answer_code` | `--user-id` |
| `questionnaire last-answer-detail` / `last-answer-record` | `questionnaire_code` | `--answer-record-code` |
| `questionnaire upload-url` | `file_name` `md5` `size` (位置参数) | — |

## 常见错误

| 错误 | 正确做法 |
|------|---------|
| `3104 官方账号不存在` | 创建/发布前先 `questionnaire accounts` 查 `code`，作为 `account_code` 传入 |
| 想直接给某人发问卷 | 问卷通过 `publish --staff-ids/--phones` 定向发布，不是发消息；配合 `--message-flag 1` 才走公号消息 |
| 不确认就 `delete` / `delete-question` | 删除触发门禁（exit 10），需 `--yes` 确认；可用 `--dry-run` 先预览 |
| `--questions` 传了扁平 snake_case 字段 | 题目结构是 camelCase 且嵌套（questionOptionList 等），严格按 references 文档构造 |
| 全天/半天的时长问题 | 该口径属请假/考勤模块；问卷题型只有 questionType，无半天概念 |
| 发布后想改题目 | 先 `withdraw` 撤回为草稿再 `save-questions`，进行中的问卷不可改题 |
| 服务端报错信息像多条拼接 | 多个校验失败的错误信息会无分隔符拼接（文档明示），逐项排查参数 |
| `errCode=10000 API 服务不可得` | 问卷模块未对该应用开放（实测 stage 2026-09-18），需在开发者中心开通后重试 |

## SDK 用法

### 核心方法

| 方法 | 说明 |
|------|------|
| `save_questionnaire(title, account_code, ...)` | 创建/更新问卷，返回 `questionnaire_code` |
| `save_questionnaire_questions(code, question_list)` | 批量存题，返回 `saved_count` |
| `publish_questionnaire(code, scope_type=..., ...)` | 发布，返回 `done` |
| `withdraw_questionnaire` / `finish_questionnaire` / `delete_questionnaire(code)` | 生命周期操作 |
| `fetch_questionnaire_detail(code)` / `fetch_questionnaire_brief(code)` | 详情（含/不含题目） |
| `fetch_questionnaire_office_accounts()` | 官方账号列表（accountCode 来源） |
| `fetch_created_questionnaires(account_code, ...)` / `fetch_my_created_questionnaires(org_id)` / `fetch_participated_questionnaires(org_id)` | 分页列表 |
| `fetch_answer_records(account_code, code)` / `fetch_answer_data(...)` | 答卷分页 |
| `fetch_questionnaire_answer_detail(account_code, answer_code)` | 单份答卷详情（含 answerMap） |

```python
from lansenger_sdk import LansengerSyncClient

client = LansengerSyncClient.from_store(profile="default")
accounts = client.fetch_questionnaire_office_accounts()
code = accounts.accounts[0]["code"]

r = client.save_questionnaire(title="2026年度员工满意度调查", account_code=code)
qn = r.questionnaire_code
client.save_questionnaire_questions(qn, [{
    "questionName": "您对当前工作环境是否满意？",
    "questionType": "radio", "requiredFlag": 1,
    "questionOptionList": [{"optionName": "非常满意", "optionOrder": 1}],
}])
client.publish_questionnaire(qn, scope_type=1, staff_ids=["U10001"])

page = client.fetch_answer_records(code, qn)
print(page.total, page.has_more)
```

> 更多批量模式（并发、断点续传、深分页）详见 `../lansenger-sdk/SKILL.md`。
