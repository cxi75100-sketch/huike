# 2026-09-30 工作区盘点报告（TASK-WS-AUDIT-01）

> 性质：只读盘点 + 当日复验。本报告不修改任何生产代码，只回答三个问题：
> 工作区里现在有什么、这些改动是否都有知识库记载、当前工作树是否仍然通过验证。

## 0. 结论摘要

- 工作区 = **2026-09-28 一整批任务的未提交改动**，37 个改动/新增文件逐项都能映射到
  已登记任务与专项报告，未发现「孤儿改动」，也未发现文档与代码冲突。
- 本地 master 与 origin/master 同为 `7bc4f10`，**已提交内容全部推送 Gitee**；
  未提交的只有工作树本身（15 个修改 + 22 个未跟踪文件）。
- 2026-09-30 当日复验：`flutter analyze --no-pub` 无问题、`flutter test --no-pub`
  **314/314**、`git diff --check` 通过；`app-debug.apk` 与 `huike-0.1.4-release.apk`
  的 SHA-256 与知识库记录逐字一致。
- 待处置两件事：① `.playwright-mcp/` 有一张自动化遗留截图，建议删除并把目录加进
  `.gitignore`；② 本批改动已滞留 2 天未归档，建议尽快按 2026-09-27 的模式提交并推送。

## 1. 范围与方法

