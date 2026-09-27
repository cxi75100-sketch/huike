# Changelog

## 2026-09-27 — 累积工作区归档并推送 Gitee

TASK-013～TASK-026 的未提交工作区整体归档为 `e804223`（图标与启动底色）与 `f9eccc9`
（Weekly/Today、Liquid Glass、动效、测试与知识库），工作区随之干净；归档前 `S:\` 下
analyze 无问题、`flutter test` 283/283，敏感扫描与构建产物检查通过。
用户提供令牌后推送成功：远端 master 由 `79c9267` 前进到 `5e5972a`（显式 Basic 头，
未用 URL 内嵌令牌），无令牌 `git ls-remote` 读回同一提交、本地与 origin/master 一致。

## 2026-09-27 — 发布 v0.1.4（Gitee release 挂 APK）

- `flutter build apk --release --no-pub` 产出通用包（arm64-v8a / armeabi-v7a / x86_64）
  `build/huike-0.1.4-release.apk`：63,982,250 字节，SHA-256 `720f0eb1…cb545`；
  `aapt2` 读回 versionCode 5 / versionName 0.1.4 / minSdk 24 / targetSdk 36 / label「汇课」。
- annotated tag `v0.1.4` → `14c1b52`；Gitee release id `1170081` 挂该 APK，
  无令牌下载读回 `200` 且 `Content-Length` 一致，中文名与正文无乱码。
- 核对 API 补记：`v0.1.2`(1143378)、`v0.1.3`(1143514) 也早已有 release 与 APK 附件
  （均创建于 2026-09-14），知识库此前只记到 `v0.1.1`。
- 签名仍是 debug 证书（ISSUE-006 未决），release 正文标注「仅内测分发」。

## 2026-09-27 — TASK-020B Floating Liquid Glass Switcher

Today/Weekly平级保留状态，两原root路径接入最小StatefulShellRoute；共享中性capsule与12dp fade，280ms现有token，Reduced直接。
删除重复顶部Today入口/Today返回按钮，FAB只上移避让；root-only栏覆盖规则含两类Preview。
268→283测试、analyze/build/diff通过，API36明暗双向录屏已查；保护69文件无变化，未提交推送。
详细报告：report_2026-09-27_root_switcher.md。此前TASK-020B去summary历史结果保留。

## 2026-09-27 TASK-026 App Icon Redesign

- 单方案三白课程块向中心汇聚+纯冷蓝，复用既有生成工具替换全部Android/iOS活动图标。
- 补可重复mask/安全区/48与64px/尺寸/旧图检查；API36桌面/最近应用/应用列表已查。
- Flutter源码不改、无依赖/签名/锁文件变更；268/268与工程检查通过，iOS设备/真机未验。
- 无commit/push，详见report_2026-09-27_app_icon.md。

## 2026-09-27 TASK-022B App Launch → Home Motion

- 修首帧保存主题与初始错误空状态；稳定环境背景接一次180ms轻量reveal，Reduced直接显示。
- Android旧版/12+仅对齐启动/窗口底色，保留品牌，系统栏图标与Flutter实际主题一致。
- 新增6例，268/268及工程检查通过；API36四模式cold/warm已执行，真机/iOS/性能仍未验。
- 不改普通transition与禁止业务范围；无commit/push，详见launch_motion报告。

## 2026-09-27 TASK-022A App Motion / Transition Audit

- A–E盘点并集中普通motion语义token；普通route/Dialog短距离绘制过渡，iOS保留边缘返回。
- 菜单连续收起、删除旋转；普通Detail删除重复stagger；Sheet/焦点/按压/Snackbar局部统一。
- Reduced无多余scale/translation；新增10例和四模式widget画面检查；262/262与完整工程检查通过。
- 启动/Preview/Weekly分页/Today布局不改；无设备性能验收。未commit/push，详见motion_audit报告。

## 2026-09-27 TASK-021 Today Compact Semantic Timeline

- Today固定164dp节次轨道改为内容驱动课程节点与连续语义时间轴；间隔分级且上限40dp。
- 日期标题适度压缩；当前时间关联课程/课间/首尾状态，30秒时钟检查分钟更新，不假造分钟Y坐标。
- 保留原Glass/tint/Hero及预览类/路由；新增20例回归与390dp明暗中文widget实画。
- Weekly源码哈希保持不变，所有禁止范围未改。无commit/push；最终验证见本轮报告。

## 2026-09-27 TASK-020B Separate Today From Weekly

- 移除Weekly的Today summary横条、摘要计算与无用组件文件。顶部学校行「今日」按钮复用原/today入口；周导航直接衔接星期栏/网格。
- 新增三个屏宽×1.3字体行为测试，更新原入口测试；保留Today功能与所选周返回状态。
- 本轮仅修改Weekly组合、header与测试；未修改Timeline、导航架构、手势或其它禁止范围。验证见本轮报告。

## 2026-09-27 TASK-020A Weekly Swipe Paging

- Weekly pager增加手势资格/消费门禁，禁止动画期间新手势接管，cancel只回弹，弹簧同步共享offset。
- 保留原跟手、位置/速度判据及箭头路径；新增12个widget行为测试。
- 完整验证及未复现边界见 `report_2026-09-27_weekly_swipe_paging.md`；未改禁止范围，不commit/push。

## 2026-09-26 TASK-019 最后视觉收尾

- 仅Weekly课程块fill/border/glow参数：light tint 8–10%、dark 12–16%，基底更透明、左上微亮；边框课程混色70%降到6%，glow降至0.8%/1.5%。不改字体、布局、网格及算法。
- 基线与最终analyze无问题、217/217通过；生产Debug APK成功、diff check通过；API36内存QA七色周Light/Dark已检查，真机/iOS未验。
- 禁止范围未改，已有加号遮挡仅记录；未开始TASK-020，未commit/push/reset/clean。

## 2026-09-24 TASK-018A（已完成，保留未提交工作区）

- 修复 Liquid Glass 引入的布局回归：`GlassButton` 的 `Center` 在 `Scaffold.bottomNavigationBar` 的松约束下纵向撑满整屏，把 `page body` 挤成 0 高，导致「导入教务课表」正文整块消失、风险确认项不在页面上、CTA 永远 disabled。改为 `heightFactor: 1`，只收缩纵向并保留原有横向占满行为与 `tapTarget` 最小尺寸；同根因的引导页（`创建学校`）与导入预览页一并恢复。
- 导入入口补齐三种非正常状态：读取中显示加载态、读取失败显示错误文案与「重试」、确实未建校显示空态与「去创建学校」，不再三者都渲染成空白；底部 CTA 追加 `MediaQuery.viewInsetsOf(context).bottom`，键盘弹起时 CTA 停在键盘上方。
- 修掉离开导入 WebView 时两条 dispose 期异常（`Using "ref" … unmounted`、`Tried to modify a provider while the widget tree was building`）：cleaner 改为在 `initState` 抓取 `ImportSessionNotifier` 实例，并把清会话推到 `Future.microtask`。此前两条异常都发生在 `reset()` 之前/之时，内存导入会话实际没有被清（见 ISSUE-018）。
- 新增 `test/import_flow_regression_test.dart`（13 例）：正文非空白、CTA 前置条件与启用、进入 `/import/web` 且 host/URL 传参正确、取消与非法地址、加载/错误/空态、390dp、1.3 倍字号、键盘与系统返回、离开导入页清空会话。`app_shell_test` 的建校用例从「直调 `onPressed`」改回真实 `enterText` + `tap`（原写法是为绕开本回归而写）。
- 验证：`flutter analyze --no-pub` 通过；`flutter test --no-pub` **207 个用例、205 通过**（改动前基线 194 个用例、其中 2 例已失败，见 `knowledge/testing.md`）；`flutter build apk --debug --no-pub` 成功；`git diff --check` 无空白错误。API 36 `ncpu_api36` 实机走通建校 → 导入页 → 勾选 → CTA 可用 → 确认弹窗 → 教务 WebView，并验证键盘态与返回，logcat 无 Flutter 异常；未登录任何真实教务账号。适配器 JS、桥协议、`NavigationPolicy`、Drift schema 未改动。未创建 commit。

## 2026-09-23 TASK-017（已完成，保留未提交工作区）

- 增加稳定的 `CourseHeroTag`（课程/学校/学期/来源/目标）与共用课程 Hero 表面。Weekly 预览 → 详情和 Today 卡片 → 预览 → 详情均有跨 PageRoute Hero；Today 预览改为透明页面路由承载的玻璃底部面板。Reduced Motion 下不运行 Hero，详情改短淡入。
- 新增 `GlassTextField`、`GlassSelectionRow`、`GlassToggleRow`、`GlassChoiceChip`、`GlassPickerRow` 与 `GlassDialog`。收敛用户可见的输入、单选/勾选/选择器、导入桥弹窗、校历/作息/课程/学校确认框与页面 CTA；删除/重置操作明确标注。
- 一致性扫描确认业务 UI 中不再直接使用 `TextField`、Material 表单列表项、ChoiceChip、IconButton、传统按钮或 `AlertDialog`；仅共享玻璃封装内部保留 Flutter `TextField`/`showDialog`，学校/校历溢出菜单与日期/时间选择器保留平台控件。
- 新增输入、选择、危险确认、1.3 倍字号、设置外观、weekly/today Hero 身份、往返与 Reduced Motion 测试。`flutter analyze --no-pub` 通过，`flutter test --no-pub` **194/194**，Android debug APK 成功构建。当前无连接设备，因此本轮未做模拟器/真机实画；iOS、GPU 与 TalkBack/VoiceOver 仍为 `UNVERIFIED`。未创建 commit。
- 交付报告：`knowledge/report_2026-09-23_liquid_glass_final.md`。

## 2026-09-23 TASK-016（已完成，保留未提交工作区）

- 周课表改为 10/12 节由视口均分一屏，14 节可滚动；课程块自适应信息密度，完整字段由预览与 Today 展示。
- 新增 `/today` 时间轴路由、添加菜单及单周事件入口；浅/深色改为中性 Apple 式玻璃，设置页改分组玻璃。
- 修 D1–D8 的核心逻辑：视觉切周判据、直接冲突 peers、统一节次数、长按触觉、dispose 解绑、布局一次计算、空周次、首帧加载态。
- 已清理 `CourseListingRow`、`TodayCoursesSheet`、`RouteBackground` 死代码。以下旧版本叙述保留为历史，不再代表当前 UI；本轮验证见 `knowledge/testing.md`。
- 追加玻璃背景到引导、课程详情/编辑、学校、学期、作息及导入入口；设置页及课程详情改用分组玻璃表面。
- 最终验证：`flutter analyze --no-pub` 通过，`flutter test --no-pub` 189/189，`flutter build apk --debug --no-pub` 成功；APK 安装后的 API 36 空周实画通过。最终报告：`knowledge/report_2026-09-23_liquid_glass.md`。

## 0.1.4+5 (2026-09-23)：TASK-015 Dynamic Liquid Glass + 内容完整显示

- 新增 `lib/core/glass/`：`GlassSurface`（五层材质：BackdropFilter / 半透明底色 /
  方向性照明 / 触摸高光 / 发丝边缘 + 投影）、`PressPhysics`（全 App 唯一一份指针物理：
  按下压缩、指针移动驱动高光位置、松手弹簧回位）、`GlassButton`、
  `GlassSheetHost`/`GlassSheetPanel`（**一个进度**同时驱动 Sheet 位移、背景缩放、
  背景模糊与压暗）、`GlassMotion`（110/180/280ms 与四个弹簧的唯一来源）；
  新增 `AmbientBackdrop` 环境底色。全部交互不再使用 InkWell / splash。
- 顶部改为浮动玻璃 island：学校行 + 周导航（一块玻璃内的 `‹ 第 N 周 · 日期范围 ›`，
  换周时旧值滑出、新值按方向滑入）+ 今日快捷条。
- 今日课程保留但不跳页：点今日快捷升起 Today Glass Sheet（名称 / 起止时间 / 地点 /
  教师完整，标注「下一节」），拖动进度与背景效果同步。
- 跟手切周：三页（上一周 / 本周 / 下一周）1:1 跟手平移、周导航高光随手势方向偏移；
  位置（15% 页宽）与速度（380px/s）共同判定提交，未达阈值弹簧回位，
  新手势可中断进行中的动画，边界不橡皮筋。
- **课程内容完整显示**：移除课程块全部 `TextOverflow.ellipsis` 与截断用 `maxLines`；
  行高改由 `course_block_layout.dart` 在与绘制完全相同的样式与 `TextScaler` 下测量
  （`max(下限, 铺满值, 内容值)`），放不下就整体变高并纵向滚动。星期栏改为 sticky 玻璃浮层，
  今天用小型液体选择器表达，「回本周」给它一次柔和起伏。
- 冲突课程不再并排（七列宽度下会把文字挤成一行一个字，见 ISSUE-016）：显示一门课的
  完整全宽信息 + 顶部 `+N` 小签进入全部课程。
- 验证：`flutter analyze` 无问题，`flutter test` **177/177**（新增
  `glass_interaction_test` 6 条、`course_block_content_test` 5 条、
  Weekly Grid 交互当时新增 8 条）；debug APK 与 API 36 模拟器日间 390dp / 夜间 / 360dp /
  今日 Sheet / 课程预览 Sheet 实画通过，logcat 0 致命；iOS 与真机 GPU 性能 `UNVERIFIED`。
- 产物：`build/huike-0.1.4-release.apk`（通用包，arm64-v8a / armeabi-v7a / x86_64，
  65,338,262 字节，sha256
  `6baece6da43bbf5c3705b6fd8daf350497ddbd3e328f91143c922d948dc130e5`，
  versionCode 5 / minSdk 24 / targetSdk 36，debug 密钥签名）；
  release 包在 `ncpu_api36` 上装机冒烟通过（引导页 → 建校 → 新首页玻璃层级与
  布局正常，logcat 0 致命），**未推送 Gitee、未打 tag**。

## 0.1.3+4 追加（2026-09-22，未发新版号）：TASK-014 Weekly Timetable

- 首页废弃「今日 / 整周」切换，默认即周一至周日完整二维课表；今天降为日期、列底与
  当前节次的上下文提示。
- 新增固定七列 Day Header、节次轴、按 `startSection..endSection` 定位的专用课程块。
  Compact 手机保留单节精确定位，但将两节合成一个视觉时段（`1–2…9–10`），十节只形成
  五个主要格区并自适应铺满剩余屏幕；两节课块分行显示名称、教室、教师与起止时间。
- 新增纯函数 collision layout：稳定分簇/分 lane，两路并排，三路以上折叠为 `+N`。
- 新增方向性周切换、水平 swipe、课程玻璃预览 Sheet、自定义添加按钮、Loading/Error/
  Empty/Ready 叠层、完整语义与 Reduced Motion。
- 玻璃模糊限制在顶部导航与 Sheet；课程块使用廉价 tint/border。详情与编辑页做轻量视觉
  对齐，不改 CRUD、数据库、导入和 imported/manual 语义，未新增 dependency。
- 验证：`flutter analyze` 无问题，`flutter test` 158/158，debug APK 与 API 36 模拟器
  明暗实画通过；iOS/真机未验证。

## 0.1.0+1 (2026-09-13)

首个可运行版本（TASK-001 基座）。

- 多校原生数据模型：学校 / 学期（开学周一锚点 + 总周数）/ 课程
  （schoolId + manual|imported）/ 每校默认作息（时段分组）/ 设置。
- 无默认学校：全新安装进入引导页，只填学校名称、教务网址（选填）、
  开学周一与总周数；教务系统类型不需要用户选择。
- 教务导入：HTTPS 风险确认门 → 受限 WebView（scheme+host 白名单）→
  社区适配脚本契约桥（shiguangBridge*，8 处理器）→ 执行导入时自动逐个
  尝试内置的正方/青果/URP/超星通用脚本 → 内存暂存 → 差异预览
  （新增/移除/修改/无效）→ 确认后事务替换；手动课程永不触碰；
  离开页面清 HTTP 缓存与内存暂存（保留 Cookie）。
- 内置学校档案「南昌工学院」：校历官方 10 节作息 + 明志/明德/至善楼
  第 3、4 节提前十分钟的教学楼变体（按教室关键词匹配）+ 开学周一与总周数
  预填；其他学校用通用兜底（10 节，晚上最多两节），均可改、可被导入替换。
- 内置适配脚本来自社区开源仓库（MIT），署名见 THIRD_PARTY_NOTICES.md。
- 课表首页「今日 / 整周」，两个视图刻意不同：整周为节次槽位网格
  （课程卡按起止节次占位、信息紧跟课程名：完整起止时间+教室教师、
  空槽淡节次号、上午/下午/晚上分段带时间范围，上下午不混排、晚上最多两节）；
  今日为竖向时间轴（贯穿轴线 + 节次圆点 + 进行中朱砂强调 + 课程条目贴内容
  高度挂轴右侧）+「下一节」提示条；整周为横向翻页周历，当前周「今天 → 之后 → 已过去」循环排列，
  打开整周第一列必是今天（当天列朱砂描边 + 今章）。
- 课程 CRUD（手动）、课程详情、学期设置、作息编辑（HH:mm 手动格式化）、
  外观三档（跟随系统/日间/夜间）。
- 「新历书」设计语言：单朱砂强调色、发丝线分组、圆角系统锁
  （区块 12/控件 10/小签 4）、明暗双主题、数字 tabular figures。
- 应用图标：朱砂印章 + 华文行楷「汇」+ 内框（tools/make_icon.py 生成；
  候选方案存 assets/icon/candidates/）。
- Android 主清单声明 INTERNET。**明文 HTTP 策略（2026-09-13 最终）**：多校教务大量为明文
  且无法在运行期新增放行域名，故放开明文——Android `network_security_config` 的 base-config
  允许明文、iOS `NSAllowsArbitraryLoadsInWebContent`（仅 WebView）；应用层保留两道门：
  入口地址确认（明文额外警示）+ 导航仅限确认过的主机。引导页建校与导入入口策略一致。
- 仓库上传 Gitee `chenxihh/huike` 并于 2026-09-14 转为公开（tag `v0.1.0`）；
  推送前做过敏感信息扫描，构建产物未入库。

验证：`flutter analyze` 无问题；`flutter test` **90/90**（明文策略变更后重新构建与复测，
后续新增导航白名单与地址校验单测共 14 条）；
Debug APK 构建成功；release 三 ABI 包复核 `INTERNET` 权限与 `networkSecurityConfig` 资源；
`ncpu_api36` 模拟器冒烟（引导/建校/加课/周历/详情/设置/导入探测循环/删校）
全程无致命异常。真实教务导入与 iOS 构建 `UNVERIFIED`。

## 0.1.0+1 追加（2026-09-14，未发新版号）

TASK-010 接手审查修复：

- 子框架继续免去跨主机确认，但不再绕过 scheme 安全边界；`file:`、`intent:`、`tel:`
  等非 HTTP(S) 导航在主框架和子框架中都由应用层拦截（ISSUE-011）。
- 复核：`flutter analyze` 无问题，导航策略测试 6/6 通过；完整基线仍为 109/109。
- UI 融合用户喜欢的校园线路语言，但保留「汇课」的朱砂、新历书排印与低饱和课程签：
  新增低噪声线路背景、七日站点概览、详情十站节次线、设置学校身份卡与空课快捷入口。
- 首页「今日 / 整周」切换提升到至少 48dp 触摸高度；夜间整周空槽的节次与时间对比度调高。
- 验证：`flutter analyze` 无问题，`flutter test` **110/110**；release x86_64 APK 构建并安装
  `ncpu_api36` 成功，日间/夜间与窄屏实画无溢出，logcat 无致命异常。真实教务导入留给用户执行。

导入链路可用性修复（TASK-009，落实 DEC-005/DEC-006/DEC-007）：

- **导航跨域确认**：WebView 放行范围 = 入口地址 + 学校档案已确认主机 + 会话中新确认主机。
  主框架跳到新主机时弹窗问一次「允许访问 xxx」，同意即记住（落库只增不减），拒绝则本会话
  不再问；子框架不参与判定（教务常用 iframe）。此前只放行入口那一台主机，
  教务登录跳统一认证/CAS 会被静默拦截、导入卡在登录页。
- **scheme 不再按入口地址钉死**：http 与 https 都允许，教务站协议互跳不再失败。
- **地址校验统一**（DEC-006）：新增 `features/schools/services/login_url_policy.dart`，
  引导页建校、学校管理改址、导入入口三处共用；学校管理页不再硬拦明文 HTTP。
- **探测过程收敛**（DEC-007「机制归交付方」）：不再提示「正在尝试某个适配器」，全部失败不逐项
  罗列、不征求是否继续，脚本之间间隔 800ms 控制请求节奏。

验证：`flutter analyze` 无问题、`flutter test` **90/90**。跨域确认弹窗与探测节奏的
UI 行为待装机复测（`UNVERIFIED`）。

同日知识库按固定结构重构：新增 `README.md`（索引与项目边界）、`decisions.md`（DEC-001~010）、
`issues.md`（ISSUE-001~009），`tasks.md` 拆出 `## Blocked` 段；并校正此前的过期陈述
（schema 版本、作息节数、明文策略、应用名、发布状态、测试基线），见 ISSUE-009。

