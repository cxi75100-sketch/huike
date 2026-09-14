# 汇课 · 进度与技术交接报告（2026-09-14）

Date: 2026-09-14
Version: `0.1.1+2`（pubspec），工作区应当干净（TASK-009/010/011 与知识库同步均已提交）
Status: **可用**（Android 装机验证通过，最近一次为 2026-09-14 于 `ncpu_api36`）；真实教务导入与 iOS 未验证
分支: `master`，HEAD 见 `git log -1`；远端 Gitee `chenxihh/huike`（**公开**）；tag `v0.1.0` 指 `8cdccda`，本版 tag `v0.1.1`（APK 挂在对应 release 附件）

本报告面向「在另一个会话里直接接手」的 Agent。**先读本文件 §0 与 §1，再按
`knowledge/README.md` 的推荐顺序读 `current_state.md` → `tasks.md` → 专题文档。**
`AGENTS.md` 是硬性工作规范，优先级高于本报告。

---

## 0. 接手第一件事：确认起点干净

工作区应当干净——TASK-009/010/011 与知识库同步都已提交，HEAD 即 §3 的验证基线，
本版打 tag `v0.1.1`（对应 release 附件里是同一份 APK）。先做一件事：

```bash
cd "D:\桌面\汇课"
git status --short          # 期望：无输出
git log --oneline -5        # 确认 HEAD 与 tag v0.1.1 指向同一次提交
```

如果 `git status` 有输出，先按 `knowledge/tasks.md` 的 Now 判断这些改动属于谁，
**不要**直接 `git checkout .` / `git clean -fd`。

### 0.1 TASK-011 改了什么（最近一轮）

首页信息架构重做（细节见 `tasks.md` 的 Done 与 `changelog.md` 的 `0.1.1+2`）：
今日从「十节轨道竖向时间轴」改为**当日议程**，整周从「节次槽位网格 / 横向翻页周历」
改为**七日议程**；删除 `lib/features/timetable/widgets/day_timeline.dart` 与
`section_slot_board.dart`，首页撤下路线水印与七日站点概览；顺带修掉引导页把教务网址
写死成「HTTPS」的文案（ISSUE-012）。

`lib/core/database/app_database.g.dart` 是 build_runner 产物但**已入库**，schema 改动必须一起提交。

---

## 1. 项目身份与位置

| 项 | 值 |
| --- | --- |
| 应用名 | **汇课**（2026-09-13 用户确认定稿） |
| 目录 | `D:\桌面\汇课`（独立 git 仓库） |
| 代替路径 | `subst S: "D:\桌面\汇课"`，中文路径下 Flutter 工具链必须在 `S:\` 下跑 |
| 包名 | `com.huike.huike_timetable` |
| 版本 | `0.1.1+2`（pubspec.yaml；versionCode 2 / versionName 0.1.1） |
| 远端 | `origin` = `https://gitee.com/chenxihh/huike.git`（公开，无令牌地址）；tag `v0.1.0`/`v0.1.1` |
| 签名 | release 仍用 Flutter 默认 debug 证书（见 ISSUE-006） |
| 知识库 | `knowledge/`（索引 `README.md`，规范 `../AGENTS.md`） |

**项目边界（硬性）**：本仓库与任何单校课表项目相互独立——不共享代码、数据库、签名或知识库；
公开文档中不出现彼此的名称与归属关系；第三方开源署名除外。**接手时不要在仓库里写入任何
跨项目引用或同步关系描述。**

---

## 2. 环境与工具链

已在 2026-09-14 复核存在：

- Flutter `3.47.2` stable（revision `d3b14c8769`）/ Dart `3.13.2` → `D:\Tools\flutter`
- JDK 17 → `D:\Tools\jdk-17`；Android SDK → `D:\Tools\android-sdk`（platform-tools、build-tools 36.0.0）
- 模拟器：AVD `ncpu_api36`（API 36 / x86_64）。**与其它项目共用**，本项目包名独立，冒烟后清理自己造的学校
- `S:` 盘已挂载（`subst`）

