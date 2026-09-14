# 项目知识库

汇课：多校通用课表 App。用户在学校官方页面登录后本地导入课表，离线保存与展示。

## 项目边界

- 独立项目：`汇课`，根目录 `D:\桌面\汇课`，独立 Git 仓库。
- 与任何单校课表项目相互独立：不共享代码、数据库、签名或知识库；公开文档中不出现彼此的名称与归属关系。
- 本目录是本项目的唯一知识库。

推荐顺序：`current_state.md` → `tasks.md` → 当前任务专题文档。

- `current_state.md`：当前状态、可用功能、阻塞与验证快照
- `tasks.md`：任务（Now / Next / Blocked / Done）
- `decisions.md`：重要技术决策（DEC-xxx）
- `issues.md`：问题与技术债（ISSUE-xxx）
- `architecture.md`：系统结构、数据模型与数据流
- `adapters.md`：教务适配脚本契约桥、导入链路与安全语义
- `design.md`：设计语言「新历书」与界面约定
- `testing.md`：测试范围、命令与环境注意事项
- `changelog.md`：实质变更记录
- `report_2026-09-14_handoff.md`：**当前进度与技术交接报告**（接手先读）
- `report_2026-09-13_handoff.md`：前一份交接报告（正文为 09-13 状态，含文件地图、踩坑、恢复命令）

所有文件均由执行任务的 Agent 在任务结束前同步维护。
