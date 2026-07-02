---
name: lansenger
version: 1.9.1
description: "蓝信 CLI 技能套件 — 使用 lansenger CLI 操作蓝信平台：发消息、管理群组、查通讯录、日历日程、待办任务、OAuth2 认证、文件上传下载、机器人指令、个人应用。触发条件：用户提到蓝信、lansenger、发消息、群组、日程、员工查询等功能时加载此技能。"
metadata:
  requires:
    bins: ["lansenger"]
  cliHelp: "lansenger --help"
---

# 蓝信 Lansenger CLI 技能套件

`lansenger` 是蓝信平台的 CLI 工具，通过命令行完成消息发送、群组管理、通讯录查询、日历日程、待办任务、文件上传等操作。

## 安装

如果 `lansenger` 尚未安装：

```bash
# 推荐：Python CLI（优先使用）
pip install lansenger-cli
pip install lansenger-sdk

# 备选：Go CLI
go install github.com/lansenger-pm/lansenger-sdk-go/cmd/lansenger@latest

# 备选：TypeScript CLI
npm install -g lansenger-cli
```

验证：`lansenger --version`（如果 PATH 未更新，打开新终端）。

---

## 策略

**L1（封装命令）→ L2（domain 命令）→ L3（raw API）**。优先使用高级封装命令：

- **L1**：`send-text`、`send-markdown`、`send-file` 等 Shortcut 命令 — 封装了通道选择和参数校验，Agent 应优先使用
- **L2**：`send-bot-message`、`send-group-message`、`send-user-message` 等 domain 命令 — 需要手动构造 JSON 消息体，仅在 L1 不覆盖时使用
- **L3**：直接调用 SDK API — 仅在 CLI 命令行无法满足需求时使用

添加 `--json` / `-j` 获取结构化输出，便于 Agent 解析。

---

## Help-First 原则

**不确定参数名、值类型或命令语法时，先跑 `--help`，别猜。** 猜-错-重试循环比一次 help 查询慢得多。

```bash
lansenger --help                      # 所有子命令
lansenger message --help              # 消息域命令
lansenger calendar --help             # 日历域命令
lansenger <domain> <command> --help   # 具体命令参数
```

**Help 与本文档之间的关系**：本技能文档教授"怎么做"和"为什么"，CLI `--help` 提供当前已安装版本的精确参数列表。当两者不一致时，**`--help` 更权威**（因为它是安装版本的实时反映）。

---

## 初始化

首次使用需配置 appID 和 appSecret：

```bash
lansenger config set app_id YOUR_APP_ID
lansenger config set app_secret YOUR_APP_SECRET
lansenger config show
```

**凭证来源**：蓝信桌面端 → 通讯录 → 智能机器人 → 个人机器人 → ℹ️ 图标；或蓝信开发者中心。

---

## 技能分发表

根据用户需求，加载对应的子技能：

| 用户意图 | 加载技能 | 说明 |
|----------|----------|------|
| 发文字/文件/图片/视频/卡片消息 | `lansenger-messaging` | 私聊+群聊，支持多种消息类型，含审批卡片 |
| 查看聊天列表、拉取消息记录 | `lansenger-chat` | 私聊+群聊聊天记录 |
| 创建/解散群、管理群成员 | `lansenger-group` | 群组生命周期管理 |
| 查员工信息、通讯录搜索 | `lansenger-staff` | ID 映射、组织扩展字段 |
| 浏览组织架构、查部门 | `lansenger-department` | 部门树、部门成员 |
| 查日历、增删改日程 | `lansenger-calendar` | 日程 CRUD、参会人 |
| 创建/管理待办任务 | `lansenger-todo` | 待办任务生命周期 |
| OAuth2 登录、获取用户 Token | `lansenger-oauth` | 授权URL、code换token |
| 上传/下载文件、图片、视频 | `lansenger-media` | 媒体文件上传下载 |
| 接收蓝信 Webhook 回调 | `lansenger-callback` | 事件解析、AES解密 |
| AI Agent 实时推送消息 | `lansenger-streaming` | SSE 流式消息 |
| 管理机器人指令 | `lansenger-bot-command` | 创建/查询/删除机器人指令（4.37） |
| 管理个人应用/机器人 | `lansenger-personal-app` | 创建/更新/查询/删除个人应用（4.38） |

> **External Token模式**：如需显式传入app_token和user_token的集成模式，请使用独立的 lansenger-skills-external 技能套件。

**注意**：`lansenger-shared` 会被所有子技能自动加载，包含认证、配置、安全等通用规则，不需要手动加载。

### 技能场景边界（Reverse Handoff）

| 技能 | 适用场景 | 不适用场景 |
|------|----------|------------|
| `lansenger-messaging` | 发消息、发文件、发卡片 | 查看聊天记录 → 用 `lansenger-chat` |
| `lansenger-chat` | 查看聊天列表、拉取消息（不强制要求 userToken） | 发消息 → 用 `lansenger-messaging` |
| `lansenger-staff` | 查员工信息 | 浏览组织架构 → 用 `lansenger-department` |
| `lansenger-department` | 查部门信息 | 查员工 → 用 `lansenger-staff` |
| `lansenger-oauth` | 用户授权登录 | 配置 appID/appSecret → `lansenger config set` |
| `lansenger-media` | 上传/下载媒体文件 | 发文件到聊天 → 用 `lansenger-messaging` |

