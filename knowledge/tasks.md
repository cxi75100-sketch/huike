# Tasks

## Now














- [ ] TASK-012 教学楼作息差异覆盖不全（2026-09-14 用户反馈）：现状只内置
      「明志 / 明德 / 至善」三栋楼**只改第 3、4 节**（10:15-10:55 / 11:05-11:45，
      基础为 10:25-11:05 / 11:15-11:55）。用户指出「有的教学楼上课时间不同」。
      其中「老学校变体没生效」已单独修复（ISSUE-014，`0.1.3+4`），**剩下的是规则范围问题**：
      **阻塞点：需要用户提供学校的实际规则**（哪些教学楼/区域、影响哪些节次、
      各自起止时间），不得凭猜测补数据（`AGENTS.md`：不臆想业务）。
      用户截图可见的教学楼还有敏行楼、致远楼、西区实训中心——它们是否也偏离基础作息需确认。
      候选做法：① 按用户给的规则扩充预设变体；② 把「按教室的作息变体」做成
      设置里可维护的项（用户自己加），避免每校差异都硬编码。

- [ ] TASK-006 真实教务导入用户验收：用户已完成一次真实导入（2026-09-14 截图确认
      课程、教室、教师均正确落库），**待确认适配器命中情况与预览页四类明细**，
      以及变体补丁后的真机显示（`0.1.3+4`）。不记录账号、密码、Cookie 或真实课表数据。

## Next

- [ ] TASK-002 Android 桌面小组件（迁移自既有单校实现，载荷 schema 升级：
  由 Dart 预计算整学期每日课程表，原生只按日期查表，消除 Dart/Kotlin 双实现）。
  注意：载荷必须走 `CalendarExceptionService` 折算「某天按哪天的课表」，否则小组件
  会在调休日显示错的那天（见 DEC-007 的同类口径问题）。
- [ ] TASK-003 本地上课提醒（迁移并按学校档案/学期配置排程，时区语义
  「课程所在地墙上时间」；例外表已就绪，排程前先经 `CalendarExceptionService` 折算）。
- [ ] TASK-005 适配器目录联网更新（远端索引 + 脚本拉取，需先定配置源与校验策略；
  按 DEC-008，届时再给内置脚本加哈希校验）。

## Blocked

- 无工程阻塞。TASK-006 已转入 Now，等用户本人在设备上完成需本人凭据的验收步骤。

## Done

- [x] 归档提交（2026-09-27）：自 2026-09-15 起的未提交工作区（TASK-013～TASK-026）整体归档为
      `e804223`（图标与启动底色）与 `f9eccc9`（Weekly/Today、Liquid Glass、动效、测试与知识库），
      工作区干净；归档前 analyze 无问题、283/283 通过。**推送未完成**：本机无可用 Gitee 凭据，
      `git push origin master` 返回 `Unauthorized`，本地领先 origin/master 7 个提交。

- [x] TASK-020B Floating Liquid Glass Switcher（2026-09-27，本次新增范围）：Today/Weekly保留分支、共享280ms capsule/12dp fade、root-only与FAB避让完成；268→283测试、analyze/build/diff通过；API36约390dp Light/Dark双向录屏已查。真机/iOS未验；保护69文件不变，无commit/push。见report_2026-09-27_root_switcher.md。

- [x] TASK-026 App Icon Redesign（2026-09-27）：落实三白块汇聚/纯冷蓝单方案；Android adaptive/monochrome/legacy与iOS21PNG/25slot全部更新，三mask×48/64px及安全圆通过。API36 Launcher/Recent Apps/Settings列表已查；268/268、analyze/build/diff check通过，iOS设备/真机未验。Flutter源码不变，无commit/push，详见app_icon报告；完成后停止。

- [x] TASK-022B App Launch → Home Motion（2026-09-27）：修保存主题/初始空状态连续性；180ms/4dp/92% reveal，Reduced直接显示；Android背景对齐。268/268与analyze/build/diff check通过；API36四模式cold/warm已执行，真机/iOS/性能benchmark未验。详见launch_motion报告；无commit/push，完成后停止。

