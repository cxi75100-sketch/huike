# 框架报告 — 第三方依赖

2026-10-03 TASK-WEBVIEW-FRAMEWORK-01：vendored Android 1.1.3除ProGuard补丁外，新增由Dart导航策略快照驱动的同步解释器、settings扩展parse/toMap/动态更新与两个Client同步分支。下方“没有原生自定义/只有ProGuard补丁”是历史基线，当前以本节为准。升级要保留并复验导航快照及失败恢复；没有新增包或版本升级，平台网络放行保持。

## Last Updated

2026-10-03 +08:00 ｜ Android同步导航补丁；无新增依赖

当前图标生成入口tools/make_icon.py：Android adaptive/monochrome及独立splash生成矢量，旧PNG与iOS仍原样复制native模板；verify_icon.py核对引用/尺寸/字节/安全圆。下方10-01复制模式及历史图标说明不代表当前Android adaptive接线。几何来源Flutter SDK BSD-3-Clause，声明增补于THIRD_PARTY_NOTICES.md，原MIT署名保持。

当前增补：sqlite3 3.5.2由已有间接依赖改为直接依赖（版本未升级），用于只读旧库导入。Android增加huike/legacyUpgrade，签名归flavor，升级签名配置只经HUIKE_UPGRADE_SIGNING_PROPERTIES指向仓库外本地properties，无密码入库。图标不再通过flutter_launcher_icons生成，统一tools/make_icon.py原样复制native模板，verify_icon.py核对。构建必须显式指定flavor；见本轮报告。

证据来源：2026-09-28 只读代码调研（`pubspec.yaml` / `pubspec.lock` / 全仓 grep 引用面 / 平台配置逐项核对）。

**用途**：升级任一依赖前先看这里——知道「本项目在哪里用了它、薄层封装在哪、升级要检查什么」。

---

## 1. 边界

**负责**：直接依赖与其精确版本、每个依赖在本项目的引用面（文件数与 API 清单）、`dependency_overrides` 与 vendored 包、平台配置（SDK 版本 / 明文 HTTP / ATS / 权限）、升级敏感位点。

**不负责**：这些依赖承载的业务实现（→ 对应的功能框架报告）；本文件不构成任何升级建议。

---

## 2. 总表

| 依赖 | `pubspec.yaml` 约束 | `pubspec.lock` 精确版本 | import 文件数（lib / test） | 主要 API | 薄层封装位置 |
| --- | --- | --- | --- | --- | --- |
| `flutter_riverpod` | `^3.4.3` | 3.4.3 | 27 / 10 | 见 §3 | 无集中封装；入口 `main.dart`（`ProviderContainer` + `UncontrolledProviderScope`）、`app.dart` |
| `riverpod` | 未直接声明（transitive） | 3.4.3 | — | 同上（经 `flutter_riverpod` 转出） | — |
| `go_router` | `^18.0.1` | 18.0.1 | 13 / 2 | 见 §4 | `lib/core/router/app_router.dart`、`lib/core/router/glass_page.dart` |
| `drift` | `^2.34.4` | **2.35.0** | 9 / 11 | 见 §5 | `lib/core/database/app_database.dart`、`database_provider.dart`、3 个 repository |
| `drift_dev`（dev） | `^2.34.6` | **2.35.0** | — | 代码生成 | 产物 `lib/core/database/app_database.g.dart` |
| `path_provider` | `^2.1.6` | 2.1.6 | 1 / 0 | `getApplicationDocumentsDirectory` | `lib/core/database/database_provider.dart:15` |
| `flutter_inappwebview` | `^6.1.5` | 6.1.5 | 2 / 0 | 见 §7 | `import_web_page.dart`、`adapter_bridge.dart`、`import_session_cleaner.dart`、`navigation_policy.dart` |
| `flutter_localizations` | `sdk: flutter` | sdk | 1 / 0 | `Global*Localizations.delegate` | `lib/app.dart:71-76` |
| `intl` | `^0.20.2` | 0.20.3 | 3 / 0 | `DateFormat` | 无封装，3 处页面直接用 |
| `flutter_launcher_icons`（dev） | `^0.14.4` | 0.14.4 | — | 图标生成 | `pubspec.yaml:43-51` + `tools/make_icon.py` / `tools/verify_icon.py` |
| `sqlite3_flutter_libs` | **未声明** | **不在 lock 中** | 0 | — | 不适用（见 §5 末尾） |

