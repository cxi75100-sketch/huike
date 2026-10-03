# 框架报告索引

2026-10-02 TASK-ADAPTER-GENERAL-01：适配框架升级到catalog schema 2，新增School Profile、协议族候选计划、attempt隔离、结构化脱敏诊断与synthetic fixture；桥/预览事务/导航边界保留。详见`framework_import.md`、`adapters.md`及`report_2026-10-02_adapter_framework.md`。真实教务端到端仍`UNVERIFIED`。

TASK-LOGIN-REPAIR-01：首读前修已知旧默认入口、确认后保存新网址；data/import与ISSUE-013已同步，详见report_2026-10-02_login_repair.md。

2026-10-02完成度复核：详见`report_2026-10-02_project_completion.md`。下方09-28审计是历史证据；当前Weekly预览已改终态面板平移（不接source几何、遮罩不blur），16色以全色相色板为准，导入O/P已修复。最新三项UI已收口，本轮362/362另保留运行证据。

2026-10-02：今日状态标签替代蓝线、浅色品牌启动、底部局部滑动见report_2026-10-02_today_launch_root.md；design/theme/startup/motion/navigation同步。

TASK-PREVIEW-RAPID-01：Weekly关闭放行点击并可重开；箭头立即换周，新横向手势接管旧落位。glass/motion/navigation规则已同步，报告见report_2026-10-02_rapid_interaction.md。

## 2026-10-02 今日过渡、课程色与节次提示

TASK-COURSE-HUES-01：最新16配对覆盖完整暖冷色相；Today面板独立平移/无Hero/无BackdropFilter/无重复正文渐显、Weekly轴内节次提示沿用TASK-TODAY-MOTION-COLOR-01。最新颜色/产物见report_2026-10-02_course_hues.md，动画验证见report_2026-10-02_today_motion_color.md。

## 2026-10-02 视觉与返回修正

TASK-VISUAL-RETURN-01：课程直接16色、Android矢量adaptive/独立启动标志、启动去Opacity、Weekly终态尺寸平移/背景固定/仅压暗。同步theme/startup/motion/glass/dependencies框架；报告report_2026-10-02_visual_return.md。通用Host几何harness保持，Weekly source接线撤除。真机卡顿改善未验。

## 2026-10-01 兼容升级

TASK-LEGACY-UPGRADE-01补只读旧数据库事务导入、首次读取门控、失败提示/重试、Android两flavor与隔离签名、旧图标恢复。同步architecture/design及data/dependencies/startup/theme/navigation/school_calendar框架；详情与产物见report_2026-10-01_legacy_upgrade.md。

## 2026-10-01 当前UI补充

课程卡当前使用16色不透明单色底；Today常规最小高度100.5dp且全字段自然换行。学校管理已撤除添加学校入口，ISSUE-019原redirect机制仅保留历史诊断。同步设计、主题、玻璃、导航文档；见 `report_2026-10-01_compact_color.md`。

## Last Updated

2026-10-03 +08:00（TASK-WEBVIEW-FRAMEWORK-01；工作区保留未提交改动，下方跨框架审计为历史基线）

TASK-WEBVIEW-FRAMEWORK-01同步import/dependencies/adapters/architecture：原生策略快照、已确认导航继续、子frame scheme判定、主frame安全错误/手动重试与generation隔离。昨日adapter更新未发现直接网络失败路径；真实学校连接中止原因未验。见report_2026-10-03_webview_framework.md。

## 这套文档是什么

按「框架」拆分的一组**可长期维护**的现状报告。目的只有一个：**改一处代码时，能立刻知道该同步哪几份文档、以及哪些位置不能被绕过**。

与既有知识库文档的分工（**避免一处策略两处定义**）：

