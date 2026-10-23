# Zip 交付说明（发给用户前请先读这一节）

本技能套件以**本地 zip** 形式交付。zip 里装的是「说明书 + 安装脚本」，不是程序本体——`lansenger` CLI / SDK 是独立的 pip / npm / go 包，用户首次使用时由 agent 联网自动安装。

---

## 一、打包（你这边做一次）

- **zip 根目录 = 仓库根**：`SKILL.md` 必须在 zip 最上层（它是根调度器），下面依次是 `skills/`（15 个子技能）、`docs/`、`scripts/`、`README.md`、`manifest.json`。
- 打包命令（在仓库根执行）：

  ```bash
  cd lansenger-skills-official
  zip -r lansenger-skills-official.zip . -x '*.git*'
  ```

- **不要**把 `skills/` 单独打成顶层——agent 依赖根 `SKILL.md` 做总调度。

## 二、导入（用户这边做一次）

把 zip 解压到宿主 Agent 的技能目录，例如 Claude Code：

```bash
# 解压后应得到 .../skills/lansenger/SKILL.md
unzip lansenger-skills-official.zip -d ~/.claude/skills/lansenger/
```

其它宿主同理，解压到该宿主的 skills 目录即可。

## 三、发给用户的交付话术（可直接复制）

> 「解压这个 zip 到你的 agent 技能目录（如 `~/.claude/skills/lansenger/`）。首次使用时，agent 会读到 `SKILL.md` 的安装小节，自动运行 `scripts/setup.sh` 安装 `lansenger` 命令行工具（需联网）。
>
> **装完命令 ≠ 能直接用**：还需要配置一次应用凭证（appID / appSecret），否则发消息会失败。第一次让 agent 干活时，它会先向你确认身份类型并引导你完成凭证配置——把 appID / appSecret 准备好即可。

## 四、凭证（用户唯一必须手动的一步）

CLI 装好后，需运行 `lansenger config set` 配置应用凭证，**agent 首次调用时会引导，但凭证要用户自己提供**。完整流程见 [`setup-for-ai-agents.md`](setup-for-ai-agents.md) 的 Step 2–5（确认身份类型 → 获取凭证 → `config set` → `lansenger health` 自检）。

> ⚠️ 不配凭证就发消息，必然报认证错误。这是用户导入 zip 后最常见的困惑点，交付话术里务必点明。

## 五、可选：真·自动安装（hook）

默认情况下是「软自动」——agent 读 `SKILL.md` 发现 CLI 缺失时才跑 `setup.sh`。若要「每次开会话自动检测、缺了就装」，需在**用户项目根**配置 hook。

**关键：hook 配置不会随 zip 自动进用户项目**——`.claude/settings.json` 在项目根，而 zip 只解压到 `skills/` 子目录，技能包没有权限也没有机制去改项目根配置。所以这一步必须让用户**手动贴一次**。

在用户项目的 `.claude/settings.json` 加入：

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "command -v lansenger >/dev/null 2>&1 || pip install --quiet lansenger-cli >/dev/null 2>&1 || pipx install --quiet lansenger-cli >/dev/null 2>&1 || npm install -g --silent lansenger-cli >/dev/null 2>&1; true"
          }
        ]
      }
    ]
  }
}
```

命令自包含（先 `command -v` 探测，缺了依次 pip→pipx→npm 兜底，末尾 `; true` 保证任何失败都不阻塞会话），不依赖技能装在哪个目录。**这步是可选的**——不贴 hook，软自动也够用；想彻底省心才贴。
