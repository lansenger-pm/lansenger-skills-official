---
name: lansenger-personal-todo
version: 1.0.0
description: "蓝信个人待办：创建、编辑、分页查询用户自己的个人待办，并管理待办资源（上传、下载链接、预签名上传地址）。当用户需要管理个人任务清单时使用。"
metadata:
  requires:
    bins: ["lansenger"]
  cliHelp: "lansenger personal-todo --help"
---

# personal-todo

**本技能继承 [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md) 的所有规则。** Shell 执行纪律、Help-First 原则、认证、权限处理等均在其定义，此处不复述。

**CRITICAL — 个人待办与应用待办是两套接口。** 本技能只操作 `/xtra/tdtask/server/openapi/...` 的用户个人待办；应用身份发起的通知/审批待办属于 `lansenger-todo`，不得混用。

## Reverse Handoff — 何时不用此技能

| 用户意图 | 正确技能 | 原因 |
|---------|---------|------|
| 创建应用通知/审批待办 | `lansenger-todo` | 那是 `/xtra/task/unified/v1/` 的应用身份待办 |
| 完成、删除待办 | `lansenger-todo` | 个人待办当前没有完成/删除接口 |
| 管理执行人流转与状态统计 | `lansenger-todo` | 个人待办不支持执行人状态流和状态统计 |
| 发送正式通知 | `lansenger-notice` | 通知不是个人任务 |

## 核心概念

### 与企业待办的差异

| 维度 | 个人待办 | 统一应用待办 |
|------|----------|--------------|
| 路径 | `/xtra/tdtask/server/openapi/...` | `/xtra/task/unified/v1/todotask/...` |
| 业务主体 | 用户个人任务 | 应用通知/审批任务 |
| 完成/删除 | 当前接口不支持 | 支持 |
| 状态统计 | 不支持 | 支持 |
| 资源附件 | 独立资源接口 | 另有实现 |

### 必填身份字段

`orgId` 不会从 `user_token` 自动回填，所有需要组织上下文的接口 MUST 显式传入。`update` 命令的 `orgId` 位于请求体顶层。

### 当前能力边界

- 支持：创建、按字段编辑、分页查询、资源上传/下载/预签名上传。
- 不支持：标记完成、删除、执行人状态更新、状态统计。
- 文档中的 `status`、`isDel`、`executors[].execStatus` 等字段不会改变完成或删除状态。

### 参数约束

| 字段 | 说明 |
|------|------|
| `priority` | 0=较低，1=普通，2=紧急，3=非常紧急 |
| `startTime` / `dueTime` / `finishTime` | epoch 毫秒 |
| `executors` | 建议始终传入，否则待办可能不出现在创建人的列表 |
| `resources` | 先通过 `upload-resource` 上传，再引用返回的 `resourceId` |
| 资源大小 | 单次上传最大 9MB |
| 下载 URL | 最长 1 小时有效 |

## CLI 命令

```bash
# Create a personal todo
lansenger personal-todo save "完成项目方案" staff001 org001 app001 \
  --start-time 1719792000000 --due-time 1720195200000 --priority 1 \
  --executors '[{"staffId":"staff001","opt":1}]'

# Update selected fields
lansenger personal-todo update TASK001 org001 \
  --update-fields "subject,dueTime" \
  --subject "完成项目最终方案" --due-time 1720377600000

# Query one user's personal todos
lansenger personal-todo list org001 staff001 --status 0 --page 1 --size 20

# Upload an attachment and use the returned resourceId in --resources
lansenger personal-todo upload-resource app001 report.pdf application/pdf org001 --file ./report.pdf
lansenger personal-todo upload-url report.pdf MD5 10240 org001
lansenger personal-todo download-url RESOURCE_ID org001
```

## 参数速查

| 命令 | 关键参数 |
|------|----------|
| `save` | `subject create_user_id org_id appid --start-time --due-time --priority` |
| `update` | `todo_code org_id --update-fields` |
| `list` | `org_id staff_id --status --page --size` |
| `upload-resource` | `app_id file_name content_type org_id --file` |
| `download-url` | `resource_id org_id` |
| `upload-url` | `file_name md5 size org_id` |

## 常见错误

| 错误 | 正确做法 |
|------|---------|
| 找不到个人待办命令 | 使用 `lansenger personal-todo`，不是 `lansenger todo` |
| `orgId参数不可为空` | 显式传入 `org_id` / `--org-id`，user_token 不会自动回填 |
| 编辑后主题未更新 | `--update-fields` 必须包含 `subject` |
| 编辑报 orgId 为空 | `orgId` 必须放请求体顶层；SDK/CLI 已处理，自拼请求时注意 |
| 创建成功但列表看不到 | 建议始终传入 executor，通常是创建人自己 |
| 想完成/删除个人待办 | 当前接口不支持，不要调用 `lansenger todo` 混淆两套数据 |
| 资源上传超过限制 | 单文件最大 9MB |
| 下载链接过期 | 下载 URL 最长 1 小时，过期后重新获取 |

## SDK 用法

| 方法 | 说明 |
|------|------|
| `save_personal_todo(...)` | 创建个人待办，返回 `todo_code` |
| `update_personal_todo(...)` | 按 `update_fields` 编辑 |
| `fetch_personal_todo_list(...)` | 分页查询用户待办 |
| `upload_personal_todo_resource(...)` | 上传 base64 资源 |
| `fetch_personal_todo_resource_download_url(...)` | 获取下载 URL |
| `fetch_personal_todo_resource_upload_url(...)` | 获取预签名上传 URL |

```python
from lansenger_sdk import LansengerSyncClient

client = LansengerSyncClient.from_store(profile="default")
r = client.save_personal_todo(
    subject="完成项目方案",
    start_time=1719792000000,
    due_time=1720195200000,
    priority=1,
    create_user_id="staff001",
    org_id="org001",
    appid="app001",
    executors=[{"staffId": "staff001", "opt": 1}],
)
page = client.fetch_personal_todo_list("org001", "staff001", status=0)
print(r.todo_code, page.total)
```

> 更多批量模式详见 `../lansenger-sdk/SKILL.md`。
