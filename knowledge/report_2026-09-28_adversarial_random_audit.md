# 2026-09-28 对抗式随机审计报告（TASK-AUDIT-02 第二轮只读复核）

任务：TASK-AUDIT-02（第二轮，只读复核）  
日期：2026-09-28 +08:00  
范围：审查代码、既有测试和 TASK-MOTION-AUDIT-01；不修改业务文件，不实施修复。

事实口径：`CONFIRMED` 表示当前代码、测试或框架源码直接支持；`INFERRED` 表示存在可解释的静态路径但本轮未动态复现；`UNVERIFIED` 表示未取得验证证据。性能成本与可感知卡顿分开判断。首轮报告只作为待验证的假设集合。

## A. Baseline

| 项目 | 本轮结果 |
| --- | --- |
| HEAD | `7bc4f10`（master） |
| 开工前工作树 | 已有 `knowledge/README.md` 修改；`knowledge/report_2026-09-28_motion_audit_full.md` 未跟踪 |
| `flutter analyze --no-pub` | `S:\` 下 `No issues found!`（59.7s） |
| `flutter test --no-pub` | 283/283 通过 |
| Android 设备 | `adb devices -l` 无设备；`flutter devices` 仅 Windows、Chrome、Edge |

`S:` 遵循 AGENTS.md 的中文路径约定。本轮结束时再次运行 `git status`、`git diff --stat`、`git rev-parse --short HEAD`：上述既有改动保持原样；本报告为唯一新增文件。未生成截图、审查日志、APK、commit 或 push。

## B. Random Sample

先读取 `git ls-files`，以固定随机种子从各类抽样，实际审阅 20 个 Dart 源文件和 10 个测试文件。至少 15 个源文件不在首轮报告 §16 的重点文件清单内。随机样本是入口；异常调用链另追读了 `week_swipe.dart`、`glass_sheet.dart`、`timetable_page.dart`、`timetable_grid.dart`、`course_repository.dart`、`semester_service.dart` 等。

| 类别 | 抽中文件（均位于 `lib/` 或 `test/`） |
| --- | --- |
| Core，种子 20260928 | `core/glass/glass_metrics.dart`、`core/widgets/launch_readiness.dart`、`core/router/app_router.dart`、`core/glass/press_physics.dart` |
| Timetable，种子 20260928 | `features/timetable/services/weekly_location_formatter.dart`、`widgets/course_hero.dart`、`services/week_agenda.dart`、`pages/today_page.dart` |
| Settings，种子 20260928 | `features/settings/pages/semester_settings_page.dart`、`bell_settings_page.dart`、`calendar_exception_page.dart`、`school_manage_page.dart` |
| Import，种子 20260928 | `features/import/services/navigation_policy.dart`、`widgets/import_widgets.dart`、`pages/import_preview_page.dart`、`pages/import_entry_page.dart` |
| Provider，种子 20260929 | `features/timetable/providers/timetable_providers.dart`、`core/theme/theme_preference_provider.dart`、`features/schools/providers/calendar_exception_providers.dart`、`school_providers.dart` |
| Tests，种子 20260928 | `week_parser_test.dart`、`adapter_batch_test.dart`、`weekly_course_block_test.dart`、`weekly_location_formatter_test.dart`、`week_agenda_ui_test.dart`、`course_repository_test.dart`、`navigation_policy_test.dart`、`course_collision_layout_test.dart`、`calendar_exception_repository_test.dart`、`app_shell_test.dart` |

## C. Previous Audit Verification Matrix

| Previous Claim | Verdict | Evidence | Correction |
| --- | --- | --- | --- |
| Preview 假设高度错误，实测偏差 111dp | PARTIALLY CONFIRMED | `glass_sheet.dart:227-249` 将目标高度写为屏高 × 0.5 | 几何假设确实不等于内容实高；111dp 是首轮设备快照，本轮未重新测量 |
| 动态全屏 blur 是最重性能点 | DOWNGRADED TO INFERRED | `glass_sheet.dart:172-189` 逐帧改变全屏 filter 的 sigma | 成本机制成立；无可靠 UI/Raster 帧耗时，不能确认是主要卡顿源，也不能列为 P0 |
| Weekly 首次拖动挂载邻周 | PARTIALLY CONFIRMED | `week_swipe.dart:302-313` 仅在 offset 非零时放入邻页 | 首帧挂载成立；“因此起手卡顿”尚未实测 |
| Weekly 每次都重算并重画三周 | PARTIALLY CONFIRMED | `timetable_page.dart:97-120` 在父页 build 时计算三周 agenda | 静止时邻页不在 pager 的绘制树中；三份 agenda 计算与三张网格都 layout/paint 不等价 |
| Root switcher 保留分支状态 | CONFIRMED | `app_router.dart:64-92`、`timetable_root_shell.dart:131-192`；既有 root switcher 测试通过 | 业务 `currentIndex` 与动画 progress 在过渡中有预期的短暂差值，非状态错乱证据 |
| Root 两整页 opacity 一直产生两个 saveLayer | PARTIALLY CONFIRMED | `timetable_root_shell.dart:154-180`；Flutter `RenderOpacity` 0/1 快路径 | 分数 opacity 期间两页参与绘制并有中间层成本；端点不应算两个分数 opacity 层，实际 GPU 成本未测 |
| 路由过渡不一致 | CONFIRMED | `app_router.dart` 使用 CustomTransitionPage、MaterialPage 和默认 builder 页面 | 具体 Android 默认过渡随 Flutter 版本变化，不能统一叫 zoom |
| Reduced Motion 有缺口 | CONFIRMED | `timetable_course_block.dart:101-102,329` 不检查 disableAnimations | Swipe、Sheet、Switcher 有 Reduced 接线；课块按压仍缩放 |
| 静止 Weekly 为 6 个 filter，Preview 约 11 个 | INCORRECT | `week_navigation.dart:94-155` 外层及两支默认 GlassButton 箭头均有 filter | 典型静止 Weekly 约 8 个；Preview 再增全屏 1、面板 1、按钮 3，约 13 个。均是组件实例数 |
| “3 处嵌套 BackdropFilter”，含 ClipRRect | INCORRECT | `glass_surface.dart:144-200` | ClipRRect 包住一个 filter 不是两个 filter 嵌套；周导航和 Sheet 面板的父子 filter 才是嵌套 |
| 单个整页 RepaintBoundary 导致逐帧重录两周 | INCORRECT | `timetable_root_shell.dart:152`、`week_swipe.dart:322-331` | 边界存在不构成该因果证明；需分别观测 rebuild、paint、合成与背景采样 |
| 启动状态连续性 | PARTIALLY CONFIRMED | `launch_readiness.dart` 等待主题/学校/课程初值，启动测试通过 | 真机首帧耗时、完整 GPU 动画仍 UNVERIFIED |
| Android MaterialPage 就是默认 zoom | INCORRECT | Flutter 3.47.2 的 `page_transitions_theme.dart:764-770` 为 `PredictiveBackPageTransitionsBuilder`；`predictive_back_page_transitions_builder.dart:79-97` 普通导航使用 FadeForwards | Material 默认路由成立；具体称为 zoom 不适用于本机当前 Android 默认配置 |
| Sheet 关闭路径不一致 | CONFIRMED | `glass_sheet.dart:135-153` 与 `timetable_page.dart:227-230` | 背景/拖动有退场；X/编辑直接清空。首轮另称“点完整详情先关闭 Preview”错误：`timetable_page.dart:204-213` 只 push 详情 |
| 冲突列表选课沿用旧 sourceRect | INCORRECT | `timetable_page.dart:220-224` | 打开冲突列表时 rect 已清空；随后选课得到 null rect，而非陈旧的前一门课矩形 |

## D. Newly Discovered Issues

以下问题均未见于首轮 Motion Audit。风险等级按本任务给出的 P0/P1/P2 定义，未动态复现的路径明确标记。

1. **P0，CONFIRMED（代码路径）：跨学期导入相同课程可能发生主键冲突。** `course_repository.dart:143-158` 的 `importedCourseId` 只包含学校 ID 与课名、星期、节次、周次，不包含学期 ID；`replaceImportedCourses` 仅删除当前学期的 imported 行（`:27-35`），再向全局主键表插入同一 ID（`:36-56`）。同一学校第二学期若有同样课程，旧学期行仍在，第二次导入无法完成。现有 `course_repository_test.dart` 只测同学期重导及跨学校隔离。
2. **P0，CONFIRMED（事务边界）：导入确认可能部分写入。** `import_preview_page.dart:415-440` 先调用 `replaceSectionTimes`，再 `replaceImportedCourses`，最后 `updateSemester`。前两者各自拥有独立 `_db.transaction`，学期更新又是独立写入。后段失败时前段已提交，界面却只报一次“写入失败”。
3. **P0，CONFIRMED（条件路径）：历史/未来学期“添加校历例外”可能触发日期选择器断言。** `calendar_exception_page.dart:99-107` 以今天为 `initialDate`，却把可选范围限制在该学期前后约 30 天。本机 Flutter `material/date_picker.dart:230-240` 要求初始日期在范围内。学期与今天相距较远时入口不能正常打开。
4. **P0，INFERRED：Weekly 内嵌 Preview 的 Android Back 很可能直接离开根页面。** Preview 是 `timetable_page.dart:174-187` 的页内 `GlassSheetHost`，不创建路由；全项目未发现 `PopScope`、`WillPopScope` 或 Back 监听。处于 `/` 根页且 Preview 打开时，没有可弹出的 Preview 路由。设备交互尚未验证。
5. **P1，INFERRED：Sheet 关闭被新手势中断时仍可能收到关闭回调。** `glass_sheet.dart:135-153` 用 `whenCompleteOrCancel` 注册目标 0 的 `onDismissed`；`_handleDragStart` 在 `:110-113` 调用 `progress.stop()`。若在退场期间重新拖动，取消也会触发此前关闭回调，可能把正在操作的 Sheet 清空。缺中断行为测试。
6. **P2，INFERRED：设置页 dialog 返回后读取已卸载的 WidgetRef。** `semester_settings_page.dart:183-199`、`bell_settings_page.dart:162-187`、`calendar_exception_page.dart:116-193,195-224` 等在 await 对话框之后使用 `ref`，未统一检查页面仍挂载。外部导航或父路由移除页面时存在异常路径。
7. **P2，CONFIRMED（状态分支）：Today Preview 可展示已删除课程的旧快照。** `today_page.dart:148-156` 在 `courseByIdProvider` 已返回 null 后仍回退到 `initialCourse`；无初始快照的无效 ID 则一直展示进度环。`course_detail_page.dart:48-52` 已有“课程不存在或已删除”的明确分支。
8. **P2，INFERRED：Weekly 跨午夜状态可能滞后。** `timetable_page.dart:235-241` 仅在 build 时读取 `DateTime.now()`；Today 的 30 秒 Timer 只 invalidate Today provider（`today_page.dart:32-45`）。长期留在 Weekly 或从保留的 Today 分支切回时，周次与“今天”标记不保证按日期变化刷新。

## E. State / Lifecycle Findings

抽查的 AnimationController、Today Timer、ValueNotifier 与 Scroll 状态的创建/dispose 大体成对。`TimetablePage` 的数据流发射会使父页重新生成三周 agenda；如果发射发生在 swipe/Sheet 过渡中，视觉内容可在几何运动期间变化。当前测试没有针对“拖动中 Drift stream 发射”的交叉场景。Sheet 的取消回调与设置页异步 `WidgetRef` 是更直接的生命周期风险。

## F. Navigation Findings

| 路径 | 当前路由推演 |
| --- | --- |
| Weekly → Preview → Detail → Edit → Back → Back | Preview 是 Weekly 内嵌状态；Detail、Edit 为根 Navigator 页面。点 Detail 不关闭 Preview，两个 Back 后返回仍打开的 Preview |
| Today → Preview → Detail → Back | Today Preview 与 Detail 都是根 Navigator 页面；Back 返回 Preview。Today Preview 的“编辑”在一个回调中先 pop 再 push，缺时序测试 |
| Weekly → Settings → Semester → Back | Settings 与 Semester 都是根 Navigator 页面；Back 依次回退 |
| Weekly → Import → Web → Preview → Back | Import/Web/Preview 在根 Navigator；Web 通过 `context.push` 打开 Preview，Back 返回 Web |

未找到明确“push 到错误 Navigator”的静态证据。Dialog、Today Preview 和普通子页由路由管理系统 Back；Weekly 内嵌 Preview 是例外。`CourseHeroTag` 包含课程/学校/学期/来源，非活动分支由 `HeroMode` 关闭；未发现已证实的重复 tag。现有测试主要查 tag 存在与相等，不能证明跨 Navigator 的实际 Hero 飞行。

## G. Weekly Findings

`week_swipe.dart` 在 drag down 锁资格，end 消费一次，cancel 回弹，完成回调至多提交相对 ±1 周；边界由 `previous`/`next` 和 `_canGo*` 限制。箭头请求重定向当前 controller，没有队列。现有测试覆盖普通/高速/长拖、边界、cancel、第二指和 Reduced。未覆盖旋转中改变 `_viewportWidth`、阈值附近的速度/距离组合、拖动中课程流发射或 provider 变更。`_viewportWidth` 变化时同一归一化 offset 对应的物理位移会变化，视觉后果为 INFERRED。

## H. Preview / Hero Findings

`sourceRect` 在课程点按时从 RenderBox 取一次全局矩形，不随滚动、窗口、键盘或布局更新。冲突列表会清掉旧矩形。Weekly Preview 中的 X、背景点按、向下拖动与 Android Back 还没有统一的“只 dismiss 一次”行为证据。完整详情当前保留 Preview 作为下层，首轮“源 Hero 被先移除”的理由不成立；实际飞行仍需运行时检查。Reduced 下 CourseHero 直接返回 child，避免建立 Hero 节点。

## I. Glass / Rendering Findings

| 阶段 | 本轮核查 |
| --- | --- |
| Build | 父页状态/流变化会重算 agenda；pager 的逐帧 offset 不调用父页 setState |
| Layout | 10/12 节均分可用高度，14 节使用滚动下限；Sheet 内容、键盘和窗口变化可改变目标尺寸 |
| Paint | CourseBlock 按压重建渐变与阴影；局部 GlassPainter 在 press/touch 变化时重绘 |
| Compositing | Root 分数 opacity 期间两页同时参与绘制；0/1 有 Flutter 快路径；raster cache 命中未知 |
| Backdrop sampling | Preview 有 1 个全屏 filter；GlassSurface 的 filter 位于各自 ClipRRect 内，属于局部区域 |

全项目 `BackdropFilter` 源码点是 2 处。典型静止 Weekly **约 8 个实例**：顶部 2、周导航外层 1 + 箭头 2、星期栏 1、FAB 1、Switcher 1。普通课程 Preview 再加全屏 1、面板 1、操作按钮 3，合计约 **13 个实例**；菜单展开等状态会改变数量。空间重叠是局部的：周导航箭头与父层、Sheet 按钮与面板；Preview 全屏层覆盖背景。13 是组件数，不能当成同一像素的 13 次模糊。未见 `BackdropGroup`/`BackdropKey`。每像素实际 overdraw、raster cache 与帧耗时均 UNVERIFIED。

`RepaintBoundary` 不能单独证明网格被每帧重录。BackdropFilter 因背后图像变化重新采样，也不等价于 Widget rebuild、RenderObject layout 或内容 paint。首轮把这些阶段合并成一条确定因果链，应撤回。`RenderOpacity` 0/1 快路径已用本机 Flutter 3.47.2 源码核对；分数透明度的具体 saveLayer/raster 开销仍需 profile 数据。

## J. Data Logic Spot Check

既有测试覆盖周一锚点、学期前后、跨周/跨月、空周、单双周解析、课程教学周过滤、停课/调休、冲突簇、同节多课、跨多个 section，以及 10/12/14 节布局。`SemesterService` 将日期裁成本地午夜后使用 `DateTime.add(Duration(days: ...))` 和 `difference.inDays`；在采用夏令时的设备时区，固定 24 小时加法可能不是日历日加法，周日期与当前周算法缺 DST 测试。当前设备时区下的问题未复现，标 INFERRED。Today 与 Weekly 都用本地时间，未见直接 UTC/local 混用证据。

## K. Accessibility / Reduced Motion

Root 非活动分支组合 `Offstage`、`TickerMode`、`ExcludeFocus`、`ExcludeSemantics`、`IgnorePointer` 与 `HeroMode`；已有 360/390/430dp、1.3 字体、明暗和 Reduced Widget 测试。课程块按压仍会缩放；Weekly Sheet 的 Reduced 路径禁用拖动，但 X/背景入口仍存在。系统 Back 路径不随 Reduced 改变。TalkBack/VoiceOver 人工遍历 UNVERIFIED。

## L. Test Quality / Coverage Gaps

10 个随机测试文件既有纯算法/仓储测试，也有真实路由与 UI 行为断言，并非只检查 Widget 是否存在。主要缺口：第二学期导入相同课程、三段导入写入的失败回滚、历史学期日期选择器、Weekly Preview 系统 Back、Sheet 关闭中途反向/取消、课程流在 swipe 中发射、跨午夜和 DST。部分动画用固定 `pump(Duration)` 再 `pumpAndSettle` 验终点；它们不能替代 profile 帧耗时或 Hero 飞行视觉验收。

## M. Runtime Smoke Test

本轮 `adb devices -l` 无设备，无法执行要求的 Android profile 随机交互、Android Back、logcat 与可靠 frame timing。对快速滑周、慢拖、fling、Preview 多路径关闭、主题/Reduced 等设备交互均标 **UNVERIFIED**。测试运行未报 Flutter framework 异常，但测试结果不代表设备日志或真机性能。未把上轮模拟器快照冒充本轮复现。

## N. P0 / P1 / P2 / PERF-HYPOTHESIS

| 级别 | 本轮事项 |
| --- | --- |
| P0 | 跨学期导入 ID 冲突；导入多段写入缺整体事务；历史学期日期选择器断言；Weekly Preview Android Back 路径需设备确认 |
| P1 | Sheet 关闭动画中断后的回调竞态（待动态复现） |
| P2 | 设置页异步 WidgetRef；Today 旧课程快照；Weekly 跨午夜状态 |
| PERF-HYPOTHESIS | 全屏动态 blur、邻周首帧挂载、分数 opacity 两页绘制、网格重算和局部 filter 重叠；均无可靠帧耗时 |

## O. Is It Safe To Start Motion Refactor?

**YES, WITH PRECONDITIONS.** 先锁定导入数据一致性与 Preview 的系统 Back/关闭状态机，再改变过渡。首轮以静态机制宣称的性能 P0 缺逐帧证据；不要以该评级直接决定重构优先级。

## P. Preconditions Before Preview Refactor

1. 在 Android 设备上核对 Weekly Preview 的系统 Back，并明确关闭语义。
2. 用关闭中途再次拖动/点按验证只触发一次 dismiss，且不会清掉新交互状态。
3. 固定 Weekly Preview → Detail → Back 后 Preview 保留的当前合同，检查 Hero 的实际飞行。
4. 在尺寸、键盘/inset 或源课程位置变化时检查 sourceRect；性能目标用 profile UI/Raster 帧数据评估。

## Q. Recommended Next Task

**TASK-DATA-INTEGRITY-01：处理跨学期导入课程 ID 与导入确认的整体事务边界，并验证失败回滚。** 本报告只提出任务，不开始实现。
