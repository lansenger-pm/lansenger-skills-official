[English](README.md) | [简体中文](README.zhHans.md) | [繁体中文](README.zhHant.md) | [繁体中文（香港）](README.zhHantHK.md) | [Français](README.fr.md)

# lansenger-skills-official

蓝信 CLI 的 AI Agent Skills — 为 Python、Go 和 TypeScript CLI 提供结构化 Markdown Skill 文档，涵盖消息、日历、群组、联系人、部门、待办、流式消息、回调、OAuth 等。

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-1.7.0-blue)](https://github.com/lansenger-pm/lansenger-skills-official)

## 什么是 Skills？

Skills 是结构化的 Markdown 文档，用于教会 AI Agent 如何使用 `lansenger` CLI。每个 Skill 覆盖一个业务领域（消息、日历、群组等），包含：

- **核心概念**和术语
- **CLI 命令参考**，含参数和示例
- **关键约束**，防止 Agent 出错
- **常见错误**表格
- **详细参考文档**，用于复杂操作

## 快速安装

### 方法 1 — `npx skills`（推荐）

最快的安装方式。支持 **OpenCode**、**Claude Code**、**Cursor**、**Codex**、**Cline** 及 [50+ 其他 Agent](https://github.com/vercel-labs/skills#supported-agents)。

```bash
# 安装所有 Skills 到所有检测到的 Agent（交互式）
npx skills add lansenger-pm/lansenger-skills-official

# 安装到指定 Agent（例如 opencode）
npx skills add lansenger-pm/lansenger-skills-official -a opencode

# 全局安装到 Claude Code
npx skills add lansenger-pm/lansenger-skills-official -a claude-code -g

# 安装到多个 Agent
npx skills add lansenger-pm/lansenger-skills-official -a opencode -a claude-code -a cursor

# 只安装指定的 Skills
npx skills add lansenger-pm/lansenger-skills-official --skill lansenger-messaging --skill lansenger-calendar

# 安装前查看可用 Skills 列表
npx skills add lansenger-pm/lansenger-skills-official --list

# 非交互式 / CI 友好
npx skills add lansenger-pm/lansenger-skills-official --all -y
```

### 方法 2 — opencode `.opencode/skills/`

对于 **opencode** 用户，复制或符号链接 `skills/` 目录：

```bash
# 符号链接（推荐 — 单一来源，便于更新）
ln -s $(pwd)/skills ~/.config/opencode/skills/lansenger-skills-official

# 或复制
cp -r skills ~/.config/opencode/skills/lansenger-skills-official
```

### 方法 3 — Claude Code `.claude/skills/`

```bash
# 符号链接到 Claude Code 的 skills 目录
ln -s $(pwd)/skills .claude/skills/lansenger-skills-official

# 全局安装
ln -s $(pwd)/skills ~/.claude/skills/lansenger-skills-official
```

### 方法 4 — 手动安装（任意 Agent）

克隆此仓库，然后让 Agent 指向 `skills/` 目录：

```bash
git clone https://github.com/lansenger-pm/lansenger-skills-official.git
# 然后指示 Agent 先读取 skill_manifest.json，
# 再根据用户需求读取相关的 SKILL.md 文件。
```

### 方法 5 — `.agents/skills/`（通用路径）

许多 Agent（Amp、Cline、Codex、Cursor、Gemini CLI 等）共享 `.agents/skills/` 作为标准路径：

```bash
ln -s $(pwd)/skills .agents/skills/lansenger-skills-official
```

## 更新 Skills

```bash
# 如果通过 npx skills 安装
npx skills update lansenger-skills-official

# 如果使用符号链接 — 只需 git pull
cd lansenger-skills-official && git pull
```

## 目录结构

```
SKILL.md                                  # 根调度器 + 安装指南
README*.md                                # 人类可读文档
skills/
  lansenger-shared/SKILL.md              # 共享规则（认证、配置、安全、错误处理）
  lansenger-messaging/SKILL.md           # 消息策略 + references/
  lansenger-chat/SKILL.md               # 聊天读取 API
  lansenger-group/SKILL.md              # 群组管理
  lansenger-staff/SKILL.md              # 联系人与员工
  lansenger-department/SKILL.md         # 部门层级
  lansenger-calendar/SKILL.md           # 日历与日程 + references/
  lansenger-todo/SKILL.md               # 统一待办
  lansenger-oauth/SKILL.md              # OAuth2 用户认证
  lansenger-streaming/SKILL.md          # 流式消息（AI-Agent SSE）
  lansenger-callback/SKILL.md           # 回调事件与 Webhook
  lansenger-media/SKILL.md              # 媒体文件上传/下载
skill_manifest.json                      # 所有 Skills 的索引
skill-template/                          # 创建新 Skill 的模板
```

## Skills 索引

| Skill | 说明 |
|-------|------|
| `lansenger-shared` | 认证、配置、错误处理、安全规则（其他 Skill 自动加载） |
| `lansenger-messaging` | 4 种消息通道、消息类型矩阵、@提及规则、提醒、CLI 方法选择 |
| `lansenger-chat` | 获取聊天列表（私聊 + 群聊）并拉取对话消息；`--split-month`、`--progress`、`plain_text()` SDK 辅助函数 |
| `lansenger-group` | 创建群组、获取信息/成员、列出群组、检查成员关系、更新设置、解散群 |
| `lansenger-staff` | 获取员工信息、ID 映射（手机/邮箱→staffId）、组织扩展字段、搜索 |
| `lansenger-department` | 浏览组织层级、获取部门详情/子部门、列出部门员工 |
| `lansenger-calendar` | 主日历、日程 CRUD、参会人管理、参会人元数据 |
| `lansenger-todo` | 创建、更新、查询、删除待办任务，管理执行人，状态统计 |
| `lansenger-oauth` | OAuth2 用户认证流程、授权 URL、Code 交换、Token 刷新、`local-callback` 命令、UserTokenManager 自动刷新 |
| `lansenger-streaming` | 基于 SSE 的 AI Agent 实时消息推送 |
| `lansenger-callback` | 25 种事件类型、结构化解析、AES 解密、签名验证 |
| `lansenger-media` | 上传/下载文件、图片、视频、音频，获取媒体路径 |

## CLI 兼容性

**推荐**：Python SDK 和 CLI。Go 和 TypeScript 作为备选。

```bash
# Python CLI（推荐）
pip install lansenger-cli
pip install lansenger-sdk  # 编程调用时安装
lansenger message send-text staff123 "Hello"

# Go CLI（备选）
go install github.com/lansenger-pm/lansenger-sdk-go/cmd/lansenger@latest
lansenger message send-text staff123 "Hello"

# TypeScript CLI（备选）
npm install -g lansenger-cli
lansenger message send-text staff123 "Hello"
```

三个 CLI 共享相同的命令结构、参数名称和输出格式，因此一套 Skills 即可同时服务三者。需要 Python SDK v1.5+ 及 CLI v0.10+。

## 多应用 / 多机器人配置

CLI 支持多个配置档案（每个对应一个 appID），凭证按 appID 隔离存储在 `~/.lansenger/sdk_state.json`（0600 权限）。详见 `lansenger-shared/SKILL.md`：

### 凭证字段

| 字段 | 是否必填 | 适用场景 | 环境变量 |
|------|----------|----------|----------|
| `app_id` | **必填** | 所有 API 调用 | `LANSENGER_APP_ID` |
| `app_secret` | **必填** | 所有 API 调用 | `LANSENGER_APP_SECRET` |
| `api_gateway_url` | **必填** | API 网关地址（私有部署需修改） | `LANSENGER_API_GATEWAY_URL` |
| `passport_url` | 需 OAuth2 时填 | OAuth2 授权页地址（私有部署需修改） | `LANSENGER_PASSPORT_URL` |
| `redirect_uri` | 需 OAuth2 时填 | OAuth2 回调地址（需在蓝信开发者中心配置为可信域名，含协议头和端口号；CLI 默认 http://localhost:8765 也需配置，约10分钟生效） | `LANSENGER_REDIRECT_URI` |
| `encoding_key` | 需接收回调时填 | 回调数据 AES 解密密钥（Base64 编码） | `LANSENGER_ENCODING_KEY` |
| `callback_token` | 需接收回调时填 | 回调签名验证 token（未填时回退到 encoding_key） | `LANSENGER_CALLBACK_TOKEN` |

```bash
# 基本凭证（所有用户必填）
lansenger config set app_id YOUR_APP_ID
lansenger config set app_secret YOUR_APP_SECRET
# api_gateway_url 默认为蓝信公有云地址，私有部署需手动设置
# lansenger config set api_gateway_url YOUR_PRIVATE_GATEWAY_URL

# OAuth2 用户认证（私有部署需手动设置 passport_url）
# lansenger config set passport_url YOUR_PRIVATE_PASSPORT_URL

# 回调接收（需要解析/验签回调 Webhook 时填写）
lansenger config set encoding_key YOUR_ENCODING_KEY
lansenger config set callback_token YOUR_CALLBACK_TOKEN

# 按档案名配置多个应用
lansenger config set app_id xxx1 --profile "my-bot"
lansenger config set app_id xxx2 --profile "my-app"
lansenger config set encoding_key yyy2 --profile "my-app"   # 此应用需要接收回调

# 通过 --profile 切换身份
lansenger message send-text staff123 "Hello" --profile "my-bot"
lansenger callback parse-payload DATA --profile "my-app"
```

## 贡献

创建新 Skill 时，请参考 `skill-template/` 目录中的模板。

## 许可证

MIT