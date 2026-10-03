# 2026-09-28 校历例外日期选择器越界修复报告（TASK-CALENDAR-DATE-01）

## 1. Root Cause

`CalendarExceptionPage._edit` 原来新增时直接把今天、编辑时直接把已有例外日期传给 DatePicker；
`firstDate` 与 `lastDate` 却按正在编辑的学期计算。历史学期的今天晚于末日，未来学期的今天早于首日；
已有例外也可能因学期设置变化落在范围外。Flutter 要求 `firstDate <= initialDate <= lastDate`，
越界时在打开入口就触发 assertion。修复前的 Widget 测试复现了 3 种越界路径。

## 2. Fix

新增时以本地今天的年月日为候选，编辑时以已有例外日期为候选。候选早于 `firstDate` 就取
`firstDate`，晚于 `lastDate` 就取 `lastDate`，范围内则保持原日期。直接比较现有边界，未用
`Duration(days: ...)` 重新推导夹取结果，也未引入 UTC 或新日期服务。

## 3. Date Range

原有范围完全保留：`firstDate = semester.firstWeekMonday - 30 天`；
`lastDate = semester.firstWeekMonday + (semester.totalWeeks * 7 + 30) 天`。
两个表达式只是提前赋给局部变量，传给 DatePicker 的值未变；各 Widget 测试逐项核对边界。
学期周数算法、SemesterService 与校历例外模型均未变。

## 4. Other DatePicker Audit

`lib` 下共有 3 处 `showDatePicker`：

| 调用点 | 审查结果 |
| --- | --- |
| `calendar_exception_page.dart` | 本轮修复；新增和编辑都夹取初始日期 |
| `onboarding_page.dart` | 初始日期来自当前周周一或现有 2026 年预设，当前运行日期在固定 2020–2040 范围内；若未来运行日期超过 2040 年，此固定边界也需另行处理 |
| `semester_settings_page.dart` | 初始日期是已保存的 `firstWeekMonday`，范围固定为 2020–2040。模型无此年份校验，若导入或历史数据保存了范围外日期，存在同类 assertion 风险；本轮仅报告，未改该页面或范围 |

`showTimePicker` 未审查或修改。

## 5. Files Changed

| 文件 | 目的 |
| --- | --- |
| `lib/features/settings/pages/calendar_exception_page.dart` | 仅夹取 DatePicker 的 initialDate |
| `test/calendar_exception_date_picker_test.dart` | 新增 5 个真实路由 Widget 测试 |
| `knowledge/current_state.md`、`knowledge/tasks.md` | 更新当前状态和任务记录 |
| `knowledge/testing.md`、`knowledge/changelog.md`、`knowledge/framework_school_calendar.md` | 同步验证结果与专题现状 |
| `knowledge/report_2026-09-28_calendar_date_01.md` | 本报告 |

此前工作区已有的导入修复及其他未提交文件均已保留。

## 6. Tests

- 此前任务执行记录的修复前基线：`flutter analyze --no-pub` 无问题、`flutter test --no-pub` **290/290** 通过。本轮接手时修复代码与 5 个新增测试已在工作区，故本轮开工即运行的是修复后套件 **295/295**，不能作为独立修复前基线。
- TASK 新增的 5 个 Widget 测试：当前学期今天、历史学期末日、未来学期首日、编辑合法原日期、编辑超范围原日期；全部核对 DatePickerDialog 的 `initialDate`、`firstDate` 和 `lastDate`。既有报告记录修复前历史、未来、越界旧日期共 3 例失败；本轮复跑全部 5 例通过。
- 修复前历史、未来、越界旧日期共 3 例失败；修复后定向 5/5，通过全量 **295/295**。

## 7. Validation

| 检查 | 结果 |
| --- | --- |
| `flutter analyze --no-pub` | 通过，无问题 |
| `flutter test --no-pub` | 295/295 通过 |
| `flutter build apk --debug --no-pub` | 通过，生成 `build/app/outputs/flutter-apk/app-debug.apk` |
| `git diff --check` | 通过 |

最终命令在 `S:\` 执行。首轮未切换到映射盘的 analyze 曾遇 analysis server LSP JSON 截断异常；在 `S:\` 重跑通过。真机、iOS 的 DatePicker 交互均 `UNVERIFIED`；未提交或推送。

## 8. Scope

未修改 `assets/adapters/*.js`、Bridge、`adapter_bridge.dart`、NavigationPolicy、WebView、
Drift schema、Course model、Import transaction、`importedCourseId`、Weekly、Today、Preview、
GlassMotion、Navigation、App icon、Android signing、SemesterService 或 DatePicker 视觉。
未新增 package；未开始 Preview/Motion 修复。
