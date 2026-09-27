# 项目知识库

汇课：多校通用课表 App。用户在学校官方页面登录后本地导入课表，离线保存与展示。

## 项目边界

- 独立项目：`汇课`，根目录 `D:\桌面\汇课`，独立 Git 仓库。
- 与任何单校课表项目相互独立：不共享代码、数据库、签名或知识库；公开文档中不出现彼此的名称与归属关系。
- 本目录是本项目的唯一知识库。

推荐顺序：`current_state.md` → `tasks.md` → 当前任务专题文档。

- `report_2026-09-27_root_switcher.md`：本次TASK-020B平级Today/Weekly悬浮共享capsule、状态保持、路由与动态设备QA；替代旧报告的顶部Today入口约定。

- `report_2026-09-27_app_icon.md`：TASK-026三白块汇聚图标、native资产、安全区/小尺寸与设备验证。

- `report_2026-09-27_launch_motion.md`：TASK-022B首帧状态连续性、启动背景、一次性reveal与启动验证边界。

- `report_2026-09-27_motion_audit.md`：TASK-022A A–E分类、普通motion统一、Reduced/iOS返回及设备验证边界。

- `report_2026-09-27_today_semantic_timeline.md`：TASK-021 Today内容高度/压缩空档、当前时间语义定位及验证边界。

- `report_2026-09-27_separate_today_from_weekly.md`：TASK-020B Weekly移除Today摘要、既有今日入口与验证范围。

- `report_2026-09-27_weekly_swipe_paging.md`：TASK-020A 单手势切周约束、行为回归和验证边界。

- `report_2026-09-26_weekly_glass_surface.md`：TASK-019B 删除左侧色条、完整玻璃面、明暗QA。

- `report_2026-09-26_weekly_information_density.md`：TASK-019 周卡信息密度、compact 地点、验证与范围。

- `current_state.md`：当前状态、可用功能、阻塞与验证快照
- `tasks.md`：任务（Now / Next / Blocked / Done）
- `decisions.md`：重要技术决策（DEC-xxx）
- `issues.md`：问题与技术债（ISSUE-xxx）
- `architecture.md`：系统结构、数据模型与数据流
- `adapters.md`：教务适配脚本契约桥、导入链路与安全语义
- `design.md`：设计语言「新历书」与界面约定
- `testing.md`：测试范围、命令与环境注意事项
- `changelog.md`：实质变更记录
- `plan_2026-09-15_week_agenda_ui.md`：TASK-013 整周自然日期顺序、UI 重构、
  Skills、彩蛋与验收计划（**2026-09-15 已实施**：见文件顶部「实施结果」与差异清单；
  未提交、未推送）
- `plan_2026-09-15_optimization_roadmap.md`：除真实教务验收与 iOS 外的项目优化总路线图，
  覆盖备份、签名、多校/学期、作息变体、小组件、提醒、测试与发布治理（待逐项批准）
- `report_2026-09-24_import_regression.md`：**TASK-018A 导入流程回归修复报告**（导入页正文
  整块消失与 CTA 恒 disabled 的根因、离开导入页的两条 dispose 期异常、测试与实机验证）
- `report_2026-09-23_review.md`：**昨日改动复审报告**（TASK-014 + TASK-015 逐文件复审：
  8 项代码缺陷、13 项文档与代码不一致、死代码与测试质量清单、处置优先级）
- `report_2026-09-23_liquid_glass.md`：**TASK-016 全 App Liquid Glass 重构报告**（D1–D8
  处置、C1–C13 文档收敛、验证结果、APK 指纹与未验证边界）
- `report_2026-09-23_liquid_glass_final.md`：**TASK-017 Liquid Glass 最终收尾报告**（weekly/today
  跨路由 Hero、表单与确认框收敛、一致性审计、测试及设备验证边界）
- `report_2026-09-14_handoff.md`：**当前进度与技术交接报告**（接手先读）
- `report_2026-09-13_handoff.md`：前一份交接报告（正文为 09-13 状态，含文件地图、踩坑、恢复命令）

所有文件均由执行任务的 Agent 在任务结束前同步维护。