## 0.1.0+1 追加（2026-09-14）：调休 / 停课例外

TASK-004 校历例外（落实 DEC-009、DEC-010）：

- schema 升 **v3**：新增 `calendar_exceptions`（`schoolId` + `semesterId` + `dateIso` +
  `kind(holiday|makeup)` + `makeupWeekday?` + `note`）。v2→v3 是 `createTable`，
  老数据升级后语义不变（空表 = 没有任何例外）。生成类名用 `@DataClassName('CalendarExceptionRow')`
  避开与模型同名。
- 只表达两种语义：**这天停课**、**这天按某个星期的课表上课**；同一天只保留一条，
  再填即覆盖，不叠规则（DEC-010）。
- 新增纯函数 `CalendarExceptionService.resolve(date) → DaySchedule{weekday, suspended}`，
  今日与整周共用：今日页停课显示空状态牌、调休显示「今天按周X的课表上课」提示条；
  整周列头给「停课 / 调休 · 按周X」小签，课程按折算后的星期取。
- 设置新增「调休 / 停课」页：日期选择 + 停课/调休单选 + 星期选择 + 备注，可改可删；
  删校时级联清例外。

验证：`flutter analyze` 无问题、`flutter test` **109/109**（新增 19 条：服务 9 + 仓储 7 + 界面 3）。
装机与视觉待验（`UNVERIFIED`，见 ISSUE-005）。

