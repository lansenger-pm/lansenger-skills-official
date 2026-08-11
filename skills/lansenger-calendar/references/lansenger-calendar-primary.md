# lansenger calendar primary

## 前置条件

../../lansenger-shared/SKILL.md

## 描述

获取用户的主日历。返回日历 ID、名称、描述、权限以及用户角色。

## 命令示例

```bash
lansenger calendar primary --user-token "ut_xxx" --user-id "uid_xxx"
```

## 参数

| 参数 | 必填 | 描述 |
|---|---|---|
| --user-token | 否 | 用于认证的用户令牌 |
| --user-id | 否 | 用于认证的用户 ID |

## 返回值

```
calendar_id    : string   - 主日历 ID
summary        : string   - 日历标题
description    : string   - 日历描述
permissions    : string   - 日历权限
role           : string   - 用户在此日历上的角色
```

## 常见错误

- 同时传递 `--user-token` 和 `--user-id`，但实际只需一个。用户令牌或用户 ID 二者取其一即可；提供您的应用所使用的那个即可。
- 期望返回日历列表。此命令返回单个主日历对象，而非列表。
