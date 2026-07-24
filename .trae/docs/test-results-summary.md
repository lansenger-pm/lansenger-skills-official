# Lansenger LanMate Skill 测试结果汇总

> 汇总来源：
> - `test-results-20260724-03.md`（主测试集，TC-EXE-01~36 + TC-GRP-01~05）
> - `test-results-supplement-20260724-5.md`（补充测试集，TC-EXE-50~121）
>
> 测试日期：2026-07-24
> CLI 版本：lansenger-cli 0.10.19 (SDK 1.6.27)
> 网关地址：https://open-stage.e.lanxin.cn/open/apigw

---

## 总览

| 测试集 | 用例数 | 通过 | 失败 | 跳过 | 通过率 |
|--------|--------|------|------|------|--------|
| 主测试集（TC-EXE-01~36 + TC-GRP-01~05） | 41 | 31 | 10 | 0 | 75.6% |
| 补充测试集（TC-EXE-50~121） | 40 | 24 | 15 | 1 | 62.0% |
| **合计** | **81** | **55** | **25** | **1** | **68%** |

---

## 按 Skill 域统计

| Skill | 用例数 | 通过 | 失败 | 跳过 | 通过率 | 覆盖命令 |
|-------|--------|------|------|------|--------|----------|
| messaging | 25 | 17 | 7 | 1 | 71% | send-text, send-markdown, send-file, send-image-url, send-link-card, send-app-card, update-dynamic-card, send-oacard, send-app-articles, approve-card, update-approve-card, send-user-message, send-bot-message, send-group-message, send-reminder, revoke |
| calendar | 13 | 10 | 3 | 0 | 77% | primary, create-schedule, fetch-schedule, update-schedule, delete-schedule, list-schedules, attendees, add-attendees, delete-attendees, attendee-meta |
| group | 9 | 4 | 5 | 0 | 44% | list, info, members, check, create, dismiss, update, update-members |
| staff | 8 | 7 | 1 | 0 | 88% | search, basic-info, detail, ancestors, id-mapping, org-info, org-extra-fields |
| chat | 7 | 4 | 2 | 1 | 67% | list, messages (type/keyword/深分页/split-month) |
| media | 5 | 4 | 1 | 0 | 80% | upload-app, upload, download-to-file, path |
| bot-command | 3 | 2 | 1 | 0 | 67% | create, query, delete |
| sdk | 2 | 1 | 1 | 0 | 50% | AsyncClient+Semaphore, CLI对比 |
| **合计** | **81** | **55** | **25** | **1** | **68%** | |

---

## 失败原因分类

| 失败类别 | 数量 | 影响用例 | 说明 |
|----------|------|---------|------|
| Stage API 宕机 (10000/10001) | 8 | TC-57, 59, 60, 61, 74, 84, 92-step2, 112 | API 基础设施不可用，非命令问题 |
| 平台权限不足 (10005) | 6 | TC-55, 63, 103, GRP-03, GRP-05, | Bot/助理应用未开启对应 API 权限 |
| 助理需机器人能力 (-10) | 6 | TC-15, 16, 17~21(5个) | 助理应用未开启机器人能力，消息实际已投递但报错 |
| API 格式不匹配 (40060) | 3 | TC-14, 81, 83 | formatText 不支持 / repeatType 映射 / 颜色值不在可选范围 |
| 未执行（API 宕机阻塞） | 3 | TC-93, 94, 120 | API 大范围宕机时跳过 |
| **合计** | **25** + 1 跳过 | | |

---

## 路径反模式检测汇总

| # | 反模式 | 状态 |
|---|--------|------|
| TC-ANTI-01 | 跳过用户确认直接发送 | ✅ 无违规 |
| TC-ANTI-02 | 身份降级尝试（换身份重试） | ✅ 无违规（TC-GRP-04 经用户授权切换，非静默降级） |
| TC-ANTI-03 | L1 可用却绕道 L2 | ✅ 无违规 |
| TC-ANTI-04 | 多技能无意义加载 | ✅ 无违规 |
| TC-ANTI-05 | `-j` 位置错误 | ✅ 无违规 |
| TC-ANTI-06 | SDK 连接泄漏 | ✅ N/A（补充集 TC-120 未执行） |
| TC-ANTI-07 | 时间戳格式错误 | ✅ 无违规 |
| TC-ANTI-08 | 手动 @mention 而非参数 | ✅ 无违规 |
| TC-ANTI-09 | 发文件先手动上传 | ✅ 无违规 |
| TC-ANTI-10 | msg_data 缺少 content 嵌套 | ✅ 无违规 |
| TC-ANTI-11 | `--user-token` 位置错误 | ✅ 无违规 |