## 0.1.1+2 (2026-09-14)：首页信息架构重做

TASK-011。首页撤销两条没赢得位置的做法：「今日再画一条十节轨道」与「整周用空节次
撑满长列」。两个视图都改为**只呈现真实有课项**。

- **今日改为当日议程**：历牌 hero（`M月D日` + 星期 + 周次 + 学期状态条）+「下一节」提示条
  （按作息结束时间取最近未结束的一节）+ 当天真实课程列表（`CourseListingRow`：色条 +
  起时/节次 + 课程名 + 教室·教师，发丝线分隔）。空课日给「今日无课」字牌与
  「看整周 / 加课程 / 教务导入」三个快捷入口，不再预留节次空白。
- **整周改为七日议程**：每天一行表头（周X + `M月D日` + 调休「按周X上课」小签 +
  右侧「N 门 / 无课 / 停课」），表头下只展开当天真实课程；空日只占一行。
  当前教学周仍以今天开头（今天 → 之后 → 本周已过去），其他周按周一到周日；
  今天所在行朱砂浅底强调。周切换器 `‹ 第 N 周 (M.d-M.d) ›` 保留。
- **删除**：`widgets/day_timeline.dart`、`widgets/section_slot_board.dart`，以及
  `WeekRouteOverview`（七日站点概览）。首页不再有路线水印；`RouteBackground`
  只保留在设置页与课程详情页。课程详情「十站节次线」不受影响。
