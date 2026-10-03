# 项目知识库

- `release_1.0.0.md`：正式版1.00学校切换、版本、验证、APK与双远端发布记录。

- `report_2026-10-03_login_recovery.md`：明确登录异常自动恢复一次、受限登录状态清理、主动重登、真实WebView证据与安全边界。

- `report_2026-10-03_import_reliability_startup.md`：首次打开直接进入首页、主动导入才填学校/网址；同源frame、动态页面与尝试清理及验证证据。

- `report_2026-10-03_webview_framework.md`：通用登录浏览器框架排查；与昨日适配更新的关系、原生导航取消重发、加载错误与恢复、脱敏诊断和验证边界。

- `report_2026-10-02_adapter_framework.md`：通用教务适配框架审计与实现；包括profile/catalog契约、候选顺序、匹配门槛、脱敏诊断、synthetic fixture、377项验证及真实环境边界。

- `report_2026-10-02_login_repair.md`：旧默认入口为何复发、自动修复与导入确认网址持久化、验证与APK。

- `report_2026-10-02_project_completion.md`：全量完成度报告；功能模块覆盖、工程质量、真实验收、平台、发布与遗留项，含本轮362/362及最新UI收口。

- `report_2026-10-02_today_launch_root.md`：今日蓝线替代、日夜浅色品牌启动、底部控件内滑动切换，验证/APK与旧导课地址诊断。

- `report_2026-10-02_rapid_interaction.md`：快速换课、连续翻周修复与验证/APK。
- `proposal_2026-10-02_today.md`：今日页信息层级/下一节摘要改进建议，待实施。

- `report_2026-10-02_course_hues.md`：最新16色全色相课程配色，专项验证与汇课新版APK；替代此前冷色色板，动画保持。

汇课：多校通用课表 App。用户在学校官方页面登录后本地导入课表，离线保存与展示。

## 项目边界

- 独立项目：`汇课`，根目录 `D:\桌面\汇课`，独立 Git 仓库。
- 与任何单校课表项目相互独立：不共享代码、数据库、签名或知识库；公开文档中不出现彼此的名称与归属关系。
- 本目录是本项目的唯一知识库。

推荐顺序：`current_state.md` → `tasks.md` → `framework_index.md`（按框架查现状与更新清单）→ 当前任务专题文档。

## 核心文档（唯一权威）

- `current_state.md`：当前状态、可用功能、阻塞与验证快照
- `tasks.md`：任务（Now / Next / Blocked / Done）
- `decisions.md`：重要技术决策（DEC-xxx）
- `issues.md`：问题与技术债（ISSUE-xxx）
- `architecture.md`：系统结构、数据模型与数据流
- `adapters.md`：教务适配脚本契约桥、导入链路与安全语义
- `design.md`：设计语言「新历书」与界面约定
- `testing.md`：测试范围、命令与环境注意事项
- `changelog.md`：实质变更记录

## 框架报告（可长期维护）

按「框架」拆分的现状报告，统一骨架：边界 / 关键文件与入口 / 机制与约定 / 唯一定义点 / 改动时必须同步的位置 / 已知问题 / 未验证边界 / 更新记录。**入口**：`framework_index.md`（含更新约定与跨框架未决项）。与 `architecture.md`、`design.md`、`adapters.md`、`testing.md`、`decisions.md`、`issues.md` 的关系：后六者仍是**唯一权威**，框架报告只登记策略在代码里的落点，不复述策略原文。

> **结论权威顺序**：`report_2026-09-28_adversarial_random_audit.md`（第二阶段只读复核，TASK-AUDIT-02）> `report_2026-09-28_motion_audit_full.md`（第一轮，已有 5 条结论被判定 INCORRECT）。框架报告已按第二阶段口径回填；两轮冲突处以后者为准。

- `framework_index.md`：索引、更新约定（改哪块要同步哪份）、跨框架未决项 A–W（含第二阶段新增的 4 项 P0/1 项 P1/3 项 P2），以及「第一轮已被判定 INCORRECT 的结论」清单。**先读它。**
- `framework_motion.md`：动效与过渡。令牌全表、按压物理、切周手势状态机、一级切换、Sheet/Preview、路由过渡方言、Reduced Motion 覆盖与缺口。
- `framework_glass.md`：玻璃材质。GlassSurface 五层与包裹顺序、GlassIntensity→sigma、同屏层数统计、嵌套模糊清单、动画与模糊的相互作用。
- `framework_navigation.md`：路由与页面层级。16 条路由表、三种过渡方言、一级页保留策略、返回行为。
- `framework_data.md`：数据与状态。6 张表与 schemaVersion 3 迁移、全部 repository 写路径、28 个 provider 图与刷新语义。
- `framework_theme.md`：主题与视觉令牌。AppPalette 双套色值、AppTheme 14 个子主题、课程16色、明暗一致性缺口。
- `framework_startup.md`：启动与首帧。原生底色一致性、deferFirstFrame、就绪判定链、reveal 代价。
- `framework_import.md`：教务导入与适配。完整链路、4 个脚本、8 个桥方法、批次契约、安全边界逐条落点、diff/写入语义。**安全敏感**。
- `framework_school_calendar.md`：学校/学期/作息/校历。内置档案、模型不变量、周次与校历派生、作息变体匹配、五个设置页能力。
- `framework_dependencies.md`：第三方依赖。版本与引用面总表、vendored 包与改动理由、平台配置、升级敏感位点。

