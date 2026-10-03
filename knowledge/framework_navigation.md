# 框架报告 — 路由与页面层级

2026-10-03 TASK-RELEASE-100：导入页新增更换学校→`/settings/schools?import=1`；选择后返回导入页。管理页新增`/onboarding?add=1`，创建后pop(true)，若从导入进入管理则再回导入确认。异步返回检查route.isCurrent，避免旧route退出动画期间误退下层。首次启动仍不填学校。

2026-10-03 TASK-DEFER-SCHOOL-01：用户要求启动不填学校/网址。取消全局学校redirect及其refresh订阅；空库直接进入`/`，今日/整周均提供导入CTA。`/import`在学校读取完成且空库时显示OnboardingPage(forImport:true)，创建后由provider切换为导入确认，保留首页返回栈。原有档案与一级Shell保留；无虚构学校，无schema迁移。下文旧学校redirect描述为历史状态。

2026-10-02 TASK-ROOT-SWIPE-01：FloatingSwitcher由StatefulWidget维护局部drag会话，仅272×64控件内安装手势；左划选今日，右划选周课表，复用onSelect/goBranch；取消不切、区域外不切、点击仍可用，分支状态保持。预览打开控件仍隐藏。

2026-10-02 TASK-PREVIEW-RAPID-01：Weekly关闭期间仍由PopScope消耗Back；课程点击可中断关闭、重开新预览，编辑待导航不被替换。页面路由不变，正常完成关闭后恢复原Back。证据见report_2026-10-02_rapid_interaction.md。

## 2026-10-02 当前今日课程路径

TASK-TODAY-MOTION-COLOR-01：/today/course/:id仍是透明CustomTransitionPage，但路由transitionsBuilder直接返回child，只在页面内移动面板/改变遮罩色。Today来源课程详情复用glassPage（Android普通过渡/iOS原生可返回），revealMetadata=false且不挂Hero；Weekly来源继续原MaterialPage/Hero/Reduced合同。路线、学校redirect及返回目的地未变。

## 2026-10-01 启动错误

HuikeApp在数据库依赖读取错误时不创建或使用router，直接显示读取失败/重试；避免兼容迁移失败被hasSchool=false误当作新安装。正常redirect策略不变。Android MainActivity清单使用完整类名，使legacyUpgrade应用ID与Kotlin namespace不同时仍可启动。

## 2026-10-01 学校管理入口更新

按用户要求移除学校管理添加学校按钮及其push调用。切换、编辑地址、删除保留。初始化/onboarding仍保留，redirect未改。下方ISSUE-019机制为历史诊断，学校管理已无该UI触发路径；不宣称底层redirect修复。

## Last Updated

2026-10-03 +08:00 ｜ 启动建校改为主动导入时进行

证据来源：`report_2026-09-28_motion_audit_full.md` §5、§7、§9。

---

## 1. 边界

**负责**：路由表、页面类型与过渡方言、一级页保留策略、返回行为（Android 返回 / iOS 边缘手势）、页面层级（LEVEL 0–5）。

**不负责**：过渡的时长与曲线令牌（→ `framework_motion.md`）、面板材质（→ `framework_glass.md`）、层级的设计理由（→ `design.md`）。

---

## 2. 关键文件与入口

| 角色 | 文件 | 说明 |
| --- | --- | --- |
| 路由表（唯一） | `lib/core/router/app_router.dart` | GoRouter 实例、redirect、全部 16 条路由、`_ordinaryRoute` 助手 |
| 普通页方言 | `lib/core/router/glass_page.dart` | `glassPage()`：Android/桌面 `CustomTransitionPage` + `GlassTransition`；iOS `_GlassNativeRoute`（`MaterialPageRoute` 子类，保留原生返回手势） |
| 一级 Shell | `lib/features/timetable/widgets/timetable_root_shell.dart` | `TimetableRootShell`（胶囊 + 浮层）、`RetainedTimetablePages`（保留两分支） |
| navigatorKey | `app_router.dart:28-30` → `rootNavigatorKeyProvider` | **每个 ProviderContainer 独立**（测试多容器不能共用全局 key） |
| 层级约定 | `knowledge/design.md` | LEVEL 0 环境底色 → 1 网格 → 2 课程块 → 3 今日上下文 → 4 浮动玻璃 → 5 Sheet |
| 保留与手势测试 | `test/root_switcher_test.dart`、`test/motion_audit_test.dart` | 改动必须保持通过 |

