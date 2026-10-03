# 框架报告 — 学校 / 学期 / 作息 / 校历

## Last Updated

2026-10-03 +08:00 ｜ TASK-RELEASE-100 正式版学校切换入口

`CONFIRMED`：学校管理修改网址输入框由 TextField State 管理控制器，onChanged 记录文本，保存前检查 mounted；退出动画期间不提前释放资源（ISSUE-020）。6项 Widget 回归通过；真机/iOS未复测。按最新需求恢复添加学校入口，导入可更换学校；新建或切换回导入确认，保留原档案数据，切换同步URL/清同意。专项7/7与代码复审通过。

兼容覆盖升级导入旧学期/课程/自定义作息，使用ncpu档案学校，adapterId=auto；按旧日期倒序规则选当前学期。学期名称保存为legacy_semester_name元数据，当前学期选择UI未新增名称显示。见TASK-LEGACY-UPGRADE-01报告。

证据来源：2026-09-28 只读代码调研（模型字段、派生计算、变体匹配、五个设置页逐项核对）。

---

## 1. 边界

**负责**：学校档案与预置、学期锚点与周次派生、作息（节次时间）与教室变体、校历例外（停课/调休）的语义与录入、以及承载这些的五个设置页。

**不负责**：这些数据的表结构与写路径实现（→ `framework_data.md`）、内置学校的教务地址与适配（→ `framework_import.md`）、周课表渲染（→ `framework_motion.md` / `framework_glass.md`）。

---

## 2. 关键文件与入口

| 角色 | 文件 | 说明 |
| --- | --- | --- |
| 内置学校档案（唯一） | `lib/features/schools/services/school_presets.dart` | 目前 **1 所**（南工） |
| 学校模型 | `lib/models/school_profile.dart` | `SchoolProfile` |
| 学期模型 | `lib/models/semester.dart` | `Semester` |
| 作息模型 | `lib/models/bell_schedule.dart` | `SectionSpec` / `SectionGroup` / `ScheduleVariant` / `BellSchedule` |
| 课程模型 | `lib/models/course.dart` | `Course` / `CourseSource` |
| 校历例外模型 | `lib/models/calendar_exception.dart` | `CalendarException` / `CalendarExceptionKind` |
| 学期派生（唯一） | `lib/services/semester_service.dart` | `currentWeek` / `weekMonday` / `termStatus` / `readingProgress` / `dateFor` |
| 校历派生（唯一） | `lib/services/calendar_exception_service.dart` | `forDate` / `resolve` / `weekdayName` |
| 课程时间（唯一） | `lib/services/course_time_service.dart` | `resolve` / `formatRange` / `sectionRangeLabel` |
| 节数解析 | `lib/services/section_count_resolver.dart` | `resolve` |
| 周次文本解析 | `lib/services/week_parser.dart` | `parseWeeks` / `formatWeeks` / `WeekParseException` |
| 设置页 | `lib/features/settings/pages/` 5 个文件 | 见 §7 |
| 引导（建校） | `lib/features/onboarding/pages/onboarding_page.dart` | 建校 + 建学期 |

---

## 3. 内置学校档案

`CONFIRMED`：内置学校档案只有 **1 所** —— `ncpuPreset` 南昌工学院（`school_presets.dart:29-39`）。

| 字段 | 值 |
| --- | --- |
| `id` | `'ncpu'` |
| `displayName` | 南昌工学院 |
| `defaultFirstWeekMonday` | `DateTime(2026, 8, 31)`（`:33`） |
| `defaultTotalWeeks` | `20`（`:34`） |
| `defaultLoginUrl` | `http://218.204.129.252:8088/jwglxt/xtgl/login_slogin.html`（`:38`） |
| `bell` | 南工官方 10 节 + 1 个变体（见 §5） |

