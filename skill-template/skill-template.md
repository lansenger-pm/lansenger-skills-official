---
name: lansenger-{{project}}
version: {{meta_version}}
description: "{{meta_description}}"
metadata:
  requires:
    bins: ["lansenger"]
  cliHelp: "lansenger {{service}} --help"
---

# {{service}} ({{version}})

**CRITICAL — 开始前 MUST 先用 Read 工具读取 [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md)，其中包含认证、权限处理**

{{introduction}}

## 核心概念

{{core_concepts}}

## CLI 命令

{{cli_commands}}

## 常见错误

| 错误 | 正确做法 |
|------|---------|
{{common_mistakes_rows}}

## 参数速查

| 命令 | 必需参数 | 关键可选参数 |
|------|---------|-------------|
{{param_table_rows}}