- [x] TASK-022A App Motion / Transition Audit（2026-09-27）：A–E盘点后统一普通route/Dialog/Menu/Sheet曲线/按压/焦点/Snackbar；删除菜单旋转与普通Detail重复reveal；保留iOS边缘返回。基线252，新增10例，262/262、analyze/build/diff check通过；Light/Dark/Reduced widget人工检查，无设备性能验收。保留启动/Preview/Weekly手势/Today布局，详见motion_audit报告；未commit/push。

- [x] TASK-021 Today Compact Semantic Timeline（2026-09-27）：仅Today改为内容高度课程节点、分级空档与当前时间语义标记；保留原Glass/tint/预览路径。基线232/232，新增20例，最终analyze无问题、252/252、Debug APK成功、diff check通过。Weekly源码哈希不变；未commit/push。详见本轮报告。

- [x] TASK-020B Separate Today From Weekly（2026-09-27）：删除Today摘要横条与计算，学校行「今日」按钮复用原/today；保留Today功能，不改Timeline/导航/手势。新增3例屏宽行为回归，基线229/229；最终结果见 `report_2026-09-27_separate_today_from_weekly.md`。未commit/push。

- [x] TASK-020A Weekly Timetable Swipe Paging（2026-09-27）：手势资格在down锁定，end消费一次，动画中新触摸整次忽略，cancel回弹且限定pointer；跟手/阈值/箭头不变。新增12例；基线217/217，最终验证见 `report_2026-09-27_weekly_swipe_paging.md`。禁止范围未改，未commit/push。

- [x] TASK-019 最后视觉收尾（2026-09-26）：仅Weekly材质降低tint、边缘染色及glow，保留布局/字号/算法。基线与最终analyze无问题、217/217通过；生产Debug APK成功；API36内存QA明暗实画检查完成。详见weekly_glass_surface报告顶部；未开始TASK-020，未commit/push。

- [x] TASK-019D Weekly 明显课程色差（2026-09-26）：整卡染色增强并提高饱和度，小字向主文字色加强50%以维持对比度。API36约390dp七色有课Light/Dark已检查；新增2例遍历八色/明暗/按压的小字对比度测试，最终analyze无问题、217/217、生产Debug APK及diff check通过。无色条，未commit。

- [x] TASK-019C Weekly 课程轮廓辨识度（2026-09-26）：卡间距3dp，均匀0.9dp中性色混tint边框和极轻投影加强分隔；不恢复色条。API36约390dp七门并排Light/Dark实画已检查，analyze无问题、215/215、生产Debug APK、diff check通过，独立复审无问题。未commit。

- [x] TASK-019B Weekly 整体玻璃轮廓（2026-09-26）：删除独立课程色竖条与占位，文字增加4dp；颜色融入透明整面tint、均匀细边缘及光晕，按压略增强。API36约390dp七色周Light/Dark实画；analyze无问题、215/215、生产Debug APK及diff check通过。未创建commit，详见 `report_2026-09-26_weekly_glass_surface.md`。

- [x] TASK-019 Weekly Timetable Information Density（2026-09-26）：普通两节周卡显示名称、compact 地点与教师；viewport 网格、冲突/切周策略不变。真实 baseline 207/207，最终 analyze 无问题、213/213、生产 Debug APK 与 diff check 通过。API 36 约390dp 有课 Light/Dark 实画通过；记录既有加号遮挡右下角问题，未越界修复。未创建 commit。详见 `report_2026-09-26_weekly_information_density.md`。