`SchoolPreset` 字段只有 `id / displayName / bell / defaultFirstWeekMonday / defaultTotalWeeks / defaultLoginUrl`（`:8-27`）—— **不含 adapterId、acceptedHosts、scheduleVariants**：
- `adapterId` 在建校时决定：有 URL → `'auto'`，否则 `''`（`onboarding_page.dart:290`）
- `acceptedHosts` = `[URL.host]`（`:273-283`）
- `scheduleVariants` 由 `preset.bell.variants` 序列化写入 `schools.scheduleVariantsJson`（`school_repository.dart:29,40-42`）

**登录地址禁改备注**（`:35-37`）：不得改回 `http://jwxt.ncpu.edu.cn`，该域名只剩 IPv6 且超时（2026-09-14 复核）。

**其他学校**一律走通用兜底作息 + 用户可改 + 导入适配器可整体替换，**代码不做猜测**（`:3-7`）。

## 4. 模型字段与不变量

| 模型 | 字段 | 约束事实 |
| --- | --- | --- |
| `SchoolProfile`（`school_profile.dart:8-41`） | `id`、`displayName`、`adapterId`（`''`=手动，`:23`）、`presetId = ''`（`:14,27`）、`loginUrl`、`acceptedHosts`、`scheduleVariants = const []`（`:16,30`）、`createdAt` | **无 assert / clamp**；`confirmedHost` getter（`:37-40`）在 lib 内**无调用点**；注释 `:5-7` 声明不含校历与作息 |
| `Semester`（`semester.dart:1-22`） | `id`、`schoolId`、`firstWeekMonday`、`totalWeeks` 全必填 | **无校验**；`totalWeeks` 1..30 只在 UI 限制（`semester_settings_page.dart:90,113`、`onboarding_page.dart:163,181`）；注释 `:12` 声明「第 1 教学周的周一是全部周次唯一锚点」；`copyWith`（`:16`）在 lib 与 test 内**均无调用点** |
| `Course`（`course.dart:10-78`） | 必填 `id/schoolId/semesterId/name/weekday/startSection/endSection/weeks`；默认 `colorKey=0`、`teacher=''`、`classroom=''`、`startTime/endTime: String?`、`note=''`、`source=manual` | 无 assert；`copyWith` 用 `??` 语义 → **无法把 startTime/endTime 置回 null**（`:45-77`）；`courseSourceFromString`（`:7`）无调用点 |
| `BellSchedule`（`bell_schedule.dart:87-196`） | `sections` 必填、`variants = const []` | 无 assert；`groupByPeriod()`（`:140`）在 lib 内无调用点（仅测试用）；`sectionGroupFromString`（`:5`）无调用点 |
| `CalendarException`（`calendar_exception.dart:14-38`） | `id/schoolId/semesterId/date/kind` 必填、`makeupWeekday: int?`、`note=''` | 无构造校验；`date` 只取年月日（`:29`）、`makeupWeekday` 1..7（`:34`）、「同一天只保留一条（由写路径保证）」（`:13`）；clamp 在仓库（`calendar_exception_repository.dart:29`） |

## 5. 作息

### 结构

- `SectionSpec`：`index`（1 起算，`:25`）、`start`/`end`（`String`）、`group`（`SectionGroup`），全 required（`:17-30`）
- `SectionGroup`：`morning` / `afternoon` / `evening`（`:3`）；`sectionGroupName` → 上午/下午/晚上（`:11-15`）
- `ScheduleVariant`：`id`、`keywords: List<String>`、`overrides: Map<int,(String,String)>`（节次→起止），全 required（`:36-47`），含 toJson/fromJson（`:57-79`）

### 教室变体匹配（`matchesClassroom`，原文规则 `:49-55`）

```
if (classroom == null || classroom.isEmpty) return false;
if (classroom.contains(keyword)) return true;
```

`resolveRange` 取**第一个**命中的变体；未命中变体的节次回落到 `section(index)`；两端任一缺失返回 `null`（`:110-138`）。课程显式 `startTime`/`endTime` 优先，由 `CourseTimeService` 处理（`course_time_service.dart:10-21`：两字段**都非空**才用显式时间）。

### 内置变体