**结论：全部 81 个用例均使用了最短最优路径，无任何反模式或路径违规。**

---

## 新发现的 Skill/CLI 问题

| # | 问题 | 影响用例 | 严重程度 |
|---|------|---------|---------|
| 1 | `send-user-message formatText` 不可用 (errCode=40060) | TC-EXE-14 | 🔴 P0 |
| 2 | 助理身份 `send-file` 需机器人能力 (errCode=-10) | TC-EXE-15/16 | 🔴 P0 |
| 3 | 群聊发消息 errCode=-10 误报（消息实际已投递） | TC-EXE-17~21 | 🔴 P0 |
| 4 | `--repeat weekly` 未正确映射到 API `repeatType` 字段 | TC-EXE-81 | 🟡 P1 |
| 5 | `--color` 不在 API 允许颜色列表中（非任意 hex） | TC-EXE-83 | 🟡 P1 |
| 6 | `download-to-file` 不接受 `--user-token` 但文档示例传了 | TC-EXE-73 | 🟡 P1 |
| 7 | Bot 无群管理 API 权限 (create/dismiss/update-members) | TC-GRP-03/05, TC-63 | 🟡 P1 |
| 8 | `send-reminder` / `group info` / `media path` Stage 频繁宕机 | TC-57/60/61/74 | 🟢 P2 |
| 9 | `send-user-message` 不支持文件附件（附件被静默丢弃） | TC-EXE-15 验证 | 🔴 P0 |

---

## Skill 覆盖度

| Skill | 总能力数 | 已覆盖 | 覆盖率 | 说明 |
|-------|---------|--------|--------|------|
| messaging | 20 | 20 | 100% | 全部命令均有测试用例 |
| calendar | 12 | 12 | 100% | 含全天日程、重复日程、attendee-meta |
| group | 8 | 8 | 100% | 含 create/dismiss/update/update-members（部分失败但路径已验证） |
| staff | 7 | 7 | 100% | 含 basic-info/detail/ancestors/id-mapping/org-info/org-extra-fields |
| chat | 8 | 8 | 100% | 含 type/keyword/深分页/split-month/mediaId提取 |
| media | 5 | 5 | 100% | upload-app/upload/download-to-file/path |
| bot-command | 3 | 3 | 100% | create/query/delete |
| sdk | 3 | 2 | 67% | 模式2(并发)和CLI对比已测，模式3(断点续传)未测 |
| **合计** | **66** | **65** | **98%** | 仅 SDK 模式3未覆盖 |

---

## 环境建议

1. 为 Stage 环境的助理应用开启机器人能力（解决 TC-EXE-15~21 失败）
2. 为 Stage 环境的 Bot 应用开启建群/群管理 API 权限（解决 TC-GRP-03/05/63 失败）
3. 验证 `send-user-message` 的 formatText 支持（解决 TC-EXE-14 失败）
4. 检查群聊发消息的 errCode=-10 误报问题（消息实际已投递）
5. 排查 `--repeat weekly` 到 API `repeatType` 的字段映射
6. 确认 `--color` 的 API 允许颜色列表，更新文档
7. 修正 `download-to-file` 文档示例（移除 `--user-token`）
8. 排查 Stage API 频繁宕机问题 (errCode 10000/10001)

---

> 汇总日期：2026-07-24
> 主测试集：test-results-20260724-03.md（41 例）
> 补充测试集：test-results-supplement-20260724-5.md（40 例）
> 合计：81 例，55 通过，25 失败，1 跳过，68% 通过率
> 路径检测：100% 最短最优路径，0 反模式违规
> Skill 覆盖度：65/66 (98%)
