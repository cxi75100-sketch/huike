# 框架报告 — 数据与状态

2026-10-02 TASK-LOGIN-REPAIR-01：schoolsProvider在订阅学校流之前await SchoolRepository.repairRetiredLoginUrls；事务仅对已知preset/精确校名的retired默认root URL改loginUrl，其他学校/自定义路径端口查询/字段/acceptedHosts不变。策略唯一定义SchoolPreset.replacementForRetiredLoginUrl，数据层不反向依赖features，schema仍3。updateLoginUrl在同一事务保存网址与确认host，相同网址不重复写。原beforeOpen兼容迁移保持。

## Last Updated

2026-10-02 +08:00 ｜ 完成度复核与历史基线提示

## 当前完整性提示（TASK-PROGRESS-REPORT-01）

导入ID包含schoolId/semesterId，confirmImport单事务覆盖作息、课程与学期更新；旧O/P已修复，下方旧审计须按此理解。schema3/6张表与兼容只读导入接线存在，本轮362/362含完整性及迁移回归。真实旧库覆盖安装仍UNVERIFIED，不从fixture测试外推。详见`report_2026-10-02_project_completion.md`及专项报告。

当前增补：databaseProvider解析同沙箱旧ncpu_timetable.sqlite；AppDatabase.beforeOpen在首读前调用legacy_database_import（schema1→独立目标schema3）。只读源、目标事务、marker幂等、已有学校跳过、错误回滚重试；未知settings不复制，学期name以显式元数据保留。见TASK-LEGACY-UPGRADE-01报告。下方09-28表/迁移描述为原结构基线，schema版本仍3。

证据来源：2026-09-28 只读代码调研（Drift schema / repository 写路径 / provider 图逐项核对）。

---

## 1. 边界

**负责**：本地 SQLite（Drift）的表结构与迁移、行↔模型映射、全部写库路径（repository）、Riverpod provider 图与刷新语义。

**不负责**：派生计算的具体口径（半学期/校历/节次时间 → `framework_school_calendar.md`）、导入链路的业务语义（→ `framework_import.md`）、数据模型的设计理由（→ `architecture.md`）。

**核心事实**：**纯本地、无后端、无账号**。全部数据只在这台设备的应用文档目录内。

---

## 2. 关键文件与入口

| 角色 | 文件 | 说明 |
| --- | --- | --- |
| 表结构与迁移（唯一） | `lib/core/database/app_database.dart` | 6 张表、`schemaVersion = 3`、`MigrationStrategy`、行↔模型扩展 |
| 生成的表代码 | `lib/core/database/app_database.g.dart` | 4308 行，`part of`；**已入 git**，不得手改 |
| 打开数据库（唯一） | `lib/core/database/database_provider.dart` | `LazyDatabase` + `NativeDatabase.createInBackground` |
| 学校/学期/作息写路径 | `lib/features/schools/services/school_repository.dart` | 9 个写方法 + 删校事务 + 启动期修复 |
| 课程写路径 | `lib/features/import/services/course_repository.dart` | 导入替换、作息替换、手动增改删、导入 id 指纹 |
| 校历例外写路径 | `lib/features/schools/services/calendar_exception_repository.dart` | 事务内「按 id 删 → 按日删 → 插」 |
| Provider 集中处 | `lib/features/schools/providers/`、`lib/features/timetable/providers/` | 仅这 2 个目录；其余 11 处声明散落在各自服务/页面文件 |
| 接缝（Drift ↔ Riverpod） | `query.watch()` 6 处：`school_providers.dart:27,57,82`、`calendar_exception_providers.dart:22`、`timetable_providers.dart:24`、`import_preview_page.dart:483` | 全部 `StreamProvider` 的数据源 |

---

## 3. 数据库

- 类：`class AppDatabase extends _$AppDatabase`，`@DriftDatabase(tables: [...])`（`app_database.dart:195-204`）
- `schemaVersion => 3`（`:207`）
- 迁移：**只有 `onUpgrade`，没有 `onCreate`/`beforeOpen`/迁移列表/`.drift` 文件**；新库建表由 drift 默认 `createAll` 完成（`INFERRED`）
  - v2：`addColumn(schools, schools.presetId)` + `addColumn(schools, schools.scheduleVariantsJson)`（`:214-215`）
  - v3：`createTable(calendarExceptions)`（`:220`）
