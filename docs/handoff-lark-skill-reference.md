# 交接文档：参考 TRAE/Lark 技能体系，优化蓝信技能

> 本文档供负责维护 `lansenger` CLI/SDK 和技能文档的 Agent 处理。
> 参考对象：TRAE 内置 Lark（飞书）插件 v1.0.3，路径 `~/.trae-cn/plugins/trae-remote-official/lark/1.0.3`
> 蓝信技能库：`lansenger-skills-official`（标准模式）、`lanmate-lansenger-report`（LanMate 日报周报）

---

## 一、先回答用户的核心疑问：日报/周报要不要改成纯编排形态？

**结论：不改。脚本编排是正确的，Lark 的纯编排模式不适合蓝信日报/周报场景。**

### 为什么 Lark 用纯编排，而我们用脚本

| 维度 | Lark `workflow-standup-report` | 蓝信日报/周报 |
|------|-------------------------------|--------------|
| 数据源 | 日程 + 待办任务（结构化、量小） | **全量聊天记录 + 日程**（每日上百到上千条消息） |
| CLI 支持 | `calendar +agenda`、`task +get-my-tasks` 现成 shortcut，一次调用拿全 | 需要先拉聊天列表，再逐个会话分页拉消息 |
| 单次数据量 | 日程几条、待办 20 条以内 | 单日 200-2000 条消息，单周 1000-3000 条 |
| 是否超 context | 不超，直接喂 AI | **超**，必须先精炼压缩 |
| 是否需分页/断点续传 | 不需要（量小） | **需要**（周报拉 420 个会话×5 个月≈20-30 分钟） |
| 是否需脱敏 | 不需要 | **需要**（AppSecret/token/手机号/邮箱/内网地址） |

Lark 的纯编排能成立，是因为它的数据源是「日程+待办」这种**小量结构化数据**，CLI 的 `+agenda`/`+get-my-tasks` 一次调用就返回全量，AI 拿到后直接汇总即可。

蓝信日报/周报的核心数据是**全量聊天记录**，这带来三个纯编排无法解决的问题：

1. **分页 + 多会话拉取**：要先 `fetch_chat_list` 拿活跃会话列表，再对每个会话 `fetch_chat_messages` 翻页（base_version 翻页机制），AI 逐条编排 CLI 命令会非常低效且容易出错
2. **context 爆炸**：单周 1000-3000 条消息直接喂 AI 会超 context，必须先用 `condense_daily_data.py` 精炼（提取"我发的消息"+"@我的消息"+上下文窗口+脱敏），这一步逻辑复杂，不适合让 AI 即兴完成
3. **断点续传 + 超时处理**：周报拉取耗时长，`progress.json` 断点续传机制是脚本的职责，不是 AI 编排该管的

所以现有的 `fetch → condense → AI生成 → send` 分层是合理的：**脚本干重活（拉取/精炼/脱敏），AI 干智活（理解上下文生成报告）**。

### 但可以借鉴 Lark 的 workflow 文档写法

Lark 的 `workflow-standup-report` SKILL.md 有一个东西值得我们学——**数据流图 + 步骤间数据传递说明**。我们的 SKILL.md 现在是「Step 1/2/3」线性描述，可以补充一个数据流图，让 Agent 一眼看清整个流程的数据形态变化：

```
{date} ─┬─► fetch_daily_data.py ──► raw_daily_{date}.json（原始消息+日程）
        │     （助理身份，分页拉取）
        │
        └─► condense_daily_data.py ──► daily_{date}.json（精炼数据，≤60KB）
              （脱敏+上下文窗口+去重）
                    │
                    ▼
              AI 理解上下文 ──► 日报 markdown
                    │
                    ▼
              generate_and_send_daily_report.py --send
              （机器人身份发送）
```

这个改动是纯文档层面的，不涉及脚本逻辑变更，可以直接在 SKILL.md 里加。

---

## 二、技能层面可参考的改进点（按优先级排序）

### 优先级 1：高风险操作的结构化门禁（需改 CLI）

这是 Lark 最值得借鉴的设计。目前蓝信技能的「写操作前确认」完全靠 SKILL.md 文字约束（"CRITICAL — 发消息前 MUST 向用户确认"），Agent 有时会忽略。Lark 的做法是在 CLI 层强制：

