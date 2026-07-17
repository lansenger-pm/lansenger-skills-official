# 发版 Checklist

## 必须完成

### 版本号
- [ ] `SKILL.md`（根）版本号已升级
- [ ] `skill_manifest.json` 版本号与根 SKILL.md 一致
- [ ] 所有本次修改过的子技能 `skills/lansenger-*/SKILL.md` 版本号已升级（每次改动至少 +0.0.1）

### 多语言 README 同步
- [ ] `README.md`（英文）
- [ ] `README.zhHans.md`（简体中文）
- [ ] `README.zhHant.md`（繁体中文）
- [ ] `README.zhHantHK.md`（繁体中文-香港）
- [ ] `README.fr.md`（法文）

### 变更检查
- [ ] `git diff --stat` 确认变更范围正确
- [ ] `git diff` 确认变更内容无误，无意外改动
- [ ] 比较远程 `origin/main` 版本，确认无版本号回退或跳跃

### 提交推送
- [ ] 提交信息包含版本号（如 `docs: v1.9.2 — ...`）
- [ ] `git push` 到 `origin/main`

## 版本号规则

- 根 `SKILL.md` 和 `skill_manifest.json` 版本号始终一致
- 子技能版本号独立管理，哪张改哪张升
- 每次改动至少升末位（patch），功能新增升次位（minor）
- 版本号在提交前一次性修改，避免多次 commit 反复升版本

## 修改 external 技能时

- 修改 `lansenger-skills-official` 后，同步更新 `lansenger-skills-external`
- external 版本号独立管理（当前为 1.0.0，暂不联动）
- 两边 README 的修改需分别处理