- 库文件：`huike_timetable.sqlite`，目录 `getApplicationDocumentsDirectory()`；`NativeDatabase.createInBackground(File(path))` 包在 `LazyDatabase` 内（`database_provider.dart:12-19`）
- `databaseProvider` 非 autoDispose，`ref.onDispose(db.close)`（`:20`）；测试用 `ProviderScope(overrides: databaseProvider.overrideWithValue(NativeDatabase.memory()))`
- **无任何 PRAGMA**：未开 `foreign_keys`、未设 `journal_mode`/WAL（全仓 grep 0 命中）
- `ensureDefaults()` 是空方法且无调用点（`:225-228`）
- `settingValue(key,{fallback})` 读单键（`:230-235`）；`setSetting` 用 `insertOnConflictUpdate`（`:237-241`）

### 6 张表

| 表 | 数据类 | 列 | 主键 |
| --- | --- | --- | --- |
| `Schools` | `School` | `id` TEXT、`displayName`、`adapterId` default `''`、`presetId` default `''`、`loginUrl` default `''`、`acceptedHostsJson` default `'[]'`、`scheduleVariantsJson` default `'[]'`、`createdAt` DATETIME | `{id}` |
| `Semesters` | `SemesterRow` | `id`、`schoolId`、`firstWeekMondayIso` TEXT、`totalWeeks` INT | `{id}` |
| `CourseEntries` | `CourseEntry` | `id`、`schoolId`、`semesterId`、`source`(textEnum `CourseSource`)、`name`、`teacher` default `''`、`classroom` default `''`、`weekday` INT、`startSection` INT、`endSection` INT、`weeksJson` TEXT、`startTime` TEXT?、`endTime` TEXT?、`note` default `''`、`colorKey` INT default 0 | `{id}` |
| `SectionTimeEntries` | `SectionTimeEntry` | `schoolId`、`sectionIndex` INT、`start`、`end`、`periodGroup`(textEnum `SectionGroup`) | `{schoolId, sectionIndex}` |
| `CalendarExceptions` | `CalendarExceptionRow` | `id`、`schoolId`、`semesterId`、`dateIso` TEXT、`kind`(textEnum `CalendarExceptionKind`)、`makeupWeekday` INT?、`note` default `''` | `{id}` |
| `Settings` | `Setting` | `key` TEXT、`value` TEXT | `{key}` |

- **无外键、无 UNIQUE、无自建二级索引**；枚举以名字存 TEXT（`EnumNameConverter`）
- 行→模型映射集中在 `app_database.dart` 的扩展：`CourseRowMapping.toModel`（`:115-133`）、`SchoolRowMapping.toModel`（`:135-147`）、`schoolVariantsFromRow`（`:149-153`）、`SemesterRowMapping.toModel`（`:155-162`）、`CalendarExceptionRowMapping.toModel`（`:164-174`）、`bellScheduleFromRows`（`:176-189`）、`encodeWeeks`（`:191`）

---

## 4. 写路径（全部 repository 方法）

| 方法 | 位置 | 事务 | 影响 |
| --- | --- | --- | --- |
| `createSchool` | `school_repository.dart:20-58` | 否 | insert `schools` + 播种 `sectionTimeEntries`（只播种不覆盖） |
| `setActiveSchool` | `:60-61` | 否 | 写 `settings.active_school_id` |
| `appendConfirmedHost` | `:64-80` | 否 | 白名单只增不减 |
| `repairPresetVariants` | `:82-107` | 否 | 全表扫描后逐校 update（幂等，ISSUE-014） |
| `updateLoginUrl` | `:110-117` | 否 | 更新 `loginUrl` |
| `createSemester` | `:119-146` | 否 | insert `semesters` + 写 `active_semester:<schoolId>` |
| `setActiveSemester` / `updateSemester` | `:148-149` / `:151-168` | 否 | 学期切换 / 改周一与周数（null 用 `Value.absent()`，不覆盖） |
| `updateSectionTime` / `resetSectionTimes` | `:170-183` / `:187-197` | 否 | 单节更新 / 删后按内置档案重播种 |
| `deleteSchool` | `:220-245` | **是** | 依次删 `courseEntries` → `sectionTimeEntries` → `calendarExceptions` → `semesters` → `schools` → `active_semester:<id>`；`active_school_id` 在事务外清 |
| `replaceImportedCourses` | `course_repository.dart:21-59` | **是** | 删 `(schoolId, semesterId, source=imported)` 后逐条 insert |
| `replaceSectionTimes` | `:62-84` | **是** | 删该校节次后逐条 insert（分组 1-4 上午 / 5-8 下午 / 其余晚上） |
| `addManualCourse` / `updateCourse` / `deleteCourse` | `:99-107` / `:109-112` / `:114-118` | 否 | 手动课程增改删 |
| `CalendarExceptionRepository.save` | `calendar_exception_repository.dart:17-69` | **是** | 按 id 删 → 按 `(school,semester,date)` 删 → 插（保证同日一条） |
| `deleteById` | `:71-75` | 否 | 删单条例外 |

