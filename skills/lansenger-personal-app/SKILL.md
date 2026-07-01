---
name: lansenger-personal-app
version: 1.0.0
description: "个人应用/个人机器人管理（4.38）：创建、更新、查询、删除个人应用（即个人机器人）。当用户需要创建自己的个人机器人时使用。"
metadata:
  requires:
    bins: ["lansenger"]
  cliHelp: "lansenger personal-app --help"
---

# personal-app

**本技能继承 [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md) 的所有规则。** Shell 执行纪律、Help-First 原则、认证、权限处理等均在其定义，此处不复述。

**CRITICAL — 所有个人应用/机器人操作均需要通过 OAuth2 获取的 userToken。**

## 什么是个人应用/个人机器人

个人应用（4.38版本），也称为个人机器人，是由用户自行创建的机器人账号。用户可以通过 API 动态创建和管理自己的机器人，用于个人自动化、智能助手等场景。

- **API 层面**：称为"个人应用"，对应 CLI 命令 `personal-app`
- **用户视角**：实际创建的是"个人机器人"，可以像普通机器人一样发送消息、接收指令

### 个人应用/机器人 vs 组织应用/机器人

| | 个人应用/机器人 | 组织应用/机器人 |
|---|---|---|
| 创建者 | 用户本人 | 组织管理员 |
| 创建方式 | API动态创建 | 开发者中心手动创建 |
| 凭证管理 | 用户自行管理 | 组织统一管理 |
| 适用场景 | 个人自动化、轻量助手 | 企业级应用、正式机器人 |

## CLI 命令速查

### 创建个人应用/机器人

```bash
# 创建基本个人应用/机器人
lansenger personal-app create --user-token "ut1" --name "我的机器人" --desc "个人助手"

# 创建个人应用/机器人（带头像）
lansenger personal-app create --user-token "ut1" --name "智能助手" --avatar-id "media123" --desc "AI智能助手"
```

### 更新个人应用/机器人

```bash
# 更新个人应用/机器人名称和描述
lansenger personal-app update app123 "新名称" --user-token "ut1" --desc "新描述"

# 更新个人应用/机器人头像
lansenger personal-app update app123 "名称不变" --user-token "ut1" --avatar-id "new_avatar_media_id"
```

### 查询个人应用/机器人信息

```bash
# 查询个人应用/机器人详情
lansenger personal-app info app123 --user-token "ut1"

# JSON 输出
lansenger -j personal-app info app123 --user-token "ut1"
```

### 删除个人应用/机器人

```bash
# 删除个人应用/机器人
lansenger personal-app delete app123 --user-token "ut1"
```

### 列出个人应用/机器人

```bash
# 列出所有个人应用/机器人
lansenger personal-app list --user-token "ut1"

# JSON 输出
lansenger -j personal-app list --user-token "ut1"
```

## 参数说明

### create 参数

| 参数 | 说明 | 必填 |
|------|------|------|
| `--user-token` | 用户token（OAuth2获取） | ✓ |
| `--name` | 应用/机器人名称 | ✓ |
| `--avatar-id` | 头像 mediaId | ✗ |
| `--desc` | 应用/机器人描述 | ✗ |

### update 参数

| 参数 | 说明 | 必填 |
|------|------|------|
| `app_id` | 应用/机器人ID（位置参数） | ✓ |
| `name` | 新应用/机器人名称（位置参数） | ✓ |
| `--user-token` | 用户token | ✓ |
| `--avatar-id` | 新头像 mediaId | ✗ |
| `--desc` | 新应用/机器人描述 | ✗ |

### info 参数

| 参数 | 说明 | 必填 |
|------|------|------|
| `app_id` | 应用/机器人ID（位置参数） | ✓ |
| `--user-token` | 用户token | ✓ |

### delete 参数

| 参数 | 说明 | 必填 |
|------|------|------|
| `app_id` | 应用/机器人ID（位置参数） | ✓ |
| `--user-token` | 用户token | ✓ |

### list 参数

| 参数 | 说明 | 必填 |
|------|------|------|
| `--user-token` | 用户token | ✓ |

## 返回字段说明

创建个人应用/机器人成功后返回以下字段：

| 字段 | 说明 |
|------|------|
| `app_id` | 应用/机器人ID |
| `secret` | 应用/机器人密钥（需妥善保管） |
| `apigw_addr` | API网关地址 |
| `passport_addr` | 通行证地址 |

## 常见错误

| 错误 | 原因 | 解决方案 |
|------|------|---------|
| `需要userToken` | 未传入--user-token | 通过OAuth2获取userToken后传入 |
| `权限不足` | 用户没有创建个人应用/机器人的权限 | 联系组织管理员开通权限 |
| `应用/机器人不存在` | app_id不正确 | 检查应用/机器人ID是否正确 |
| `头像上传失败` | avatar_id无效 | 先通过media upload上传图片获取mediaId |

## 注意事项

- 个人应用/机器人的 `secret` 仅在创建时返回一次，后续无法查询，请妥善保管
- 个人应用/机器人创建后可以独立使用，拥有完整的机器人能力
- 删除个人应用/机器人后无法恢复，请谨慎操作