**sqlite3 hook 离线构建**：`sqlite3` 的 Dart hook 会从 GitHub 下载预编译库，缓存于
`.dart_tool/hooks_runner/shared/sqlite3/build/download-<hash>/`（带 sha256 校验）。
本机 GitHub 直连不可用（需代理且不常开），缓存已存在（`.dart_tool/hooks_runner/shared/sqlite3/build/`
下有 `7090818b06/`、`709b01079f/`、`7675732477/` 三份），**不要删 `.dart_tool`**。

常用命令（Git Bash）：

```bash
subst S: "D:\桌面\汇课"; cd /s/
flutter analyze && flutter test
dart run build_runner build          # schema 改动后必须重跑（生成 app_database.g.dart）
export MSYS_NO_PATHCONV=1            # 否则 adb 的 /sdcard/... 路径会被 Git Bash 改写
D:/Tools/android-sdk/platform-tools/adb.exe install -r 'S:\build\app\outputs\flutter-apk\app-release.apk'
```

---

## 3. 构建与验证基线

| 检查 | 结果 | 证据时间 |
| --- | --- | --- |
| `flutter analyze` | **No issues found** | 2026-09-14 |
| `flutter test` | **110/110 通过**（16 个测试文件） | 2026-09-14 |
| 装机冒烟 | 2026-09-14（`ncpu_api36`）：建校 → 今日议程（空课 / 单课 / 两课）→ 整周议程 → 夜间两视图 → 窄屏 360dp，logcat 0 致命异常 | 2026-09-14 |
| release APK | `build/app/outputs/flutter-apk/app-release.apk` = `0.1.1+2`（versionCode 2），通用包 61.7MB（arm64-v8a / armeabi-v7a / x86_64） | 2026-09-14 |
| 真实教务导入 | 无证据 | `UNVERIFIED` |
| iOS | 未构建 | `UNVERIFIED` |

**注意**：APK 不入库（`/build/` 在 `.gitignore`），对外分发走 Gitee release 附件
（tag `v0.1.1` 对应包 SHA-256 `98510723…f396019`）。改代码后必须重新
`flutter build apk --release` 再装机，不要复用旧包。

---

## 4. 代码地图