- [x] TASK-018A 导入流程回归修复（2026-09-24）：修复「导入教务课表」正文整块消失、
      CTA 恒不可用的回归。根因是 `GlassButton` 的 `Center` 在
      `Scaffold.bottomNavigationBar` 的松约束下纵向撑满整屏，把 body 挤成 0 高
      （见 ISSUE-017）；同一根因也让引导页与导入预览页正文失效。顺带修掉离开导入
      WebView 时两条 dispose 期异常导致内存导入会话未清（见 ISSUE-018）。导入入口补齐
      加载 / 读取失败 / 未建校三种状态的可见反馈，底部 CTA 补键盘高度。
      `flutter analyze --no-pub` 通过；`flutter test --no-pub` **207 个用例、205 通过**，
      剩 2 个失败属既有 `course_block_content_test` 430dp/1.0 倍字号用例（临时回退
      本轮改动仍失败，非本轮引入，属周课表范围）；`flutter build apk --debug --no-pub`
      成功。API 36 `ncpu_api36` 实机走通「建校 → 导入页正文 → 勾选确认 → CTA 变可用 →
      确认弹窗 → 进入教务 WebView」，logcat 无 Flutter 异常；未做任何真实教务账号登录。
      按用户要求未创建 commit。适配器 JS / 桥 / 导航策略 / Drift schema 均未改动。

- [x] TASK-017 Liquid Glass 最终收尾（2026-09-23）：新增稳定 Hero 身份，完成 Weekly
      预览 → 详情与 Today 卡片 → 预览 → 详情的跨 PageRoute 共享元素往返；Today 预览以透明
      PageRoute 玻璃面板呈现。Reduced Motion 跳过 Hero 并短淡入。新增共享玻璃文本框、单选、
      勾选、选项、选择器和对话框，收敛用户可见输入、确认框及页面 CTA；原生日期/时间选择器
      保留。补测试覆盖表单行为、设置选项、危险确认、1.3 倍字号、Hero 身份/返回与 Reduced
      Motion。一致性扫描后业务页面不再直接使用 Material 表单/确认控件。
      `flutter analyze --no-pub` 通过，`flutter test --no-pub` **194/194**，Debug APK 构建成功。
      本轮无连接设备，未实画；iOS、真机 GPU、TalkBack/VoiceOver `UNVERIFIED`。未创建 commit。
      详情见 `knowledge/report_2026-09-23_liquid_glass_final.md`。

- [x] TASK-016 全 App Liquid Glass 重构（2026-09-23）：完成主要共享玻璃材质与明暗主题，
      周课表 10/12 节由视口均分、14 节仅网格滚动；新增 Today 时间轴、课程预览和添加菜单；
      修复复审 D1–D8 并收敛 C1–C13 的文档说法。`flutter analyze` 通过、`flutter test`
      189/189、Android debug APK 构建和 API 36 模拟器空周实画通过。APK 安装在临时
      Android 用户后已移除此用户；iOS、真机 GPU 与 TalkBack/VoiceOver 仍为 `UNVERIFIED`。
      按用户要求未创建 commit。

- [x] TASK-015 Dynamic Liquid Glass 交互系统 + 课程内容完整显示（2026-09-23 完成）：
      用户要求「玻璃随触摸 / 按压 / 拖动 / 切周 / Sheet 进度动态变化」，并新增硬约束
      「课程块内信息完整显示、禁止省略号」。实施：
      ① 新增 `lib/core/glass/` 统一玻璃系统（`GlassSurface` 五层材质、`PressPhysics`
      唯一一份指针物理、`GlassButton`、`GlassSheetHost/Panel`、`GlassMotion` 动效令牌）
      与 `AmbientBackdrop` 环境底色；
      ② 课程块改为内容测量驱动行高：`course_block_layout.dart` 用与绘制同一份样式与
      `TextScaler` 量出所需高度，网格取「下限 / 铺满值 / 内容值」三者最大值——
      放不下就整体变高并纵向滚动，绝不出现省略号（`maxLines` / `ellipsis` 全部移除）；
      ③ 星期栏改为 sticky 玻璃浮层 + 今天液体选择器（回本周一次脉冲）；
      ④ 跟手切周 pager：三页跟手、位置与速度共同判定、动画可中断、边界不橡皮筋；
      ⑤ 顶部改为浮动玻璃 island（学校行 + 周导航 + 今日快捷）；
      ⑥ 今日 Glass Sheet 与课程预览 Glass Sheet：同一个 progress 驱动 Sheet 位移、
      背景缩放、背景模糊与压暗；
      ⑦ 冲突布局改为「一门课全宽完整显示 + 顶部 `+N` 小签」（见 ISSUE-016）；
      ⑧ Reduced Motion 全面降级、模糊只出现在导航与弹层。
      验证：`flutter analyze` 无问题、`flutter test` **177/177**（新增
      `test/glass_interaction_test.dart` 6 条、`test/course_block_content_test.dart` 5 条，
      另在 `week_agenda_ui_test` 当时新增跟手切周 / 判定函数 / 今日 Sheet / 按压反馈 8 条）；
      `ncpu_api36` 装机实画：日间 390dp、夜间、360dp、今日 Sheet、课程预览 Sheet 均通过，
      logcat 0 命中 `FATAL EXCEPTION` / `E/flutter` / `RenderFlex overflowed`；
      iOS 与真机 GPU 性能仍为 `UNVERIFIED`。