| 文档 | 地位 |
| --- | --- |
| `architecture.md`、`design.md`、`adapters.md`、`testing.md` | **仍然是唯一权威**。策略原文、设计语言、适配契约、测试范围以它们为准 |
| `decisions.md`（DEC）、`issues.md`（ISSUE） | **仍然是唯一权威**。框架报告只引用编号，不复述决策理由 |
| `current_state.md`、`tasks.md` | **仍然是当前状态与任务的唯一权威** |
| `report_YYYY-MM-DD_*.md` | 某次任务的历史快照，**不更新** |
| 本目录 `framework_*.md` | 现状记录 + 入口清单 + 唯一定义点 + 改动同步清单 + 未验证边界。**有新事实时更新** |

规则：框架报告里出现与代码冲突的描述时，**以代码与测试为准，先修文档**。框架报告不得新增策略，只登记策略在代码里的落点。

## 文件清单

| 框架 | 文件 | 覆盖范围 | 依据 |
| --- | --- | --- | --- |
| 索引 | `framework_index.md` | 更新约定、跨框架未决项 | — |
| 动效与过渡 | `framework_motion.md` | 令牌、按压物理、切周手势、一级切换、Preview/Sheet、路由过渡、Reduced Motion | TASK-MOTION-AUDIT-01 |
| 玻璃材质 | `framework_glass.md` | GlassSurface 五层、模糊成本、嵌套模糊、材质数值 | TASK-MOTION-AUDIT-01 |
| 路由与页面 | `framework_navigation.md` | 路由表、Shell 分支、页面类型方言、返回行为、保留策略 | TASK-MOTION-AUDIT-01 |
| 数据与状态 | `framework_data.md` | Drift schema 与迁移、repository 写路径、Riverpod provider 图 | 2026-09-28 只读调研 |
| 主题与视觉令牌 | `framework_theme.md` | AppPalette、AppTheme 覆盖、课程八色、明暗、令牌与魔数 | 2026-09-28 只读调研 |
| 启动与首帧 | `framework_startup.md` | native splash、deferFirstFrame、readiness、reveal | TASK-MOTION-AUDIT-01 |
| 教务导入与适配 | `framework_import.md` | WebView壳、JS桥、family与School Profile、候选计划、attempt隔离、4个脚本、批次契约、安全边界 | 2026-10-02 TASK-ADAPTER-GENERAL-01 |
| 学校/学期/作息/校历 | `framework_school_calendar.md` | 学校档案、学期锚点、作息变体、校历例外、5 个设置页 | 2026-09-28 只读调研 |
| 第三方依赖 | `framework_dependencies.md` | 6 个直接依赖 + vendored 包、引用面、升级敏感点、平台配置 | 2026-09-28 只读调研 |

## 统一骨架

每份框架报告固定这几节，便于对比与更新：

1. **边界** —— 这个框架负责什么、不负责什么
2. **关键文件与入口** —— 表：角色 → 文件 → 说明
3. **机制与约定** —— 事实，附 `file:line`
4. **唯一定义点** —— 本项目「一处策略一处定义」的落点清单（改这里才知道改哪里）
5. **改动时必须同步的位置** —— checklist
6. **已知问题与技术债** —— 引用 ISSUE / P0 / P1 编号
7. **未验证边界** —— 不得据此宣称可用
8. **更新记录** —— 表格：日期 / 变更 / 依据

## 更新约定（什么时候必须更新哪一份）

| 触发的改动 | 必须同步 |
| --- | --- |
| 改任意 `Duration` / `Curve` / 弹簧 | `framework_motion.md` |
| 改 `GlassSurface` / `GlassMetrics` / 模糊 sigma | `framework_glass.md` + `framework_motion.md` |
| 加/改路由、页面类型、页面层级 | `framework_navigation.md`（+ `framework_motion.md` 的过渡表） |
| 改表结构、`schemaVersion`、仓库写路径 | `framework_data.md`（+ `architecture.md`） |
| 加 provider 或改 provider 类型 | `framework_data.md` |
| 改颜色、圆角、令牌、明暗 | `framework_theme.md` |
| 改 `main.dart` / `app.dart` / splash 资源 | `framework_startup.md` |
| 改适配脚本、桥方法、白名单、批次字段 | `framework_import.md`（+ `adapters.md`） |
| 改内置学校、作息、校历语义 | `framework_school_calendar.md` |
| 升级/替换依赖、动 `pubspec.yaml` | `framework_dependencies.md` |