```text
lib/
  main.dart / app.dart                     入口；MaterialApp.router + 明暗主题 + 中文本地化
  core/
    database/app_database.dart             Drift schema v3 + 行→模型映射 + 迁移(v1→v2→v3)
    database/app_database.g.dart           build_runner 产物（已入库，schema 改动必须一起提交）
    database/database_provider.dart        全局库（LazyDatabase；测试注入内存库）
    router/app_router.dart                 路由表；单实例 + refreshListenable（见 §12 坑 3）
    theme/app_palette.dart, app_theme.dart, course_colors.dart, theme_preference*.dart
  models/
    school_profile.dart                    学校档案（presetId、scheduleVariants）
    bell_schedule.dart                     节次规范 + 时段分组 + ScheduleVariant + 通用兜底(10 节)
    semester.dart / course.dart
    calendar_exception.dart                校历例外：停课 / 调休补课（本次新增）
  services/
    week_parser.dart                       周次文本解析/格式化
    semester_service.dart                  currentWeek / termStatus / dateFor / weekdayOf
    course_time_service.dart               显式时间 > 作息变体 > 基础作息；缺节次返回 null
    calendar_exception_service.dart        **例外 → 某天按哪天的课表（纯 Dart，UI 共用）**
  features/
    schools/
      services/school_presets.dart         内置档案：南昌工学院（官方作息+变体+默认地址）
      services/school_repository.dart      建校/切换/删校/学期/作息（播种只一次；删校级联清例外）
      services/adapter_catalog.dart        assets/adapters/catalog.json 加载
      services/login_url_policy.dart       **checkLoginUrl：三处入口共用（本次新增）**
      services/calendar_exception_repository.dart 例外写路径（同日覆盖）
      providers/school_providers.dart      学校流/激活学校/激活学期/作息流(+schoolBellProvider)
      providers/calendar_exception_providers.dart 例外流 + 激活学校解析器
    import/
      services/adapter_bridge.dart         shiguangBridge* 契约桥（8 处理器）
      services/import_session.dart         内存暂存（三类原始数据 → 合并规范化）
      services/navigation_policy.dart      scheme + host 白名单（纯 Dart）
      services/import_diff.dart, course_repository.dart, import_session_cleaner.dart
      models/adapter_batch.dart            规范化器（无效条目计数不猜语义）
      pages/import_entry_page.dart         入口：地址确认 + 明文警示 + 风险勾选
      pages/import_web_page.dart           **受限 WebView + 跨域逐主机确认 + 自动探测**
      pages/import_preview_page.dart       差异预览 + 附加选项 + 确认写入
    timetable/
      providers/timetable_providers.dart   课程流 / todayDaySchedule / todayCourses
      pages/timetable_page.dart            首页（TASK-011 后两个视图都在此文件内）：
                                           历牌 / 模式切换 / 今日议程 / 整周议程
      pages/course_detail_page.dart, course_edit_page.dart
      widgets/course_listing_row.dart      CourseListingRow（今日议程行）+ EmptyDayPlate
      （TASK-011 已删除 widgets/day_timeline.dart 与 widgets/section_slot_board.dart）
    settings/
      pages/settings_page.dart             学校/学期/作息/**调休停课**/外观/关于
      pages/semester_settings_page.dart, bell_settings_page.dart
      pages/school_manage_page.dart        切换/菜单（改网址/删除）
      pages/calendar_exception_page.dart   **调休 / 停课（本次新增）**
    onboarding/pages/onboarding_page.dart  创建学校 + 第一学期（必经）
assets/
  adapters/catalog.json                    适配器目录（4 条）
  adapters/{zhengfang_01,qingguo_01,urp_01,chaoxing}.js  社区脚本（MIT，署名见 THIRD_PARTY_NOTICES.md）
  icon/*.png                               印章行楷图标（候选在 icon/candidates/）
tools/make_icon*.py                        图标生成脚本
third_party/flutter_inappwebview_android/  AGP 兼容补丁（dependency_overrides 固定）
knowledge/                                 知识库（结构见 §10）
```

---

## 5. 测试清单（16 文件 / 110 条）

| 文件 | 覆盖 |
| --- | --- |
| `week_parser_test.dart` | 周次解析/格式化（范围、离散、单双周、中英文括号、异常） |
| `semester_service_test.dart` | 周次边界、学期状态、日期换算 |
| `bell_schedule_test.dart` | 通用兜底 10 节、分组、跨节解析、作息变体、JSON 往返 |
| `school_presets_test.dart` | 南工 10 节逐节时间、明志/明德/至善变体、CourseTimeService 组合、默认明文地址 |
| `course_time_service_test.dart` | 显式时间优先、缺节次 null、equalsFallback |
| `adapter_batch_test.dart` | 契约形状规范化、weeks 文本、非法条目计数、边界 |
| `import_diff_test.dart` | added/removed/changed、周次乱序不算修改 |
| `adapter_bridge_test.dart` | 8 处理器齐、契约名保持、幂等、不落盘 |
| `adapter_catalog_test.dart` | 目录 4 条、资产存在、脚本用桥契约 |
| `course_repository_test.dart` | 内存库：播种一次、导入替换保手动、跨校隔离、指纹 id、级联删除、设置 |
| `navigation_policy_test.dart` | **新增**：白名单放行、http/https 都允许、未确认主机拦截、子域名不自动放行、非 http(s) scheme 拦截、名单追加即刻生效 |
| `login_url_policy_test.dart` | **新增**：空输入必填/非必填、http 标记明文、https、裁剪空白、缺 scheme、非 http(s) scheme、无主机 |
| `calendar_exception_service_test.dart` | **新增**：停课/调休折算、同一天任意时刻命中、未指定目标星期退回自然星期、越界夹取、多条例外互不干扰 |
| `calendar_exception_repository_test.dart` | **新增**：内存库写入读回、同日二次写入是覆盖、编辑换日期不残留、停课忽略 makeupWeekday、删除只删指定、跨校隔离、删校级联清 |
| `calendar_exception_ui_test.dart` | **新增**：今日停课空状态、调休提示条、「设置 → 调休 / 停课」路由 |
| `app_shell_test.dart` | App 壳 widget：引导→建校→首页；空课日空状态；`today-agenda`/`week-agenda` 互斥切换、整周当天行 key、首页无「本周线路概览」语义标签 |