**导入课程 id 是内容指纹**：`importedCourseId(schoolId, draft)`（`course_repository.dart:143-159`），载荷 = `schoolId|name|weekday|startSection|endSection|weeks.join(',')`，双散列 → `imp-<schoolId>-<hex><hex>`。**teacher/classroom/startTime/endTime/note 不进指纹**。

**没有删除学期的入口**（仓库无 `deleteSemester`，`semester_settings_page` 只有 update / setActive）。

---

## 5. Provider 图（28 处声明，全部手写，无代码生成）

> Riverpod 3 默认 `isAutoDispose = false`，下表「常驻」= 进程内不自动释放。

### 基础设施

| Provider | 类型 | 生命周期 | 依赖 |
| --- | --- | --- | --- |
| `databaseProvider` | `Provider<AppDatabase>` | 常驻 | — |
| `rootNavigatorKeyProvider` | `Provider<GlobalKey<NavigatorState>>` | 常驻 | — |
| `appRouterProvider` | `Provider<GoRouter>` | 常驻 | `rootNavigatorKeyProvider`；`ref.listen(activeSchoolIdProvider)` + `refreshListenable` |
| `themePreferenceProvider` | `AsyncNotifierProvider<ThemeController, ThemePreference>` | 常驻 | `databaseProvider` |
| `launchReadinessProvider` | `Provider<bool>` | 常驻 | 主题 + 学校 + 学期 + 作息 + 课程 + 校历（见 `framework_startup.md`） |
| `presetVariantRepairProvider` | `FutureProvider<void>` | 常驻 | 启动期一次性修库（ISSUE-014） |
| `adapterCatalogProvider` | `FutureProvider<AdapterCatalog>` | 常驻 | `rootBundle` 读 `assets/adapters/catalog.json` |

### Repository

| Provider | 类型 | 依赖 |
| --- | --- | --- |
| `schoolRepositoryProvider` | `Provider` | `databaseProvider` |
| `calendarExceptionRepositoryProvider` | `Provider` | `databaseProvider` |
| `courseRepositoryProvider` | `Provider` | `databaseProvider` |
| `importSessionProvider` | `NotifierProvider<ImportSessionNotifier, AdapterImportSession>` | 内存会话 |

### 学校与设置

| Provider | 类型 | 生命周期 |
| --- | --- | --- |
| `schoolsProvider` | `StreamProvider<List<SchoolProfile>>` | 常驻（全表，orderBy createdAt） |
| `activeSchoolIdProvider` | `StreamProvider<String?>` | 常驻（读 `settings` 单键） |
| `activeSchoolProvider` | `Provider<SchoolProfile?>` | 常驻（遍历 schools 找 id） |
| `settingValueProvider` | `StreamProvider.family.autoDispose<String?, String>` | autoDispose |
| `semestersForSchoolProvider` | `StreamProvider.family.autoDispose<List<Semester>, String>` | autoDispose（orderBy firstWeekMonday **desc**） |
| `activeSemesterProvider` | `Provider.family<Semester?, String>` | **常驻**（注意与上面不同） |
| `sectionTimesProvider` | `StreamProvider.family.autoDispose<BellSchedule, String>` | autoDispose |
| `schoolBellProvider` | `Provider.family.autoDispose<BellSchedule, String>` | autoDispose |
| `activeCalendarServiceProvider` | `Provider.autoDispose<CalendarExceptionService>` | autoDispose |