---

## 3. 路由表（16 条）

`initialLocation: '/'`，`navigatorKey` 来自provider；无学校redirect/refreshListenable，空库与已建校均进入首页。主动`/import`在空库时显示建校表单，创建后原route切换内容；显式`/onboarding`完成回首页。历史ISSUE-019的强制redirect已取消，没有恢复学校管理添加按钮。

| # | 路径 | 页面 | Page 类型 | 过渡语言 |
| --- | --- | --- | --- | --- |
| 1 | `/today` | `TodayPage` | `StatefulShellBranch`(preload, branch 0) + `builder` | GoRouter 默认（平台默认过渡，见 §3 末更正） |
| 2 | `/` | `TimetablePage` | `StatefulShellBranch`(preload, branch 1) + `builder` | 同上；两分支由 Shell 自绘切换 |
| 3 | `/today/course/:id` | `TodayCoursePreviewPage` | `CustomTransitionPage`（`opaque: false`） | 路由identity；页内固定面板平移，无Hero |
| 4 | `/onboarding` | `OnboardingPage` | `builder`（读 query `add`） | 平台默认 |
| 5 | `/import` | `ImportEntryPage` | `_ordinaryRoute` → `glassPage` | 12dp + fade（280/180） |
| 6 | `/import/web` | `ImportWebPage` | `builder`（读 query `host`/`url`） | 平台默认 |
| 7 | `/import/preview` | `ImportPreviewPage` | `builder` | 平台默认 |
| 8 | `/course/new` | `CourseEditPage` | `_ordinaryRoute` | 12dp + fade |
| 9 | `/event/new` | `CourseEditPage(isEvent: true)` | `_ordinaryRoute` | 12dp + fade |
| 10 | `/course/:id` | `CourseDetailPage` | 无 extra/Today来源 → glassPage；Weekly来源Reduced → 短fade；Weekly普通 → MaterialPage | 今日普通页面/周预览Hero |
| 11 | `/course/:id/edit` | `CourseEditPage` | `_ordinaryRoute` | 12dp + fade |
| 12 | `/settings` | `SettingsPage` | `_ordinaryRoute` | 12dp + fade |
| 13 | `/settings/schools` | `SchoolManagePage` | `_ordinaryRoute` | 12dp + fade |
| 14 | `/settings/semester` | `SemesterSettingsPage` | `_ordinaryRoute` | 12dp + fade |
| 15 | `/settings/bell` | `BellSettingsPage` | `_ordinaryRoute` | 12dp + fade |
| 16 | `/settings/calendar` | `CalendarExceptionPage` | `_ordinaryRoute` | 12dp + fade |

**未使用**：`errorBuilder`、`NoTransitionPage`、`context.replace`、`context.pushReplacement`、`context.pop`（0 命中）。

### 过渡方言现状（三种并存）

| 方言 | 使用范围 | 事实 |
| --- | --- | --- |
| `GlassTransition`（12dp + fade） | 9 条 `_ordinaryRoute` + Dialog | `glass_transition.dart`；有测试保证「内容不随帧重建」「中途反向保持 geometry 连续」 |
| 页内固定面板平移 | 仅 `/today/course/:id` | 面板自身高度范围平移，遮罩留在原位，不对整屏淡入 |
| 平台默认（本机 Flutter 3.47.2 的 Android 默认 = `PredictiveBackPageTransitionsBuilder`，普通导航回退 **FadeForwards**；Windows/Linux 才是 Zoom） | `/course/:id`（hero 路径）、Shell 两分支、`/onboarding`、`/import/web`、`/import/preview` | **无全局 `pageTransitionsTheme`**（grep 0 命中），因此无法在此集中覆盖 |

> **已更正**（第二阶段复核 TASK-AUDIT-02 §C）：第一轮写「Android = Material 默认 zoom」不适用本机当前 Flutter 版本。本机 `material/page_transitions_theme.dart:766` 对 `TargetPlatform.android` 取 `PredictiveBackPageTransitionsBuilder()`，其非返回手势路径回退到 `FadeForwardsPageTransitionsBuilder`（`predictive_back_page_transitions_builder.dart:79-97`）。**具体默认过渡随 Flutter 版本变化**，升级 Flutter 后需重核。