## 任务报告

- `report_2026-10-01_legacy_upgrade.md`：旧图标恢复、两种签名的兼容Debug包、保留课表的只读迁移与启动失败重试、最终产物及未验证边界。

分组内按时间倒序。**排查类报告（诊断 / 修复 / 审计 / 盘点 / 性能取证）标题一律为
`YYYY-MM-DD 中文标题（TASK/ISSUE 号）`；功能实施类报告标题不强制带日期。**
新增排查类报告时沿用该格式，并登记到第一组。

### 排查、修复与审计

- `report_2026-10-02_today_motion_color.md`：**2026-10-02 今日详情过渡、课程配色与当前节次提示修正（TASK-TODAY-MOTION-COLOR-01）**。今日面板独立动画、减少滤镜/重复飞行、统一冷色、轴内文字提示，静态/交互测试和汇课Release/Debug包；真机帧率未验。

- `report_2026-10-02_visual_return.md`：**2026-10-02 启动图标、课程配色与预览返回修正（TASK-VISUAL-RETURN-01）**。矢量安全区、终态尺寸平移、对比度与测试/安装包；真机流畅度未验。

- `report_2026-10-01_school_url_dialog.md`：**2026-10-01 修改教务网址关闭红屏：原因与修复**（TASK-SCHOOL-URL-DIALOG-01 / ISSUE-020）。控制器提前释放→焦点继承组件断言的复现、修复与回归结果。

- `report_2026-10-01_perf_blur_01.md`：**2026-10-01 Weekly Preview 模糊性能取证与局部优化报告**（TASK-PERF-BLUR-01）。分层 A–H、三次重复逐帧 profile、
  Weekly Preview 三按钮局部优化、前后对照与视觉/测试边界；原始脱敏证据为
  `evidence_2026-10-01_blur_profile.json`。

- `progress_report_2026-10-01_weekly_perf_profile_01.md`：**2026-10-01 Weekly / Preview 性能取证进度报告**（TASK-WEEKLY-PERF-PROFILE-01）。快速进度摘要；概括模拟器 profile、blur A/B、验证结果和未覆盖范围。

- `report_2026-09-30_workspace_audit.md`：**2026-09-30 工作区盘点报告**（TASK-WS-AUDIT-01，只读盘点 +
  当日复验）。09-28 批次 37 个改动/新增文件逐项映射到任务、与知识库记载全部吻合；
  APK 大小与 SHA-256 复算一致；当日 analyze 无问题、314/314、diff-check 通过；
  顶部记录 `.playwright-mcp/` 遗留与「整批未归档」两个待处置项。

- `report_2026-09-28_adversarial_random_audit.md`：**2026-09-28 对抗式随机审计报告**（TASK-AUDIT-02 第二阶段只读复核，随机抽样 20 源文件 + 10 测试文件，逐条核验第一轮结论）。判定第一轮 5 条 INCORRECT、6 条 PARTIALLY CONFIRMED，并新增 4 项 P0（跨学期导入 ID 冲突、导入多段写入无整体事务、历史学期日期选择器断言、Weekly Preview 的 Android Back）、1 项 P1、3 项 P2；把第一轮的性能 P0 降级为 PERF-HYPOTHESIS。**当前结论权威**。

- `report_2026-09-28_motion_audit_full.md`：**2026-09-28 全 App 动画 / 过渡现状审计报告**（TASK-MOTION-AUDIT-01，纯审查，无改动）。含全量动画清单、Weekly手势状态机、一级切换、Preview、路由方言、玻璃与BackdropFilter成本、启动、成熟度评分、P0/P1/P2与GitHub研究方向。模拟器 profile 实测但**未取得**逐帧耗时。**顶部有更正声明**：5 条结论已被第二阶段判定 INCORRECT，引用前先读该声明。

- `report_2026-09-28_add_school_entry_crash.md`：**2026-09-28 点「添加学校」红屏诊断报告**（Navigator 重复 pageKey 断言，ISSUE-019；纯诊断，无修复）。定位到 `app_router.dart` 的 redirect 吞掉 `?add=1`，被改写的 push 让 go_router 追加重复 `StatefulShellRoute` 页 → 根 Navigator 两个 Page 同 key（`navigator.dart:4096`）。含 match 树实测证据、时间线（0.1.0 起入口不可达、0.1.4 起变红屏）、已临时验证未保留的修法与回归测试清单。

