---
name: lansenger-callback
version: 1.1.0
description: "蓝信回调事件解析：解析加密/明文回调数据、AES解密、验证签名、查看事件类型映射。当用户需要处理蓝信 Webhook 回调、解析或解密事件数据时使用。"
metadata:
  requires:
    bins: ["lansenger"]
  cliHelp: "lansenger callback --help"
---

# callback (v1.1)

**本技能继承 [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md) 的所有规则。** Shell 执行纪律、Help-First 原则、认证、权限处理等均在其定义，此处不复述。

## Reverse Handoff — 何时不用此技能

| 用户意图 | 正确技能 | 原因 |
|----------|----------|------|
| 回复回调中的消息 | `lansenger-messaging` | callback 只解析事件，不发送消息 |
| 配置 encoding_key | `lansenger config set` | 凭证配置见 shared |

**CRITICAL — 回调是纯数据处理（无 HTTP 调用），解析结果用于指导后续操作（如发消息回复），不要在回调解析中直接发送消息。**

## 核心概念

蓝信回调事件解析是纯数据侧操作——将 Webhook payload 解析为结构化事件对象。不涉及任何 HTTP 调用。

### 事件类型分类（25种事件 × 13个类别）

| 类别 | 事件类型 |
|------|---------|
| **bot** | bot_private_message, bot_group_message |
| **public_account** | account_message, account_subscribe, account_unsubscribe |
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
- **加密数据**：需要 `encoding_key` 解密（AES-256-CBC，key = Base64_Decode(encoding_key)，IV = key[:16]）
- **JSON 包含 dataEncrypt 字段**：自动提取加密值并解密

### 解密原理（4.10.1.4）

AES-256-CBC 解密后数据结构：`random(16B) + eventsLen(4B big-endian uint32) + orgId + appId + eventsJSON`

其中 `orgId` 和 `appId` 在解密缓冲区中是连续拼接的（无分隔符），`known_app_id` 参数用于帮助拆分两者。

### 签名验证原理（4.10.1.4）

签名算法：`sha1(sort(token, timestamp, nonce, dataEncrypt))`

- `token` = `callback_token`（如果提供），否则回退到 `encoding_key`
- `dataEncrypt` = 加密数据字符串（签名验证必需参数）

## CLI 命令

### 解析回调数据

```bash
# 解析明文 JSON 回调数据
lansenger callback parse-payload '{"appId":"xxx","orgId":"xxx","events":[...]}'

# 解析加密回调数据（需 encoding_key）
lansenger callback parse-payload "ENCRYPTED_DATA" --encoding-key "your_key"

# 解析加密数据，指定 known_app_id 以拆分 orgId/appId
lansenger callback parse-payload "ENCRYPTED_DATA" --encoding-key "your_key" --known-app-id "your_app_id"

# 解析并验证签名（使用 callback_token 作为签名 token）
lansenger callback parse-payload "ENCRYPTED_DATA" --encoding-key "key" --callback-token "your_token" --verify-sig --timestamp "1234567890" --nonce "abc" --signature "sig_value"

# 解析并验证签名（无 callback_token 时回退到 encoding_key）
lansenger callback parse-payload "ENCRYPTED_DATA" --encoding-key "key" --verify-sig --timestamp "1234567890" --nonce "abc" --signature "sig_value"

# JSON 输出
lansenger callback parse-payload '{"appId":"xxx","orgId":"xxx","events":[...]}' --json
```

### 解密回调数据

```bash
# 仅解密（不解析事件），查看原始 orgId/appId/events
lansenger callback decrypt-payload "ENCRYPTED_DATA" --encoding-key "your_key"

# 解密并指定 known_app_id 拆分 orgId/appId
lansenger callback decrypt-payload "ENCRYPTED_DATA" --encoding-key "your_key" --known-app-id "your_app_id"

# JSON 输出
lansenger callback decrypt-payload "ENCRYPTED_DATA" --encoding-key "your_key" --json
```

### 验证签名

```bash
# 验证签名（仅位置参数，encoding_key 同时作为 token 和 key）
lansenger callback verify-signature "1234567890" "nonce_value" "signature_value" "encoding_key"

# 验证签名（提供 data_encrypt 和 callback_token）
lansenger callback verify-signature "1234567890" "nonce_value" "signature_value" "encoding_key" --data-encrypt "encrypted_data_value" --callback-token "your_callback_token"

# JSON 输出
lansenger callback verify-signature "1234567890" "nonce_value" "signature_value" "encoding_key" --data-encrypt "encrypted_data_value" --json
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
| `encrypted_data` (位置参数) | str | — | 回调数据（明文 JSON、加密 dataEncrypt、或包含 dataEncrypt 的 JSON，必需） |
| `--encoding-key` | str | "" | Base64-encoded AES key，用于解密 |
| `--callback-token` | str | "" | 签名验证 token（来自开发者中心回调配置；未提供时回退到 encoding_key） |
| `--known-app-id` | str | "" | 已知 appId，帮助解密时拆分 orgId/appId |
| `--verify-sig` | bool | False | 是否验证签名 |
| `--timestamp` | str | "" | 签名验证的时间戳 |
| `--nonce` | str | "" | 签名验证的 nonce |
| `--signature` | str | "" | 要验证的签名值 |

### callback decrypt-payload

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `encrypted_data` (位置参数) | str | — | 加密 dataEncrypt 值（必需） |
| `--encoding-key` | str | — | Base64-encoded AES key（必需） |
| `--known-app-id` | str | "" | 已知 appId，帮助拆分 orgId/appId |

返回值包含：random, orgId, appId, events (list), length。

### callback verify-signature

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `timestamp` (位置参数) | str | — | 时间戳（必需） |
| `nonce` (位置参数) | str | — | nonce 值（必需） |
| `signature` (位置参数) | str | — | 签名值（必需） |
| `encoding_key` (位置参数) | str | — | encoding key（必需；未提供 callback-token 时同时用作签名 token） |
| `--data-encrypt` | str | "" | 加密数据值（签名计算中的 dataEncrypt 参数） |
| `--callback-token` | str | "" | 签名 token（来自开发者中心回调配置；未提供时回退到 encoding_key） |

### callback event-types

无参数。

## 常见错误

| 错误 | 正确做法 |
|------|---------|
| 在回调解析中直接发消息 | 回调是纯数据解析，回复消息需通过 `lansenger message` 命令 |
| 期望每次回调只有一个事件 | payload 可能包含多个事件（数组）或单个事件（对象） |
| 传入加密数据但不提供 encoding-key | 加密数据需提供 `--encoding-key` |
| 不验证签名就信任回调数据 | 建议使用 `--verify-sig` 验证签名真实性 |
| 签名验证不传 data-encrypt | 签名算法需要 dataEncrypt 值，需通过 `--data-encrypt` 传入 |
| 签名验证缺少 callback-token | 若开发者中心配置了回调 token，需通过 `--callback-token` 传入；否则回退到 encoding_key |
| 解密后 orgId/appId 混在一起 | 提供 `--known-app-id` 可帮助正确拆分 |
| 把回调当 API 调用 | 回调解析是本地数据处理，不发送 HTTP 请求 |