`ScheduleVariant(id: 'ncpu.mingzhi', keywords: ['明志','明德','至善'], overrides: {3: ('10:15','10:55'), 4: ('11:05','11:45')})`（`school_presets.dart:56-65`）—— 第 3、4 节在上述教学楼**提前 10 分钟**（`:46`）。

### 通用兜底（`BellSchedule.fallback()`，`:151-174`）

10 节、每节 45 分钟；1-4 上午、5-8 下午、9-10 晚上。注释声明「**仅供新建学校播种，不能代表任何学校的官方作息**」（`:150-151`）。

| 节 | 起 | 止 | | 节 | 起 | 止 |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 08:00 | 08:45 | | 6 | 14:55 | 15:40 |
| 2 | 08:55 | 09:40 | | 7 | 16:00 | 16:45 |
| 3 | 10:00 | 10:45 | | 8 | 16:55 | 17:40 |
| 4 | 10:55 | 11:40 | | 9 | 19:00 | 19:45 |
| 5 | 14:00 | 14:45 | | 10 | 19:55 | 20:40 |

数据来源优先级与「只播种一次」：`bell_schedule.dart:84-86` + `school_repository.dart:46-47,199-204`。

## 6. 学期、周次与校历派生

> **两点边界**（第二阶段复核）：
> 1. **DST**：`SemesterService` 把日期裁成本地午夜后用 `DateTime.add(Duration(days: ...))` 与 `difference.inDays`；在采用夏令时的设备时区，固定 24 小时加法不一定是日历日加法 → 周日期与当前周算法缺 DST 测试（本机时区未复现，`INFERRED`）。
> 2. **跨午夜刷新**：周次与「今天」标记只在页面 build 时按 `DateTime.now()` 计算；停在 Weekly 跨午夜时不保证刷新（见 §10 的 V 项）。

### `SemesterService`（纯函数类，`semester_service.dart:11`）

| 方法 | 语义 |
| --- | --- |
| `currentWeek(semester, now)` | 早于 `firstWeekMonday` → **0**；否则 `diffDays ~/ 7 + 1`，超过 `totalWeeks` 封顶（`:13-20`） |
| `weekMonday(semester, week)` | week clamp(1, totalWeeks) 后加偏移（`:22-26`） |
| `termStatus(semester, now)` | `before` / `within`（`today < start + totalWeeks*7`）/ `after`（`:28-34`） |
| `readingProgress(semester, week, now)` | before → `(0, '尚未开卷')`；after → `(1, '此卷已毕')`；within → `(week/totalWeeks).clamp(0,1)` + `'阅至此处'`（`:40-56`） |
| `dateFor(semester, week, weekday)` | **不夹取 week** —— 周历要忠实显示翻到的周（`:58-63`） |

### `CalendarExceptionService`（`calendar_exception_service.dart:27`）

- `CalendarExceptionKind{holiday, makeup}`（`calendar_exception.dart:4,7`）：
  - `holiday` = 当天不上课 → `suspended = true`，`weekday` 保持自然星期（`:52-58`）
  - `makeup` = 按 `makeupWeekday` 那天的课表上课 → `weekday = (makeupWeekday ?? natural).clamp(1,7)`，`suspended = false`（`:59-63`）
- `forDate`：**线性扫描**，只比年月日；同日多条返回**第一条**（`:39-44`）
- 语义边界：**不支持「把某天的课移到另一天」**（`app_database.dart:85-89` 记录了不这样做的理由）

### 其他派生

| 函数 | 语义 |
| --- | --- |
| `CourseTimeService.resolve(course, schedule)` | 显式时间优先，否则查作息；缺节次 → `null`（`course_time_service.dart:10-21`）；`formatRange` null → `'时间未定'`（`:24-28`）；`sectionRangeLabel` 统一「第 3 节 / 第 3-4 节」（`:34-37`） |
| `SectionCountResolver.resolve(schedule, courses:)` | 起点 **10**（旧数据无节次记录），取 `max(10, 最大 section.index, 最大 course.endSection)`，`clamp(1,20)`（`section_count_resolver.dart:10-23`） |
| `parseWeeks(String)` | 中英文括号归一、去「周」与空白；支持 `1-16周`、`1,3,5`、`1-3,5,7-8`、`(单)`/`(双)`；结果去重升序（`week_parser.dart:16`）。抛出分支：空输入、同时含单双、正则不匹配、范围非法、单值 <1、单双筛选后为空（`:18-61`） |
| `formatWeeks(List<int>)` | 压缩为 `1-3,7,9-10周`；空 → `'无'`（`:65-81`） |