其他 lock 版本：`build_runner` 2.16.1、`flutter_lints` 6.0.0、`sqlite3` 3.5.2、`jni` / `jni_flutter` 1.0.3、`flutter_inappwebview_android` **1.1.3（`source: path`）**、`flutter_inappwebview_ios/macos/web` 1.1.2、`flutter_inappwebview_windows` 0.6.0、`flutter_inappwebview_platform_interface` 1.3.0+1。

`pubspec.lock` 的 sdks：`dart: ">=3.13.2 <4.0.0"`、`flutter: ">=3.44.0"`。`pubspec.yaml:7` 只声明 `sdk: ^3.13.2`，**未声明 flutter 约束**。App 版本 `0.1.4+5`。

## 3. flutter_riverpod

- 引用面：**lib 27 个文件，test 10 个**。
- API 用量：

| API | 数量 / 位置 |
| --- | --- |
| `ConsumerWidget` | 7 个类（5 个设置页 + `course_detail_page.dart:19` + `today_page.dart:136`） |
| `ConsumerStatefulWidget`/`ConsumerState` | 8 个类（`app.dart:14`、3 个导入页、`onboarding_page.dart:22`、`today_page.dart:18`、`course_edit_page.dart:26`、`timetable_page.dart:38`） |
| `Provider` | 14 处 |
| `Provider.family` | 8 处 |
| `Provider.autoDispose` | 6 处 |
| `StreamProvider` | 9 处（含 `.family` 5、`.autoDispose.family` 1） |
| `FutureProvider` | 2 处（`adapter_catalog.dart:70`、`school_repository.dart:262`） |
| `NotifierProvider` | 1 处（`import_session.dart:111`） |
| `AsyncNotifierProvider` | 1 处（`theme_preference_provider.dart:24`） |
| `UncontrolledProviderScope` | 仅 `main.dart:22` |
| `ProviderScope` | **无实际使用**（只在 `database_provider.dart:11` 注释中出现） |
| `ref.watch` / `ref.read` / `ref.listen` / `ref.invalidate` | 84 / 24 / **2** / 5 处 |
| `ref.onDispose` | 2 处 |
| `WidgetRef` 类型 | 15 次 |

- **无 `riverpod_annotation`、无代码生成**：全部 provider 手写（grep 0 命中）。
- 命名与存放约定：顶层 provider 声明 **28 处**；只有 2 个 `providers/` 目录（`lib/features/schools/providers/`、`lib/features/timetable/providers/`），其余 11 处散落在 `core/database`、`core/router`、`core/theme`、`core/widgets`、`features/import/{pages,services}`、`features/schools/services`。后缀统一 `xxxProvider`。
- 测试侧注入：`databaseProvider.overrideWithValue(NativeDatabase.memory())`（5 个用例文件）。
- 详细 provider 表见 `framework_data.md` §5。

## 4. go_router

- 引用面：**lib 13 个文件，test 2 个**。
- API 计数：`GoRoute` 18、`GoRouter` 9、`StatefulShellRoute` 1、`StatefulShellBranch` 2、`CustomTransitionPage` 3、`MaterialPage` 2、`pageBuilder` 3、`redirect` 2、`refreshListenable` 2、`GoRouterState` 2、`initialLocation` 1、`navigatorKey` 1、`context.push` 20（7 文件）、`context.go` 3、`GoRouter.of` 4。
- **0 命中**：`errorBuilder`、`NoTransitionPage`、`context.replace`、`context.pushReplacement`、`context.pop`。
- 路由表与 Page 类型见 `framework_navigation.md` §3（权威）。
- **版本敏感位点**：`StatefulShellRoute` 使用 `builder` + **`navigatorContainerBuilder`**（`app_router.dart:64-71`，配 `timetable_root_shell.dart:132` 的 `RetainedTimetablePages`）与 `StatefulShellBranch(preload: true)` —— 这两个是较新演进的接口，升级时要重点回归：分支切换（`goBranch`）、保留容器、返回行为。

## 5. drift / drift_dev / sqlite3