- [x] TASK-014 Weekly Timetable 首页完整重构（2026-09-22 完成）：废弃「今日 / 整周」
      一级切换与七日纵向议程，首页直接展示周一至周日同时可见的二维课表。Compact 手机
      以单节为定位单位、两节为一个视觉时段（`1–2 / 3–4 / …`），360/390dp 不横向滚动，
      五个时段自适应铺满屏幕；两节课程完整显示名称、教室、教师与起止时间。新增纯函数冲突分 lane、
      水平切周、课程预览 Sheet、玻璃导航/操作、Loading/Error/Empty/Ready、完整语义与
      Reduced Motion；拆分 `TimetablePage` 并轻量对齐详情/编辑页。保留 WeekAgenda、校历
      例外、作息、周次、数据库与导入语义，未新增依赖。验证：`flutter analyze` 无问题，
      `flutter test` 158/158，debug APK 构建及 API 36 模拟器明暗实画通过；iOS/真机未验。

- [x] TASK-013 整周议程顺序与 UI 细节重构（2026-09-15 完成，用户以「阅读并且完成
      任务」授权后从 Next 直接实施到 Done）：整周日期固定为**周一 → 周日自然顺序**，
      当前周用 `CustomScrollView` 的 `center` sliver 把**今天**做成初始视口锚点——
      今天在列表顶端、本周已经过去的日子留在它上方（向上滚可回看），周日后不再循环
      接回本周周一，也不混入相邻教学周；其它周一律从周一开始，浏览其它周时出现
      「回本周」。日期顺序只有一个来源
      （`features/timetable/services/week_agenda.dart` 的 `buildWeekAgenda`），
      Widget 里不再排序。整周课程改为复用 `CourseListingRow` 的排印列表（去掉大面积
      课程色卡片，课程色只留左侧 4×36dp 色条），日期分组为 60dp 日期栏
      （26sp 日期数字 + 13sp 星期 + 月份 / 今天 / 停课 / 按周X上课小签 + 门数），
      今天用「今天」小签 + 朱砂日期数字 + 左侧 3dp 短线 + 极浅朱砂底四重表达，
      每个日期分组给一句整行读屏语义（「9月18日，周五，今天，3门课」）。节次文案
      统一为「第 3-4 节」一种写法（`sectionRangeLabel`，`course_time_service.dart`）。
      新增克制彩蛋：长按周标题 500ms → 一次轻触觉 + 学期翻页弹层（大号周次 +
      「第 N / 总周数 周」+ 进度条 + 朱砂印记「阅至此处 / 尚未开卷 / 此卷已毕」），
      进度只由 `SemesterService.readingProgress` 一处计算并夹取在 0..1。
      验证：`flutter analyze` 无问题、`flutter test` **149/149**（新增
      `test/week_agenda_test.dart` 21 条、`test/week_agenda_ui_test.dart` 9 条）；
      模拟器实画见 `current_state.md` 验证快照与 `testing.md`。
      顺带修掉新测试查出的既有缺陷（见 ISSUE-015）。未实施的项、与计划书的差异
      见 `plan_2026-09-15_week_agenda_ui.md` 顶部状态段与 `knowledge/changelog.md`。