**缺口**：没有迁移测试（Drift `SchemaVerifier` 未接入），v2→v3 的 `createTable` 只在内存库
新建成库的路径上被间接验证过；页面级 widget 测试只覆盖了设置与今日/整周的一小部分。

---

## 6. 数据模型（schema v3）

- `schools(id, displayName, adapterId, presetId, loginUrl, acceptedHostsJson,
  scheduleVariantsJson, createdAt)`
- `semesters(id, schoolId, firstWeekMondayIso, totalWeeks)` —— 生成类名 `SemesterRow`
- `course_entries(id, schoolId, semesterId, source(manual|imported), name, teacher, classroom,
  weekday, startSection, endSection, weeksJson, startTime?, endTime?, note, colorKey)`
- `section_time_entries(schoolId+sectionIndex, start, end, periodGroup)`
- `calendar_exceptions(id, schoolId, semesterId, dateIso, kind(holiday|makeup), makeupWeekday?,
  note)` —— 生成类名 `CalendarExceptionRow`
- `settings(key, value)`：`theme_mode` / `active_school_id` / `active_semester:<schoolId>`

迁移链：v1→v2 `addColumn`（`presetId`、`scheduleVariantsJson`）；v2→v3 `createTable`
（`calendar_exceptions`，空表语义 = 没有例外）。**没有内置默认学校**；引导页必建校。
导入课程 id = 内容指纹（同内容同 id，周次段不同则不同）。

---

## 7. 导入链路与适配器契约

**契约桥**（`adapter_bridge.dart`，社区脚本零修改可跑）：

| API | 返回 |
| --- | --- |
| `shiguangBridge.showToast(msg)` / `notifyTaskCompletion()` | — |
| `shiguangBridgePromise.showAlert(title,msg,btn)` | bool |
| `shiguangBridgePromise.showSingleSelection(title,jsonNames,defaultIdx)` | 下标 / null |
| `shiguangBridgePromise.showPrompt(title,msg,default,validator?)` | String / null |
| `shiguangBridgePromise.saveImportedCourses(json)` | bool |
| `shiguangBridgePromise.savePresetTimeSlots(json)` | bool |
| `shiguangBridgePromise.saveCourseConfig(json)` | bool |

数据形状：courses `[{name,teacher,position,day(1-7),startSection,endSection,weeks[]}]`、
timeSlots `[{number,startTime,endTime}]`、courseConfig `{semesterStartDate,totalWeeks}`。

**流程**：入口确认地址（明文额外警示 + 风险勾选）→ 受限 WebView → 点「执行导入」→
自动依次尝试全部内置适配器（脚本自己校验页面；桥弹窗打开时暂停该次超时 25s）→
成功进预览（新增/移除/修改/无效四类）→ 确认后事务替换 `(schoolId, semesterId, imported)`。
手动课程永不触碰。

**2026-09-14 的三处改动（TASK-009，见 DEC-005/006/007）**：

1. **导航**：放行范围 = 入口地址 + 学校档案 `acceptedHosts` + 会话中新确认主机；
   主框架跳新主机时弹窗确认一次，同意即记住（内存 + `appendConfirmedHost` 落库，只增不减），
   拒绝则本会话不再问；**子框架不参与判定**（教务常用 iframe）；scheme 允许 http/https。
   此前只放行入口那一台主机，登录跳统一认证/CAS 会被静默 CANCEL（ISSUE-001）。
2. **地址校验**：统一在 `checkLoginUrl`，建校/改址/导入入口三处共用，http/https 都收。
   此前学校管理页仍硬拦 https 是明文放开的漏改（ISSUE-002）。
3. **探测过程**：去掉「正在尝试 xxx」提示，失败不逐项罗列、不征求是否继续，
   脚本之间固定间隔 800ms；全部失败只给一句可操作提示（DEC-007）。