同时按 `AGENTS.md`：`current_state.md`（含顶部 Last Updated）与 `tasks.md` 始终要更新；用户可见行为变化还要更新 `changelog.md`。

## ⚠️ 文档基线与并行改动（写于 2026-09-28 16:30 前后）

本套框架报告的**事实基线是提交 `7bc4f10`（master）**。建立过程中，**同一工作区出现另一会话的未提交改动**，与本套文档的两个条目直接相关：

| 工作区（未提交） | 内容 |
| --- | --- |
| `lib/features/import/services/course_repository.dart` | 文件头注释已改为「id 由**学校 + 学期** + 课程内容指纹决定」 |
| `lib/features/import/pages/import_preview_page.dart` | 导入确认写入路径改动 |
| `test/import_integrity_test.dart`（新增 292 行）、`test/course_repository_test.dart`（改动） | 完整性测试 |
| `test/zz_repro_test.dart`（新增 81 行） | 疑为临时复现用例 |
| `knowledge/{adapters,changelog,current_state,tasks,testing}.md` | 该会话的知识库同步 |

**含义**：`framework_import.md` §12 的 **P0-O（跨学期导入主键冲突）** 与 **P0-P（导入多段写入无整体事务）** 描述的是**已提交基线**的状态；工作区正在修这两条（疑似 TASK-DATA-INTEGRITY-01）。
**本套文档不覆盖未提交代码，也不对在修代码做完成度判断。** 该工作落地后，**必须重新同步** `framework_import.md`（§8、§9、§12）、`framework_data.md`（§4、§8）与 `framework_dependencies.md`（引用面），并在 `current_state.md` 里确认口径。同时 `framework_import.md` §12 列出的其余项（K、G、console 风险等）需按新代码复核。

## 跨框架未决项

> **来源分层**：A–N 建立于 2026-09-28 第一轮审计（TASK-MOTION-AUDIT-01）；**O–W 来自同日第二阶段只读复核（TASK-AUDIT-02，`report_2026-09-28_adversarial_random_audit.md`）**。TASK-AUDIT-02 已判定第一轮的 5 条结论为 `INCORRECT`、6 条为 `PARTIALLY CONFIRMED`；**凡两轮冲突处，以第二阶段结论为准**（其更正已回填到各框架报告）。

