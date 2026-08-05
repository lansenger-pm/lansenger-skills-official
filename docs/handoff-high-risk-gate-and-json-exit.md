# 交接文档：高风险操作门禁 + JSON 退出码修复（Skills 文档需同步）

> 本文档供负责维护蓝信技能库（`lansenger-skills-official`、`lanmate-lansenger-report` 等）的 Agent 处理。
> 背景：`lansenger-cli` 已落地"高风险操作门禁"和"JSON 模式退出码修复"两项 CLI 改动（对应 `docs/handoff-lark-skill-reference.md` 中的优先级 1、3）。
> Skills 侧需要同步文档，否则 Agent 按旧约定调用这些命令会卡在退出码 10。

---

## 一、CLI 改了什么（Skills Agent 需要知道的）

### 1. 高风险写操作新增 `--yes` 门禁

以下 7 个命令现在**默认不执行**，缺省调用会退出码 `10`，必须显式传 `--yes` 才会真正执行：

| 命令 | 文件位置 | 风险动作 |
|------|----------|----------|
| `message revoke` | `commands/message.py` | 撤回消息 |
| `group dismiss` | `commands/group.py` | 解散群 |
| `group update-members`（仅 `--remove` 时） | `commands/group.py` | 移除群成员（`--add` 不触发门禁） |
| `calendar delete-schedule` | `commands/calendar.py` | 删除日程 |
| `calendar delete-attendees` | `commands/calendar.py` | 删除参会人 |
| `todo delete` | `commands/todo.py` | 删除待办 |
| `todo delete-executors` | `commands/todo.py` | 删除执行人 |

每个命令新增两个参数：

- `--yes` / `-y`：确认执行高风险操作
- `--dry-run`：校验参数但不真正执行，输出"将要做什么"后退出 0

### 2. 退出码 10 的结构化信封

不带 `--yes` 调用上述命令时，**退出码 10**，并输出结构化 JSON（`--json` 模式写 stderr，文本模式写人话提示）。

`--json` 模式 stderr 内容：

```json
{
  "ok": false,
  "error": {
    "type": "confirmation_required",
    "message": "High-risk operation requires confirmation: dismiss group g1.",
    "hint": "add --yes to confirm and proceed.",
    "risk": {
      "level": "high-risk-write",
      "action": "dismiss group g1"
    }
  }
}
```

文本模式 stdout：

```
Confirmation required — dismiss group g1
Re-run with --yes to confirm and proceed.
```

### 3. `--dry-run` 的结构化信封

`--dry-run` 时退出码 0，不调用任何 API。`--json` 模式 stdout：

```json
{
  "ok": true,
  "dry_run": true,
  "would_perform": "dismiss group g1",
  "message": "Dry run: would dismiss group g1. No action taken."
}
```

### 4. JSON 模式失败退出码修复（顺带修的 bug）

之前 `--json` 模式下 API 调用失败也退出 0（直接 return），现在改为退出 1。这是 bug 修复，对脚本/Agent 判断更可靠。SKILL.md 里若已有"用 `success==true` 判断、不要用退出码"的经验记录，继续保持即可——但现在退出码也能正确反映成败了。

---

## 二、Skills Agent 要做的事

### 任务 1：更新受影响命令的 SKILL.md（必做）

以下技能文档里涉及上述 7 个命令的部分都要同步。核心是加一条**退出码 10 处理流程**，并补上 `--yes` / `--dry-run` 参数说明。

涉及技能（按参考实现路径，请按实际仓库结构调整）：

- `lansenger/skills/lansenger-messaging/SKILL.md` — `message revoke`
- `lansenger/skills/lansenger-group/SKILL.md` — `group dismiss`、`group update-members`
- `lansenger/skills/lansenger-calendar/SKILL.md` — `calendar delete-schedule`、`calendar delete-attendees`
- `lansenger/skills/lansenger-todo/SKILL.md` — `todo delete`、`todo delete-executors`

#### 建议加的文档段落（模板，可按各 SKILL.md 风格调整）

在涉及高风险命令的章节，加入类似下面的说明：

> **高风险操作确认流程**
>
> 以下命令默认不执行，调用后返回退出码 `10` + 结构化 JSON（`--json` 模式在 stderr）：
> - `group dismiss` / `group update-members --remove` / `message revoke`
> - `calendar delete-schedule` / `calendar delete-attendees`
> - `todo delete` / `todo delete-executors`
>
> **处理流程（MUST 遵守）：**
> 1. 调用命令（不带 `--yes`）
> 2. 若退出码 `10` 且 `error.type == "confirmation_required"`：向用户展示 `error.risk.action`（如"dismiss group g1"），用自然语言说明将要做什么
> 3. 用户明确同意后，追加 `--yes` 重新执行
> 4. **禁止**：看到退出码 10 就自动补 `--yes`，不经用户确认
>
> 可选 `--dry-run`：先校验参数、预览将执行的动作，再决定是否带 `--yes` 执行。适合在确认前先看一眼"要动什么"。
>
> **参数：**
> - `--yes` / `-y`：确认执行（高风险命令必需）
> - `--dry-run`：只校验不执行，退出 0