- 模式切换为 58dp 分段控件，各段最小高度 48dp。
- 顺带修复 ISSUE-012：引导页网址字段标签不再写死「HTTPS」，改为「http/https」，
  与明文放开的 DEC-004 口径一致。

验证：`flutter analyze` 无问题；`flutter test` **110/110**（`app_shell_test` 增加
`today-agenda`/`week-agenda` 互斥切换、整周当天行 key、以及「本周线路概览」语义标签
已移除的断言）。release APK（`0.1.1+2`，通用包三 ABI）装机 `ncpu_api36` 实画核验：
日间空课/单课/多课、整周议程、夜间两视图、窄屏 360dp（`wm size 720x1600` +
`wm density 320`，历牌行与议程行均无溢出），logcat 无 `FATAL EXCEPTION` / `E/flutter`。

发布：master 已推送 Gitee（`bd0ecc8`），annotated tag `v0.1.1`，release 附件为该 APK
（`huike-0.1.1-release.apk`，64,731,306 字节，SHA-256 `98510723…f396019`，
无令牌可下载）。

## 0.1.2+3 (2026-09-14)：修正南昌工学院教务地址

用户报障：点「南昌工学院」建校后导入页 WebView 白屏，登录页打不开。查明档案里预填的
`http://jwxt.ncpu.edu.cn` 当前只剩 IPv6 解析、请求直接超时（curl 返回 `000`），
学校实际入口是明文 HTTP 的正方教务入口。

