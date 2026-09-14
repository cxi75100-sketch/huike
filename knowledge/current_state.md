# Current State

## Last Updated

2026-09-13 19:30 +08:00

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
下一步是 TASK-002（桌面小组件）与 TASK-003（上课提醒）的迁移，以及真实教务系统的端到端导入验收。

## Working Features

- Flutter Android/iOS 工程；Riverpod 3 + GoRouter + Drift/SQLite 单机架构，与设计文档一致。
- 多校数据模型（schema v1，无迁移包袱）：`schools`（用户显式创建，含导航白名单）、
  `semesters`（属于学校，开学周一 + 总周数）、`course_entries`（`schoolId` + `source=manual|imported`）、
  `section_time_entries`（每校一套默认作息，含时段分组）、`settings`。
- 没有任何内置默认学校/学期/作息覆盖路径：`ensureDefaults()` 为空壳，播种只发生在创建学校时一次。
- 通用兜底作息（8:00 起上午四节、14:00 起下午四节、19:00 起晚间，12 节），仅作播种，
  `BellSchedule.equalsFallback()` 用于判断「未被修改」。
- 导入链路（TASK-001 核心）：风险确认门 + HTTPS 强制 → 受限 WebView
  （scheme+host 白名单，用户确认过的主机）→ 注入社区契约桥 → 点「执行导入」后
  App **自动逐个尝试全部内置适配器**（用户不需要知道学校用什么教务系统；
  每个脚本自己校验当前页面，读不到课表就换下一个；桥弹窗打开时暂停该次超时）→
  脚本回传数据全部暂存内存 → 预览页（新增/移除/修改/无效四类明细 + 附加选项）→
  确认后事务替换 (schoolId, semesterId, imported)。全部失败时逐项汇总弹窗。
  手动课程永不触碰。
- 引导页不要求选教务系统类型：只填学校名称（必填）、教务网址（选填 HTTPS）、
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
- 学校管理：列表、点按切换激活、修改教务网址（仅 HTTPS、白名单只增不减）、
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
- TASK-004 调休/停课例外表（用户可编辑）。
- TASK-005 适配器目录联网更新（需先定配置源与校验策略）。
- 真实教务系统端到端导入验收：需要一所真实学校的账号在 Debug 包里由用户本人登录脱敏验证。
  目前导入链路只有代码与单测证据，无真实教务系统证据（`UNVERIFIED`）。
- iOS 构建验证（`UNVERIFIED`，不阻塞）。

## Current Blockers

- 无外部阻塞。注意：本机 GitHub 直连不可用；`flutter build` 时 sqlite3 hook 需要
  从 GitHub 下载预编译库（见 testing.md 的离线缓存办法），Clash 未开时构建会失败。

## Important Context

- 「汇课」为暂定名，用户未最终确认；改名为纯文案工作。
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
  课程详情元数据完整 → 设置四组入口正常 → 默认作息 12 节含上下午晚分组 →
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
- `BLOCKED`：Gitee 新仓库上传（等用户提供 projects 权限令牌；命令模板见交接报告 §11）。

## Recommended Next Action

TASK-002 桌面小组件迁移（含载荷 v2 设计），或先约一次真实教务导入验收
（需要用户提供一所学校的 HTTPS 教务地址并用本人账号在 Debug 包登录一次）。
两者都不依赖对方，可并行。
