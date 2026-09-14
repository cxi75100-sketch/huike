# Current State

## Last Updated

2026-09-14 +08:00

## Project Boundary

- `CONFIRMED`：本目录是独立 Git 仓库（`D:\桌面\汇课`），是「汇课」多校通用课表 App 的唯一代码与知识库。
- 本项目与任何单校课表项目相互独立：不共享代码、数据库、签名或知识库；公开文档中不出现彼此的名称与归属关系。
- 参考与引用边界：教务适配脚本来自社区开源仓库（MIT），署名固定在 `THIRD_PARTY_NOTICES.md`，不得删除。

## Handoff

- 完整交接报告：`knowledge/report_2026-09-13_handoff.md`（文件地图、适配契约、错误报告、
  恢复命令、上传模板）。新会话接手请先读它。

## Current Milestone

TASK-001（基座）+ 用户第一轮反馈迭代（自动适配探测、印章行楷图标、
横向周历今天优先、南工内置档案与变体作息、卡片信息完整、晚上两节）
全部完成并经模拟器实测，版本 `0.1.0+1`（工作区，提交以 git log 为准）。
应用图标为「朱砂印章 + 华文行楷汇 + 内框」（用户两轮否定日历卡片方案后定稿；
候选与生成脚本在 assets/icon/candidates/ 与 tools/make_icon*.py）。
2026-09-14 完成 TASK-009：导入链路的跨域导航确认、地址校验统一、探测过程收敛
（落实 `decisions.md` DEC-005/DEC-006/DEC-007）。
下一步按 DEC-009 先做 TASK-004（调休/停课例外表），再做 TASK-002（桌面小组件），
以及真实教务系统的端到端导入验收（TASK-006，等用户真机反馈）。

## Working Features

- Flutter Android/iOS 工程；Riverpod 3 + GoRouter + Drift/SQLite 单机架构，与设计文档一致。
- 多校数据模型（schema **v3**：v2 的 `schools.presetId`/`scheduleVariantsJson` 基础上，
  v3 新增 `calendar_exceptions`（校历例外），见 `app_database.dart` 的 `schemaVersion => 3`）：
  `schools`（用户显式创建，含导航白名单）、
  `semesters`（属于学校，开学周一 + 总周数）、`course_entries`（`schoolId` + `source=manual|imported`）、
  `section_time_entries`（每校一套默认作息，含时段分组）、`calendar_exceptions`（调休/停课）、`settings`。
- 没有任何内置默认学校/学期/作息覆盖路径：`ensureDefaults()` 为空壳，播种只发生在创建学校时一次。
- 通用兜底作息（8:00 起上午四节、14:00 起下午四节、19:00 起晚间 9/10 两节，**共 10 节**），
  仅作播种，`BellSchedule.equalsFallback()` 用于判断「未被修改」。
- 导入链路（TASK-001 核心，TASK-009 修复）：风险确认门（明文 HTTP 额外警示）→ 受限 WebView
  （导航放行范围 = 入口地址 + 学校档案已确认主机 + 会话中新确认主机；主框架跳新主机时
  弹窗确认一次并记住，只增不减）→ 注入社区契约桥 → 点「执行导入」后
  App **自动逐个尝试全部内置适配器**（用户不需要知道学校用什么教务系统，也看不到
  逐个尝试的过程；每个脚本自己校验当前页面，读不到课表就换下一个，脚本之间间隔 800ms；
  桥弹窗打开时暂停该次超时）→
  脚本回传数据全部暂存内存 → 预览页（新增/移除/修改/无效四类明细 + 附加选项）→
  确认后事务替换 (schoolId, semesterId, imported)。全部失败只给一句可操作提示。
  手动课程永不触碰。
- 教务地址校验统一在 `features/schools/services/login_url_policy.dart`（`checkLoginUrl`），
  引导页建校、学校管理改址、导入入口三处共用；http/https 都收，明文由入口额外警示
  （DEC-006，杜绝同一策略多处各写一份）。
- 校历例外「调休 / 停课」：设置里按日期维护，只表达两种语义——**这天停课**，或
  **这天按某个星期的课表上课**（如周六补周四的课）；同一天只保留一条，再填即覆盖。
  折算逻辑是纯函数 `CalendarExceptionService.resolve(date)`，今日页与整周页共用
  （今日：停课显示空状态牌、调休显示「今天按周X的课表上课」；整周：列头给
  「停课 / 调休 · 按周X」小签，课程按折算后的星期取）。换学校/换学期天然隔离，删校级联清除。
- 引导页不要求选教务系统类型：只填学校名称（必填）、教务网址（选填，http/https 均可）、
  开学周一（必填）与总周数；填了网址的学校 adapterId='auto'。