## 7. 五个设置页

| 页面 | 能做什么 | 仓库方法 | 危险操作确认 |
| --- | --- | --- | --- |
| `SettingsPage` | 当前学校卡片、4 个跳转行、明暗三选、关于（提 THIRD_PARTY_NOTICES） | `ThemeController.set`（`theme_preference_provider.dart:16-20`） | 无 |
| `SchoolManagePage` | 切换当前校、改教务地址（checkLoginUrl + updateLoginUrl + 白名单只增不减；ISSUE-020 已修关闭生命周期）、删除学校；添加入口已撤除 | `setActiveSchool`、`updateLoginUrl`、`appendConfirmedHost`、`deleteSchool` | 仅删除学校有 destructive 确认；**文案只提「课程、学期与作息」，未提校历例外，也未提会清 `active_school_id`** |
| `SemesterSettingsPage` | 改开学第一周周一（datePicker → 归到周一，`:171-190`）、教学周数 ±（`:86-122`，限 1..30）、历史学期切换（`:147-163`） | `updateSemester:151-168`、`setActiveSemester:148-149` | **无**——每次点击即写库；**无删除学期入口** |
| `BellSettingsPage` | 逐节编辑起止（`:60-115`，连开两个 timePicker `:122-148`）、恢复默认（`:162-188`） | `updateSectionTime:170-183`、`resetSectionTimes:187-197` | 恢复默认有 destructive 确认 |
| `CalendarExceptionPage` | FAB 添加（`:48-56`）、日期（绑定学期范围 `:101-108`）、停课/调休（`:125-137`）、1-7 星期 chips（`:144-151`）、备注（`:155-161`）、删除（`:195-225`） | `save:17-69`、`deleteById:71-75` | 仅删除有 destructive 确认 |

### 导航入口

| 目标 | 入口 |
| --- | --- |
| `/settings` | `timetable_page.dart:78`、`:136` |
| `/settings/schools` | `settings_page.dart:82` |
| `/settings/semester` | `settings_page.dart:89`、`timetable_page.dart:335`（空课表「设置学期」按钮） |
| `/settings/bell` | `settings_page.dart:96` |
| `/settings/calendar` | `settings_page.dart:103` |
| `/onboarding`（无学校时） | redirect 强制（`app_router.dart:56-62`） |

## 8. 唯一定义点

| 策略 | 唯一位置 |
| --- | --- |
| 内置学校档案 | `school_presets.dart`（`presetById` / `presetByDisplayName`） |
| 周次锚点语义 | `SemesterService`（`firstWeekMonday` 唯一锚点） |
| 校历例外语义 | `CalendarExceptionService.resolve` |
| 节次时间解析 | `CourseTimeService.resolve` + `BellSchedule.resolveRange` |
| 教室变体匹配 | `BellSchedule.matchesClassroom`（文本包含关键词） |
| 节数 | `SectionCountResolver.resolve`（起点 10） |
| 周次文本读写 | `week_parser.dart` |
| 通用兜底作息 | `BellSchedule.fallback()` |

## 9. 改动时必须同步的位置

