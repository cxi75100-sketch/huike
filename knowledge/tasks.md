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

- 无工程阻塞。TASK-006 已转入 Now，等用户在当前模拟器完成需本人凭据的验收步骤。

## Done

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