- 社区适配脚本契约完整实现：`shiguangBridge.showToast/notifyTaskCompletion` +
  `shiguangBridgePromise.showAlert/showSingleSelection/showPrompt/saveImportedCourses/
  savePresetTimeSlots/saveCourseConfig`，契约名不变，社区脚本零修改可跑。
  三类 save 只进内存会话；落库必须经预览确认（与「预览确认」准则一致）。
- 导入规范化器 `AdapterBatchNormalizer`：课程（name/day/startSection/endSection/weeks 必需，
  weeks 接受数组或周次文本）、节次时间、学期配置；不满足契约的条目丢弃并计数，
  预览页明示「N 条无效」与原因，不猜语义。
- 课表首页「今日 / 整周」双栏目（新历书设计）：今日历牌 hero（大字日期 + 星期 + 周次 +
  学期状态提示条）+「下一节」提示条（按作息表结束时间取最近未结束的一节）。
- 整周为**节次槽位网格**（`SectionSlotBoard` 窄列）：一节一格（紧凑 64dp），
  课程卡按起止节次占位，信息紧跟课程名排布（名称 + 完整起止时间 + 教室·教师，
  不留中段空白），空槽显示淡节次号与开始时间，上午/下午/晚上作为带时间范围的
  分隔带；上下午不混排，晚上最多两节。
- 今日为**竖向时间轴**（`DayTimeline`，与整周网格刻意区分）：左侧节次时刻 +
  贯穿轴线与圆点，进行中的节次朱砂强调（圆点放大 + 课程条目「进行中」章）；
  课程条目挂在轴右侧、贴内容高度（不被跨节次拉成大空块），左侧色条 +
  完整信息（名称 / 教室·教师 / 起止时间 / 节次）；空档显示「第 N 节」淡刻度。
- 整周为横向翻页周历（PageView，一屏两列）：**打开整周第一列必是今天**——
  当前教学周按「今天 → 之后的日期 → 本周已过去日期」循环排列，其他周按周一到周日；
  当天列朱砂描边 + 「今」章 + 白色表面；周切换器保留。
- 课程 CRUD：手动新增/编辑/删除（表单含星期签、节次下拉、周次文本解析、备注），
  详情页完整元数据。导入课程 id 由内容指纹生成，同内容同 id，供差异比对。
- 学期设置（开学周一选择后自动对齐所在周周一、总周数 1-30）、默认作息编辑（时间选择器，
  手动格式化 HH:mm 避免本地化格式破坏契约）、恢复通用默认（显式操作）。
- 外观三档（跟随系统/日间/夜间）持久化到 settings 表，系统栏图标随明暗切换。
- 学校管理：列表、点按切换激活、修改教务网址（http/https 均可，与建校/导入入口同一判定；
  白名单只增不减）、
  删除学校（级联清数据 + 清激活键，确认弹窗）。切换后另一校数据保留但不显示。
- Android 主清单已声明 `INTERNET`（吸取单校版 release 缺权限的教训）。
- **明文 HTTP 策略（2026-09-13 变更，取代此前的「仅南工白名单」）**：多校现实是大量教务为
  明文且无法运行期新增放行域名，故放开明文——Android `network_security_config`
  base-config 允许明文、iOS `NSAllowsArbitraryLoadsInWebContent`（仅 WebView）；
  应用层两道门保留：导入入口地址确认（明文额外警示）+ 导航仅限确认过的主机。
  本应用唯一网络消费是导入 WebView。

## In Progress

- 无。

## Not Started

- TASK-002 Android 桌面小组件（迁移 + 载荷由 Dart 预计算整学期每日课程，消除双实现）。
- TASK-003 上课提醒（按学校档案与学期排程，时区语义「课程所在地墙上时间」）。
- TASK-005 适配器目录联网更新（需先定配置源与校验策略）。
- 真实教务系统端到端导入验收（TASK-006）：用户已取 release 包在真机试用（南工档案 + 教务导入），
  结果待用户反馈。目前导入链路只有代码、单测与 example.com 探测循环的证据，
  真实教务系统证据仍为 `UNVERIFIED`（`BLOCKED`：等用户真机反馈）。
- iOS 构建验证（`UNVERIFIED`，不阻塞）。

## Current Blockers

- `BLOCKED`：TASK-006 真实教务导入验收，等用户真机反馈（见 `tasks.md` Now）。
  本机 GitHub 直连不可用；`flutter build` 时 sqlite3 hook 需要
  从 GitHub 下载预编译库（见 testing.md 的离线缓存办法），Clash 未开时构建会失败。