| # | 事实 | 影响框架 | 证据 |
| --- | --- | --- | --- |
| A | Sheet 的全屏 `BackdropFilter` sigma 在开合时逐帧变化。TASK-WEEKLY-PERF-PROFILE-01 的 API 36 模拟器 Preview-open blur A/B 显示 Raster 代表帧由 34.9–37.2 ms 降至 5.9–7.2 ms；**模拟器路径关联已确认，具体滤镜层与真机结果仍未验证** | 玻璃 / 动效 | `glass_sheet.dart`、`report_2026-09-28_weekly_perf_profile_01.md` |
| B | **TASK-PREVIEW-BACK-01 已修关闭分流**：背景、下拖、X、Back、编辑统一完成动画后清理一次；「完整详情」仍只 push，Preview 保留为下层 | 动效 | `timetable_page.dart`、`glass_sheet.dart`、`preview_dismiss_test.dart` |
| C | **TASK-PREVIEW-GEOMETRY-01 已修（Widget）**：Weekly Preview source 与实测 destination 转为 Host Stack-local Rect 后插值；透明首帧测量，内容分阶段显现，source 失效时安全退回底部位移 | 动效 | `glass_sheet.dart`、`timetable_page.dart`、`preview_geometry_test.dart` |
| D | Weekly 拖动第一帧才挂载相邻整周网格（`CONFIRMED` 代码路径）。「整页单一 `RepaintBoundary` → 逐帧重录两周 / 全部玻璃重算模糊」为 **PERF-HYPOTHESIS**：边界存在不构成因果证明，需分别观测 rebuild / paint / 合成 / 背景采样 | 动效 / 玻璃 | `week_swipe.dart:302-313`、`timetable_root_shell.dart:152`；复核见 TASK-AUDIT-02 §I |
| E | 课程块与 `+N` 签按压缩放未接 Reduced Motion，与 `GlassSurface` 策略不一致 | 动效 | `timetable_course_block.dart:101-102,329` |
| F | `AppPalette` 不是 `ThemeExtension`、无 lerp；明暗切换时自绘颜色瞬时跳变，Material 控件却在 200ms 内渐变 | 主题 | `app_theme.dart:178-182`、`app.dart:47-49` |
| G | **来源注释与代码冲突**：`AndroidManifest.xml` 注释称「不声明 usesCleartextTraffic、只允许 HTTPS」，但同文件引用的 `network_security_config.xml` 是全局 `cleartextTrafficPermitted="true"` | 依赖 / 导入 | `AndroidManifest.xml:3-5` vs `network_security_config.xml:11` |
| H | `bell_settings_page.dart:171` 文案说恢复「通用作息」，实现是按内置档案恢复官方作息 | 学校/作息 | `school_repository.dart:192-196` |
| I | `CalendarExceptions` 无 DB 唯一约束，「同日一条」只由写路径事务保证 | 数据 / 校历 | `app_database.dart:91-105`、`calendar_exception_repository.dart:32-58` |
| J | 全部表仅主键，无二级索引；`weeksJson` 为 JSON 文本，周次无法 SQL 过滤 | 数据 | `app_database.dart:18-113` |
| K | 导入写入是「删后重建」：手工改过的导入课程（含备注）在下次导入后丢失 | 导入 / 数据 | `course_repository.dart:21-59` |
| L | 多个「定义存在但无调用点」的符号（`GlassMetrics.edgeWidth`、`GlassMotion.emphasized/flicksPast/simulation`、`encodeHosts`、`groupByPeriod`、`Semester.copyWith`、`sectionGroupFromString`、`courseSourceFromString`、`AdapterCourseDraft.toFieldMap`、`SchoolProfile.confirmedHost`） | 全部 | 见各框架报告 |
| M | `pubspec.yaml` 声明但全仓零使用的依赖：`yaml`、`cupertino_icons` | 依赖 | `pubspec.yaml:14,21` |
| N | 真实教务端到端、iOS、真机仍未验证 | 导入 / 全部 | `adapters.md:3`、`tasks.md` TASK-006 |
| **O** | **TASK-DATA-INTEGRITY-01 已修**：`importedCourseId` 纳入 `semesterId`，跨学期同课可共存 | 导入 / 数据 | `course_repository.dart`、`import_integrity_test.dart` |
| **P** | **TASK-DATA-INTEGRITY-01 已修**：导入确认由单个事务覆盖作息、课程和学期元数据 | 导入 / 数据 | `course_repository.dart`、`import_integrity_test.dart` |
| **Q** | **TASK-CALENDAR-DATE-01 已修**：校历例外的初始日期夹取到原学期边界；历史/未来学期 Widget 回归通过 | 校历 | `calendar_exception_page.dart`、`calendar_exception_date_picker_test.dart` |
| **R** | **TASK-PREVIEW-BACK-01 已修（Widget）** Weekly 内嵌 Preview 的 Back 由 `PopScope` 消费；双 Back 与关闭中 Back 不离开根页。真机 predictive back 未验 | 动效 / 导航 | `timetable_page.dart`、`preview_dismiss_test.dart` |
| **S** | **TASK-PREVIEW-BACK-01 已修（Widget）** Sheet 关闭中忽略重复请求/拖动，取消动画不再调用 `onDismissed`；回调每次展示仅一次。极端真实手势未验 | 动效 | `glass_sheet.dart`、`preview_dismiss_test.dart` |
| **T** | **P2 `INFERRED`** 设置页在 `await` 对话框之后使用 `ref`，未统一检查页面仍挂载 | 校历/作息设置 | `semester_settings_page.dart:183-199`、`bell_settings_page.dart:162-187`、`calendar_exception_page.dart:116-224` |
| **U** | **P2 `CONFIRMED`** Today Preview 在 `courseByIdProvider` 已返回 null 后仍回退展示 `initialCourse` 旧快照；无初始快照的无效 ID 一直显示进度环 | 数据 / 导航 | `today_page.dart:148-156` vs `course_detail_page.dart:48-52` |
| **V** | **P2 `INFERRED`** 停在 Weekly 跨午夜时周次与「今天」标记不保证刷新（仅 Today 有 30s Timer，且只 invalidate Today 的 provider） | 数据 / 校历 | `timetable_page.dart:235-241`、`today_page.dart:32-45` |
| **W** | 日期算法在采用夏令时的设备时区下用固定 24 小时加法（`DateTime.add(Duration(days:))`），周日期与当前周缺 DST 测试；本机时区未复现 | 校历 | `semester_service.dart:13-26,58-63` |