- [x] ISSUE-014 老学校教学楼变体未补齐（2026-09-14 修复，版本 `0.1.3+4`）：变体只在
      建校时播种，v2 之前建的学校变体列停在 `'[]'` 且无人补写，导致明志/明德/至善
      一直按基础时间显示。新增 `repairPresetVariants()`（只补空值、幂等）+
      启动钩子 `presetVariantRepairProvider`；新增 7 条测试，`flutter test` 119/119。

- [x] ISSUE-013 南工教务地址失效（2026-09-14 修复，版本 `0.1.2+3`）：档案预填的
      `http://jwxt.ncpu.edu.cn` 只剩 IPv6 解析、请求超时，改为学校实际入口
      `http://218.204.129.252:8088/jwglxt/xtgl/login_slogin.html`；测试锁定新地址
      与「IP + 端口」形态；装机验证 WebView 能打开正方登录页（未输入凭据）。

- [x] TASK-011 首页信息架构重做（2026-09-14 完成）：撤销「今日再画十节轨道」与
      「整周空节次撑满长列」。今日改为**当日议程**（历牌 hero + 「下一节」条 + 只列当天
      真实课程，`CourseListingRow`，空课日给字牌与三个快捷入口）；整周改为**七日议程**
      （每天一行表头「周X + 日期 + 调休小签 + N门/无课/停课」，表头下只展开真实课程；
      空日只占一行；当前周仍以今天开头）。撤销首页的路线水印与七日站点概览
      （`day_timeline.dart`、`section_slot_board.dart` 随之删除，`RouteBackground` 仅留在
      设置页与课程详情页）。**实现比登记时的描述更进一步**：整周不是「压缩空槽的网格」
      而是议程列表。验证：`flutter analyze` 无问题、`flutter test` **110/110**；
      release APK（`0.1.1+2`）装机 `ncpu_api36` 实画核验日间/夜间、空课/单课/多课、
      窄屏 360dp 与整周议程，logcat 无致命异常（详见 `current_state.md` 验证快照）。
      已推送 Gitee（master `bd0ecc8`、tag `v0.1.1`）并在 release 附件发布该 APK。

- [x] TASK-010 接手收口与 UI 融合验收（2026-09-14 完成）：审查并分批提交原 34 项
      工作区改动，修复子框架非 HTTP(S) 导航绕过（ISSUE-011）。按用户方向将既有校园
      线路/站点语言融入「汇课 / 新历书」：新增低噪声路线背景、七日线路概览、
      十站详情线、学校身份卡与空状态快捷入口。日间/夜间、窄屏整周与空课界面
      已实画验证，调休/停课由 widget 回归测试覆盖；`flutter analyze` 无问题，`flutter test` **110/110**，
      release x86_64 APK 构建并安装成功，logcat 无致命异常。
      **其中首页的路线水印与七日线路概览已被 TASK-011 撤下**（路线语言只保留在详情与设置）。

- [x] TASK-004 调休/停课例外表（2026-09-14 完成）：schema v3 新增 `calendar_exceptions`
      （`schoolId` + `semesterId` + `dateIso` + `kind(holiday|makeup)` + `makeupWeekday` + `note`，
      v2→v3 为 `createTable`，老数据语义不变）。只表达「这天停课」或「这天按某星期课表上课」
      两种语义，同一天只保留一条（再写即覆盖，不叠规则）。新增 `CalendarExceptionService`
      （纯 Dart，`resolve(date) → DaySchedule{weekday, suspended}`）供今日、整周共用；
      今日页停课显示空状态牌、调休显示「今天按周X的课表上课」提示条，整周列头给
      「停课 / 调休 · 按周X」小签并按折算后的星期取课；设置新增「调休 / 停课」页
      （日期选择 + 停课/调休单选 + 星期选择 + 备注，可改可删）。删校同时级联清例外。
      验证：`flutter analyze` 无问题、`flutter test` **109/109**（新增
      `calendar_exception_service_test` 9 条、`calendar_exception_repository_test` 7 条）。
      装机与视觉待验（ISSUE-005）。

