---
name: lansenger-suite
version: 1.0.0
description: "通过 lansenger CLI 操作蓝信：消息、群聊、通讯录、部门、日历、待办、流式消息、回调事件、OAuth等。"
metadata:
  category: "productivity"
  requires:
    bins: ["lansenger"]
---

# 蓝信全功能 Skill 模板

> **架构说明**：本项目采用「技能分发表」架构。根 skill (`SKILL.md`) 定义通用规则和分发表，各业务域为独立子 skill (`skills/lansenger-xxx/SKILL.md`)。
>
> 以下提供两种模板方案，根据需求选择：

---

## 方案一：多 Skill 分发表（推荐，当前架构）

### 根 Skill 模板（`SKILL.md`）

```yaml
---
name: lansenger
version: 1.0.0
description: "...触发条件：..."
metadata:
  requires:
    bins: ["lansenger"]
  cliHelp: "lansenger --help"
---

# 标题

## 安装 / 策略 / Help-First 原则 / 初始化

## 技能分发表

| 用户意图 | 加载技能 | 说明 |
|----------|----------|------|
| ... | `lansenger-xxx` | ... |

## 身份模型

## 推荐技能优先级

### 多技能并发加载优先级
...
```

### 子 Skill 模板

使用 [skill-template.md](skill-template.md)。

---

## 方案二：单文件 All-in-One（备选，适用于小型 CLI）

```yaml
---
name: lansenger-suite
version: 1.0.0
description: "..."
metadata:
  category: "productivity"
  requires:
    bins: ["lansenger"]
  cliHelp: "lansenger --help"
---

# 标题

你是 AI Agent，通过 lansenger CLI 命令操作蓝信资源。

{{shared_body}}

## 能力索引

{{domain_entries}}

## 命令探索

lansenger <domain> <command> [flags]
lansenger <domain> --help
lansenger --help
```

- `{{shared_body}}`：认证、安全、错误处理等通用规则（即 `lansenger-shared/SKILL.md` 的内容）
- `{{domain_entries}}`：各业务域的能力说明表，格式：`| 用户意图 | 域名 | 参考文档 |`
