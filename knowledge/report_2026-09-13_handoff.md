# 汇课 · 进度与技术接手报告

Date: 2026-09-13
Version: 0.1.0+1（本地）
Status: **可用**（Android 装机验证通过）；真实教务导入与 iOS 未验证；远端未上传（待令牌）

本报告面向「在另一个会话里直接接手」的 Agent 或本人。**先读本文件，再读
`knowledge/current_state.md` 与 `knowledge/tasks.md`**；`AGENTS.md` 是硬性工作规范。

---

## 1. 项目身份与位置

| 项 | 值 |
| --- | --- |
| 应用名 | **汇课**（用户 2026-09-13 确认定稿） |
| 目录 | `D:\桌面\汇课`（独立 git 仓库，与任何单校项目互不引用） |
| 代替路径 | S: 盘（`subst S: "D:\桌面\汇课"`），中文路径下 Flutter 工具链必须在 S: 下跑 |
| 包名 | `com.huike.huike_timetable` |
| 版本 | `0.1.0+1`（pubspec.yaml） |
| 本地提交 | 7 笔，最新 `c1d56cd`；`git log --oneline` 为准 |
| 远端 | `origin` = `https://gitee.com/chenxihh/huike.git`（**已推送**，当前为**私有**；公开需账号完成 2FA/绑定第三方，见 §11） |
| 签名 | release 用 Flutter 默认 debug 证书（自用试用可；正式发布需换正式 keystore） |
| 知识库 | `D:\桌面\汇课\knowledge\`（本报告所在目录） |

## 2. 环境与工具链

- Flutter/Dart：`D:\Tools\flutter`（3.47.2 / Dart 3.13.2）
- JDK 17：`D:\Tools\jdk-17`；Android SDK：`D:\Tools\android-sdk`（platform-tools、build-tools 36.0.0）
- 模拟器：AVD `ncpu_api36`（API 36 / x86_64，与其它项目共用；本项目包名独立，互不影响）
- 常用命令（Git Bash）：
  ```bash
  subst S: "D:\桌面\汇课"        # 中文路径规避（只需一次）
  cd /s/ && flutter analyze && flutter test
  flutter build apk --release --split-per-abi
  export MSYS_NO_PATHCONV=1      # 否则 adb 的 /sdcard/... 路径会被 Git Bash 改写
  D:/Tools/android-sdk/platform-tools/adb.exe install -r 'S:\build\app\outputs\flutter-apk\app-arm64-v8a-release.apk'
  ```
- **sqlite3 hook 离线构建**（重要）：`sqlite3` 3.5.2 的 Dart hook 会从 GitHub 下载
  `libsqlite3.*.so`，缓存于项目内 `.dart_tool/hooks_runner/shared/sqlite3/build/download-<hash>/`
  （带 sha256 校验）。GitHub 直连不通（Clash 关）时构建必失败；把同版本工程的
  `download-*` 目录整目录拷过来即可复用（已验证）。同版本判据 = 两份 `pubspec.lock`
  里 `sqlite3` 的 sha256 一致。

## 3. 构建与验证基线（截至报告时）

| 检查 | 结果 | 证据 |
| --- | --- | --- |
| `flutter analyze` | **No issues found** | `S:\` 下执行 |
| `flutter test` | **76/76 通过** | 见 §5 测试清单 |
| Debug APK | 构建成功 | `build/app/outputs/flutter-apk/app-debug.apk` |
| Release APK（arm64） | 22,630,026 B / SHA-256 `0e244ad154546b5b…` | `app-arm64-v8a-release.apk` |
| Release APK（v7a） | 20,284,882 B / SHA-256 `359a5a9b2abab4b8…` | `app-armeabi-v7a-release.apk` |
| Release APK（x86_64） | 24,147,294 B / SHA-256 `f70cfc1b48c5692f…` | `app-x86_64-release.apk` |
| release 权限 | `INTERNET` 在包内 | `aapt2 dump permissions` |
| release 明文策略 | `android:networkSecurityConfig=@0x7f110001`，资源存在 | `aapt2 dump xmltree/dump resources` |
| 模拟器冒烟 | 引导→建校→加课→今日时间轴→整周网格→详情→设置→作息→学校管理→删校→导入探测循环，全程 logcat **0** 致命异常 | `ncpu_api36` |
| 真机 | 用户已拿到 release 包自行试用（NCPU 档案 + 教务导入） | `UNVERIFIED`（结果待用户反馈） |
| iOS | 未构建 | `UNVERIFIED` |

## 4. 代码地图（关键文件与职责）

```
lib/
  main.dart / app.dart                     入口；MaterialApp.router + 明暗主题 + 中文本地化
  core/database/app_database.dart          Drift schema v2 + 行→模型映射 + 迁移(v1→v2)
  core/database/database_provider.dart     全局库（LazyDatabase；测试注入内存库）
  core/router/app_router.dart              路由表；**单实例 + refreshListenable**（见 §10 坑 3）
  core/theme/app_palette.dart              「新历书」调色板（日/夜）
  core/theme/app_theme.dart                ThemeData（圆角系统锁、发丝线、组件样式）
  core/theme/course_colors.dart            8 色课程签 + 名称散列定色 colorKeyForName
  core/theme/theme_preference*.dart        外观三档 + settings 持久化
  models/school_profile.dart               学校档案（含 presetId、scheduleVariants）
  models/bell_schedule.dart                节次规范 + 时段分组 + ScheduleVariant + 通用兜底(10节)
  models/semester.dart / models/course.dart
  services/week_parser.dart                周次文本解析/格式化（1-16周(单) 等）
  services/semester_service.dart           currentWeek / termStatus / dateFor / weekdayOf
  services/course_time_service.dart        显式时间 > 作息变体 > 基础作息；缺节次返回 null
  features/schools/services/school_presets.dart   **内置档案：南昌工学院**（官方作息+变体+默认地址）
  features/schools/services/school_repository.dart 建校/切换/删校/学期/作息（播种只一次）
  features/schools/services/adapter_catalog.dart   assets/adapters/catalog.json 加载
  features/schools/providers/school_providers.dart 学校流/激活学校/激活学期/作息流(+schoolBellProvider)
  features/import/services/adapter_bridge.dart      **shiguangBridge* 契约桥（8 处理器）**
  features/import/services/import_session.dart      内存暂存（三类原始数据 → 合并规范化）
  features/import/models/adapter_batch.dart         规范化器（无效条目计数不猜语义）
  features/import/services/import_diff.dart         added/removed/changed 差异
  features/import/services/course_repository.dart   导入替换事务 + 手动 CRUD + 内容指纹 id
  features/import/services/navigation_policy.dart   scheme+host 白名单（纯 Dart）
  features/import/services/import_session_cleaner.dart 离页清 HTTP 缓存+内存（保留 Cookie）
  features/import/pages/import_entry_page.dart      入口：地址确认 + 明文警示 + 风险勾选
  features/import/pages/import_web_page.dart        **受限 WebView + 自动逐个尝试适配器 + 汇总弹窗**
  features/import/pages/import_preview_page.dart    差异预览 + 附加选项 + 确认写入
  features/timetable/pages/timetable_page.dart      首页：今日/整周 + hero + 下一节提示
  features/timetable/widgets/day_timeline.dart      **今日：竖向时间轴**（轴+圆点+进行中）
  features/timetable/widgets/section_slot_board.dart **整周：节次槽位网格**
  features/timetable/pages/course_detail_page.dart / course_edit_page.dart
  features/settings/pages/*.dart                    主设置/学校管理/学期/作息
  features/onboarding/pages/onboarding_page.dart    **引导（含「南昌工学院」档案快捷选择）**
assets/
  adapters/catalog.json                    适配器目录（4 条）
  adapters/{zhengfang_01,qingguo_01,urp_01,chaoxing}.js  社区脚本（MIT，署名见 THIRD_PARTY_NOTICES.md）
  icon/{app_icon_android,app_icon_ios,foreground}.png    印章行楷图标（候选在 icon/candidates/）
tools/
  make_icon.py                             图标生成（印章+行楷「汇」+内框）
  make_icon_candidates.py                  4 个候选方案（c1 印章/c2 卡片/c3 四路汇流/c4 隶书）
  patch_*.py                               一次性结构调整脚本（历史用途，可删）
knowledge/                                 知识库（本报告 + current_state/tasks/adapters/design/…）
third_party/flutter_inappwebview_android/  AGP 9 兼容补丁（pubspec dependency_overrides 固定）
```

## 5. 测试清单（76 项）

| 文件 | 覆盖 |
| --- | --- |
| `test/week_parser_test.dart` | 周次解析/格式化（范围、离散、单双周、中英文括号、异常） |
| `test/semester_service_test.dart` | 周次边界、学期状态、日期换算（不夹取/夹取） |
| `test/bell_schedule_test.dart` | 通用兜底 10 节（晚 2 节）、分组、跨节解析、**作息变体**、JSON 往返 |
| `test/school_presets_test.dart` | 南工档案 10 节逐节时间、明志/明德/至善变体、CourseTimeService 组合、默认明文地址 |
| `test/adapter_batch_test.dart` | 契约形状规范化、weeks 文本、非法条目计数、时间/配置边界 |
| `test/import_diff_test.dart` | added/removed/changed、周次乱序不算修改 |
| `test/adapter_bridge_test.dart` | 8 处理器齐、契约名保持、幂等、不落盘 |
| `test/adapter_catalog_test.dart` | 目录 4 条、资产存在、脚本用桥契约 |
| `test/course_repository_test.dart` | 内存库：播种一次、导入替换保手动、跨校隔离、指纹 id、级联删除、设置 |
| `test/course_time_service_test.dart` | 显式时间优先、缺节次 null、equalsFallback |
| `test/app_shell_test.dart` | App 壳 widget：引导→建校→首页；空课日空状态 |

## 6. 适配器体系（核心资产）

**契约桥**（`adapter_bridge.dart`，与社区脚本兼容，脚本零修改可跑）：

| API | 形态 | 返回 |
| --- | --- | --- |
| `shiguangBridge.showToast(msg)` | 同步 | — |
| `shiguangBridge.notifyTaskCompletion()` | 同步 | —（脚本执行完毕信号） |
| `shiguangBridgePromise.showAlert(title,msg,btn)` | 异步 | bool |
| `shiguangBridgePromise.showSingleSelection(title,jsonNames,defaultIdx)` | 异步 | 选中下标 int / null |
| `shiguangBridgePromise.showPrompt(title,msg,default,validator?)` | 异步 | String / null |
| `shiguangBridgePromise.saveImportedCourses(json)` | 异步 | bool |
| `shiguangBridgePromise.savePresetTimeSlots(json)` | 异步 | bool |
| `shiguangBridgePromise.saveCourseConfig(json)` | 异步 | bool |

数据形状：courses `[{name,teacher,position,day(1-7),startSection,endSection,weeks[]}]`、
timeSlots `[{number,startTime,endTime}]`、courseConfig `{semesterStartDate,totalWeeks}`。
脚本来源：社区仓库 `xingheyuzhuan/shiguang_warehouse`（MIT），署名在 `THIRD_PARTY_NOTICES.md`。

**导入流程**（`import_web_page.dart`）：入口确认地址（明文 HTTP 额外警示）→ 受限 WebView
（host 白名单，scheme 跟随确认的地址）→ 点「执行导入」→ **依次自动尝试全部内置适配器**
（每个脚本自己校验页面；桥弹窗打开时暂停该次超时 25s）→ 成功即进预览，全部失败弹逐项汇总。
三类 `save*` 只进内存（`import_session.dart`），落库必须经预览确认
（`import_preview_page.dart`：新增/移除/修改/无效四类 + 「同时更新作息」「更新学期配置」勾选）。

**明文 HTTP 策略（2026-09-13 变更）**：多校现实是大量教务为明文，Android/iOS 无法运行期
新增放行域名 → 现策略为**放开明文**（Android `base-config cleartextTrafficPermitted=true`；
iOS `NSAllowsArbitraryLoadsInWebContent=true`，仅 WebView），应用层两道门保留：入口确认 +
明文警示 + 导航仅限确认过的主机。本应用唯一网络消费是导入 WebView。

## 7. 数据模型（schema v2）

- `schools(id, displayName, adapterId, presetId, loginUrl, acceptedHostsJson, scheduleVariantsJson, createdAt)`
- `semesters(id, schoolId, firstWeekMondayIso, totalWeeks)` —— 生成类名 `SemesterRow`
- `course_entries(id, schoolId, semesterId, source(manual|imported), name, teacher, classroom,
  weekday, startSection, endSection, weeksJson, startTime?, endTime?, note, colorKey)`
- `section_time_entries(schoolId+sectionIndex, start, end, periodGroup)`
- `settings(key, value)`：`theme_mode` / `active_school_id` / `active_semester:<schoolId>`
- **无任何内置默认学校**；引导页必建校；导入 id = 内容指纹（同内容同 id，周次段不同则不同）。
- v1→v2 迁移：学校表新增 `presetId`、`scheduleVariantsJson`（`addColumn`）。

## 8. 设计语言「新历书」

单朱砂强调色（日 `#C3402B` / 夜 `#E0604A`）；纸白与墨；结构靠发丝线不堆卡片；
圆角系统锁（区块 12 / 控件 10 / 小签 4）；课程签只用 8 色低饱和色且只在小块面；
数字 tabular figures；动效克制。
**两个课表视图刻意不同**：整周 = 节次槽位网格（一天一列、横向翻页、当前周今天优先循环排列、
打开必见今天）；今日 = 竖向时间轴（轴线 + 节次圆点 + 进行中朱砂强调 + 卡片贴内容高度 +
「下一节」提示条）。图标 = 朱砂印章 + 华文行楷「汇」+ 白内框（`tools/make_icon.py`）。

## 9. 已完成

- TASK-000 仓库/AGENTS/知识库；TASK-001 多校基座（模型/导入链路/两视图/主题/图标）；
- 用户反馈迭代 5 轮：适配自动探测、印章图标（否掉两版日历卡）、横向周历今天优先、
  南工内置档案与变体作息、卡片信息完整 + 晚上两节、今日时间轴与整周区分、明文 HTTP 放开。
- 老仓库（南工）已记录「多校转独立软件」决策并推送 Gitee（`8c17a86` 读回一致）。

## 10. 错误与踩坑报告（按重要性）

1. **Riverpod 3 无 `valueOrNull`** → 全部改 `.value`（`AsyncValue.value` 不再抛异常）。
2. **生成类与模型重名**：`Semesters` 表生成 `Semester` 与模型冲突 → `@DataClassName('SemesterRow')`。
3. **GoRouter 不能重建**：`appRouterProvider` 里 `ref.watch` 学校流会每次重建 Router，
   与 `context.go('/')` 竞争导致导航悬挂（widget 测试 pumpAndSettle 超时）。修：单实例 +
   `refreshListenable` 计数 notifier；navigator key 用 `rootNavigatorKeyProvider`（**不能是全局
   GlobalKey**，否则跨测试挂载冲突）。
4. **sqlite3 下载失败**（详见 §2）；release 构建额外注意 `networkSecurityConfig` 资源会被编进
   resources.arsc，`unzip -l` 看不到，要用 `aapt2 dump resources/xmltree` 验证。
5. **图标两次被否**：程序化日历卡被用户评为「丑」两次 → 改为印章 + 行楷「汇」获认可；
   `PIL` 的 CJK 锚点不可靠（`anchor='mm'` 会让字跑到角落），必须用像素包围盒居中 +
   光学上提 2.5%；band 圆角下沿缺口用 `corners=(True,True,False,False)` 解决。
6. **卡片空隙**：信息贴底 + Spacer 会把跨节次卡片中间拉出大片空白；`Align` 在该场景不收敛，
   最终用 `Expanded → Padding → Column[卡片]` 保证卡片贴内容高度。
7. **明文策略反复**：先做了「仅南工白名单」被用户指出其它 HTTP 学校不可用 → 改为放开明文 +
   双重确认（§6）。教训：多校工具不能按校逐个个案放行。
8. **学校管理 UX 缺陷**：正在使用的学校原本不给操作菜单 → 无法删除；已改为始终提供溢出菜单。
9. **Shell 补丁事故**：用 python heredoc 打大段 Dart 补丁多次出现引号/缩进错误（甚至把文件
   打坏 47 个错误）→ 教训：大段代码改动用 Write 整文件重写，别用 shell 字符串替换。
10. **iOS plist 静默未命中**：`if key not in s` + `replace` 未被匹配时仍打印成功 → 教训：
    替换后必须断言命中或复核文件。
11. **adb 中文输入不可用**（标准 IME 只能 ASCII）→ 涉及中文教室/课名的 UI 路径只能在单测里
    验证（如明志楼变体），模拟器上只能验基础分支；uiautomator dump 里 Flutter 文本在
    `content-desc`/`text` 两个属性，且长文本是整段含 `&#10;` 换行。
12. **模拟器遗留**：`ncpu_api36` 上留有一门冒烟课「TimelineClass」（周日 1-4 节）与
    学校「南昌工学院」，进详情点删除即可；保留学校方便继续试用。

## 11. 待办与阻塞

| 项 | 状态 | 说明 |
| --- | --- | --- |
| **上传 Gitee 新仓库** | **已完成（2026-09-13）** | 仓库 `chenxihh/huike`；master 读回 `8cdccda`、tag `v0.1.0` 指向同一提交；推送前做过敏感信息扫描（无凭据/无真实课表数据/构建产物未入库） |
| 仓库转为公开 | **BLOCKED（需用户操作）** | Gitee 返回：`您的帐号安全评级较低，发布公开内容前请在「个人设置」完成2FA设置，或绑定可靠第三方帐号`。用户在 Gitee 完成 2FA 或绑定后，我可用同一条 PATCH 改公开（`private=false` + `name=huike`） |
| TASK-002 桌面小组件 | 未开始 | 建议载荷 v2：Dart 预计算整学期每日课程，原生只查表（消除双实现） |
| TASK-003 上课提醒 | 未开始 | 迁移 + 按学校/学期排程，时区语义「课程所在地墙上时间」 |
| TASK-004 调休/停课例外表 | 未开始 | 用户可编辑 CalendarException |
| TASK-005 适配器目录联网更新 | 未开始 | 需先定配置源与校验策略 |
| TASK-006 真实教务导入验收 | **BLOCKED（等用户真机反馈）** | 南工已预填地址；若四个通用脚本在南工（新正方 jwglxt）都不命中，需按已确认的接口形状写南工专用适配脚本 |
| iOS 构建 | 未做 | ATS 已按 WebView-only 放开；未在 mac 上构建 |
| GitHub 镜像 | 未做 | 需 Clash 开启 + 新建 GitHub 仓库；当前 Clash 关闭 |
| 老仓库 GitHub 镜像 | 落后一笔 | `8c17a86` 只推了 Gitee；Clash 开时补推 `git push github master` 并读回 |

**上传命令（已完成，留档备查；令牌已用毕，需撤销）**：

```bash
# 1) 建仓（令牌仅在本次命令的环境变量里，不落盘、不写日志）
curl -s -X POST "https://gitee.com/api/v5/user/repos" \
  -d "access_token=$GITEE_TOKEN" -d "name=huike" -d "private=false" \
  -d "description=汇课：多校通用本地课表 App"
# 2) 配远端并推送（含 tag）
cd "D:\桌面\汇课"
git remote add origin https://gitee.com/<user>/huike.git
git push "https://<user>:<TOKEN>@gitee.com/<user>/huike.git" master
# 3) 读回校验
git ls-remote https://gitee.com/<user>/huike.git refs/heads/master   # 应等于本地 HEAD
```

## 12. 恢复现场 · 命令清单

```bash
subst S: "D:\桌面\汇课"; cd /s/
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # drift 生成
flutter analyze && flutter test                            # 期望: 无问题 + 76/76
flutter build apk --release --split-per-abi                # 期望: 三个 APK
export MSYS_NO_PATHCONV=1
adb install -r 'S:\build\app\outputs\flutter-apk\app-arm64-v8a-release.apk'
adb shell am start -W -n com.huike.huike_timetable/.MainActivity
# 装机后自测：引导页选「南昌工学院」→ 建校 → 加课 → 今日时间轴 / 整周网格 →
# 右上角导入 → 确认地址（默认 http://jwxt.ncpu.edu.cn）→ 登录 → 执行导入
```

## 13. 需要用户提供/确认

1. **Gitee 令牌**（projects 权限）→ 我建仓 + 推送 + 读回校验，用完请撤销。
2. **真机导入结果**：南工执行导入后是否命中适配器；失败汇总截图。
3. 是否要出正式签名（换 keystore 需卸载重装，会丢本机数据）。
4. iOS 是否需要（需 mac 环境）。

## 14. 事实等级

- `CONFIRMED`：analyze 干净、测试 76/76、release 构建与包内权限/安全配置、模拟器全流程冒烟
  （含导入探测循环）、南工作息与变体（单测）、图标装机观感、老仓库决策提交推送读回。
- `UNVERIFIED`：真实教务导入、真机 arm64 安装、iOS 构建、桌面小组件与提醒（未开始）。
- `BLOCKED`：Gitee 上传（等令牌）；真实导入验收（等用户真机操作）。
