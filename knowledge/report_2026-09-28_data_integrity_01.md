# 2026-09-28 导入数据完整性修复报告（TASK-DATA-INTEGRITY-01）

## 1. Root Cause

- `importedCourseId` 原先只计算学校与课程内容；同校两个学期出现完全相同课程时生成同一全局主键。`replaceImportedCourses` 仅删除当前学期的导入行，另一个学期的行仍占用该主键，插入会失败。
- 预览确认原先顺序调用 `replaceSectionTimes`、`replaceImportedCourses`、`updateSemester`。前两个方法各自提交独立事务，最后一步失败时已提交的数据不会随 UI 的“写入失败”回滚。

## 2. ID Fix

- 新输入为 `schoolId`、`semesterId`、课程名、星期、起止节次和周次列表；教师、教室沿用既有规则，不参与身份计算。
- `semesterId` 既参与稳定指纹，也写入 `imp-$schoolId-$semesterId-...` 前缀。同样输入总是得到相同 ID；不同学期有不同前缀，不会因指纹相同而跨学期重用主键。
- 预览差异与数据库插入共用新签名。同学期重新导入仍先按学校、学期、`imported` 来源删除旧行，再插入新行；手动课程及其他学校不在删除范围内。

## 3. Legacy Data Compatibility

- 未改 schema，也无迁移。现有旧格式导入行在下次同学期重导时，由 `(schoolId, semesterId, source=imported)` 删除条件选中，然后以新 ID 插入；回归测试确认没有旧行残留或重复。
- ID 还用于预览差异映射、课程查询/编辑/删除路由、课程块 Key、Hero 身份和 Today 展示。首次重导前，旧行与新草稿 ID 不同，预览可能显示“移除 + 新增”；重导后指向旧 ID 的已有详情/编辑链接会失效。数据库未发现以课程 ID 为外键保存的其他表，正常页面会从新行构建新链接。此影响是 ID 规则变更的兼容性边界，未扩展处理其他 Import 行为。

## 4. Transaction Boundary

- `CourseRepository.confirmImport` 是确认导入的单个 `_db.transaction` 边界。它依次执行勾选的作息替换、课程替换、勾选的学期元数据更新；UI 只调用此入口。
- 原有两个 public `replace*` 方法仍各自包装事务，供独立调用；共同的私有写入步骤不启动事务。确认入口直接调用私有步骤，随后调用不自行开事务的 `SchoolRepository.updateSemester`，因此本路径没有嵌套事务。运行时 UI 的两个 repository 均由同一 `databaseProvider` 构造。
- 已检查本地 Drift 2.35.0 实现对嵌套事务的支持；本次仍采用一个明确的事务边界，避免依赖嵌套行为。

## 5. Rollback Verification

- 课程阶段失败：给同一批传入两条完全相同草稿，使第二次插入触发全局主键冲突。此时作息已替换、旧课程已删除且第一条新课程已插入；异常后对比数据库作息行、课程行、学期行的完整旧快照，均一致。
- 末阶段失败：测试用 `SchoolRepository` 子类先实际写入新学期元数据，再抛出注入异常。此时作息和课程也已写入；异常后上述三类真实数据库行全部与导入前一致。
- 成功路径另外检查新作息、新课程、开学日期和总周数均已保存。

## 6. Files Changed

| 文件 | 修改目的 |
| --- | --- |
| `lib/features/import/services/course_repository.dart` | 学期隔离 ID；新增确认导入单事务及内部写入步骤 |
| `lib/features/import/pages/import_preview_page.dart` | 预览 ID 使用学期参数，确认按钮调用统一入口 |
| `test/course_repository_test.dart` | 既有 ID 测试适配新签名 |
| `test/import_integrity_test.dart` | 新增一致性、兼容性和回滚测试 |
| `knowledge/current_state.md`、`knowledge/tasks.md` | 更新当前状态和任务完成记录 |
| `knowledge/adapters.md`、`knowledge/testing.md`、`knowledge/changelog.md` | 同步导入契约、验证事实和变更记录 |
| `knowledge/report_2026-09-28_data_integrity_01.md` | 本报告 |

开工前已存在的 `knowledge/README.md` 修改和多个未跟踪知识库文件属于工作区原有改动，本任务未修改或清理它们。

## 7. Tests

- 基线：283/283 通过；`flutter analyze --no-pub` 无问题。
- 新增：`import_integrity_test.dart` 7 例，涵盖同校跨学期同课共存、ID 稳定、同学期重导、跨学校隔离、旧 ID 替换、完整成功写入、课程阶段失败回滚和元数据更新后失败回滚；相关断言合并在 7 个测试中。
- 最终：290/290 通过；原有导入仓库测试继续通过。

## 8. Validation

| 检查 | 结果 |
| --- | --- |
| `flutter analyze --no-pub` | 通过，无问题 |
| `flutter test --no-pub` | 290/290 通过 |
| `flutter build apk --debug --no-pub` | 通过，生成 `build/app/outputs/flutter-apk/app-debug.apk` |
| `git diff --check` | 通过 |

命令在 `S:\` 路径执行；本轮无真实教务端到端、真机或 iOS 验收，均为 `UNVERIFIED`。未 commit、push、reset 或 clean。

## 9. Scope Confirmation

`assets/adapters/*.js`：NO；`shiguangBridge` / `shiguangBridgePromise`：NO；`adapter_bridge.dart`：NO；`NavigationPolicy`：NO；WebView：NO；Drift schema / migration：NO；Course model：NO；Weekly：NO；Today：NO；Motion：NO。未新增 package，未开始其他 Preview/Motion 修复。
