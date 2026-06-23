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
pip install lansenger-cli
```

验证：

```bash
lansenger --version
```

备选安装方式（任选其一）：

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

先确认 `redirect_uri` 已配置：

```bash
lansenger config show --profile "NAME"
```

如果没有 `redirect_uri`，设置默认值：

```bash
lansenger config set --profile "NAME" redirect_uri http://localhost:8765
```

> `http://localhost:8765` 需在蓝信开发者中心配置为可信域名（含协议头和端口），约 10 分钟生效。

私有部署用户还需配置 `passport_url`（不同于 `api_gateway_url`）：

```bash
lansenger config set --profile "NAME" passport_url PASSPORT_URL
```

### 6c — 发起 OAuth2 授权

```bash
lansenger oauth authorize --profile "NAME"
```

CLI 会：
1. 在终端输出授权 URL
2. 启动本地回调服务器（`http://localhost:8765`）
3. 自动用浏览器打开授权页面

将授权 URL 以 **Markdown 自动链接** 形式呈现给用户：`<URL>`。角度括号保留 URL 原样并渲染为可点击链接。

> **不要在 Agent 自己的沙箱浏览器中打开 URL** — Agent 的浏览器无法完成用户授权。

**等待用户确认已完成授权**。不要提前执行下一步 — 用户还没点击，会阻塞直到超时。

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

配置完成。之后所有蓝信任务优先使用 `lansenger` CLI。用 `--help` 发现可用命令：

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