**`/course/:id` 当前分支**：无extra或Today source走glassPage；Weekly source走MaterialPage，Reduced为短fade。Today和Weekly的iOS返回仍复用既有原生route合同。

---

## 4. 机制与约定

### 4.1 一级页保留（`RetainedTimetablePages`）

- 两个 `StatefulShellBranch`（`preload: true`）常驻同一 `Stack`；不是 `IndexedStack`、不是 route、不是 `AnimatedSwitcher`。
- 可见性由 `Offstage` + `Opacity` + `Transform.translate(12dp)` + `TickerMode` + `ExcludeFocus` + `ExcludeSemantics` + `IgnorePointer` 控制，全部由同一个 `progress` 驱动。
- `Offstage` 以**同一 constraints** 布局 child（已核对 Flutter `rendering/proxy_box.dart`），因此切 tab **不改变** Weekly 网格节高、不丢滚动位置。
- `HeroMode(enabled: i == index)`：只有当前分支参与 Hero 飞行。
- 切换入口：`navigationShell.goBranch(index)`（`timetable_root_shell.dart:86`），切换前发 `HapticFeedback.selectionClick()`。
- Provider 不重建（同参数 family 即同实例）；DB 不重查。

### 4.2 根级浮层的显隐

- 底部切换器只在 `/` 与 `/today` 显示：`Offstage(offstage: _previewVisible.value || (path != '/' && path != '/today'))`（`timetable_root_shell.dart:118-121`），路径来自 `GoRouter.of(context).routerDelegate`。
- `_previewVisible` 由页面在打开 Sheet 和关闭动画完成清理时置位（`timetable_page.dart`）；关闭动画期间保持 Preview 可见语义。
- 打开 Sheet 时切换器 `Offstage`，同时 FAB 上移 `RootSwitcherLayout.fabLift`（= 64 + 16 = 80dp，`timetable_root_shell.dart:14-18`）——**不改动网格 viewport**。

### 4.3 返回行为

| 场景 | 事实 |
| --- | --- |
| iOS 普通页 | `_GlassNativeRoute extends MaterialPageRoute` → 保留 Cupertino 交互式边缘返回；Reduced 时用 `CupertinoRouteTransitionMixin` 包一层 fade，**手势检测仍在**（`glass_page.dart:31-85`） |
| Android 返回 | Weekly 的 `TimetablePage` 已用 `PopScope` 消费页内 Preview 打开/关闭中的 Back；其它路由沿用既有 GoRouter 行为。`/today/course/:id` 仍是 `barrierDismissible: false`，靠自定义关闭入口 |
| iOS `/course/:id`（hero） | 走 `MaterialPage` → 原生 Cupertino 返回（有意的） |
| 一级页 | `router.canPop()` 为假（测试断言 `test/root_switcher_test.dart:157`）；Android 返回不会退出一级页 |
| **Weekly 内嵌 Preview（TASK-PREVIEW-BACK-01 已修）** | Preview 仍是页内 `GlassSheetHost`；打开或关闭中 `PopScope(canPop: false)` 消费 Back 并只请求一次 dismiss。关闭完成后恢复原路由 Back 行为。Widget 测试已验证根页保留；真机 predictive back 未验 |
| Weekly → Preview → Detail → Back | 点「完整详情」**不关闭** Preview（`timetable_page.dart:204-209`），Detail 是根 Navigator 页面；Back 返回后 Preview 仍打开 |

---

## 5. 唯一定义点

| 策略 | 唯一位置 |
| --- | --- |
| GoRouter 实例与全部路由 | `app_router.dart`（不得在别处 `GoRouter(...)`） |
| 普通页的 Page 构造 | `glass_page.dart` → `glassPage()` |
| navigatorKey | `app_router.dart:28-30` → `rootNavigatorKeyProvider` |
| 一级页保留容器 | `timetable_root_shell.dart` → `RetainedTimetablePages` |
| 一级页切换 | `timetable_root_shell.dart` → `_select()` → `goBranch` |
| 根浮层显隐条件 | `timetable_root_shell.dart:118-121` |

## 6. 改动时必须同步的位置