- 引用面：`package:drift/*` **lib 9 个，test 11 个**（test 侧都 import `package:drift/native.dart` 建内存库）。
- 生成代码：唯一产物 `lib/core/database/app_database.g.dart`（4308 行，`part of 'app_database.dart'`），**已入 git**，**不得手改**。
- 代码生成命令：`dart run build_runner build --delete-conflicting-outputs`（`README.md:21`）。**项目根无 `build.yaml`**；**无 `.drift` 文件**（schema 全为 Dart 表类）。
- API 用量：`LazyDatabase` 1、`NativeDatabase.createInBackground` 1、`@DriftDatabase` 1、`MigrationStrategy`/`onUpgrade` 1、`db.select` 13、`query.watch()` **6**（Riverpod 接缝）、`transaction` **4**、`insertOnConflictUpdate` 1（settings 写入）、`.delete` 14、`.update` 6、`.into` 7、`watchSingleOrNull` 3、`.get()` 2。
- **0 命中**：`customSelect`、`customStatement`、`execute(`、`Migrator`、`createAll`、手写 `TypeConverter` 子类。
- 枚举转换：`textEnum<T>()` 3 处（`CourseSource`、`SectionGroup`、`CalendarExceptionKind`）→ 生成 `EnumNameConverter`。
- 表名映射：`@DataClassName('SemesterRow')`、`@DataClassName('CalendarExceptionRow')`。
- **`sqlite3_flutter_libs` 不是本项目的依赖**（`pubspec.yaml` / `pubspec.lock` 均无）。`sqlite3` 3.5.2 为 transitive，走 **Dart build hooks**；`README.md:23` 说明其原生库 hook 需访问 GitHub 下载并做 sha256 校验，离线替代见 `knowledge/testing.md`。

## 6. path_provider / intl / flutter_localizations

- `path_provider`：仅 1 处使用，函数只有一个 `getApplicationDocumentsDirectory()`（`database_provider.dart:15`）。
- `intl`：仅日期格式化，`DateFormat` 共 6 处 —— `onboarding_page.dart:235`（`yyyy-MM-dd`）、`calendar_exception_page.dart:120,205,275`（`M月d日`）、`semester_settings_page.dart:60,153`（`yyyy-MM-dd`）。**所有 pattern 硬编码、未传 locale**；**无 `initializeDateFormatting` 调用**。
- `flutter_localizations`：仅 `app.dart:2` import；3 个全局 delegate（`:71-75`）；`supportedLocales: [Locale('zh','CN'), Locale('en','US')]`（`:76`）；**未设置显式 `locale:`**；无 `l10n.yaml`、无 `.arb`。

## 7. flutter_inappwebview 与 vendored 包（重点）

- 引用面：**lib 仅 2 个文件** —— `import_web_page.dart:1`、`import_session_cleaner.dart:1`。`adapter_bridge.dart` 只在注释里提到该包（它是纯 Dart 的 JS 契约常量）。
- API 用量：`InAppWebView` 1、`initialUrlRequest` + `WebUri` 1、`initialSettings: InAppWebViewSettings` 1、`onWebViewCreated` 1、`onLoadStop` 1、`evaluateJavascript` 3、`shouldOverrideUrlLoading` 1、`onProgressChanged` 1、`addJavaScriptHandler` **8 处**、`clearAllCache` 1。
- **未使用**：`creationParams`、`onReceivedHttpError`、`onConsoleMessage`、`CookieManager`、全部旧式 options（`InAppWebViewOptions`、`InAppWebViewGroupOptions`、`initialFile`、`initialData`、`onLoadError`、`androidOnPermissionRequest` —— 0 命中，**未踩 deprecated 选项**）。

### `third_party/` 是什么

- 只有两项：`third_party/README.md` 与 `third_party/flutter_inappwebview_android/`（pub.dev 上 **1.1.3** 的整包源码，Apache-2.0，含原 LICENSE/CHANGELOG，**207 个文件全部入 git**）。
- 接入方式：`pubspec.yaml:34-36` 的 `dependency_overrides: flutter_inappwebview_android: path: third_party/flutter_inappwebview_android`；lock 中为 `direct overridden` + `source: path` + 1.1.3。
- 改动内容与意图（读自 `third_party/README.md`）：
  1. `third_party/flutter_inappwebview_android/android/build.gradle` 的两个 build type 把 ProGuard 文件从 AGP 9 已移除的 `proguard-android.txt` 换成 `proguard-android-optimize.txt`。
  2. 包内 `analysis_options.yaml` 把 `lib/**` 排除出仓库级 lint（vendored 上游代码逐字节保留）。
  3. README 声明的动机：Pub cache 清理后与新机器上保持 Android 构建可复现，同时保留稳定的 1.1.3 API；并明确「**不要给 vendored 包加无关改动；上游发布兼容稳定版时移除 override 并重跑完整 Android 验证管线**」。