- [x] TASK-009 导入链路可用性修复（2026-09-14 完成，落实 DEC-005/DEC-006/DEC-007）：
      ① WebView 导航改为「跨域跳转 + 逐主机确认一次」——放行范围 = 入口地址 + 学校档案
      已确认主机 + 会话中新确认主机，同意后 `appendConfirmedHost` 落库只增不减，拒绝过的主机
      本会话不再问；子框架不参与判定（教务常用 iframe）；scheme 不再按入口地址钉死，
      http/https 互跳不再静默失败（ISSUE-001）。② 教务地址校验抽成公共函数
      `features/schools/services/login_url_policy.dart`，引导页建校、学校管理改址、导入入口
      三处共用，学校管理页不再硬拦明文 HTTP（ISSUE-002）。③ 探测全自动、不展示逐个尝试过程、
      失败不征求是否继续，脚本之间加 800ms 间隔（ISSUE-003）。
      验证：`flutter analyze` 无问题、`flutter test` **90/90**（新增 `navigation_policy_test`
      与 `login_url_policy_test` 共 14 条）。待装机复测见 ISSUE-005。
      同日把知识库按 `README.md` + `decisions.md`（DEC-xxx）+ `issues.md`（ISSUE-xxx）重构，
      并校正此前的过期陈述（见 ISSUE-009）。
- [x] TASK-008 仓库转公开（2026-09-14 完成）：用户绑定第三方账号后执行
      `PATCH private=false` 成功；**无令牌** `git ls-remote` 可读 master `ceb3686` 与
      tag `v0.1.0`，网页描述可命中——公开可用性已复核。
- [x] TASK-007 上传汇课仓库到 Gitee（2026-09-14 完成）：建仓 `chenxihh/huike` 并推送
      master 与 annotated tag `v0.1.0`；读回 master `8cdccda` = 本地 HEAD、tag `5bd42fb`
      指向同一提交。推送前扫描确认无凭据、无真实课表数据、构建产物未入库；`origin`
      配为无令牌地址。令牌由用户提供、仅经环境变量传入命令、未落盘（**用户已确认撤销**）。
      推送当时仓库暂为私有；转公开见 TASK-008。
- [x] TASK-001 多校通用课表 App 基座（2026-09-13 完成）：独立 Flutter 工程
  （Riverpod 3 + GoRouter + Drift），多校原生数据模型；导入链路实现社区适配脚本
  契约桥，内置正方/青果/URP/超星四个通用脚本（MIT，署名在 THIRD_PARTY_NOTICES）；
  引导页不让用户选教务系统类型，执行导入时 App 依次自动尝试全部适配器
  （桥弹窗暂停超时，全部失败给逐项汇总）；差异预览四类明细后事务替换。
  界面为「新历书」设计语言；整周视图为横向翻页周历，当前周今天优先循环排列，
  打开整周第一列必是今天。应用图标为朱砂印章 + 行楷「汇」+ 内框
  （用户两轮否定日历卡片方案后定稿，候选存 assets/icon/candidates/）。
  用户反馈迭代（同日完成）：引导页不要求选教务系统类型（导入自动逐个探测）；
  课表改节次槽位网格（课程卡占位、信息完整、上下午分段、晚上最多两节）；
  内置「南昌工学院」档案（校历 10 节作息 + 明志/明德/至善楼第 3、4 节变体 +
  开学周一预填，schema v2）。验收：`flutter analyze` 无问题、`flutter test`
  76/76（当时基线；TASK-009 增至 90/90、TASK-004 增至 109/109）、Debug APK 构建成功、`ncpu_api36` 模拟器冒烟（含 example.com 探测
  循环端到端）全程无致命异常。`UNVERIFIED`：真实教务导入、iOS 构建。证据见 knowledge/current_state.md。
- [x] TASK-000 建立独立仓库、AGENTS.md 与知识库（2026-09-13）。