- 加内置学校 → `school_presets.dart` + `framework_import.md`（地址/适配）+ `adapters.md` + 本文件 §3；**不得猜测**地址与作息
- 改 `firstWeekMonday` 语义或 `currentWeek` 边界 → 本文件 §6 + `test/semester_service_test.dart` + 周课表与 Today 两处显示
- 改 `makeup` 语义（例如支持「调课到另一天」）→ `calendar_exception_service.dart` + `app_database.dart` 的 `makeupWeekday` 语义注释 + UI 文案 + 本文件 §6
- 改变体匹配规则 → `bell_schedule.dart:49-55` + 本文件 §5 + `test/school_variant_seeding_test.dart`
- 改 `SectionCountResolver` 起点（10）→ 本文件 §6 + 网格渲染（`framework_motion.md`）
- 改任何设置页写操作 → 本文件 §7 表 + `framework_data.md` §4
- 改 `parseWeeks` 支持范围 → 本文件 §6 + `test/week_parser_test.dart` + 适配脚本字段说明（`framework_import.md` §6）

---

## 10. 已知问题与技术债

### P0（第二阶段复核新增，`CONFIRMED` 条件路径）

- **Q 已修复（TASK-CALENDAR-DATE-01）**：校历例外以今天或原例外日期为候选初始日期，并夹取到原有学期前后约 30 天范围。历史/未来学期的真实路由 Widget 测试确认 DatePicker 可打开，范围未扩大。

### P2（第二阶段复核新增）

- **T `INFERRED`** 设置页在 `await` 对话框之后使用 `ref`，未统一检查页面仍挂载：`semester_settings_page.dart:183-199`、`bell_settings_page.dart:162-187`、`calendar_exception_page.dart:116-193,195-224`。外部导航或父路由移除页面时存在异常路径。
- **W** 日期算法在采用夏令时的设备时区下用固定 24 小时加法（`DateTime.add(Duration(days:))` + `difference.inDays`），周日期与当前周缺 DST 测试；本机时区未复现，标 `INFERRED`。

### 其余

- **索引表 H**：`bell_settings_page.dart:171` 文案说恢复「8:00 起的通用作息」，实现是按内置档案恢复官方作息（`school_repository.dart:192-196`）。**文案与实现不一致**。
- **索引表 I**（关联）：校历「同日一条」仅由写路径事务保证，**DB 无唯一约束**，UI 也无查重提示。
- **无删除学期入口**（仓库无 `deleteSemester`）。
- 删除学校的确认文案不完整（未提校历例外与 `active_school_id` 清理范围）。
- `SemesterSettingsPage` 的每次点击即写库（周数 ±、切学期），**无确认、无撤销**。
- 无调用点的符号：`SchoolProfile.confirmedHost`、`Semester.copyWith`、`BellSchedule.groupByPeriod`（仅测试）、`sectionGroupFromString`、`courseSourceFromString`。
- `Course.copyWith` 无法把 `startTime`/`endTime` 置回 null（`??` 语义）→ 清空显式时间的需求无法通过现有 API 表达。
- 模型层普遍**无 assert**：越界值（如 `makeupWeekday`）只靠 UI 与仓库 clamp 拦。
- `SectionCountResolver` 起点固定 10 → 旧数据（无 `SectionTimeEntries`）在节次设置缺失时按 10 节渲染。

---

## 11. 未验证边界

- 各校真实作息与内置/兜底作息的差异：`UNVERIFIED`（除南工外不做猜测）。
- 南工教务地址 `http://218.204.129.252:8088/...` 的可用性：**未在本次审计中验证**（知识库记录为 2026-09-14 复核）。
- 校历例外在真实学校校历上的覆盖度（如临时调课）：`UNVERIFIED`。
- 教室变体关键词（明志/明德/至善）是否覆盖全部教学楼：`UNVERIFIED`。
- 真机上的日期/时间选择器与字体缩放表现：`UNVERIFIED`。

---

## 12. 更新记录

| 日期 | 变更 | 依据 |
| --- | --- | --- |
| 2026-09-28 | 首次建立：内置档案、模型字段与不变量、派生计算、作息与变体、校历语义、五页能力与入口 | 2026-09-28 只读调研 |
| 2026-09-28 | 校历例外 DatePicker 初始日期夹取；Q 已修，5 个 Widget 回归覆盖当前/历史/未来及已有日期 | TASK-CALENDAR-DATE-01 |
