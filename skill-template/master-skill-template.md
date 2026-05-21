---
name: lansenger-suite
version: 1.0.0
description: "通过 lansenger CLI 操作蓝信：消息、群聊、通讯录、部门、日历、待办、流式消息、回调事件、OAuth等。"
metadata:
  category: "productivity"
  requires:
    bins: ["lansenger"]
---

# 蓝信全功能 Skill

你是 AI Agent，通过 lansenger CLI 命令操作蓝信资源。下方是认证和通用规则，具体域的用法见「能力索引」中的 references 文档。

{{shared_body}}

## 能力索引

根据用户需求，必须读取对应业务域的详细文档来学习明确的可用能力与使用方式。

{{domain_entries}}

## 命令探索

```bash
lansenger <domain> <command> [flags]   # 调用命令
lansenger <domain> --help               # 列出可用命令
lansenger --help                        # 探索更多能力
```