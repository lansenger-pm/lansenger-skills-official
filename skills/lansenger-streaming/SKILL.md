---
name: lansenger-streaming
version: 1.0.0
description: "蓝信流式消息（AI Agent 实时推送）：创建流式消息会话、获取流式消息状态。当 AI Agent 需要实现打字式渐进输出时使用。"
metadata:
  requires:
    bins: ["lansenger"]
  cliHelp: "lansenger streaming --help"
---

# streaming (v1)

**CRITICAL — 开始前 MUST 先用 Read 工具读取 [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md），其中包含认证、权限处理、安全规则。**

**CRITICAL — receiver_type 只支持 "single"（私聊）或 "group"（群聊），不要使用 "user" 或其他值。每个流式会话必须使用唯一的 stream_id。**

## 核心概念

蓝信流式消息 API 为 AI Agent 提供"打字中..."渐进输出体验。这是发送消息的辅助机制——先创建流式占位符，再发送最终内容。

### 流式消息工作流程

1. 用户发消息给机器人（通过回调接收）
2. 机器人调用 `create` → 在用户聊天中创建"打字中..."占位符
3. AI 生成回复内容（渐进式）
4. 机器人发送最终消息（通过 `lansenger message send-text` 等命令）
5. "打字中..."状态自动消解

### receiver_type 取值

| receiver_type | 说明 |
|---------------|------|
| `single` | 私聊（发给单个用户） |
| `group` | 群聊（发到群里） |

### stream_id

每次流式会话需要唯一标识符。建议使用 UUID 或业务唯一 ID（如 `ai-reply-{uuid}`）。

## CLI 命令

### 创建流式消息

```bash
# 创建私聊流式消息
lansenger streaming create staff123 single "ai-reply-abc123"

# 创建群聊流式消息
lansenger streaming create group456 group "ai-reply-def456"

# JSON 输出
lansenger streaming create staff123 single "ai-reply-abc123" --json
```

### 获取流式消息状态

```bash
# 查看流式消息状态
lansenger streaming fetch msg123

# JSON 输出
lansenger streaming fetch msg123 --json
```

## 参数说明

### streaming create

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `receiver_id` (位置参数) | str | — | 接收者 ID（用户 staffId 或群 openId，必需） |
| `receiver_type` (位置参数) | str | — | 接收者类型：single 或 group（必需） |
| `stream_id` (位置参数) | str | — | 流式会话唯一标识（必需） |

### streaming fetch

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `msg_id` (位置参数) | str | — | 流式消息 ID（create 返回的 message_id，必需） |

## 常见错误

| 错误 | 正确做法 |
|------|---------|
| receiver_type 用 "user" | 只支持 "single" 或 "group" |
| stream_id 不唯一 | 每次流式会话必须使用新的唯一 stream_id |
| 流式消息代替最终消息 | 流式消息只是占位符，最终内容需通过 `lansenger message send-text` 发送 |
| 不传 receiver_id 位置参数 | receiver_id 是必需位置参数 |