**Lark 的机制：**
- 高风险写操作（删消息、删文档、改权限等）不带 `--yes` 时，CLI 退出码 `10`，stderr 返回结构化 JSON：
  ```json
  {"ok": false, "error": {"type": "confirmation_required", "message": "...", "hint": "add --yes to confirm", "risk": {"level": "high-risk-write", "action": "drive +delete"}}}
  ```
- Agent 看到 exit 10 + `confirmation_required` → 向用户展示 `risk.action` → 用户同意后追加 `--yes` 重试
- SKILL.md 明确禁止「看到 exit 10 就默认加 `--yes`」

**蓝信可落地方案（交接给 CLI 维护 Agent）：**

1. 在 CLI 中给写操作标记 risk level（read / write / high-risk-write），高风险包括：
   - `message recall`（撤回消息）
   - `group dismiss`（解散群）
   - `group member remove`（移除群成员）
   - `schedule delete`（删除日程）
   - `todo delete`（删除待办）
   - 任何批量操作
2. 高风险命令不带 `--yes` 时，退出码 10 + 结构化 JSON（含 `risk.level`、`risk.action`）
3. 配套 `--dry-run` 参数：打印完整请求（URL/body/params）但不执行，让 Agent 预览给用户看
4. 更新 `lansenger-shared` SKILL.md 增加「高风险操作审批协议」章节

### 优先级 2：`+` 前缀的 Shortcut 命名约定（需改 CLI）

Lark CLI 用 `+` 前缀区分高级封装和原始 API 命令，在 `--help` 输出里一眼可辨：
```
+chat-create        # Shortcut（高级封装，优先用）
+messages-send      # Shortcut
chat.managers       # 原始 API（resource.method）
```

蓝信现在的 L1/L2 分层是靠命名（`send-text` vs `send-bot-message`），但不够直观。建议：

- L1 封装命令统一加 `+` 前缀：`+send-text`、`+send-markdown`、`+send-file`
- L2 domain 命令保持原样：`send-bot-message`、`send-group-message`
- `--help` 输出里 Shortcut 和 domain 命令分组显示

**注意**：这是 breaking change，需要考虑向后兼容（旧命令保留别名或至少一个版本的 deprecation warning）。

### 优先级 3：JSON 输出契约明确化（需改 CLI + 文档）

Lark 的 JSON 信封设计比我们当前更规范，值得对齐：

**Lark 的契约：**
- 成功：`{"ok": true, "identity": "user", "data": {...}, "meta": {...}}`，退出码 0，写 stdout
- 失败：`{"ok": false, "identity": "user", "error": {"type": "api", "code": 99991679, "message": "...", "hint": "..."}}`，退出码非 0，写 stderr
- 强调「用 `ok==true` 判断成功，不要用 `code==0`」

**蓝信现状：** 我们也踩过这个坑（`code==0` 误判），SKILL.md 里有经验记录但没有在 CLI 层统一信封结构。

**建议：**
- CLI 统一输出 `{ok, identity, data, meta}` / `{ok, error}` 信封
- 错误信息增加 `hint` 字段（修复建议命令）
- `--jq` 参数支持（JSON 输出后直接 jq 过滤，减少 Agent 后处理）
- 抑制 notice 的环境变量：`LANSENGER_NO_UPDATE_NOTIFIER=1`（避免更新提示干扰 JSON 解析）

### 优先级 4：workflow 编排技能模式（纯文档，可直接做）

Lark 有两个纯编排技能值得参考其文档结构：
- `lark-workflow-standup-report`（日程+待办摘要）
- `lark-workflow-meeting-summary`（会议纪要汇总）

它们的 SKILL.md 特点：
1. **数据流图**开头，展示整个流程的数据形态变化
2. **适用场景**用用户原话列举（"今天有什么安排"/"早报摘要"）
3. **步骤间数据传递**明确说明（Step 1 产出 xxx_id → Step 2 使用）
4. **AI 汇总的数据处理规则**单独列出（时间转换、排序、冲突检测等）
5. **权限表**单独列出每个步骤所需 scope