## Important Context

- 「汇课」为用户 2026-09-13 确认定稿的名称；改名是纯文案工作。
- 应用包名 `com.huike.huike_timetable`（`flutter create --org com.huike`）。
- 中文路径下 Flutter 工具链需 `subst S: "D:\桌面\汇课"` 后在 `S:\` 执行（同单校项目经验）。
- sqlite3（3.5.2）的 Dart hook 构建期从 GitHub 下载预编译库并缓存在项目内
  `.dart_tool/hooks_runner/shared/sqlite3/build/download-<hash>/`，带 sha256 校验；
  同版本工程的缓存可直接复用（2026-09-13 已这样完成离线构建）。
- 调试 UI 用 `adb shell uiautomator dump` 读语义树（Flutter 文本在 content-desc/text 里）；
  Git Bash 调 adb 传 `/sdcard/...` 路径要设 `MSYS_NO_PATHCONV=1`，native python 读文件用 Windows 路径。
- 模拟器 `ncpu_api36` 是与单校项目共用的验证环境；本项目 App 包名独立（`com.huike.*`），
  冒烟时全程未触及其它应用的数据库。
- Riverpod 3 注意：`AsyncValue.valueOrNull` 已删除，用 `.value`；`RadioListTile` 的
  groupValue/onChanged 已弃用，改用 `RadioGroup` 祖先。
- GoRouter 必须单实例 + `refreshListenable` 做响应式 redirect；重建 Router 会让进行中
  导航悬挂（曾导致 widget 测试 pumpAndSettle 超时）。navigator key 也不能是全局变量，
  用 `rootNavigatorKeyProvider` 每容器一份。

## Validation Snapshot

以下按时间顺序记录，**最新基线在末尾**；早期条目里的测试数（65/65、75/75）是当时基线，
不是当前状态（当前 109/109）。

- `CONFIRMED`（2026-09-13 19:10 +08:00）：`flutter analyze`（`S:\`）No issues found。
- `CONFIRMED`（2026-09-13 19:12 +08:00）：`flutter test` **65/65 通过**。覆盖：周次解析、
  学期服务、作息表、适配器规范化、导入差异、桥契约、数据库/仓库语义（内存库：
  播种一次、导入替换保手动、跨校隔离、级联删除、设置读写）、目录资产、App 壳 widget 流程。
- `CONFIRMED`（2026-09-13 20:10 +08:00）：自动适配探测端到端验证——创建
  adapterId='auto' 的学校（网址 example.com）→ 风险确认 → WebView → 执行导入 →
  四个适配器依次尝试（正方脚本弹出其自带确认框，超时正确暂停；取消后继续）→
  全部失败后弹出逐项汇总弹窗，四条结果文案正确。删除冒烟学校后回到引导页。
  全程 logcat 无 `FATAL EXCEPTION` / `E/flutter`。
- `CONFIRMED`（2026-09-13 20:20 +08:00）：新图标（印章行楷）装机确认，
  应用抽屉中圆形遮罩下内框与字形完整清晰。
- `CONFIRMED`（2026-09-13 19:20 +08:00）：Debug APK 构建成功
  （`build/app/outputs/flutter-apk/app-debug.apk`，含 INTERNET 权限）。
- `CONFIRMED`（2026-09-13 19:00-19:30 +08:00，`ncpu_api36` 模拟器 / API 36 / x86_64）：
  装机冒烟全程通过——冷启动 `Status: ok`；引导页渲染完整 → 创建学校（SmokeUniversity，
  手动类型，开学周一 2026-09-07，20 周）→ 首页 hero「9月13日 星期日 第 1 周」计算正确 →
  整周七天纵列与周切换器正常 → 手动加课（SmokeCourse101，周一第 1 节）落格显示 08:00 →
  课程详情元数据完整 → 设置四组入口正常 → 默认作息 12 节含上下午晚分组（**该时间点的版本；
  同日迭代 `4db55f2` 后兜底作息改为 10 节**）→
  学校管理「使用中」标签与溢出菜单正常 → 导入入口对手动学校显示降级说明 →
  删除学校（确认弹窗）后回到引导页，激活键清除。期间发现并修复「使用中的学校无菜单
  无法删除」缺陷（trailing 改为始终提供 PopupMenuButton）。logcat 全程无
  `FATAL EXCEPTION` / `E/flutter`。共用模拟器上的其它应用数据未被触碰。
- `CONFIRMED`（2026-09-13 23:00 +08:00）：今日时间轴按用户「与整周雷同/卡片
  空隙」反馈重做并在模拟器实测——课程卡贴内容高度（跨节次不再拉成大空块）、
  左侧色条 + 完整信息；整周网格卡同样改为信息紧跟课程名；轴线与进行中强调
  正常。`flutter analyze` 无问题、`flutter test` 75/75、logcat 0 致命异常。
  遗留：模拟器上留有一门冒烟课「TimelineClass」（周日 1-4 节），进详情点
  删除即可，不影响任何功能。
- `CONFIRMED`（2026-09-13 22:10 +08:00）：南工预设端到端实测——引导页点
  「南昌工学院」→ 名称/开学周一(2026-08-31)/周数预填 → 建校后今日页显示
  官方三段范围（08:20-11:55 / 14:00-17:25 / 19:00-20:30 只两槽）→ 加
  明智楼外的教室 3-4 节课显示基础时间 10:25-11:55 与完整卡片信息（名称 +
  完整起止时间 + 教室·教师），第 2 周周次正确；变体路径（明志楼→10:15）由
  `school_presets_test` 锁定（adb 无法输中文故 UI 只验了基础时间分支）。
  `flutter analyze` 无问题、`flutter test` 75/75、冒烟课已删、logcat 0 致命。
- `CONFIRMED`（2026-09-13 23:40 +08:00）：明文 HTTP 策略变更完成后重建 release 包并复核：
  `aapt2 dump xmltree` 确认 manifest 带 `networkSecurityConfig=@0x7f110001`、
  `dump resources` 确认该资源在包内、`dump permissions` 确认 `INTERNET`；
  `flutter analyze` 无问题、`flutter test` 76/76。
- `UNVERIFIED`：真实教务系统导入（用户已取 release 包在真机试用，结果待反馈）；
  arm64 真机安装；iOS 构建；应用名「汇课」为用户 2026-09-13 确认定稿。
- `CONFIRMED`（2026-09-14 00:05 +08:00）：仓库已上传 Gitee `chenxihh/huike`（**私有**）——
  master 读回 `8cdccda`（= 本地 HEAD）、annotated tag `v0.1.0`（`5bd42fb` → `8cdccda`）；
  推送前敏感扫描无命中、构建产物未入库；`origin` 已配为无令牌地址。
- `CONFIRMED`（2026-09-14 00:20 +08:00）：**仓库已转公开**——用户绑定第三方账号后
  `PATCH private=false` 成功；无令牌 `ls-remote` 读回 master `ceb3686`、tag `v0.1.0`，
  网页可匿名访问。
- `CONFIRMED`（2026-09-14）：TASK-009 导入链路修复后复核——`flutter analyze`（`S:\`）
  No issues found、`flutter test` **90/90**（新增 `test/navigation_policy_test.dart`
  6 条、`test/login_url_policy_test.dart` 8 条）。改动：导航跨域确认（`import_web_page.dart`
  `_handleNavigation`/`_confirmNewHost`）、地址校验统一（`login_url_policy.dart` 三处共用）、
  探测过程收敛（去掉逐个尝试提示、失败不逐项罗列、脚本间隔 800ms）。
  **模拟器/真机未跑**：本次仅静态与单测验证，跨域确认弹窗与探测节奏待装机复测（TASK-009 的
  UI 行为为 `UNVERIFIED`）。
- `CONFIRMED`（2026-09-14）：TASK-004 调休/停课例外表完成后复核——`flutter analyze` 无问题、
  `flutter test` **109/109**（新增 `test/calendar_exception_service_test.dart` 9 条、
  `test/calendar_exception_repository_test.dart` 7 条覆盖停课/调休折算、同日覆盖、
  编辑换日期、跨校隔离、删校级联清；`test/calendar_exception_ui_test.dart` 3 条覆盖
  今日页停课牌/调休提示条与「设置 → 调休 / 停课」路由）。schema 升 v3，
  v2→v3 为 `createTable`，老数据语义不变（空表 = 没有例外）。
  新界面测试顺带查出一个既有缺陷并修复：设置页的 `RadioListTile` 组嵌在带背景的
  `Container` 里，触发 Flutter「背景与涟漪不可见」断言（见 ISSUE-010）。
  **模拟器/真机未跑**：调休/停课页日期选择与整周列头小签的实际观感为 `UNVERIFIED`。

## Recommended Next Action

TASK-002 Android 桌面小组件（载荷 schema v2：由 Dart 预计算整学期每日课程，
原生只按日期查表）。预计算必须经 `CalendarExceptionService` 折算「某天按哪天的课表」，
否则调休日会显示错的那天。TASK-003 同理。与之并行不冲突的是 TASK-006 真实教务导入验收
（需要用户装机走一次导入，见 `tasks.md` Blocked）。
