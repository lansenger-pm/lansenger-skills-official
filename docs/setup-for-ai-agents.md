# 为 AI Agent 设置蓝信 CLI

## 概述

你（AI Agent，运行在 Claude Code / Codex / Cursor / OpenClaw / Hermes 等环境中）负责安装 `lansenger` CLI 并完成凭证配置。用户不需要手动粘贴 Token。

> **适用环境**：macOS / Linux 终端。Windows 请使用 WSL2。

---

## 错误策略

任何非零退出（`exit code != 0`）：
1. 将 stderr 输出原样呈现给用户
2. **停止**，不要重试

**例外**：下文标注了 **「覆盖停止规则」** 的步骤描述了恢复路径；其他所有错误一律停止。

---

## Step 1 — 安装

```bash
# 安装 CLI
pip install lansenger-cli

# 安装技能（Agent 需要技能才能正确使用 CLI）
npx -y skills add lansenger-pm/lansenger-skills-official -y
```

验证：

```bash
lansenger --version
```

备选 CLI（任选其一）：

```bash
# Go CLI
go install github.com/lansenger-pm/lansenger-sdk-go/cmd/lansenger@latest

# TypeScript CLI
npm install -g lansenger-cli
```

---

## Step 2 — 确认身份类型

蓝信有三种身份，不同身份的能力完全不同。问用户：

> 你想以什么身份使用蓝信 CLI？
>
> - **个人机器人** — 收发消息（含群聊）、上传下载文件。适合通知、简单问答。需要在蓝信桌面端获取凭证。
> - **蓝信应用** — 完整的组织应用能力：通讯录、日历、待办、OAuth2 授权、公号消息。需在开发者中心创建。
> - **蓝信应用 + 机器人** — 蓝信应用的全部能力 + 机器人消息通道（bot 私聊、群聊、群管理）。需在开发者中心创建并开启机器人能力。

映射：
- "个人机器人" → `IDENTITY=personal-bot`
- "蓝信应用" → `IDENTITY=org-app`
- "蓝信应用 + 机器人" → `IDENTITY=org-app-bot`

用户回答不明确 → 追问，不要猜。