- 内置档案 `defaultLoginUrl` 改为
  `http://218.204.129.252:8088/jwglxt/xtgl/login_slogin.html`（IPv4 + 8088，
  正方 jwglxt V9.0，UTF-8 登录页）；档案里留注释说明不要改回旧域名。
- 测试锁定：`school_presets_test` 逐项断言 scheme/host/port/path 且断言不含旧域名；
  `login_url_policy_test` 新增「IP + 端口 + 路径」用例；`navigation_policy_test`
  新增「白名单按主机粒度、端口不参与判定」用例。

验证：`flutter analyze` 无问题、`flutter test` **112/112**；装机 `ncpu_api36` 实测
「引导页点南工 → 预填新地址 → 建校 → 导入页确认（含明文警示）→ WebView 成功加载
南昌工学院正方登录页」，全程未输入任何凭据（真实登录仍为 `UNVERIFIED`，见 TASK-006）。

## 0.1.3+4 (2026-09-14)：补齐老学校缺失的教学楼作息变体

用户导入后反馈「有的教学楼时间不同，你没有做区分」。查证：档案与代码都没问题
（新建学校实测 明志楼 3-4 节 = 10:15），问题是**老数据**——变体只在建校时播种，
schema v2 之前建的学校变体列是迁移默认的 `'[]'`，没有任何路径补回来，
于是这些学校永远显示基础时间（10:25）。详见 ISSUE-014。