**明文 HTTP 策略**：Android `base-config cleartextTrafficPermitted=true`；
iOS `NSAllowsArbitraryLoadsInWebContent=true`（仅 WebView）。应用层两道门：入口地址确认
（明文额外警示）+ 导航仅限确认过的主机。**不要退回按校白名单放行**（DEC-004）。

---

## 8. 校历例外（本轮新增，TASK-004）

只表达两种语义：**这天停课**，或**这天按某个星期的课表上课**。同一天只保留一条，
再写即覆盖（DEC-010）。

- 纯函数 `CalendarExceptionService.resolve(date) → DaySchedule{weekday, suspended, exception}`，
  今日、整周共用。
- 今日页：停课 → 空状态牌「今天停课」；调休 → 提示条「调休　今天按周五的课表上课」。
  提示条判定**先于**「今日无课」（这天到底上不上课由校历决定）。
- 整周页：每列先按日期折算实际星期再取课，列头加「停课 / 调休 · 按周四」小签。
- 设置 → 调休 / 停课：日期选择 + 停课/调休单选 + 星期 chips + 备注，可改可删。
- **后续小组件与提醒必须走同一折算**，不要各自判星期（`architecture.md` 已写明）。

---

## 9. 设计语言「新历书」

单朱砂强调色（日 `#C3402B` / 夜 `#E0604A`）；纸白与墨；结构靠发丝线不堆卡片；
圆角系统锁（区块 12 / 控件 10 / 小签 4）；课程签 8 色低饱和且只在小块面；
数字用 tabular figures；动效克制。
**两个课表视图（TASK-011 后）**：都是「只排真实有课项」的议程，不再画节次轨道。
今日 = 历牌 hero + 「下一节」提示条 + 当天课程行（`CourseListingRow`）；
整周 = 七天分组，每天表头写「周X + 日期 + 调休小签 + N门/无课/停课」，表头下展开当天课程，
空日只占一行；当前周仍以今天开头、今天行朱砂浅底。
首页不使用路线水印（`RouteBackground` 只在设置页与课程详情页），
课程详情保留「十站节次线」。
图标 = 朱砂印章 + 华文行楷「汇」+ 白内框。

---

## 10. 知识库约定

```text
knowledge/
  README.md        索引：项目边界 + 推荐顺序 + 逐文件一句话
  current_state.md 当前状态、可用功能、阻塞、验证快照（含 Last Updated）
  tasks.md         Now / Next / Blocked / Done
  decisions.md     技术决策 DEC-xxx（Status/Context/Decision/Reason/Consequences）
  issues.md        问题与技术债 ISSUE-xxx（Observed/Root Cause/Impact/Resolution/Evidence/Prevention）
  architecture.md  结构、数据模型、数据流
  adapters.md      契约桥、导入链路与安全语义
  design.md        设计语言
  testing.md       测试范围、命令与环境注意事项
  changelog.md     实质变更记录
  report_*.md      报告（按日期 + 主题命名）
```

规则（`AGENTS.md` 工程准则）：**知识库同步属于同一笔提交**；跨页策略只允许一个函数；
放宽类改动先做入口盘点；文档宣称的能力必须有代码接线；未验证不得宣称可用；
20 行以上的 Dart 改动整文件重写（不要用 shell 字符串替换）。
引用编号一律用 `TASK-` / `DEC-` / `ISSUE-`，不要自创第三套编号。

---

## 11. 已完成 / 未完成

**已完成**（详见 `tasks.md` Done）：

- TASK-000 仓库、`AGENTS.md`、知识库
- TASK-001 多校基座（模型 / 导入链路 / 两视图 / 主题 / 图标）+ 五轮用户反馈迭代
- TASK-007/008 上传 Gitee 并转公开（公开可匿名读，无令牌）
- TASK-009 导入链路可用性修复（§7 的三处）
- TASK-010 接手收口与 UI 融合（线路语言进入详情与设置）
- TASK-004 校历例外（§8）
- TASK-011 首页信息架构重做（§0.1：今日/整周都改为议程），release `0.1.1+2` 已挂到 Gitee release

**未完成**：