- **注意**：项目根 `analysis_options.yaml:12-16` 的 exclude 只有 `build/**`、`android/**`、`ios/**`，**不含 `third_party/**`**；vendored `lib/**` 不被分析依赖的是包内那份 `analysis_options.yaml`。**删除或移动该文件会让 vendored 源码进入根分析。**
- 相关记录：`knowledge/testing.md:112`、两份 handoff 报告都把它记为「AGP 9 兼容补丁」。

## 8. 平台配置

| 项 | 事实 | 来源 |
| --- | --- | --- |
| minSdk / targetSdk / compileSdk / ndk | **全部来自 Flutter 默认值**（`flutter.minSdkVersion` 等），本项目无硬编码数字 | `android/app/build.gradle.kts` |
| Java / Kotlin target | 17 | 同上 |
| AGP / Kotlin / Gradle | AGP 9.1.0、Kotlin 2.4.0、wrapper 9.3.1-all | `android/settings.gradle.kts`、`gradle.properties` |
| applicationId / namespace | `com.huike.huike_timetable` | `android/app/build.gradle.kts` |
| Android 明文 HTTP | `network_security_config.xml:11` = `<base-config cleartextTrafficPermitted="true"/>`（**全局放行**），文件头注释列出三层应用内约束 | 见 `framework_import.md` §7.1 |
| Android 权限 | **仅 `android.permission.INTERNET`**；另有 `<queries>` 声明 `PROCESS_TEXT`。无存储/相机/位置权限 | `AndroidManifest.xml` |
| Activity | `.MainActivity`、`exported=true`、`launchMode=singleTop`、`taskAffinity=""`、`windowSoftInputMode=adjustResize` | 同上 |
| iOS ATS | 只有 `NSAllowsArbitraryLoadsInWebContent = true`（仅 WebView）；无 `NSAllowsArbitraryLoads` | `ios/Runner/Info.plist:5-9` |
| iOS 其他 | `CADisableMinimumFrameDurationOnPhone = true`、`CFBundleDisplayName = 汇课`、`UIApplicationSceneManifest`、竖屏+横屏 | 同上 |
| iOS 部署目标 | `IPHONEOS_DEPLOYMENT_TARGET = 15.0`（3 处一致）、`SWIFT_VERSION = 5.0` | `ios/Runner.xcodeproj/project.pbxproj` |
| iOS 插件解析 | **无 `ios/Podfile`、无 `Podfile.lock`**（未跑过 pod install）；`.flutter-plugins-dependencies` 里 `swift_package_manager_enabled = {ios: false}`，但 `project.pbxproj` 已含 `FlutterGeneratedPluginSwiftPackage` 引用且该目录存在 → **两处信号不一致，方式不确定** | — |
| 插件清单 | android：`flutter_inappwebview_android, jni, jni_flutter, path_provider_android`；ios：`flutter_inappwebview_ios, path_provider_foundation`；windows：`flutter_inappwebview_windows, jni`；linux：`jni, path_provider_linux`；web：`flutter_inappwebview_web` | `.flutter-plugins-dependencies` |

**为本项目依赖做的平台特化配置**只有三处：iOS ATS、Android 明文放行、`third_party` 的 AGP 9 ProGuard 修复（+ 包内 analysis exclude）。**没有**任何 inappwebview 的原生侧自定义。

## 9. 工具脚本（`tools/`）

6 个 Python 脚本，**均非构建链的一部分**：

| 脚本 | 用途 |
| --- | --- |
| `make_icon.py`（70 行） | 生成应用图标（TASK-026 三课程单元汇聚），之后跑既有 `flutter_launcher_icons` |
| `verify_icon.py`（122 行） | 校验原生图标资产（15 个 Android 资源、iOS 文件/slot 尺寸/不透明/单色一致） |
| `make_icon_candidates.py`（252 行） | 生成 4 个候选图标到 `assets/icon/candidates/` |
| `patch_day_groups.py`、`patch_slot_board.py`、`patch_week_board.py` | 一次性结构改写脚本，正文自述「运行一次即可」；被 `issues.md`（ISSUE-008）列为历史遗留物 |

**没有**依赖版本校验或锁文件校验类工具。

## 10. 升级敏感位点（事实，不含建议）

