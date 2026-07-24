# Lansenger LanMate Skill 问题汇总报告

> 汇总来源：
> - `skill-doc-issue-send-user-message.md`（msg_data 格式问题）
> - `skill-fix-send-user-message.md`（--user-token 参数位置问题）
> - `skill-analysis-20260724.md`（测试分析报告，含 8 项发现）
>
> 日期：2026-07-24

---

## 目录

- [一、文档与实际 API 不符 — 参数格式（2 项）](#一文档与实际-api-不符--参数格式2-项)
  - [1.1 send-user-message 的 msg_data 缺少 content 嵌套](#11-send-user-message-的-msg_data-缺少-content-嵌套)
  - [1.2 send-user-message 的 --user-token 参数位置错误](#12-send-user-message-的---user-token-参数位置错误)
- [二、待修复问题 — 文档与实际 API 不符（3 项）](#二待修复问题--文档与实际-api-不符3-项)
  - [2.1 send-user-message formatText 不可用（TC-EXE-14）](#21-send-user-message-formattext-不可用tc-exe-14)
  - [2.2 助理身份 send-file 需机器人能力（TC-EXE-15/16）](#22-助理身份-send-file-需机器人能力tc-exe-1516)
  - [2.3 群聊发消息 errCode=-10 误报（TC-EXE-17~21）](#23-群聊发消息-errcode-10-误报tc-exe-1721)
- [三、待修复问题 — 文档缺失（2 项）](#三待修复问题--文档缺失2-项)
  - [3.1 缺少 API 权限/能力前置条件矩阵](#31-缺少-api-权限能力前置条件矩阵)
  - [3.2 formatText 无降级方案](#32-formattext-无降级方案)
- [四、待修复问题 — 路径设计（1 项）](#四待修复问题--路径设计1-项)
  - [4.1 群解散操作应支持双身份路由](#41-群解散操作应支持双身份路由)
- [五、优化建议（2 项）](#五优化建议2-项)
  - [5.1 增加快速连通性检查命令](#51-增加快速连通性检查命令)
  - [5.2 增加 pre-flight checklist](#52-增加-pre-flight-checklist)
- [六、优先级排序](#六优先级排序)

---

## 一、文档与实际 API 不符 — 参数格式（2 项）

### 1.1 send-user-message 的 msg_data 缺少 content 嵌套

**来源**：`skill-doc-issue-send-user-message.md`

**问题类型**：文档示例与实际 API 契约不一致

**涉及 Skill**：`lansenger-lanmate-messaging`
**影响命令**：`message send-user-message`

**问题描述**

SKILL.md 中 `send-user-message` 的示例使用了错误的 `msg_data` JSON 格式——将 `"text"` 的值写成字符串，漏掉了 `{"content": ...}` 嵌套层。

**文档中的示例（错误）**：
```bash
lansenger ... message send-user-message staff456 text '{"text":"你好，这是消息内容"}'
```

**实际 API 期望格式（正确）**：
```bash
lansenger ... message send-user-message staff456 text '{"text":{"content":"你好，这是消息内容"}}'
```

**根因**

蓝信 API 中 `MsgText.text` 字段的类型是 `openApi.SystemTextContent`（对象），而非简单字符串。文档示例直接传字符串导致反序列化失败。

实际 API 返回的错误信息：
```
API error (errCode=40060): 消息为空或格式错误||unmarshal text error:json:
cannot unmarshal string into Go struct field MsgText.text of type
openApi.SystemTextContent
```

**影响范围**

所有使用 `send-user-message` 发送 text 类型消息的场景，包括用户给第三方发私聊、创建日程后通知参会人。

**修复状态**：❌ 待修复 — 需将 SKILL.md 及 skill-test-cases.md 中所有相关示例改为嵌套结构 `{"text":{"content":"..."}}`，并新增 TC-ANTI-10 反模式检测。

---

### 1.2 send-user-message 的 --user-token 参数位置错误

**来源**：`skill-fix-send-user-message.md`

**涉及 Skill**：`lansenger-lanmate-messaging`
**影响命令**：`message send-user-message`

**问题描述**

`send-user-message` 的 `--user-token` 是**子命令级 option**，必须放在位置参数（receiver_id、msg_type、msg_data）之后。但 SKILL.md 中 5 处示例将其放在全局位置（`message` 之前），导致 AI 照搬示例时命令执行失败。

**根因**

`--user-token` 在 lansenger CLI 中的位置取决于子命令：

| 子命令 | --user-token 级别 | 正确位置 |
|--------|-------------------|----------|
| `staff search` | 全局级 | `--app-token` 旁边，子命令之前 |
| `calendar *` | 全局级 | `--app-token` 旁边，子命令之前 |
| `chat *` | 全局级 | `--app-token` 旁边，子命令之前 |
| `send-user-message` | **子命令级** | 位置参数之后 |

文档未区分这两种情况，统一将 `--user-token` 放在全局位置。

**5 处修复点**

| # | 位置 | 修复前 | 修复后 |
|---|------|--------|--------|
| 1 | 第 61 行 决策树 | `... --user-token "..." message send-user-message` | `... message send-user-message <receiver> text '<json>' --user-token "..."` |
| 2 | 第 72 行 速查表 | `... --user-token "..." message send-user-message staff123 "..."` | `... message send-user-message staff123 text '{"text":{"content":"..."}}' --user-token "..."` |
| 3 | 第 75 行 速查表 | `... --user-token "..." message send-user-message ...` | `... message send-user-message <receiver> text '...' --user-token "..."` |
| 4 | 第 201 行 人→人私聊示例 | `... --user-token "..." message send-user-message staff456 text '...'` | `... message send-user-message staff456 text '...' --user-token "..."` |
| 5 | 第 204 行 formatText 示例 | `... --user-token "..." message send-user-message staff456 formatText '...' --common '...'` | `... message send-user-message staff456 formatText '...' --common '...' --user-token "..."` |

**修复状态**：❌ 待修复 — 需将 SKILL.md 5 处示例的 `--user-token` 移到位置参数之后，并在文档头部增加 CRITICAL 规则说明；skill-test-cases.md 中 3 处示例同样需修正，并新增 TC-ANTI-11 反模式检测。

---

## 二、待修复问题 — 文档与实际 API 不符（3 项）

### 2.1 send-user-message formatText 不可用（TC-EXE-14）

**涉及 Skill**：`lansenger-lanmate-messaging`
**影响命令**：`message send-user-message formatText`

**文档内容**：
```bash
# 发 Markdown 消息
lansenger --app-token "$LANSENGER_APP_TOKEN" message send-user-message staff456 formatText '{"content":"**重要通知**\n\n请今天下班前完成审批"}' --common '{"chat_type":"p2p"}' --user-token "$LANSENGER_USER_TOKEN"
```

**实测结果**：
```
errCode=40060: 消息为空或格式错误||invalid formatType for FormatText, unmarshal error
```

**根因**：Stage 环境 API 不支持 `send-user-message` 的 `formatText` 类型，或 `msg_data` 格式需调整。尝试了 `{"content":"..."}` 和 `{"formatText":{"content":"..."}}` 两种格式均失败。

**建议**：
- 确认 formatText 是否需要特定 API 版本或权限
- 增加 fallback 说明：如果 formatText 不可用，退而使用 `text` 类型发送纯文本

---

### 2.2 助理身份 send-file 需机器人能力（TC-EXE-15/16）

**涉及 Skill**：`lansenger-lanmate-messaging`
**影响命令**：`message send-file`（助理身份 + userToken）

**文档内容**：
```bash
# 发文件附件
lansenger --app-token "$LANSENGER_APP_TOKEN" message send-file staff456 /path/to/report.pdf --user-token "$LANSENGER_USER_TOKEN"
```

**实测结果**：
```
errCode=-10: 应用需要开启机器人能力||failed to get botId
```

**根因**：`send-file` 内部依赖 Bot 的文件上传通道（`media upload-app`），即使传了 `--user-token`，助理身份也需要 Bot 能力。

**补充验证**：尝试通过 `send-user-message text` + mediaIds / attachments 等 4 种格式发送附件给第三方，API 均返回 success 但附件被静默丢弃——`send-user-message` 实际不支持文件附件。

**建议**：
- 文档标注前置条件：「助理应用需开启机器人能力」
- 标注已知限制：给第三方发文件在未开启 Bot 能力时无可用 CLI 通道

---

### 2.3 群聊发消息 errCode=-10 误报（TC-EXE-17~21）

**涉及 Skill**：`lansenger-lanmate-messaging`
**影响命令**：`message send-text --group`（助理身份）

**文档内容**：
```bash
# 用户 → 群（需userToken，使用助理身份）
lansenger --app-token "$LANSENGER_APP_TOKEN" --user-token "$LANSENGER_USER_TOKEN" message send-text group123 "I'll handle it" --group
```

**实测结果**：
- API 返回 `errCode=-10: 应用需要开启机器人能力||invalid visitor (sender)`
- **但消息实际已成功投递！**（TC-EXE-32 聊天记录可查证）

**根因**：API 返回了误导性的错误码，实际消息发送成功。这是蓝信 Stage API 的 bug。

**建议**：
- **严重**：文档应标注此 API 返回值为误报，建议发送后通过 `chat messages` 验证实际投递状态
- 向蓝信 API 团队报告 `errCode=-10` 误报问题

---

## 三、待修复问题 — 文档缺失（2 项）

### 3.1 缺少 API 权限/能力前置条件矩阵

**影响用例**：TC-GRP-03/04/05

测试发现不同操作所需权限差异显著，但文档没有统一说明：

| API | Bot 身份 Stage 权限 | 助理身份 Stage 权限 |
|-----|---------------------|---------------------|
| `group create` | ❌ errCode=10005 | 不支持此操作 |
| `group dismiss` | ❌ errCode=10005 | ✅ 群主本人可用 |
| `group update-members` | ❌ errCode=10005 | 不支持此操作 |

**建议**：在 skill 文档中增加「所需 API 权限」矩阵：

| 操作 | 身份 | 所需权限 |
|------|------|---------|
| 发消息（bot私聊） | Bot | Bot 消息发送 |
| 发文件 | Bot/助理 | Bot 文件上传 + 消息发送 |
| 发群消息（Bot） | Bot | Bot 消息发送 + 群内成员 |
| 发群消息（用户） | 助理 | Bot 消息发送（底层依赖） |
| 建群 | Bot | 群管理 API |
| 解散群 | Bot/群主 | 群管理 API（群主可用助理身份） |
| 群成员管理 | Bot | 群管理 API |
| 通讯录查询 | 助理 | 通讯录读取 |
| 日历操作 | 助理 | 日历 API |

---

### 3.2 formatText 无降级方案

**问题**：当 `send-user-message formatText` 不可用时（errCode=40060），没有备选路径。用户实际意图是"发 Markdown 消息给第三方"，但唯一路径失败后无替代。

**建议**：文档增加降级策略：
```
优先级 1: formatText（Markdown 渲染最佳）
   ↓ 如果 errCode=40060
优先级 2: text 类型 + Markdown 语法（部分客户端可渲染）
   lansenger ... send-user-message <id> text '{"text":{"content":"**Bold**\\n\\n- item"}}' ...
```

---

## 四、待修复问题 — 路径设计（1 项）

### 4.1 群解散操作应支持双身份路由

**发现**：`group dismiss` 的预期路径是 Bot 身份，但群主用助理身份同样可以解散（TC-GRP-04 实测验证）。当前分发表只有 Bot → 解散群这一条路由。

**实测记录**：

| # | 身份 | 命令 | 结果 |
|---|------|------|------|
| 1 | 机器人 (`$LANSENGER_BOT_APP_TOKEN`) | `group dismiss <id>` | ❌ errCode=10005 |
| 2 | 助理 (`$LANSENGER_APP_TOKEN` + userToken) | `group dismiss <id> --user-token` | ✅ 成功 |

**建议**：分发表增加助理身份的路由：

| 操作 | Bot 身份 | 助理身份 |
|------|----------|----------|
| 解散群 | 需群管理 API 权限 | ✅ 群主本人（无需 Bot 权限） |

并标注优先级：当 Bot 无权限时，若用户是群主 → 切换到助理身份（需用户授权）。

---

## 五、优化建议（2 项）

### 5.1 增加快速连通性检查命令

在 shared SKILL.md 中增加一条"健康检查"命令，一次调用即可验证 Gateway 连通性、APP_TOKEN 有效性、USER_TOKEN 有效性：

```bash
lansenger -j --app-token "$LANSENGER_APP_TOKEN" staff basic-info "$LANSENGER_STAFF_ID" --user-token "$LANSENGER_USER_TOKEN"
```

---

### 5.2 增加 pre-flight checklist

建议在 skill 的 Master SKILL.md 开头增加：

```markdown
## 前置检查清单
- [ ] `lansenger --version` ≥ 0.10.19
- [ ] `$LANSENGER_API_GATEWAY_URL` 指向正确环境
- [ ] `$LANSENGER_APP_TOKEN` 有效（测试: `staff basic-info`）
- [ ] `$LANSENGER_BOT_APP_TOKEN` 有效（测试: `group list`）
- [ ] `$LANSENGER_USER_TOKEN` 有效
- [ ] 助理应用是否开启机器人能力（影响 send-file / 群消息）
- [ ] Bot 应用是否有群管理 API 权限（影响 group create/dismiss/update-members）
```

---

## 六、优先级排序

| 优先级 | 编号 | 问题 | 类别 | 状态 |
|--------|------|------|------|------|
| 🔴 P0 | 1.1 | `msg_data` 缺少 content 嵌套 | 文档错误 | ❌ 待修复 |
| 🔴 P0 | 1.2 | `--user-token` 参数位置错误 | 文档错误 | ❌ 待修复 |
| 🔴 P0 | 2.3 | 群聊 errCode=-10 误报 — API 返回错误但消息已投递 | 文档错误 | ❌ 待修复 |
| 🔴 P0 | 2.1 | `send-user-message formatText` 不可用 | 文档错误 | ❌ 待修复 |
| 🔴 P0 | 2.2 | 助理 `send-file` 需机器人能力 + 给第三方发文件无通道 | 文档错误 | ❌ 待修复 |
| 🟡 P1 | 3.1 | 缺少 API 权限/能力前置条件矩阵 | 文档缺失 | ❌ 待修复 |
| 🟡 P2 | 4.1 | 群解散操作应支持双身份路由 | 路径设计 | ❌ 待修复 |
| 🟢 P2 | 3.2 | formatText 无降级方案（→ text 兜底） | 文档缺失 | ❌ 待修复 |
| 🟢 P3 | 5.1 | 增加快速连通性检查命令 | 优化建议 | ❌ 待修复 |
| 🟢 P3 | 5.2 | 增加 pre-flight checklist | 优化建议 | ❌ 待修复 |

---

> 汇总日期：2026-07-24
> 汇总来源：skill-doc-issue-send-user-message.md、skill-fix-send-user-message.md、skill-analysis-20260724.md
> 涉及 Skill：lansenger-lanmate-messaging、lansenger-lanmate-group、lansenger-lanmate-shared