- `git status` / `git diff --stat` 逐文件清点，untracked 文件逐个读取大小与内容抽样。
- lib 改动逐文件抽取 diff 关键行，与各专项报告声称的机制比对。
- 构建产物比对文件大小与 SHA-256（`sha256sum`）。
- 当日在 `S:\`（`subst S: "D:\桌面\汇课"`）重跑 analyze、全量测试、diff-check。

## 2. Git 状态（2026-09-30）

- 分支 master；HEAD `7bc4f10`（docs: 知识库补齐归档与发布的精确日期时间）。
- `origin/master` 引用读回 `7bc4f10` = 本地 HEAD；`git log origin/master..master` 为空，
  **没有未推送提交**。
- 无 stash。
- 工作树：**15 个修改文件**（lib 7、knowledge 7、test 1，合计 +776/−236 行）+
  **22 个未跟踪文件**（knowledge 18、test 4）+ 1 个自动化遗留目录 `.playwright-mcp/`。

## 3. 改动 → 任务映射（逐项核对）

### lib / test（生产代码与测试）

| 文件 | 任务 | diff 抽查确认的内容 |
| --- | --- | --- |
| `lib/core/glass/glass_sheet.dart`（+391 行级重构） | TASK-PREVIEW-BACK-01 + TASK-PREVIEW-GEOMETRY-01 | 新增 `sourceRectProvider` / `onDismissStarted`；`_dismissing` / `_dismissed` 一次性关闭状态机；`close()` 公开入口；destination 统一到 Host-local 并有 `_retryOrFallbackGeometry` 回退 |
| `lib/features/timetable/pages/timetable_page.dart` | 同上（页面侧） | `PopScope` + `onPopInvokedWithResult` 消费 Back；`_sheetHostKey`、`_courseSourceKey` / `_courseSourceRect` 采集与关闭前刷新 |
| `lib/features/timetable/widgets/timetable_course_block.dart`、`timetable_grid.dart` | TASK-PREVIEW-GEOMETRY-01 | 课程块 source Rect 接线 |
| `lib/features/import/services/course_repository.dart` | TASK-DATA-INTEGRITY-01 | `confirmImport` 单 Drift 事务覆盖作息/课程/学期配置；`_replaceImportedCourses` 为事务内不自行提交的私有步骤；`importedCourseId` 签名加入 `semesterId` |
| `lib/features/import/pages/import_preview_page.dart` | TASK-DATA-INTEGRITY-01 | 改调 `confirmImport`（删除页面自行拼装的 replaceSectionTimes/replaceImportedCourses/updateSemester 序列） |
| `lib/features/settings/pages/calendar_exception_page.dart` | TASK-CALENDAR-DATE-01 | `initialDate` 按 firstDate/lastDate 夹取；firstDate/lastDate 计算保持原范围 |
| `test/course_repository_test.dart`（修改） | TASK-DATA-INTEGRITY-01 | 适配新 ID 签名 |
| `test/import_integrity_test.dart`（新，292 行） | 同上 | 7 例：跨学期共存、重导替换、跨校隔离、旧 ID 换新、成功写入与两类回滚 |
| `test/calendar_exception_date_picker_test.dart`（新，144 行） | TASK-CALENDAR-DATE-01 | 5 例：今天/历史/未来/合法旧日期/越界旧日期 |
| `test/preview_dismiss_test.dart`（新，249 行） | TASK-PREVIEW-BACK-01 | 9 例关闭状态机回归 |
| `test/preview_geometry_test.dart`（新，327 行） | TASK-PREVIEW-GEOMETRY-01 | 10 例 source/destination 几何回归 |

### knowledge（新增 18 + 修改 7）

- 新增 `framework_*.md` 10 份（共 1,901 行）+ `framework_index.md`：TASK-AUDIT-01/02
  产出的长期框架报告体系，README 已登记。
- 新增 `report_2026-09-28_*.md` 8 份（共 1,222 行）：add_school_entry_crash（ISSUE-019 诊断）、
  adversarial_random_audit（第二阶段复核，**当前结论权威**）、motion_audit_full（第一轮，
  顶部有更正声明）、weekly_perf_profile_01、preview_geometry_01、preview_back_01、
  calendar_date_01、data_integrity_01。
- 修改：`README.md`（框架报告索引与权威顺序）、`changelog.md`（+37 行，5 条 09-28 记录）、
  `current_state.md`、`tasks.md`、`testing.md`（5 个 09-28 任务验证段）、`issues.md`
  （ISSUE-019 全条目）、`adapters.md`（导入 ID 语义与 confirmImport 事务）。

## 4. 与知识库一致性核对结果

- **每个代码改动都有归属**：7 个 lib 文件、4 个新测试、1 个修改测试全部落在
  09-28 的五个任务内；没有任何无法解释的改动。
- **数字核对一致**：
  - `testing.md` 记录的最终 APK `207,132,994` 字节 ↔ 实际 `build/app/outputs/flutter-apk/app-debug.apk`
    （2026-09-28 20:03）大小一致，SHA-256 复算 `26A9A567…EBBA6EE` 与记录逐字一致；
  - `build/huike-0.1.4-release.apk` `63,982,250` 字节，SHA-256 `720F0EB1…CB545` 与
    「发布 v0.1.4」记录逐字一致；
  - `build/app/outputs/flutter-apk/app-profile.apk`（44,763,879 字节，09-28 19:50）为
    TASK-WEEKLY-PERF-PROFILE-01 的 profile 构建产物，与该任务性质吻合；
  - 四个新测试文件的用例数（10/9/7/5）与 `testing.md` 各段记载一致。
- `build/` 在 `.gitignore` 内，构建产物未入库（沿用既有纪律）。

## 5. 当日复验（2026-09-30）

- `CONFIRMED`（`S:\`，subst 后执行）：`flutter analyze --no-pub` **No issues found**（56.0s）。
- `CONFIRMED`：`flutter test --no-pub` **314/314 全部通过**。
- `CONFIRMED`：`git diff --check` 退出码 0。
- 与 2026-09-28 收口记录（314/314）一致，说明该日之后工作树未再变化。

## 6. 发现的问题

1. `.playwright-mcp/page-2026-09-28T11-17-35-176Z.png`（205 KB，2026-09-28 19:17）：
   浏览器自动化会话遗留截图，内容为 Flutter DevTools「What's new in DevTools?」弹窗
   （连着 profile 构建的应用，属 TASK-WEEKLY-PERF-PROFILE-01 现场残留）。
   **无证据价值**；该目录未被 `.gitignore` 覆盖，若不处理会一直挂在 untracked 里。
   建议：删除整个 `.playwright-mcp/` 目录，并在 `.gitignore` 加一行 `.playwright-mcp/`。
2. **整批改动滞留未归档**：自 2026-09-28 至今（09-30）第 3 天，15 修改 + 22 新文件。
   工作树没有任何提交保护，一次误操作的 `reset`/`clean` 即可丢掉两天工作量；
   建议 按 2026-09-27 模式归档（feat 提交代码与测试 + docs 提交知识库，或合并为一笔），
   推送 Gitee 需用户提供令牌（走既有 extraHeader 方式，不落盘）。
3. ISSUE-019（有学校时点「添加学校」红屏/入口不可达）仍 **Open**：诊断与临时验证已完成
   （见 `report_2026-09-28_add_school_entry_crash.md`），修复代码未落地；
   TASK-NAV-ADD-SCHOOL-01 在 tasks.md 的 Now。
4. 既有未决项维持原状（本报告不改变其状态）：release 签名仍为 debug 证书（ISSUE-006）、
   真机 GPU / iOS / 真实教务端到端维持各专项报告的 `UNVERIFIED` 标记。

## 7. 事实标记汇总

- 本报告第 2、4、5 节的全部结论为 `CONFIRMED`（本机 git、文件系统与当日测试运行取证）。
- 本报告不引入新的 `UNVERIFIED` 项；各任务自身的未验证边界以其专项报告为准。
