[English](README.md) | [简体中文](README.zhHans.md) | [繁体中文](README.zhHant.md) | [繁体中文（香港）](README.zhHantHK.md) | [Français](README.fr.md)

# lansenger-skills-official

Lansenger CLI 的 AI Agent Skills — 結構化 Markdown Skills 文件，適用於 Python、Go 及 TypeScript CLI，涵蓋訊息、行事曆、群組、聯絡人、部門、待辦事項、串流訊息、回呼事件、OAuth 等。

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 甚麼是 Skills？

Skills 是結構化 Markdown 文件，教導 AI Agent 如何使用 `lansenger` CLI。每個 Skill 涵蓋一個業務領域（訊息、行事曆、群組等），包含：

- **核心概念**及術語
- **CLI 命令參考**，含參數及範例
- **CRITICAL 限制**，防止 Agent 出錯
- **常見錯誤**對照表
- **詳細參考文件**，用於複雜操作

## 快速安裝

### 方法一 — `npx skills`（推薦）

最快的安裝方式。支援 **OpenCode**、**Claude Code**、**Cursor**、**Codex**、**Cline** 及 [50+ 其他 Agent](https://github.com/vercel-labs/skills#supported-agents)。

```bash
# 安裝所有 Skills 至所有已偵測的 Agent（互動式）
npx skills add lansenger-pm/lansenger-skills-official

# 安裝至指定 Agent（例如 opencode）
npx skills add lansenger-pm/lansenger-skills-official -a opencode

# 全域安裝至 Claude Code
npx skills add lansenger-pm/lansenger-skills-official -a claude-code -g

# 安裝至多個 Agent
npx skills add lansenger-pm/lansenger-skills-official -a opencode -a claude-code -a cursor

# 只安裝指定 Skills
npx skills add lansenger-pm/lansenger-skills-official --skill lansenger-messaging --skill lansenger-calendar

# 安裝前先列出可用的 Skills
npx skills add lansenger-pm/lansenger-skills-official --list

# 非互動式 / CI 適用
npx skills add lansenger-pm/lansenger-skills-official --all -y
```

### 方法二 — opencode `.opencode/skills/`

適用於 **opencode** 用戶，複製或建立符號連結至 `skills/` 目錄：

```bash
# 符號連結（推薦 — 單一來源，方便更新）
ln -s $(pwd)/skills ~/.config/opencode/skills/lansenger-skills-official

# 或直接複製
cp -r skills ~/.config/opencode/skills/lansenger-skills-official
```

### 方法三 — Claude Code `.claude/skills/`

```bash
# 建立符號連結至 Claude Code 的 skills 目錄
ln -s $(pwd)/skills .claude/skills/lansenger-skills-official

# 全域安裝
ln -s $(pwd)/skills ~/.claude/skills/lansenger-skills-official
```

### 方法四 — 手動（任何 Agent）

複製此儲存庫並將 Agent 指向 `skills/` 目錄：

```bash
git clone https://github.com/lansenger-pm/lansenger-skills-official.git
# 然後指示你的 Agent 先閱讀 skill_manifest.json，
# 再根據用戶需要讀取相關的 SKILL.md 文件。
```

### 方法五 — `.agents/skills/`（通用路徑）

許多 Agent（Amp、Cline、Codex、Cursor、Gemini CLI 等）共用 `.agents/skills/` 作為標準路徑：

```bash
ln -s $(pwd)/skills .agents/skills/lansenger-skills-official
```

## 更新 Skills

```bash
# 如經 npx skills 安裝
npx skills update lansenger-skills-official

# 如使用符號連結 — 只需 git pull
cd lansenger-skills-official && git pull
```

## 結構

```
skills/
  lansenger-shared/SKILL.md              # 共用規則（認證、設定、安全、錯誤處理）
  lansenger-messaging/SKILL.md           # 訊息策略 + references/
  lansenger-chat/SKILL.md               # 聯絡對話讀取 API
  lansenger-group/SKILL.md              # 群組管理
  lansenger-staff/SKILL.md              # 聯絡人及員工
  lansenger-department/SKILL.md         # 部門架構
  lansenger-calendar/SKILL.md           # 行事曆及日程 + references/
  lansenger-todo/SKILL.md               # 統一待辦事項
  lansenger-oauth/SKILL.md              # OAuth2 用戶認證
  lansenger-streaming/SKILL.md          # 串流訊息（AI-Agent SSE）
  lansenger-callback/SKILL.md           # 回呼事件及 webhook
  lansenger-media/SKILL.md              # 媒體檔案上傳/下載
skill_manifest.json                      # 所有 Skills 的索引
skill-template/                          # 建立新 Skills 的範本
```

## Skills 索引

| Skill | 描述 |
|-------|------|
| `lansenger-shared` | 認證、設定、錯誤處理、安全規則（由其他所有 Skill 自動載入） |
| `lansenger-messaging` | 4 個訊息頻道、訊息類型對照表、@提及規則、提醒、CLI 方法選擇 |
| `lansenger-chat` | 讀取聯絡對話列表（私聊 + 群組）及從對話中拉取訊息；`--split-month`、`--progress`、`plain_text()` SDK 輔助函式 |
| `lansenger-group` | 建立群組、讀取資訊/成員、列出群組、檢查成員資格、更新設定、解散群 |
| `lansenger-staff` | 讀取員工資訊、ID 映射（電話/電郵→staffId）、組織額外欄位、搜尋 |
| `lansenger-department` | 瀏覽組織架構、讀取部門詳情/子部門、列出部門員工 |
| `lansenger-calendar` | 主要行事曆、日程 CRUD、與會者管理、與會者元資料 |
| `lansenger-todo` | 建立、更新、查詢、刪除待辦事項、管理執行人、狀態計數 |
| `lansenger-oauth` | OAuth2 用戶認證流程、授權 URL、code 交換、憑證刷新、`local-callback` 命令、UserTokenManager 自動刷新 |
| `lansenger-streaming` | SSE 即時訊息傳遞，適用於 AI Agent |
| `lansenger-callback` | 25 種事件類型、結構化解析、AES 解密、簽名驗證 |
| `lansenger-media` | 上傳/下載檔案、圖片、影片、音訊，取得媒體路徑 |

## CLI 相容性

**推薦**：Python SDK 和 CLI。Go 和 TypeScript 作為備選。

```bash
# Python CLI（推薦）
pip install lansenger-cli
pip install lansenger-sdk  # 程式設計呼叫時安裝
lansenger message send-text staff123 "Hello"

# Go CLI（備選）
go install github.com/lansenger-pm/lansenger-sdk-go/cmd/lansenger@latest
lansenger message send-text staff123 "Hello"

# TypeScript CLI（備選）
npm install -g lansenger-cli
lansenger message send-text staff123 "Hello"
```

三個 CLI 共用相同的命令結構、參數名稱及輸出格式，因此一套 Skills 即可同時適用。需要 Python SDK v1.5+ 及 CLI v0.10+。

## 多應用 / 多機械人設定

CLI 支援多個設定檔（每個對應一個 appID），憑證按 appID 隔離儲存在 `~/.lansenger/sdk_state.json`（0600 權限）。詳見 `lansenger-shared/SKILL.md`：

### 憑證欄位

|欄位 | 是否必填 | 適用場景 | 環境變數 |
|------|----------|----------|----------|
| `app_id` | **必填** | 所有 API 請求 | `LANSENGER_APP_ID` |
| `app_secret` | **必填** | 所有 API 請求 | `LANSENGER_APP_SECRET` |
| `api_gateway_url` | **必填** | API 網關地址（私有部署需修改） | `LANSENGER_API_GATEWAY_URL` |
| `passport_url` | 需 OAuth2 時填 | OAuth2 授權頁地址（私有部署需修改） | `LANSENGER_PASSPORT_URL` |
| `redirect_uri` | 需 OAuth2 時填 | OAuth2 回呼地址（需在藍信開發者中心配置為可信域名，含協議頭和端口號；CLI 預設 http://localhost:8765 也需配置，約10分鐘生效） | `LANSENGER_REDIRECT_URI` |
| `encoding_key` | 霈接收回呼時填 | 回呼資料 AES 解密密鑰（Base64 編碼） | `LANSENGER_ENCODING_KEY` |
| `callback_token` | 霈接收回呼時填 | 回呼簽名驗證 token（未填時回退到 encoding_key） | `LANSENGER_CALLBACK_TOKEN` |

```bash
# 基本憑證（所有用戶必填）
lansenger config set app_id YOUR_APP_ID
lansenger config set app_secret YOUR_APP_SECRET
# api_gateway_url 預設為藍信公有雲地址，私有部署需手動設定
# lansenger config set api_gateway_url YOUR_PRIVATE_GATEWAY_URL

# OAuth2 用戶認證（私有部署需手動設定 passport_url）
# lansenger config set passport_url YOUR_PRIVATE_PASSPORT_URL

# 回呼接收（需要解析/驗簽回呼 Webhook 時填寫）
lansenger config set encoding_key YOUR_ENCODING_KEY
lansenger config set callback_token YOUR_CALLBACK_TOKEN

# 按設定檔名稱設定多個應用
lansenger config set app_id xxx1 --profile "my-bot"
lansenger config set app_id xxx2 --profile "my-app"
lansenger config set encoding_key yyy2 --profile "my-app"

# 透過 --profile 切換身份
lansenger message send-text staff123 "Hello" --profile "my-bot"
lansenger callback parse-payload DATA --profile "my-app"
```

## 參與貢獻

建立新 Skills 时请参考 `skill-template/` 目錄中的範本。

## 授權

MIT