**蓝信可落地方案：**
- 日报/周报 SKILL.md 补充数据流图（见上文第一节）
- `lansenger-messaging` 的「收件人解析决策树」已经是类似思路，可以再补充数据流图
- 如果未来有「日程+待办摘要」这种轻量场景（不拉聊天记录），可以新增一个 `lansenger-workflow-standup` 纯编排技能，对标 Lark 的 standup-report

### 优先级 5：openapi-explorer 元技能（纯文档，可直接做）

Lark 有一个 `lark-openapi-explorer` 技能，教 Agent 在 CLI 没有封装某 API 时，如何从官方文档挖掘原生 OpenAPI 接口，再用 `lark-cli api` 裸调。

蓝信目前没有这个机制。如果蓝信有类似官方 API 文档库，可以做一个 `lansenger-openapi-explorer` 技能：
- 当 CLI 和 SDK 都不覆盖某需求时，Agent 知道去查蓝信 OpenAPI 文档
- 拿到接口规范后，用 SDK 的 raw HTTP 调用方式兜底
- 这样能减少「CLI 没封装就做不了」的盲区

**前提**：需要确认蓝信是否有结构化的 API 文档入口（类似飞书的 `llms.txt` 索引）。

### 优先级 6：skill-maker 自举技能（纯文档，可直接做）

Lark 的 `lark-skill-maker` 教 Agent 如何创建新技能，包含：
- CLI 能力分层说明（Shortcut > 已注册 API > api 裸调）
- API 调研流程（`--help` → `schema` → `api`）
- SKILL.md 标准模板
- 关键原则（description 决定触发、认证说明、安全确认、编排说明）

蓝信的 `skill-template/skill-template.md` 已经有模板，但没有「如何调研 API → 如何写技能」的流程指南。建议补充一个 `lansenger-skill-maker` 技能或扩展现有 template 文档：
- 加入 L1/L2/L3 调研流程
- 加入「description 决定触发」的写作指南
- 加入 reference 文件拆分规范（每个命令一个 `.md`）

---

## 三、不建议照搬的部分

### 1. OAuth Connector 集成
Lark 通过 `connector.json` + `plugin.json` 的 env 映射，让 TRAE 平台自动注入 OAuth token。蓝信是私有部署产品，认证模型不同（appToken/userToken 两级 + LanMate 双身份），且我们有 External Token 模式（`--app-token`/`--user-token` 直接传），已经比 Lark 的纯 OAuth 更灵活。不需要照搬。

### 2. 二进制内嵌技能
Lark 的 `lark-cli skills read` 能从二进制内读出技能文档，这要求技能和 CLI 二进制一起打包发布。蓝信的技能是独立 Markdown 仓库，更新迭代更灵活，不需要内嵌。

### 3. 业务域授权（--domain）
Lark 的 `auth login --domain calendar,task` 按业务域批量授权。蓝信的 scope 体系不同，且 LanMate 模式下 token 由平台管理，标准模式下用户手动配置，这个设计不一定适配。

---

## 四、落地清单

| 编号 | 改进点 | 涉及方 | 类型 | 工作量 |
|------|--------|--------|------|--------|
| 1 | 高风险操作门禁（exit 10 + --yes + --dry-run） | CLI 维护 Agent | 改 CLI + 改 shared 文档 | 中 |
| 2 | `+` 前缀 Shortcut 命名 | CLI 维护 Agent | 改 CLI（breaking） | 大 |
| 3 | JSON 输出契约统一 + --jq + notice 抑制 | CLI 维护 Agent | 改 CLI + 改 shared 文档 | 中 |
| 4 | 日报/周报 SKILL.md 补数据流图 | 技能文档 Agent | 改文档 | 小 |
| 5 | 新增 lansenger-workflow-standup 纯编排技能（可选） | 技能文档 Agent | 新增技能 | 中 |
| 6 | openapi-explorer 元技能（需先确认蓝信有文档库） | 技能文档 Agent | 新增技能 | 中 |
| 7 | skill-maker / 扩展 template 指南 | 技能文档 Agent | 改文档 | 小 |

**建议执行顺序**：先做 4、7（纯文档，零风险）→ 再做 1、3（改 CLI 但向后兼容）→ 最后评估 2（breaking change，需规划版本迁移）→ 5、6 视需求排期。
