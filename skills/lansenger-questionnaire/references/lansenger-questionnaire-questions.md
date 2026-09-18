# lansenger questionnaire save-questions

题目 JSON 结构完整说明（`questionnaire save-questions --questions` 与 SDK `save_questionnaire_questions(code, question_list)`）。

## 前置条件

../../lansenger-shared/SKILL.md

## 描述

`question_list` 是一个 JSON 数组，每个元素是一道题目的 camelCase dict。所有题目必填三字段：`questionName`、`questionType`、`requiredFlag`；其余字段按题型选填。单选（radio）、多选（checkbox）、图片投票（picturesVote）、打分题（multiScore）必须提供 `questionOptionList`。

## 参数

| 参数 | 必填 | 描述 |
|------|------|------|
| questionName | 是 | 题目名称 |
| questionType | 是 | 题型（16 种，见下表） |
| requiredFlag | 是 | 1=必答 0=选答 |
| code | 否 | 题目编码（修改时携带） |
| questionDesc / questionDescFlag | 否 | 题干描述及开关（1=是 0=关闭） |
| questionSortOrder | 否 | 排序号（1-999） |
| questionOptionList | 按题型 | 选项数组（结构见下） |
| radioStyle | radio | 1=普通单选 2=下拉单选 |
| selectType / selectMin / selectMax | checkbox | 选择类型 1单选 2多选 / 最少 0不限 / 最多 0不限 |
| fillblankSubType | fillblank | text（默认）/ number / letter / chinese / mail / phone / idCardNo / bankCarkNo |
| wordLimit | fillblank | 字数上限（默认 100） |
| inputPrint | 填空类 | 输入提示 |
| autoFill | name/phone/email/sex/age 等 | 1=自动填入 0=否 |
| addressType | address | 1=详细地址 2=区县 3=城市 4=省份（city 题型必填） |
| uploadLimit / uploadSize | picturesUpload/filesUpload | 最大上传数量 1-9 / 单文件大小 1-100（MB） |
| multiScoreSetting | multiScore | JSON 对象：minScore/maxScore/scoreIconStyle/notUseFlag/leftTip/midTip/rightTip |
| fillblankSubSetting | fillblank(number) | JSON 对象：numberSetting{pointLimit/minValue/maxValue/numberUnit} |

## questionType 题型（16 种）

| questionType | 说明 | 特有字段 |
|--------------|------|---------|
| radio | 单选 | radioStyle、questionOptionList |
| checkbox | 多选 | selectType/selectMin/selectMax、questionOptionList |
| picturesVote | 图片投票 | questionOptionList（optionResourceId） |
| fillblank | 填空 | fillblankSubType、wordLimit、inputPrint、fillblankSubSetting |
| multiScore | 打分 | questionOptionList（minScore/maxScore）、multiScoreSetting |
| name / phone / email / sex / age / dateTime | 基本信息类 | autoFill |
| date | 日期 | — |
| address | 城市 | addressType |
| remark | 备注 | wordLimit、inputPrint |
| picturesUpload / filesUpload | 上传 | uploadLimit、uploadSize |

## questionOptionList 选项结构

| 参数 | 必填 | 描述 |
|------|------|------|
| optionName | 是 | 选项内容 |
| optionOrder | 否 | 排序号 |
| optionResourceId | 否 | 选项资源 ID（图片投票） |
| minScore / maxScore | 打分题 | 最小/最大分值 |
| notUseFlag | 否 | 1=不适用 0=适用（默认适用） |
| noteFlag / noteRequiredFlag / noteContent | 否 | 带说明标识 / 说明必填 / 说明内容 |

## 命令示例

```bash
# 单选题（两个选项，第二项带说明）
lansenger questionnaire save-questions QN001 --questions '[
  {"questionName":"您对当前工作环境是否满意？","questionType":"radio","requiredFlag":1,
   "questionOptionList":[
     {"optionName":"非常满意","optionOrder":1},
     {"optionName":"一般","optionOrder":2,"noteFlag":1,"noteRequiredFlag":1}]}]'

# 填空题（数字类型，限 3 位小数）
lansenger questionnaire save-questions QN001 --questions '[
  {"questionName":"您每天的通勤时长（小时）？","questionType":"fillblank","requiredFlag":0,
   "fillblankSubType":"number","fillblankSubSetting":{"numberSetting":{"pointLimit":3,"minValue":0,"maxValue":24}}}]'

# 打分题
lansenger questionnaire save-questions QN001 --questions '[
  {"questionName":"请为本期培训打分","questionType":"multiScore","requiredFlag":1,
   "multiScoreSetting":{"minScore":1,"maxScore":5},
   "questionOptionList":[
     {"optionName":"课程内容","minScore":1,"maxScore":5,"optionOrder":1},
     {"optionName":"讲师水平","minScore":1,"maxScore":5,"optionOrder":2}]}]'
```

## 返回值

`saved_count`：本次保存的题目数量（Integer）。

## CRITICAL — 结构透传

题目 dict 由 SDK **原样透传**给服务端（camelCase），SDK 不做字段改名或校验。字段拼错不会报参数错误，而是被静默忽略——构造后务必用 `questionnaire detail` 回读确认。

## 重要注意事项

- 新增题目不传 `code`；修改题目必须携带原 `code`。
- 题目顺序由 `questionSortOrder` 决定，建议显式传 1..n。
- 进行中（status=2）的问卷不可改题，先 `questionnaire withdraw` 撤回为草稿。
- 选项资源（图片投票）需先经 `questionnaire upload-url` 两步上传取得 resourceId。

## 常见错误

- 用 snake_case（question_name）代替 camelCase（questionName）→ 字段被服务端忽略，题目缺必填项报错。
- radio 题忘记 `questionOptionList` → 服务端报错。
- `requiredFlag` 传字符串 `"1"` → 应传数字 1。