### 课程与今日

| Provider | 类型 | 生命周期 |
| --- | --- | --- |
| `coursesForProvider` | `StreamProvider.family.autoDispose<List<Course>, (String,String)>` | autoDispose（orderBy startSection） |
| `courseByIdProvider` | `StreamProvider.autoDispose.family<Course?, String>` | autoDispose |
| `todayDayScheduleProvider` | `Provider.autoDispose<DaySchedule?>` | autoDispose（build 内读 `DateTime.now()`） |
| `todayCoursesProvider` | `Provider.autoDispose<List<Course>>` | autoDispose |
| `bellForActiveSchoolProvider` | `Provider.autoDispose<BellSchedule?>` | autoDispose（包 `schoolBellProvider`） |
| `activeSemesterRefProvider` | `Provider.autoDispose<Semester?>` | autoDispose |
| `importedCoursesProvider` | `StreamProvider.family.autoDispose<List<Course>, (String,String)>` | autoDispose（**与 `coursesForProvider` 查询重复**，仅多 `source='imported'` 过滤；声明在 `import_preview_page.dart:472-486`） |

### 刷新语义

- `ref.watch` 84 处 / `ref.read` 24 处 / `ref.listen` **2 处**（`app_router.dart:48`、`import_web_page.dart:101`）/ `ref.invalidate` **5 处**（`import_entry_page.dart:175-176`、`today_page.dart:42-43`、`timetable_page.dart:114`）
- **写入后不手动 invalidate**：靠 Drift `.watch()` 自动推流
- 派生 provider 大量使用 `.value` **丢弃 loading/error**（错误即当空）：`school_providers.dart:42-43,65,91-93`、`timetable_providers.dart:54-55`、`calendar_exception_providers.dart:39-40`
- 跨页面共享点（多页面同时 watch）：`activeSchoolProvider`（12+ 处）、`activeSemesterProvider`（8 处）、`bellForActiveSchoolProvider`（5 处）、`coursesForProvider`（3 处）、`sectionTimesProvider`（4 处）、`courseByIdProvider`（3 处）

---

## 6. 唯一定义点

| 策略 | 唯一位置 |
| --- | --- |
| 表结构与迁移 | `app_database.dart`（表类 + `migration`） |
| 打开数据库与文件位置 | `database_provider.dart` |
| 行→模型映射 | `app_database.dart` 的 7 个扩展 |
| 导入课程 id 指纹 | `course_repository.dart` → `importedCourseId()` |
| 删校的连锁删除范围 | `school_repository.dart:220-245` |
| 「校历同日一条」 | `calendar_exception_repository.dart:32-58`（写路径，**无 DB 约束**） |
| 设置读写 | `app_database.dart` → `settingValue()` / `setSetting()` |

## 7. 改动时必须同步的位置

- 加表/加列/改约束 → `schemaVersion` + `onUpgrade` 分支 + `app_database.g.dart`（跑 `dart run build_runner build --delete-conflicting-outputs`）+ 本文件 §3 + `architecture.md`
- 加 provider → 本文件 §5 + `framework_startup.md`（若参与 `launchReadinessProvider`）
- 改仓库写路径 → 本文件 §4 + 相关功能框架报告
- 改设置键名 → 本文件 §3（`Settings` 表）+ 使用点 + 本文件 §6
- 改 `launchReadinessProvider` 的依赖 → `framework_startup.md`

**代码生成命令**：`dart run build_runner build --delete-conflicting-outputs`（根目录无 `build.yaml`）。

---

## 8. 已知问题与技术债