- 新增 `SchoolRepository.repairPresetVariants()`：只给「变体列为空」的学校补写档案变体
  （`presetId` 缺失时按校名精确匹配档案），已有变体不动、幂等。
- 新增启动钩子 `presetVariantRepairProvider`，由 App 外壳 watch 一次
  （不放进 Drift 迁移：`core/database` 不应反向依赖 `features/schools`）。
- 新增 `test/school_variant_seeding_test.dart` 7 条：建校播种、校区前缀教室文本匹配
  （`九龙湖校区明志楼223`）、老数据补齐、不误伤其它学校、以及接线级断言。

验证：`flutter analyze` 无问题、`flutter test` **119/119**。
装机验证受限：模拟器只能用 ASCII 输入课程表单，无法造出中文教室名的课程，
真机显示效果待用户反馈（`UNVERIFIED`）。

## 0.1.3+4 追加（2026-09-15，未发新版号）：TASK-013 整周自然日期顺序与 UI 细节

用户反馈「整周周日下面又出现本周周一」，并同步要求重做整周 UI、补细节与克制彩蛋。
按 `knowledge/plan_2026-09-15_week_agenda_ui.md` 实施，**未改版本号、未提交、未推送、
未发 release**（计划书把这些明确排除在授权外）。

- **日期顺序**：整周固定为周一 → 周日自然顺序。顺序只有一个来源：
  新增 `features/timetable/services/week_agenda.dart` 的 `buildWeekAgenda`，
  一次性给出每天的日期、校历例外折算结果、当天课程、isToday / isPast / showMonth，
  以及今天在七天里的下标；Widget 里不再排序，循环排列彻底删除。
