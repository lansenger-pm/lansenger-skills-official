---
name: lansenger-bot-command
version: 1.0.2
description: "机器人指令管理（4.37）：创建、查询、删除机器人指令。当用户需要管理机器人指令时使用。"
metadata:
  requires:
    bins: ["lansenger"]
  cliHelp: "lansenger bot-command --help"
---

# bot-command

**本技能继承 [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md) 的所有规则。** Shell 执行纪律、Help-First 原则、认证、权限处理等均在其定义，此处不复述。

**CRITICAL — 机器人指令仅对有机器人能力的应用可用。**

## 什么是机器人指令

机器人指令是蓝信机器人的命令菜单系统（4.37版本），用户可以在聊天窗口通过输入命令名来触发机器人执行特定操作。

### 指令作用域

| scope_type | 说明 | 参数要求 |
|------------|------|----------|
| 1 | 单群单人 | --chat-id, --chat-type, --staff-id |
| 2 | 单群管理员 | --chat-id, --chat-type |
| 3 | 单聊 | --chat-id, --chat-type |
| 4 | 所有群管理员 | 无 |
| 5 | 所有群 | 无 |
| 6 | 所有私聊 | 无 |
| 7 | 全局 | 无 |

## CLI 命令速查

### 创建机器人指令

```bash
# 创建全局指令
lansenger bot-command create 7 '[{"command":"add","description":"添加成员","icon":"icon_url"},{"command":"list","description":"列出成员"}]'

# 创建单群指令（scope=2，仅群管理员可见）
lansenger bot-command create 2 '[{"command":"admin","description":"管理设置"}]' --chat-id group123 --chat-type group

# 创建单聊指令（scope=3）
lansenger bot-command create 3 '[{"command":"help","description":"帮助"}]' --chat-id staff123 --chat-type staff

# 创建单群单人指令（scope=1）
lansenger bot-command create 1 '[{"command":"personal","description":"个人设置"}]' --chat-id group123 --chat-type group --staff-id staff123
```

### 查询机器人指令

```bash
# 查询全局指令
lansenger bot-command query 7

# 查询单群指令
lansenger bot-command query 2 --chat-id group123 --chat-type group

# 查询单聊指令
lansenger bot-command query 3 --chat-id staff123 --chat-type staff

# JSON 输出
lansenger -j bot-command query 7
```

### 删除机器人指令

```bash
# 删除全局指令
lansenger bot-command delete 7

# 删除单群指令
lansenger bot-command delete 2 --chat-id group123 --chat-type group

# 删除单聊指令
lansenger bot-command delete 3 --chat-id staff123 --chat-type staff
```

## 指令格式说明

每个指令对象包含以下字段：

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `command` | string | ✓ | 指令名称，仅支持字母、数字、下划线，**不允许以斜杠 / 开头**，长度1-64 |
| `description` | string | ✓ | 指令描述 |
| `icon` | string | ✗ | 指令图标 URL |

## 常见错误

| 错误 | 原因 | 解决方案 |
|------|------|---------|
| `权限不足` | 应用没有机器人能力 | 确认应用已开启机器人能力 |
| `参数错误` | scope_type 与参数不匹配 | 检查 scope_type 对应的参数是否齐全 |
| `指令已存在` | 同一作用域下指令名称重复 | 修改指令名称后重新创建 |
| `命令格式错误` | command 包含非法字符或以斜杠 / 开头 | 仅使用字母、数字、下划线，**不要加斜杠前缀** |

## SDK 用法

当需要批量管理机器人指令时，用 SDK 替代逐条 CLI 调用。详见 `../lansenger-sdk/SKILL.md`。

### 核心方法

```python
from lansenger_sdk import LansengerClient

client = LansengerClient.from_store(profile="default")

# 创建指令
result = await client.create_bot_commands(commands=[{"command": "help", "description": "帮助"}])

# 查询指令
result = await client.fetch_bot_commands()

# 删除指令
result = await client.delete_bot_commands(command_ids=["cmd1", "cmd2"])
```