- `report_2026-09-28_data_integrity_01.md`：**2026-09-28 导入数据完整性修复报告**（TASK-DATA-INTEGRITY-01）。跨学期导入课程 ID 冲突、预览确认多段写入无整体事务的根因，新 ID 签名（纳入 semesterId）与单事务写入，回归测试。

- `report_2026-09-28_calendar_date_01.md`：**2026-09-28 校历例外日期选择器越界修复报告**（TASK-CALENDAR-DATE-01）。历史/未来学期与既有例外日期越界触发 DatePicker 断言的三种复现路径、候选日期夹取修复与回归测试。

- `report_2026-09-28_preview_back_01.md`：**2026-09-28 Weekly Preview 返回拦截修复报告**（TASK-PREVIEW-BACK-01）。Android Back 用 PopScope 消费，X、背景、下拖、编辑统一一次关闭状态机，回归测试。

- `report_2026-09-28_preview_geometry_01.md`：**2026-09-28 Weekly Preview 几何修正实施报告**（TASK-PREVIEW-GEOMETRY-01）。source/destination 实测、统一坐标系容器插值、内容 reveal、反向关闭/fallback 与测试边界。

- `report_2026-09-28_weekly_perf_profile_01.md`：**2026-09-28 Weekly / Preview 性能取证报告**（TASK-WEEKLY-PERF-PROFILE-01）。Weekly / Preview
  的 Android profile 逐场景证据、临时 blur A/B、冷/热切周边界与未验证项目；无生产优化。

- `report_2026-09-24_import_regression.md`：**2026-09-24 导入流程回归修复报告**（TASK-018A）。导入页正文
  整块消失与 CTA 恒 disabled 的根因、离开导入页的两条 dispose 期异常、测试与实机验证。

- `report_2026-09-23_review.md`：**2026-09-23 昨日改动复审报告**（TASK-014 + TASK-015，逐文件复审）：
  8 项代码缺陷、13 项文档与代码不一致、死代码与测试质量清单、处置优先级。

### 功能实施

- `report_2026-10-01_compact_color.md`：**TASK-UI-COMPACT-COLOR-01 学校入口与紧凑单色课程卡**（2026-10-01）。学校管理移除添加入口、Today常规高度75%与完整字段、16色单色课程卡；验证与平台边界。
- `report_2026-09-27_root_switcher.md`：TASK-020B 平级Today/Weekly悬浮共享capsule、状态保持、路由与动态设备QA；替代旧报告的顶部Today入口约定。
- `report_2026-09-27_app_icon.md`：TASK-026 三白块汇聚图标、native资产、安全区/小尺寸与设备验证。
- `report_2026-09-27_launch_motion.md`：TASK-022B 首帧状态连续性、启动背景、一次性reveal与启动验证边界。
- `report_2026-09-27_motion_audit.md`：TASK-022A A–E分类、普通motion统一、Reduced/iOS返回及设备验证边界。
- `report_2026-09-27_today_semantic_timeline.md`：TASK-021 Today内容高度/压缩空档、当前时间语义定位及验证边界。
- `report_2026-09-27_separate_today_from_weekly.md`：TASK-020B Weekly移除Today摘要、既有今日入口与验证范围。
- `report_2026-09-27_weekly_swipe_paging.md`：TASK-020A 单手势切周约束、行为回归和验证边界。
- `report_2026-09-26_weekly_glass_surface.md`：TASK-019B 删除左侧色条、完整玻璃面、明暗QA。
- `report_2026-09-26_weekly_information_density.md`：TASK-019 周卡信息密度、compact 地点、验证与范围。
- `report_2026-09-23_liquid_glass.md`：**TASK-016 全 App Liquid Glass 重构报告**（D1–D8
  处置、C1–C13 文档收敛、验证结果、APK 指纹与未验证边界）
- `report_2026-09-23_liquid_glass_final.md`：**TASK-017 Liquid Glass 最终收尾报告**（weekly/today
  跨路由 Hero、表单与确认框收敛、一致性审计、测试及设备验证边界）

### 计划与交接

- `plan_2026-09-15_week_agenda_ui.md`：TASK-013 整周自然日期顺序、UI 重构、
  Skills、彩蛋与验收计划（**2026-09-15 已实施**：见文件顶部「实施结果」与差异清单；
  **2026-09-27 已随归档提交 `f9eccc9` 入库并推送 Gitee**）
- `plan_2026-09-15_optimization_roadmap.md`：除真实教务验收与 iOS 外的项目优化总路线图，
  覆盖备份、签名、多校/学期、作息变体、小组件、提醒、测试与发布治理（待逐项批准）
- `report_2026-09-14_handoff.md`：**当前进度与技术交接报告**（接手先读；正文为 09-14 状态，顶部有过时声明）
- `report_2026-09-13_handoff.md`：前一份交接报告（正文为 09-13 状态，含文件地图、踩坑、恢复命令）

所有文件均由执行任务的 Agent 在任务结束前同步维护。