- **当前周锚定**：当前周用 `CustomScrollView` 的 `center` sliver 把今天做成初始视口
  锚点——今天为首个可见日期，本周已过去的日子留在它上方（向上滚可回看）；
  周日后不再接回本周周一，也不混入相邻教学周。其它周一律从周一开始，
  离开本周时出现「回本周」文本按钮。没有引入任何第三方滚动包。
- **UI**：整周课程不再是大面积课程色卡片，改为复用 `CourseListingRow` 的排印列表
  （色条收窄到 4×36dp，色只落在这一小块面上，行间发丝线）；日期分组为 60dp 日期栏
  （26sp 数字 + 13sp 星期，月份只在周一/跨月首日）+「今天/停课/按周X上课」4dp 小签 +
  「N 门 / 无课」；今天用朱砂日期数字 +「今天」小签 + 左侧 3dp 短线 + 极浅朱砂底四重表达；
  过去日期只降低日期元信息对比度，课程正文不跟着变淡。日期分组给整行读屏语义
  （「9月15日，周二，今天，1门课」），装饰线与小签不进语义树。
  分段控件收紧到 52dp（可点高度仍 48dp），周导航文字加大、离开本周才出现「回本周」，
  列表底部避让按 FAB 高度 + 安全区计算（104dp + inset）。