- 加/删/改路由 → 本文件 §3 表 + `framework_motion.md` §6（过渡方言）
- 新增 `_ordinaryRoute` 之外的 Page 类型 → 本文件 §3「过渡方言现状」表 + 说明是否保留 iOS 手势
- 改一级页容器 → 本文件 §4.1 + 跑 `test/root_switcher_test.dart`（含 State 同一性与周次保留断言）
- 改 FAB 避让距离 → `RootSwitcherLayout` + `timetable_page.dart` + `today_page.dart`（两处都读同一常量）
- 改根浮层显隐路径白名单 → `timetable_root_shell.dart:118-121` + 本文件 §4.2

---

## 7. 已知问题与技术债

- **历史P0，2026-10-01已撤除UI触发入口（ISSUE-019，`CONFIRMED`，2026-09-28 复现）**：有学校时点「添加学校」→ redirect 把 `push('/onboarding?add=1')` 改写成 `/` → go_router 的 push 合并追加**同一个 `StatefulShellRoute` 的副本**（`copyWith` 保留 `pageKey`，`match.dart:177/639/643`）→ 根 Navigator 出现两个同 key 的 Page → debug 红屏（`navigator.dart:4096`），release 下入口依旧不可达。机制、复现与已临时验证的修法见 `report_2026-09-28_add_school_entry_crash.md`。修法方向：redirect 放行 `add=1`。
- **P0-R 已修复（Widget）**：Weekly 页内 Preview 用 `PopScope` 拦截 Back；单次、双次及关闭中的 Back 不 pop 根页。真机 predictive back 仍待验证。
- **P1-3（已更正表述）**：`/course/:id`（预览→详情）用 `MaterialPage` → 走平台默认过渡（本机 Android 为 FadeForwards，非 zoom）。它仍是**唯一完全绕过 Glass 语言的页面跳转**，且是用户从预览进入详情的主动作。
- **P1-2**：Today 预览（路由 + Hero + 0.14 位移）与 Weekly 预览（Sheet 宿主）是两套机制、三种关闭语义。
- **P1-4（已更正）**：一级切换**分数 opacity 期间**两页同绘；端点 0/1 走 `RenderOpacity` 快路径，不应算两个分数层，实际 GPU 成本未测。
- **P1-6**：Loading / Empty / Error 三态在同一页内硬切，无过渡。
- **P2-U `CONFIRMED`**：Today 预览在 `courseByIdProvider` 返回 null 后仍回退展示 `initialCourse` 旧快照；无快照的无效 ID 一直显示进度环（`today_page.dart:148-156` vs `course_detail_page.dart:48-52` 的明确分支）。
- 平台默认过渡覆盖了 5 条路由；**没有全局 `pageTransitionsTheme`** 可用来集中改。
- **已撤回**：原「Weekly 预览的『完整详情』先 `_closeSheet()` 再 push，导致 Hero 源在同一帧消失」——`onDetails` 并不关闭 Preview（`timetable_page.dart:204-209`），Hero 飞行仍需运行时检查。

## 8. 未验证边界与前置条件

未验证边界：

- iOS 交互式边缘返回的实际表现：`UNVERIFIED`（无 iOS 设备）。
- 真机 Android 上平台默认过渡（FadeForwards）的观感：`UNVERIFIED`。
- `/course/:id` 的 Hero + `MaterialPage` 组合在 Android 上的实际飞行：`UNVERIFIED`（现有测试只查 tag 存在与相等，**不能证明跨 Navigator 的真实 Hero 飞行**）。
- Weekly 内嵌 Preview 的 Android Back 实际行为：`UNVERIFIED`（`P0-R`）。

**进入 Preview / 过渡重构前的设备前置条件**（来自第二阶段复核 §P）：

1. 在 Android 设备上核对 Weekly Preview 的系统 Back，并明确关闭语义（是否应拦截 Back 只关 Preview）。
2. 验证关闭中途再次拖动/点按时**只触发一次 dismiss**，且不会清掉新交互状态。
3. 固定「Weekly Preview → Detail → Back 后 Preview 保留」这一当前合同，并检查 Hero 的实际飞行。
4. 在尺寸 / 键盘 inset / 源课程位置变化时检查 `sourceRect` 的有效性。

---

## 9. 更新记录

| 日期 | 变更 | 依据 |
| --- | --- | --- |
| 2026-09-28 | 首次建立：16 条路由表、三种过渡方言、保留策略、返回行为 | TASK-MOTION-AUDIT-01 |
