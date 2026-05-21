---
name: lansenger-callback
version: 1.0.0
description: "蓝信回调事件解析：解析加密/明文回调数据、验证签名、查看事件类型映射。当用户需要处理蓝信 Webhook 回调、解析事件数据时使用。"
metadata:
  requires:
    bins: ["lansenger"]
  cliHelp: "lansenger callback --help"
---

# callback (v1)

**CRITICAL — 开始前 MUST 先用 Read 工具读取 [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md），其中包含认证、权限处理、安全规则。**

**CRITICAL — 回调是纯数据处理（无 HTTP 调用），解析结果用于指导后续操作（如发消息回复），不要在回调解析中直接发送消息。**

## 核心概念

蓝信回调事件解析是纯数据侧操作——将 Webhook payload 解析为结构化事件对象。不涉及任何 HTTP 调用。

### 事件类型分类（24种事件 × 13个类别）

| 类别 | 事件类型 |
|------|---------|
| **bot** | bot_private_message, bot_group_message |
| **public_account** | account_subscribe, account_unsubscribe |
| **staff** | staff_info, staff_modify, staff_create, staff_delete |
| **department** | dept_modify, dept_create, dept_delete |
| **group** | group_create_approve |
| **tag** | tag_member |
| **app** | app_install_org, app_uninstall_org |
| **notification** | telephone_track |
| **certificate** | ua_cert_create, ua_cert_delete |
| **location** | report_location |
| **auth** | user_logout |
| **data_scope** | data_scope |
| **workbench** | wb_visible_config |
| **calendar** | schedule_modify, schedule_delete |

### Payload 格式

回调 payload 可能是：
- **明文 JSON**：直接传入即可解析
- **加密数据**：需要 encoding_key 解密（当前 CLI 依赖 SDK 解密能力）

### 签名验证

蓝信在回调 HTTP 请求中附带 timestamp、nonce、signature 参数，用于验证请求来源的真实性。

## CLI 命令

### 解析回调数据

```bash
# 解析明文 JSON 回调数据
lansenger callback parse-payload '{"appId":"xxx","orgId":"xxx","events":[...]}'

# 解析加密回调数据（需 encoding_key）
lansenger callback parse-payload "ENCRYPTED_DATA" --encoding-key "your_key"

# 解析并验证签名
lansenger callback parse-payload "ENCRYPTED_DATA" --encoding-key "key" --verify-sig --timestamp "1234567890" --nonce "abc" --signature "sig_value"

# JSON 输出
lansenger callback parse-payload '{"appId":"xxx","orgId":"xxx","events":[...]}' --json
```

### 验证签名

```bash
# 验证回调请求签名是否有效
lansenger callback verify-signature "1234567890" "nonce_value" "signature_value" "encoding_key"
```

### 查看事件类型映射

```bash
# 列出所有回调事件类型及其所属类别
lansenger callback event-types

# JSON 输出
lansenger callback event-types --json
```

## 参数说明

### callback parse-payload

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `encrypted_data` (位置参数) | str | — | 回调数据（明文 JSON 或加密数据，必需） |
| `--encoding-key` | str | "" | 解密用的 encoding key |
| `--verify-sig` | bool | False | 是否验证签名 |
| `--timestamp` | str | "" | 签名验证的时间戳 |
| `--nonce` | str | "" | 签名验证的 nonce |
| `--signature` | str | "" | 要验证的签名值 |

### callback verify-signature

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `timestamp` (位置参数) | str | — | 时间戳（必需） |
| `nonce` (位置参数) | str | — | nonce 值（必需） |
| `signature` (位置参数) | str | — | 签名值（必需） |
| `encoding_key` (位置参数) | str | — | encoding key（必需） |

### callback event-types

无参数。

## 常见错误

| 错误 | 正确做法 |
|------|---------|
| 在回调解析中直接发消息 | 回调是纯数据解析，回复消息需通过 `lansenger message` 命令 |
| 期望每次回调只有一个事件 | payload 可能包含多个事件（数组）或单个事件（对象） |
| 传入加密数据但不提供 encoding-key | 加密数据需提供 `--encoding-key` |
| 不验证签名就信任回调数据 | 建议使用 `--verify-sig` 验证签名真实性 |
| 把回调当 API 调用 | 回调解析是本地数据处理，不发送 HTTP 请求 |