- TASK-002 Android 桌面小组件（载荷 v2：Dart 预计算整学期每日课程，原生只查表）
- TASK-003 本地上课提醒（时区语义「课程所在地墙上时间」）
- TASK-005 适配器目录联网更新（届时按 DEC-008 给内置脚本加哈希校验）
- TASK-006 真实教务导入验收（`BLOCKED`，等用户真机）
- iOS 构建验证、GitHub 镜像

---

## 12. 错误与踩坑（按重要性）

1. **Riverpod 3 无 `valueOrNull`** → 用 `.value`（不再抛异常）。
2. **Drift 生成类与模型重名**：`Semesters` 生成 `Semester`、`CalendarExceptions` 生成
   `CalendarException`，都会与模型冲突 → 用 `@DataClassName('XxxRow')`。
3. **GoRouter 不能重建**：`ref.watch` 学校流会每次重建 Router，与 `context.go` 竞争导致
   导航悬挂（widget 测试 `pumpAndSettle` 超时）。修：单实例 + `refreshListenable`；
   navigator key 用 `rootNavigatorKeyProvider`（不能是全局 GlobalKey）。
4. **schema 改动必须重跑 build_runner**，且 `app_database.g.dart` 已入库、要一起提交；
   忘记重跑会出现「表不存在」的运行时错误而不是编译错误。
5. **`ListTile` 的背景/涟漪画在最近的 Material 上**：中间隔一层带背景的 Container 会
   触发断言（debug 下打开设置页就抛）。修：外层补 `Material`（ISSUE-010）。
6. **明文 HTTP 策略反复**：曾做「仅南工白名单」被用户否决（多校工具不能按校个案放行）；
   随后放开明文时又漏改学校管理页（ISSUE-002）。教训：放宽类改动先做入口盘点。
7. **只放行入口主机**：白名单写成了单主机精确匹配，登录跳统一认证必被拦（ISSUE-001）。
   教训：文档/注释宣称的能力必须在代码里有调用点。
8. **sqlite3 hook 下载失败**（见 §2）；release 的 `networkSecurityConfig` 资源在
   resources.arsc 里，`unzip -l` 看不到，要用 `aapt2 dump resources/xmltree` 验证。
9. **adb 中文输入不可用**（标准 IME 只能 ASCII）→ 涉及中文教室/课名的 UI 路径只能靠单测
   （如明志楼变体）；`uiautomator dump` 里 Flutter 文本在 `content-desc`/`text`。
10. **Git Bash 调 adb 传 `/sdcard/...` 要 `export MSYS_NO_PATHCONV=1`**；
    native python 读 dump 用 Windows 路径。
11. **模拟器是共用的**：`ncpu_api36` 上有本项目冒烟留下的学校/课程时，删掉自己的即可；
    不要碰其它应用的数据。收尾用 `adb shell pm clear com.huike.huike_timetable` 回到全新安装态；
    改过 `wm size`/`wm density` 必须 `reset`（TASK-011 核验用了 720x1600 + density 320）。
12. **大段 Dart 改动不要用 shell 字符串替换**（曾把一个文件打坏成 47 个错误）→ 整文件重写。
13. **截图坐标不可直接当点击坐标**：`android_screenshot` 返回的图会被缩放，
    直接用肉眼估的像素点会点偏（本轮踩到过）。要点哪个控件先用 `android_ui_resolve` /
    `android_ui_describe` 拿真实 bounds，再按 `centerX/centerY` 点。

---

## 13. 待办与阻塞