---

## 身份模型

蓝信有两级身份体系：

| Token | 身份 | 获取方式 | 有效期 |
|-------|------|---------|--------|
| **appToken** | 应用/机器人 | 自动管理（appID + appSecret） | 2小时，自动刷新 |
| **userToken** | 个人用户 | OAuth2 流程获取 | 2小时，SDK 自动刷新 |

- **无 `--user-token`**：以机器人/应用身份操作
- **有 `--user-token`**：以个人用户身份操作（可访问用户日历、聊天记录等个人资源）

---

## 推荐技能优先级

1. `lansenger-shared`（自动）— 认证、配置、安全
2. 按用户意图加载对应子技能（见分发表）

### 多技能并发加载优先级

当用户请求涉及多个领域（如"在张三的日历上创建日程并通知他"），需同时加载多个子技能时，优先级规则：

| 优先级 | 规则 | 示例 |
|--------|------|------|
| **1** | 先获取数据，再操作 | 先 `lansenger-staff` 查 staffId → 再 `lansenger-calendar` 创建日程 |
| **2** | 先完成写入，再通知 | 先完成日程/待办创建 → 再 `lansenger-messaging` 发送通知 |
| **3** | OAuth 前置 | 需要 userToken 时，`lansenger-oauth` 优先于任何需要用户身份的操作 |
| **4** | 同类互斥，跨界协作 | 发消息 vs 看消息 → 只加载其中一个；查员工 + 查部门 → 可同时加载 |

冲突裁决：当两个子 skill 的规则冲突时，按操作类型决定 — 写入操作（messaging/calendar/todo）的确认规则优先于读取操作（chat/staff/department）的宽松规则。

---

## 场景化指南

以下为常见业务场景的最佳实践示例，Agent 可直接参考执行。

### 查询今日消息（日报素材）

用户想要汇总今天的聊天记录，需拉取当天所有私聊和群聊消息。

```
# Step 1：先获取聊天列表（获取用户今天活跃的聊天）
lansenger -j chat list --user-token "ut1"

# Step 2：从返回结果中提取各聊天对象
# Step 3：逐个拉取今天的消息（计算今日 00:00:00 微秒时间戳作为 --start）
# 例如 2026-07-01 00:00:00 = 1770912000000000
lansenger chat messages --staff-id staff123 --start 1770912000000000 --user-token "ut1"

# 群聊同样操作
lansenger chat messages --group-id group456 --start 1770912000000000 --user-token "ut1"
```

**关键提示**：
- `chat list` 不传 `--start/--end`（默认 0=不限制）可获取所有历史联系过的聊天
- 要精确限定"今天"，需手动计算当天零点微秒时间戳并传入 `--start`
- 从消息返回中提取 `sender`（姓名）、`msgType`、`plain_text` 用于生成摘要

### 生成工作日报

结合聊天记录和日程数据，生成当日工作日报。

```
# Step 1：拉取今日聊天摘要
lansenger chat list --user-token "ut1"

# Step 2：拉取今日日程
lansenger -j calendar list-schedules calOpenId 1770912000 1770998400 --user-token "ut1"

# Step 3：拉取今日待办
lansenger -j todo list org123 --user-token "ut1"

# Step 4：汇总数据，生成 Markdown 日报
# - 今日日程：从 list-schedules 结果提取 summary + start_time
# - 今日待办：从 todo list 结果提取待办状态（21=待办, 22=已办）
# - 今日沟通：从 chat messages 结果汇总各聊天的消息主题
```

### 按时间范围查询聊天记录

拉取指定时间段内的聊天消息，用于回溯或审计。

```
# 拉取 2024年1月的私聊记录（时间跨度 ≤ 1个月）
lansenger chat messages --staff-id staff123 --start 1704067200000000 --end 1706745599000000 --user-token "ut1"

# 跨多个月拉取（使用自动按月拆分）
lansenger chat messages --staff-id staff123 --start 1704067200000000 --end 1717199999000000 --split-month --progress --user-token "ut1"
```

### 群发通知

向多个群发送同一条通知消息。

```
# Step 1：查询可发消息的群列表
lansenger -j message query-groups

# Step 2：逐个群发送通知（注意逐条执行，逐条检查）
lansenger message send-text group123 "【通知】今晚 20:00 系统维护" --group
lansenger message send-text group456 "【通知】今晚 20:00 系统维护" --group
```

### 创建日程并通知参会人

完整流程：创建日程 → 发送通知给参会人。

```
# Step 1：创建日程
lansenger calendar create-schedule calOpenId "项目评审会" 1770998400 1771005600 '[{"staffId":"staff1","attendeeFlag":"yes"},{"staffId":"staff2","attendeeFlag":"yes"}]' --desc "讨论项目进度" --user-token "ut1"

# Step 2：查询参会人姓名（用于通知消息）
lansenger -j staff basic-info staff1
lansenger -j staff basic-info staff2

# Step 3：发送通知消息
lansenger message send-text staff1 "您有一个新日程：项目评审会，时间：7月14日 16:00-18:00" 
```

**关键原则**：先完成写入操作（创建日程），再执行通知操作（发消息）。
