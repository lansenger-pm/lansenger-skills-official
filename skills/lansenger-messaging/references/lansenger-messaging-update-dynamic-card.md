# lansenger message update-dynamic-card

更新先前发送的动态应用卡片消息。

**继承** [`../../lansenger-shared/SKILL.md`](../../lansenger-shared/SKILL.md) 中的所有规则（Shell 规范、帮助优先、认证、权限）。

**安全提醒：** 修改已发送卡片前务必与用户确认更新内容。动态卡片更新会改变所有收到原始卡片的收件人可见的内容。

**重要：** 此命令仅对通过 `send-app-card` 以 `--dynamic` 标志原始发送的卡片生效。

## 参数

| 参数 | 类型 | 必填 | 描述 |
|-----------|------|----------|-------------|
| msg_id | arg | 是 | 要更新的原始动态卡片的消息 ID |
| --last | flag | 否 | 标记为最后一次更新（卡片变为静态，不允许进一步更新） |
| --status-desc | option | 否 | 更新后的状态描述文本 |
| --status-colour | option | 否 | 更新后的状态颜色（如 green, red, grey） |
| --link | option | 否 | 更新后的链接条目 JSON 列表（name/URL 对） |

## 示例

```bash
lansenger message update-dynamic-card msg_abc123 --status-desc "Completed" --status-colour green

lansenger message update-dynamic-card msg_abc123 --status-desc "Failed" --status-colour red --last

lansenger message update-dynamic-card msg_abc123 --link '[{"name":"View Result","url":"https://app.example.com/result"}]'

lansenger message update-dynamic-card msg_abc123 --status-desc "In Review" --status-colour grey --link '[{"name":"Details","url":"https://app.example.com/details"},{"name":"History","url":"https://app.example.com/history"}]'
```

> **key=value 格式**：`--link` 参数支持 key=value 简写格式，避免命令行传 JSON 的引号问题：
> - `--link "View Result=https://app.example.com/result"` 代替 `--link '{"name":"View Result","url":"https://app.example.com/result"}'`
> - 同时兼容旧 JSON 格式，json.loads() 失败时自动尝试 key=value 解析

> **Windows PowerShell 注意**：推荐使用 key=value 格式。如需传 JSON，PowerShell 下须用双引号包裹整个参数值，内部双引号用反引号 `` ` `` 转义：
> ```powershell
> lansenger message send-app-card user_123 "Report" --field "[{`"name`":`"Status`",`"value`":`"Done`"}]"
> ```

## 常见错误

- 尝试更新未以 `--dynamic` 发送的卡片 — 只有动态卡片才能更新。
- 计划稍后再次更新却使用了 `--last` — 使用 `--last` 之后不允许进一步更新。
- 将 `--link` 作为普通字符串而非 JSON 传递 — 必须是有效的 JSON 数组。
- 未保存 `send-app-card` 返回的原始 msg_id — 调用此命令时需要它。

## 返回值

返回更新确认信息：

```json
{
  "msg_id": "msg_abc123",
  "updated": true
}
```