| 项 | 状态 | 说明 |
| --- | --- | --- |
| TASK-002 桌面小组件 | 未开始 | 载荷经 `CalendarExceptionService` 折算后再预计算 |
| TASK-003 上课提醒 | 未开始 | 同上；时区语义用「课程所在地墙上时间」 |
| TASK-005 适配器联网更新 | 未开始 | 先定配置源与哈希/签名策略（DEC-008） |
| TASK-006 真实导入验收 | **`BLOCKED` 等用户** | 需要用户装机走一次导入；先重装新包 |
| ISSUE-004 真实导入未验收 | Open | 无任何真实教务证据 |
| ISSUE-005 新 UI 未装机验证 | 部分关闭 | 跨域确认弹窗、800ms 节奏、调休页与整周小签仍未装机复测；首页两视图已由 TASK-011 装机核验（§3） |
| ISSUE-012 引导页网址文案写死 HTTPS | Resolved（2026-09-14） | 标签改为「http/https」，与 DEC-004 一致 |
| ISSUE-006 签名仍为 debug 证书 | Open | 正式分发前必须换（换签要卸载重装） |
| ISSUE-007 iOS 未构建 | Open | 需要 mac |
| ISSUE-008 历史遗留物未清理 | Open | `tools/patch_*.py`、`assets/icon/candidates/` 按 DEC 保留到发版前 |

---

## 14. 恢复现场 · 命令清单

```bash
subst S: "D:\桌面\汇课"; cd /s/
flutter pub get
dart run build_runner build                 # schema 有改动时必须重跑
flutter analyze && flutter test             # 期望：无问题 + 110/110
flutter build apk --release                 # 期望：app-release.apk（通用包，三 ABI，约 62MB）
# 需要按 ABI 分包的签名档时：flutter build apk --release --split-per-abi

export MSYS_NO_PATHCONV=1
D:/Tools/android-sdk/platform-tools/adb.exe install -r 'S:\build\app\outputs\flutter-apk\app-release.apk'
D:/Tools/android-sdk/platform-tools/adb.exe shell am start -W -n com.huike.huike_timetable/.MainActivity

# 装机后建议自测：
# 引导页选「南昌工学院」→ 建校 → 加课 → 今日议程 / 整周议程
# → 设置 → 调休 / 停课：加一条「今天停课」+ 一条「调休按周五」→ 回今日与整周核对
# → 右上角导入 → 确认地址（默认 http://jwxt.ncpu.edu.cn）→ 登录 →
#   跨域时确认「允许访问新域名」→ 执行导入 → 预览 → 确认写入
```

---

## 15. 需要用户提供 / 确认

1. **真实教务导入结果**：是否命中适配器；跨域确认弹窗是否正常；失败时的现象。
2. 是否现在换正式 keystore（换签需卸载重装，会丢本机数据）。
3. iOS 是否需要（需要 mac 环境）。
4. 是否要清理仓库里的历史遗留物（ISSUE-008）。

## 16. 事实等级

- `CONFIRMED`：`analyze` 干净、`flutter test` **110/110**（2026-09-14）、schema v3 代码生成与
  内存库读写、导入链路与地址校验的逻辑层（单测）、校历例外的折算与界面接线（单测 + widget 测试）、
  南工作息与档案（单测）、首页两视图（今日/整周议程）在 `ncpu_api36` 上的空课/单课/多课、
  夜间与窄屏 360dp 实画、release `0.1.1+2` 的 `INTERNET` 与明文配置、仓库公开可匿名读。
- `UNVERIFIED`：真实教务导入、跨域确认弹窗与 800ms 探测节奏的装机观感、调休页与整周调休小签的观感、
  arm64 真机安装、**v2→v3 迁移在真机老库上的执行**（无迁移测试）、iOS 构建、小组件与提醒（未开始）。
- `BLOCKED`：TASK-006 真实导入验收（等用户真机操作）。

---

## 17. 与用户协作的注意事项

- **用户是产品负责人，不是测试员**：不要把实现层面的选择交给用户，也不要展示内部过程
  （探测顺序、重试、请求间隔都由 App 承担，见 DEC-007）。用户只做
  「填地址 → 登录 → 点导入 → 确认写入」。
- **汇报要贴内容，不要只给文件路径**：用户明确要求「在对话中看到」规则、选项与改动的正文。
- **决策、问题、任务用 `DEC-` / `ISSUE-` / `TASK-` 编号**，在讨论与提交信息里引用编号。
- **不要问「要不要我继续」**：可逆且属于原请求范围内的事直接做完，只对破坏性动作或范围变更
  才停下来确认。
- 用户否定过的方向不要重提：按校明文白名单、日历卡片式图标、把内部机制暴露给用户。