### 第一轮已被判定 `INCORRECT` 的结论（**不得再引用**）

| 第一轮说法 | 更正 |
| --- | --- |
| 静止 Weekly 6 层玻璃 / Preview 约 11 层 | 实际静止 **约 8 层**（周导航外层 + **两个箭头按钮**各有 filter，第一轮漏计）；普通课程 Preview 约 **13 层**。均为组件实例数，**不等于同一像素的多次模糊**（无 `BackdropGroup`/`BackdropKey`） |
| 「3 处嵌套 BackdropFilter，含 ClipRRect」 | `ClipRRect` 包住**一个** filter 不是嵌套。真正的嵌套是「周导航外层 + 两个箭头」与「Sheet 面板 + 3 个按钮」、`course_edit` 底栏 + 按钮 |
| 「单个整页 RepaintBoundary 导致逐帧重录两周」 | 因果不成立，降级为 PERF-HYPOTHESIS |
| 「Android 上 MaterialPage 就是 Material 默认 zoom」 | 本机 Flutter 3.47.2 的 Android 默认 builder 是 `PredictiveBackPageTransitionsBuilder`；普通（非返回手势）导航回退到 **FadeForwards**，不是 zoom。且具体默认随 Flutter 版本变化 |
| 「点『完整详情』先关闭 Preview」 | `onDetails` 只 push 详情，**不关闭** Preview；因此「Hero 源在同一帧消失」的推断一并撤回 |
| 「从 `+N` 冲突列表选课沿用陈旧 `sourceRect`」 | 打开冲突列表时 rect 已清空（`sheet is! _CourseSheet` → `null`），随后选课得到 null rect，而非陈旧矩形 |
| 「Root 两整页 opacity 一直产生两个 saveLayer」 | 端点 0/1 走 Flutter `RenderOpacity` 快路径；只有分数 opacity 期间两页参与绘制，实际 GPU 成本未测 |


## 事实标记

沿用 `AGENTS.md`：`CONFIRMED` 已由代码/测试/真机验证；`INFERRED` 有证据但未直接验证；`UNVERIFIED` 未验证；`BLOCKED` 缺外部条件。**未验证不得写进「已完成」**。

## 更新记录

| 日期 | 变更 | 依据 |
| --- | --- | --- |
| 2026-09-28 | 首次建立：索引 + 9 份框架报告 | TASK-MOTION-AUDIT-01 审计 + 4 路只读代码调研 |
| 2026-10-02 | 更新教务导入框架现状与更新索引 | TASK-ADAPTER-GENERAL-01 |