| # | 事实 | 位置 |
| --- | --- | --- |
| **O** | **P0 `CONFIRMED` 跨学期导入主键冲突**（基线 `7bc4f10`）：`importedCourseId` 不含 `semesterId`，`replaceImportedCourses` 只删当前学期的 imported 行 → 同一学校第二学期的相同课程会因主键冲突导致导入失败。**工作区已有未提交改动在修此条，本文件不覆盖未提交代码**（见 `framework_index.md` 顶部） | `course_repository.dart:143-158`、`:27-56` |
| **P** | **P0 `CONFIRMED` 导入确认三段写入无整体事务**（基线 `7bc4f10`）：`replaceSectionTimes` → `replaceImportedCourses` → `updateSemester` 各自独立提交，后段失败留下已提交的前段。**同上，工作区在修** | `import_preview_page.dart:415-440` |
| I | `CalendarExceptions` **无 DB 唯一约束**，「同日一条」只由写路径事务保证 | `app_database.dart:91-105`、`calendar_exception_repository.dart:32-58` |
| J | **全部表仅主键、无二级索引**；`weeksJson` 为 JSON 文本 → 周次无法 SQL 过滤，`coursesForProvider` 拉全学期课程后由 Dart 过滤 | `app_database.dart:18-113`、`timetable_providers.dart:19-24`、`week_agenda.dart:128-135` |
| K | 导入写入是「删后重建」→ 手工改过的导入课程（含备注）在下次导入后丢失；删掉的导入课会重新出现 | `course_repository.dart:21-59`、`course_edit_page.dart:304-317` |
| — | 无外键/级联；删课程只删单行；唯一手写级联是 `deleteSchool` | `course_repository.dart:114-118`、`school_repository.dart:221-238` |
| — | 无删除学期入口 | `school_repository.dart`（无 `deleteSemester`） |
| — | `importedCoursesProvider` 与 `coursesForProvider` 查询重复 | `import_preview_page.dart:472-486` vs `timetable_providers.dart:15-27` |
| — | 派生 provider 用 `.value` 吞掉 loading/error（错误即渲染为空） | 见 §5 刷新语义 |
| — | 启动期修库 `presetVariantRepairs` 失败无 UI 提示、无重试入口（`INFERRED`：调用点只 `ref.watch` 不消费 `.value`） | `app.dart:39` |
| — | N+1 型写入：`_seedSectionTimes` 逐节 insert、`replaceImportedCourses` 逐条 insert、`replaceSectionTimes` 逐槽 insert、`repairPresetVariants` 全表+逐校 update、`deleteSchool` 6 条 delete | 见 §4 |
| — | 线性查找热点：`BellSchedule.section`、`CalendarExceptionService.forDate`（每日线性）、`activeSchoolProvider`（遍历全校）、`SectionCountResolver`（遍历课程） | `bell_schedule.dart:98-103`、`calendar_exception_service.dart:39-44`、`school_providers.dart:45-48` |
| L | 无调用点的符号：`encodeHosts`、`groupByPeriod`、`Semester.copyWith`、`sectionGroupFromString`、`courseSourceFromString`、`AdapterCourseDraft.toFieldMap` | `app_database.dart:193`、`bell_schedule.dart:5,140`、`semester.dart:16`、`course.dart:7`、`adapter_batch.dart:29-36` |
| **U** | **P2 `CONFIRMED`** Today 预览在 `courseByIdProvider` 返回 null 后仍回退展示 `initialCourse` 旧快照（读 provider 的一侧） | `today_page.dart:148-156` |
| **V** | **P2 `INFERRED`** 停在 Weekly 跨午夜时周次/「今天」不保证刷新：`TimetablePage` 只在 build 时读 `DateTime.now()`，只有 Today 有 30s Timer 且只 invalidate Today 的两个派生 provider | `timetable_page.dart:235-241`、`today_page.dart:32-45` |
| — | **`lib/` 内无 TODO/FIXME/HACK/XXX**（全仓 grep 0 命中） | — |

---

## 9. 未验证边界

- 无二级索引下的实际查询计划（是否全表扫描）：`UNVERIFIED`（未 EXPLAIN）。
- `NativeDatabase.createInBackground` + 无 WAL 在真机大课程量下的表现：`UNVERIFIED`。
- 迁移路径 v1→v3 的真实升级（无旧版本数据库样本）：`UNVERIFIED`。
- 首次建库时 `createAll` 是否确实由 drift 默认完成：`INFERRED`。

---

## 10. 更新记录

| 日期 | 变更 | 依据 |
| --- | --- | --- |
| 2026-09-28 | 首次建立：6 表结构、schemaVersion 3 与迁移、全部写路径、28 个 provider | 2026-09-28 只读调研 |