- **彩蛋**：长按周标题 500ms → 一次轻触觉 + 学期翻页弹层（大号周次 +
  「第 N / 总周数 周」+ 4dp 进度条 + 朱砂印章式落款「阅至此处 / 尚未开卷 / 此卷已毕」）。
  进度只由 `SemesterService.readingProgress` 一处计算并夹取 0..1；无网络、无埋点、
  无数据库写入；Reduced Motion 下弹层动画与分段控件过渡直接归零。
- 节次文案统一：新增 `sectionRangeLabel`（`course_time_service.dart`），
  今日与整周都写作「第 3-4 节」，同页不再混用「3-4节」。
- 顺带修掉新测试查出的既有缺陷：引导页与学期设置的「开学第一周周一」一行在
  360dp + 1.3 倍字体下溢出（ISSUE-015）；同时在 360dp + 1.3 倍字体下实测
  今日页 hero 的周次标签会挤爆，改为可省略的次级信息。
- 与计划书的差异（未做 / 改法不同）已逐条记在计划书顶部状态段，例如
  「上课中 / 下一门」实时标签、AppBar 滚动发丝线、课程行右侧箭头、
  「本周收卷」落款按计划本身的 MAY/SHOULD 逃生口未实现。

验证：`flutter analyze` 无问题、`flutter test` **149/149**（新增
`test/week_agenda_test.dart` 21 条、`test/week_agenda_ui_test.dart` 9 条）；
`ncpu_api36` 装机实画（日间/夜间/窄屏 360dp/1.3 倍字体/其它周与回本周/长按弹层/停课日），
logcat 0 致命异常；核验后 `pm clear`，共用模拟器未留冒烟数据。
# 2026-09-26 TASK-019 Weekly Timetable Information Density

- Weekly 普通两节块补齐紧凑地点与教师；删除宽度门槛，按实际主题字体与缩放测量内部行数。
- 新增纯展示地点 formatter，不保存 compact 值。收紧节次轴与课程横向留白，辅助字号 10sp。
- 保留七列、10/12 节一屏、14 节滚动、冲突与切周；未改 Today/Preview/Import/数据库。
- 新增 6 例测试并加强 13 例 viewport 验证；API 36 有课周明暗实画。详见 TASK-019 报告。
# 2026-09-26 TASK-019B Weekly 完整玻璃轮廓

- 明确废弃左侧课程色竖条，删除独立装饰区与占位；文字区域增加4dp。
- 课程色改为克制整卡 tint、均匀细边缘、微弱光晕及按压增强；保留固定网格与三字段。
- 新增明暗课程色/按压回归，强化无竖条和文字全宽断言；API36约390dp七色有课周实画。
# 2026-09-26 TASK-019C Weekly 课程分隔

- 用户反馈前版边界过弱：卡间距1→3dp；均匀边框0.7→0.9dp并增加中性轮廓对比，玻璃基底更清楚，增加微弱中性投影。
- 不恢复色条；课程信息、颜色和固定网格保持，跨节/冲突测试精确匹配新间距。
# 2026-09-26 TASK-019D Weekly 明显课程色差

- 按用户进一步明确的偏好提高整卡颜色饱和度和染色强度，保留色相，不再仅增强边框。
- 中间渐变也染色；地点/教师小字增强对比度。新增八色明暗/静止按压的小字对比度测试。
- 无竖条、3dp间隔、字段排版与固定网格保持。