| # | 事实 |
| --- | --- |
| 1 | `dependency_overrides` **仅 1 条**：`flutter_inappwebview_android` → vendored path。**升级 `flutter_inappwebview` 根包时，`_android` 版本不会自动跟随，仍固定为 vendored 1.1.3** |
| 2 | `drift` 与 `drift_dev` 的约束都解析到 2.35.0，但声明不同步（`^2.34.4` vs `^2.34.6`） |
| 3 | **声明但全仓零使用**：`yaml: ^3.1.3`（`pubspec.yaml:21`；`catalog.json` 走 `dart:convert`）、`cupertino_icons: ^1.0.8`（`:14`） |
| 4 | 全部依赖均为 caret 约束；**无 `any`、无 `=` 锁定** |
| 5 | 未发现文本层面的 deprecated 用法（Flutter/Riverpod/go_router/inappwebview 各名单 0 命中）；`lib/` 内无 `@deprecated` 标注。**但未运行 analyze，不能排除引用了某包自身 deprecated 成员而未命中名单的情况** |
| 6 | go_router 18 特有 API 已用于 `app_router.dart:64-71`；`StatefulShellBranch(preload: true)` 同属版本敏感位点 |
| 7 | `pubspec.yaml` **未声明 flutter SDK 约束**（lock 里是 `>=3.44.0`） |
| 8 | 本机环境约束（影响升级验证）：中文路径需 `subst S:`；`report_2026-09-27_app_icon.md:48` 记录 `dart run` 曾触发 `path` 依赖解析异常（`S:\S:\third_party...`）；sqlite3 原生 hook 需访问 GitHub |

## 11. 唯一定义点

| 策略 | 唯一位置 |
| --- | --- |
| 依赖清单与约束 | `pubspec.yaml`（不要绕过 `dependency_overrides` 另加补丁） |
| vendored 包与其改动理由 | `third_party/README.md` |
| 第三方署名与许可 | `THIRD_PARTY_NOTICES.md`（**不得删除或改写**） |
| Riverpod 的容器挂载 | `main.dart`（`ProviderContainer` + `UncontrolledProviderScope`） |
| GoRouter 实例 | `app_router.dart` |
| Drift 生成配置与产物 | `app_database.dart` + `app_database.g.dart` |
| 平台明文/A TS 放行 | `network_security_config.xml` / `Info.plist`（见 `framework_import.md` §7.1） |

## 12. 改动时必须同步的位置

- 升级/替换任一依赖 → 本文件 §2 总表（版本 + 引用面）+ §10 敏感位点 + 跑 `flutter analyze` 与 `flutter test` + 真机回归（`testing.md`）
- 动 `pubspec.yaml` 的 assets/dev_dependencies → §2、§9
- 动 `third_party/` → `third_party/README.md` + `pubspec.yaml` 的 override + 本文件 §7 + **重跑完整 Android 验证管线**
- 加新依赖 → 本文件全部相关小节 + `changelog.md`
- 改平台配置（权限/ATS/明文/SDK）→ §8 + **按 `AGENTS.md` 做入口盘点** + `framework_import.md` §7

---

## 13. 已知问题与技术债

- **索引表 G**：`AndroidManifest.xml:3-5` 注释与 `network_security_config.xml:11` 全局放行明文相矛盾（注释待修，代码为准）。
- **索引表 M**：`yaml` 与 `cupertino_icons` 声明但零使用。
- vendored 包的版本漂移风险：根包升级不会带动 `_android` 子包（§10 #1）；`third_party/README.md` 已写明退出条件。
- `drift` / `drift_dev` 约束不同步（§10 #2）。
- iOS 插件解析方式两处信号矛盾（§8），而 **iOS 侧完全没有 Podfile** → 新机器上能否直接构建 `UNVERIFIED`。
- `tools/patch_*.py` 三个一次性脚本仍留在仓库（ISSUE-008）。
- `pubspec.yaml` 未声明 flutter SDK 约束（§10 #7）。
- 项目根 `analysis_options.yaml` 的 exclude 不含 `third_party/`，vendored 源码的分析排除依赖包内文件（§7 末）。

---

## 14. 未验证边界

- **iOS 构建（无 Podfile / SPM 信号不一致）：`UNVERIFIED`** —— 不做 iOS 可用性宣称。
- 依赖升级后的实际回归：本文件**未做任何升级验证**，§10 只是敏感位点清单。
- 未运行 `flutter pub outdated` / `flutter pub deps` 类只读检查（本次范围外）。
- vendored `_android` 补丁在真机 AGP 9 构建下的实际产物：`UNVERIFIED`（`testing.md` 记录过 Debug APK 构建通过，但本次未复跑）。

---

## 15. 更新记录

| 日期 | 变更 | 依据 |
| --- | --- | --- |
| 2026-09-28 | 首次建立：6 个直接依赖 + vendored 包、引用面计数、API 清单、平台配置、升级敏感位点 | 2026-09-28 只读调研 |