#### 关键原则（务必写进文档）

- **退出码 10 ≠ 失败**，是"待确认"。Agent 不应把它当错误上报，而是触发用户确认。
- **禁止自动 `--yes`**：这是整个门禁的意义，文档里要明确写"看到 exit 10 就默认加 `--yes`"是违规行为。
- `group update-members` 只有 `--remove` 触发门禁，`--add` 不需要 `--yes`——文档要区分清楚，避免 Agent 给纯加人操作也硬加 `--yes`。

### 任务 2：审查现有 SKILL.md 里的调用示例（必做）

搜索技能库里这 7 个命令的示例代码/CLI 调用片段，凡是直接调用、没带 `--yes` 的，都要补注说明"实际执行需 `--yes`"，或改为展示 `--dry-run` 优先的调用顺序。例如：

旧示例：
```
lansenger group dismiss g1
```

建议改成：
```
# 预览（退出 0，不执行）
lansenger group dismiss g1 --dry-run

# 用户确认后执行
lansenger group dismiss g1 --yes
```

### 任务 3（可选）：在 `lansenger-shared` 加一条通用规则

如果 `lansenger/skills/lansenger-shared/SKILL.md` 有"错误处理/退出码"章节，可加一条全局约定：

> 高风险写命令（`dismiss`/`revoke`/`delete*`/`update-members --remove` 等）使用退出码 `10` 表示"待用户确认"。Agent 应展示 `risk.action` 并等待用户同意后补 `--yes` 重试，**不得自动确认**。详见各命令 SKILL.md。

---

## 三、不需要 Skills 侧做的事

以下 CLI 层的改动**不涉及** Skills 文档，不用动：

- `+` 前缀 shortcut 命名（报告优先级 2）——**未采纳**，不实施。
- `{ok, data, meta}` 信封重命名——**未采纳**，JSON 输出结构不变，仍是各 Result 对象的 `to_dict()`（`success`/`message_id`/`error` 等）。现有解析逻辑无需改。
- `--jq` 参数——未实现。
- `LANSENGER_NO_UPDATE_NOTIFIER` 环境变量——CLI 无 notifier 逻辑，不适用。

也就是说：**Skills 现有的 JSON 解析方式（按 `success` 字段判断）全部继续有效**，本次只需处理退出码 10 / `--yes` / `--dry-run` 这一组新增行为。

---

## 四、验证方式

Skills Agent 改完文档后，可用以下命令快速验证 CLI 行为与文档描述一致（需先 `pip install -e .` 安装本仓库）：

```bash
# 1. 退出码 10 + 文本提示
lansenger group dismiss g1
echo "exit=$?"   # 应为 10

# 2. 退出码 10 + 结构化 JSON（stderr）
lansenger --json group dismiss g1 2>&1 1>/dev/null

# 3. dry-run 预览（退出 0，stdout）
lansenger --json group dismiss g1 --dry-run

# 4. --remove 条件门禁：add 不触发
lansenger group update-members g1 --add u1      # 正常执行（需凭证）
lansenger group update-members g1 --remove u1   # 退出 10
```

无凭证时门禁和 dry-run 也会正常返回（门禁在调用 API 前触发），可用于纯文档验证。

---

## 五、CLI 侧变更清单（供参考）

| 文件 | 改动 |
|------|------|
| `src/lansenger_cli/utils.py` | 新增 `EXIT_OK`/`EXIT_ERROR`/`EXIT_CONFIRM_REQUIRED` 常量、`confirm_high_risk()` 函数；修 `output_result` JSON 模式失败退出码 |
| `src/lansenger_cli/commands/message.py` | `revoke` 加 `--yes`/`--dry-run` |
| `src/lansenger_cli/commands/group.py` | `dismiss`、`update-members` 加 `--yes`/`--dry-run` |
| `src/lansenger_cli/commands/calendar.py` | `delete-schedule`、`delete-attendees` 加 `--yes`/`--dry-run` |
| `src/lansenger_cli/commands/todo.py` | `delete`、`delete-executors` 加 `--yes`/`--dry-run` |
| `tests/test_high_risk_gate.py` | 新增 12 个测试，覆盖门禁/dry-run/退出码 |

CLI 测试 `pytest -q` 全绿（21 passed）。版本号尚未 bump（当前 `0.11.0`），发版时由 CLI 侧处理。