**`IDENTITY` 一旦选定，本次会话内不可切换。** 如果后续发现能力不足需要升级，参照 [Step 7 — 恢复程序](#step-7--恢复程序)。

---

## Step 3 — 获取凭证

根据 `IDENTITY`，告诉用户如何获取 `appID` + `appSecret` + `api_gateway_url`：

| IDENTITY | 获取方式 |
|----------|---------|
| `personal-bot` | 蓝信桌面端 → 通讯录 → 智能机器人 → 个人机器人 → 点击 ℹ️ 图标。**界面上会直接显示 AppID、AppSecret 和 API Gateway 地址**，无需额外判断公有云/私有部署。手机端不显示凭证。 |
| `org-app` | 在蓝信开发者中心创建应用后获得 — 可能需要组织管理员审批。凭证和 API Gateway 地址均在开发者中心查看。 |
| `org-app-bot` | 在蓝信开发者中心创建应用并开启机器人能力后获得 — 与蓝信应用共用同一个 appID。API Gateway 地址同应用配置。 |

问用户索要 **appID**、**appSecret** 和 **API Gateway 地址**（如果非公有云默认地址）。用户提供后，继续 Step 4。

> **安全提醒**：appSecret 是敏感凭证。你收到后直接写入配置文件，不要在对话中回显 appSecret。

---

## Step 4 — 配置凭证

先检查是否已有相同 AppID 的 profile（避免覆盖已有的其他 Agent 配置）：

```bash
lansenger config list-profiles
```

**如果已有 profile 的 AppID 与用户提供的一致** → **覆盖停止规则**。告诉用户已存在 profile `xxx`，问是否复用。不要新建。

**如果没有** → 创建新 profile：

```bash
lansenger config set --profile "NAME" app_id APP_ID
lansenger config set --profile "NAME" app_secret APP_SECRET
```

`NAME` 建议用应用名或机器人名。如果用户的 `api_gateway_url` 非蓝信公有云默认地址，需配置网关：

```bash
lansenger config set --profile "NAME" api_gateway_url GATEWAY_URL
```

验证配置：

```bash
lansenger config show --profile "NAME"
```

---

## Step 5 — 验证凭证

用一个轻量命令触发 appToken 获取并验证凭证：

```bash
lansenger health check --profile "NAME"
```

- 成功 → 凭证有效，继续 Step 6
- 认证错误 → **覆盖停止规则**。让用户重新确认 appID 和 appSecret 是否正确
- 网络/超时错误 → **覆盖停止规则**。确认 `api_gateway_url` 是否正确

---

## Step 6 — 按需 OAuth2（仅 `org-app` / `org-app-bot`）

如果 `IDENTITY == personal-bot` → **跳过此步骤**，直接到 Step 8。个人机器人无法发起 OAuth2。

如果 `IDENTITY == org-app` 或 `org-app-bot`：

### 6a — 确认是否需要

问用户：

> 你需要以**用户身份**操作蓝信吗？（如：查看用户自己的日历、以用户身份发消息、查询通讯录）
>
> - 如果只需要应用/机器人身份操作 → 跳过 OAuth2
> - 如果需要以用户身份操作 → 需要 OAuth2 授权

不需要 → 跳到 Step 8。

### 6b — 配置 OAuth2 回调地址

问用户：

> 你的 OAuth2 回调地址（`redirect_uri`）想在本地还是用已配置的可信域名？
>
> - **本地回调（推荐）**：用 `http://localhost:8765`，CLI 自动启动本地服务器接收回调，完全自动化。但需在开发者中心把此地址加入可信域名（约 10 分钟生效）。
> - **已有可信域名**：用你已在开发者中心配置好的域名（如 `https://myapp.com/callback`）。授权后需手动从浏览器地址栏复制 `code` 参数。

根据用户选择设置 `redirect_uri`：

```bash
# 本地回调
lansenger config set --profile "NAME" redirect_uri http://localhost:8765

# 或已有可信域名
lansenger config set --profile "NAME" redirect_uri REDIRECT_URI
```

私有部署用户还需配置 `passport_url`（不同于 `api_gateway_url`）：

```bash
lansenger config set --profile "NAME" passport_url PASSPORT_URL
```

### 6c — 发起 OAuth2 授权

根据 6b 的选择走对应的流程：

#### 方式一：本地回调（`redirect_uri == http://localhost:8765`，推荐）

**CRITICAL — 必须在后台执行**，`local-callback` 会阻塞等待回调。

```bash
# 后台启动，输出重定向到临时文件（用于后续读取）
lansenger -j oauth local-callback --port 8765 --profile "NAME" > /tmp/lansenger_oauth_result.json 2>&1 &
```

**不要等它完成** — 立即读取输出提取 URL：

```bash
# 等待少量时间让 JSON 输出刷出
sleep 1
# 提取授权 URL
AUTH_URL=$(grep -o '"authorize_url":"[^"]*"' /tmp/lansenger_oauth_result.json | cut -d'"' -f4)
```

将 `AUTH_URL` 以 **Markdown 自动链接** 形式呈现给用户：`<AUTH_URL>`。

Agent 自动打开浏览器：

```bash
# macOS
open "$AUTH_URL"
# Linux
xdg-open "$AUTH_URL"
```

**等待用户确认已完成授权**。用户扫码授权后，`local-callback` 自动完成 token 兑换。检查后台进程是否已退出：

```bash
pgrep -f "lansenger.*local-callback"
# 无输出 = 已完成或超时
```

完成后跳到 6d。

#### 方式二：手动 code 兑换（有已有可信域名时）

Step 1 — 构建授权 URL：

```bash
lansenger -j oauth authorize-url --profile "NAME"
```

提取 `authorize_url`，以 Markdown 自动链接形式呈现给用户：`<AUTH_URL>`。Agent 自动打开浏览器。

Step 2 — **等待用户提供 code**：

用户授权后，浏览器会重定向到 `redirect_uri?code=XXX&state=YYY`。让用户从地址栏复制完整的 `code` 参数值（不含 &state= 部分）发给你。

> **redirect_uri 必须满足两个条件**：
> 1. **在开发者中心的可信域名列表中** — 否则授权直接拒绝
> 2. **不会自动跳转** — 如果重定向到一个会自跳转的页面（如首页），地址栏里的 `code` 会丢失。建议用可信域名下一个不存在的路径（如 `https://myapp.com/oauth/callback`），页面 404 但 `code` 保留在地址栏。

Step 3 — 兑换 token：

```bash
lansenger -j oauth exchange-code "CODE" --profile "NAME"
```

成功 → 继续 6d。失败 → 授权码有效期仅 5 分钟，重新执行方式二。

### 6d — 验证 OAuth2 状态

```bash
lansenger config show --profile "NAME"
```

检查 `user_token` 字段存在且非空 → OAuth2 成功。将 `staff_id` 记录下来，后续可通过 `--as staff_id` 以该用户身份操作。

失败 → **覆盖停止规则**。常见原因：
- 授权码过期（5 分钟有效）→ 重新执行 6c
- `redirect_uri` 未在开发者中心配置 → 确认可信域名配置

---

## Step 7 — 恢复程序（参考用，不是顺序步骤）

> 此步骤仅在后续使用中遇到能力不足时参考。正常流程从 Step 6 直接到 Step 8。

如果当前身份类型能力不足，用户**明确要求切换**时，按以下优先级处理：

1. `personal-bot` 想用通讯录/日历/OAuth2 → 必须升级为 `org-app` 或 `org-app-bot`。用户需在开发者中心创建应用。**新建 profile**，不要覆盖原有个人机器人 profile。
2. `org-app` 想发群聊/群管理 → 需在开发者中心开启机器人能力，升级为 `org-app-bot`。**同一 appID，复用现有 profile**，无需新建。
3. `org-app-bot` 想用公号消息 → 在开发者中心确认公号能力已启用。

切换身份后，重新从 Step 4 开始配置。

---

## Step 8 — 使用 `lansenger` 执行蓝信任务

配置完成。之后所有蓝信任务优先使用 `lansenger` CLI。**每次命令都必须带上 `--profile "NAME"`**，除非用户明确说用 default profile。用 `--help` 发现可用命令：

```bash
lansenger --help
lansenger message --help
lansenger staff --help
```

常用命令速查：

| 场景 | 命令 |
|------|------|
| 发文本消息 | `lansenger message send-text <chat_id> "<content>" --profile NAME` |
| 发群消息 | `lansenger message send-text <group_id> "<content>" --group --profile NAME` |
| 发 Markdown | `lansenger message send-markdown <chat_id> "<md>" --profile NAME` |
| 查员工 | `lansenger staff search <keyword> --profile NAME` |
| 查日历 | `lansenger calendar list-schedules --user-token <token> --profile NAME` |
| 上传文件 | `lansenger media upload <file_path> --profile NAME` |
| 撤消息 | `lansenger message revoke <msg_id> --profile NAME` |
| 查聊天列表 | `lansenger chat list --user-token <token> --profile NAME` |

> **身份能力提醒**：不是所有命令对所有身份类型都可用。遇到权限错误时，先查 [身份能力矩阵](../skills/lansenger-shared/SKILL.md#身份能力矩阵)。
