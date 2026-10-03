# 框架报告 — 动效与过渡

## Last Updated

2026-10-02 +08:00 ｜ 今日状态、浅色品牌退场与局部根切换手势

TASK-LAUNCH-BRAND-01：启动品牌层复用slow280ms/enter，scale1→0.92、Y0→-12dp、alpha1→0；child原4dp平移且不透明，首触摸直接完成，Reduced无动画。不改全局token。TASK-ROOT-SWIPE-01：仅底部控件HorizontalDrag接受切分支，复用weekSwipeTarget的15%/380px/s判断，primary pointer cancel先消费、每手势最多一次onSelect；原点击/胶囊/页面过渡保持。

最新Weekly覆盖：关闭允许被新generation课程中断；箭头立即_finish切网格，label动画保留；新horizontal drag start消费旧pending目标、停止旧ticker后接受新手势。普通tap/vertical scroll仅down不会触发旧目标提前提交；cancel/边界/多指过滤保持。下方“落位期间忽略”记录为旧策略。

当前Today覆盖（TASK-TODAY-MOTION-COLOR-01）：透明预览路由transition identity，TodayCoursePreviewPage监听route.animation，以同一个GlassMotion.enter函数映射双向进度，仅移动终态尺寸面板与改变固定遮罩alpha；快速Back不切曲线、不跳变。Reduced直接落位。今日卡/预览/详情不挂Hero，详情复用glassPage并revealMetadata=false。下方早期Hero和0.14屏高Today相关审计为历史。

证据来源：`report_2026-09-28_motion_audit_full.md`（TASK-MOTION-AUDIT-01 全量审计，含 26 行清单表、实测数据与逐条证据）。本文件是**维护用手册**：改动画时看这里，需要证据链时看审计报告。

---

## 1. 边界

**负责**：全 App 的时长/曲线/弹簧令牌、指针按压物理、手势驱动的进度、页面与弹层的进入退出、Reduced Motion 接入。

**不负责**：材质数值与模糊成本（→ `framework_glass.md`）、路由表与页面类型（→ `framework_navigation.md`）、启动首帧门控（→ `framework_startup.md`）。

---

## 2. 关键文件与入口

| 角色 | 文件 | 说明 |
| --- | --- | --- |
| 令牌唯一来源 | `lib/core/glass/glass_motion.dart` | 时长、曲线、4 条弹簧 |
| 指针物理唯一实现 | `lib/core/glass/press_physics.dart` | 按下/移动/抬起；支持外部 `pressDriver`/`touchDriver` |
| 普通页与 overlay 过渡 | `lib/core/glass/glass_transition.dart` | `GlassTransition`（`Opacity` + 12dp `Transform.translate`）、`glassSnackBarStyle` |
| 普通页路由方言 | `lib/core/router/glass_page.dart` | `glassPage()`：Android/桌面 `CustomTransitionPage`，iOS `_GlassNativeRoute`（保留原生返回手势） |
| 弹窗 | `lib/core/glass/glass_dialog.dart` | `DialogRoute` 子类，只换绘制过渡 |
| Sheet 宿主 | `lib/core/glass/glass_sheet.dart` | 弹簧驱动位移 + 背景缩放/模糊/压暗 + 源矩形飞行 |
| 切周手势 | `lib/features/timetable/widgets/week_swipe.dart` | `WeekSwipeState` 广播 + `WeekSwipePager` 状态机 |
| 一级切换 | `lib/features/timetable/widgets/timetable_root_shell.dart` | 胶囊位置 + 两分支 crossfade |
| 菜单 | `lib/features/timetable/widgets/liquid_add_button.dart` | `SizeTransition` + `FadeTransition` |
| 今日脉冲 | `lib/features/timetable/widgets/weekday_header.dart` | 一次性 `sin` 起伏 |
| 周次标签换字 | `lib/features/timetable/widgets/week_navigation.dart` | 双文本 crossfade + 14dp |
| 启动 reveal | `lib/core/widgets/launch_reveal.dart` | 一次性 180ms / 4dp / 始终不透明 |
| 既有约束测试 | `test/motion_audit_test.dart`、`test/glass_interaction_test.dart`、`test/root_switcher_test.dart`、`test/week_agenda_ui_test.dart` | **改动画前先读**，避免打破既有断言 |

---

## 3. 令牌全表（`glass_motion.dart`）

| 令牌 | 值 | 当前使用者 |
| --- | --- | --- |
| `fast` | 110ms | `PressPhysics` 按压进入、FAB `AnimatedOpacity`、`GlassTextField` 描边 |
| `touchFollow` | 90ms | `PressPhysics` 高光跟随 |
| `reducedHero` / `reduced` | 90ms | 所有 Reduced Motion 路由与 Dialog |
| `standard` | 180ms | 启动 reveal、菜单收回、`pageExit`、`dialog`、`snackEnter` |
| `menu` | 220ms | 加课菜单展开 |
| `weekLabel` | 260ms | 周次标签换字 |
| `slow` / `pageEnter` | 280ms | 普通页进入、一级切换、学期 Sheet |
| `todayPulse` | 460ms | 今日选择器脉冲 |
| `snackExit` | 110ms | Snackbar 退出（仅 2 个调用点使用） |
| `enter` | `Curves.easeOutCubic` | 进入与多数正向过渡 |
| `exit` | `Curves.easeInCubic` | 退出与反向过渡 |
| `emphasized` | `Curves.easeOutQuart` | **无调用点** |
| `releaseSpring` | mass 1 / stiffness 520 / damping 34 | 按压抬起回位 |
| `sheetSpring` | 300 / 35 | Sheet 开合与拖动落位 |
| `weekSpring` | 340 / 37 | 切周提交 |
| `returnSpring` | 420 / 36 | 切周回弹 |

**无调用点**：`GlassMotion.emphasized`、`GlassMotion.flicksPast()`、`GlassMotion.simulation()`（两个弹簧调用点各自直接 `new SpringSimulation`：`glass_sheet.dart:104`、`week_swipe.dart:216`）。

---

## 4. 机制与约定

### 4.1 指针物理

- `PressPhysics` 是全 App 唯一指针代码，`press: 0→1` + `touch: Alignment` 两个通道。内部 2 个控制器（`_press` 110ms、`_follow` 90ms）。
- `Listenable.merge` + `child:` 保证按压期间**只重排外壳、不重建内容子树**（`press_physics.dart:168-178`）。
- 外部进度接管：`pressDriver` / `touchDriver` 非空时不接管指针。使用者：周导航玻璃高光（`week_navigation.dart:94-100`）。
- 不使用 `InkWell`/`InkSplash`；`splashFactory: NoSplash.splashFactory`（`app_theme.dart:39`）。

### 4.2 切周手势（`week_swipe.dart`）

```
drag down   → 锁定手势资格（动画中按下整次忽略）
drag start  → _dragActive = true
drag update → _offset.value += delta/width，clamp ±1，越界方向直接停（无橡皮筋）
pointer up  → 先 consume 会话，再按「速度 ≥380px/s 或位置 ≥15% 页宽」决定提交，弹簧继承松手速度
cancel      → 只回弹
落位完成    → 先 _offset.value = 0，再 onCommit 改业务周次（同帧等价交换，不闪）
```

- 几何唯一权威是 `AnimationController _offset`（范围 ±1.05）；`WeekSwipeState.offset` 是广播镜像，不是第二份权威。
- 业务周次唯一权威是 `TimetablePage._weekOffset`，**只在落位回调里改一次**。
- 箭头与手势**共用同一条过渡**（箭头 → `WeekSwipeState.stepRequest` → `_step` → 同一弹簧）。
- 相邻周**只在 `offset != 0` 时挂载**（`week_swipe.dart:306-313`）——省静止成本，代价落在起手帧。

### 4.3 Sheet（`glass_sheet.dart`）

- 当前Weekly不传sourceRect/sourceRectProvider，backgroundScale=0、maxBlur=0。单一progress驱动终态大小面板的FractionalTranslation、遮罩压暗及圆角；正文全程可见，不做课程块→面板的宽高重排与回缩空胶囊。
- GlassSheetHost的可选实测source/destination几何机制保留在通用组件和harness回归中，Weekly已不接线；不要误记为当前Weekly产品行为。其他调用方默认缩放/blur参数不变。
- 启动LaunchReveal去掉Opacity，保留一次性180ms/4dp平移和Reduced Motion直接落位。
- 拖动：`progress -= delta / sheetHeight`，clamp 0..1；几何插值直接使用原始 progress，因此拖动与短拖回弹连续跟手；高度取已布局 Sheet，尚不可用时取 Host Stack 高度；松手按 900px/s 或位置 0.72 判定。打开/关闭弹簧正常完成时将 `progress` 精确落在目标端点。
- **退出状态机（TASK-PREVIEW-BACK-01 保持）**：背景、下拖、X、Android Back 和编辑统一进入 `GlassSheetHost.close`；首次请求将状态从 open 置为 dismissing，弹簧正常完成后只调用一次 `onDismissed`，父页一次性清空 `_sheet`。Reduced Motion 同步完成。动画被取消不触发完成回调；拖动与重复关闭在 dismissing 期间被忽略。「完整详情」仍只 push，Preview 保留为下层。

### 4.4 一级切换（`timetable_root_shell.dart`）

- 索引映射为单一控制器的数值域，`animateTo(280ms, enter)`。
- 胶囊是**位置动画**（`Transform.translate(cell * progress)`），不是两个背景 crossfade。
- 页面用 `Offstage` + `Opacity` + `Transform.translate(12dp)`；`Offstage` 以同一 constraints 布局，**不改变网格节高**（已核对 Flutter `RenderOffstage`）。
- 两分支常驻，State/周次/滚动位置保留（有测试断言）。

### 4.5 Reduced Motion

统一判据 `MediaQuery.disableAnimationsOf(context)`。已接入：路由、`GlassTransition`、`PressPhysics`、`GlassSurface`、`GlassSheetHost`（开/拖/落位/飞行）、`WeekSwipePager`（不位移、只按阈值提交）、一级切换、加课菜单、周标签、今日脉冲、启动 reveal、Snackbar 时长、Dialog、学期 Sheet（`AnimationStyle.noAnimation`）、Hero（退化普通 child）、详情页元信息淡入、`GlassTextField`。

**未接入**：课程块按压缩放（`timetable_course_block.dart:102`）、`+N` 冲突签按压缩放（`:329`）；`showDatePicker`/`showTimePicker`/`PopupMenuButton` 只能跟随框架。

---

## 5. 唯一定义点（改这里才知道改哪里）

| 策略 | 唯一位置 |
| --- | --- |
| 所有时长/曲线/弹簧 | `glass_motion.dart` |
| 指针按压与高光物理 | `press_physics.dart` |
| 普通页与 overlay 的进入退出 | `glass_transition.dart` → `GlassTransition` |
| 普通页的 Page 类型与 iOS 手势保留 | `glass_page.dart` → `glassPage()` |
| Dialog 路由与时长 | `glass_dialog.dart` → `showGlassDialog()` |
| Snackbar 动画时长 | `glass_transition.dart` → `glassSnackBarStyle()` |
| 切周提交阈值 | `week_swipe.dart` → `weekSwipeTarget()`（0.15 / 380px/s） |
| Sheet 落位判定 | `glass_sheet.dart` → `_handleDragEnd`（0.72 / 900px/s） |
| Reduced Motion 判据 | `MediaQuery.disableAnimationsOf`（无第二套 flag） |

## 6. 绕过令牌或与令牌并存的位置（更新时重点盯）

| 位置 | 事实 |
| --- | --- |
| `week_navigation.dart:221` | 硬写 `Curves.easeOutCubic`（与 `GlassMotion.enter` 同值但绕过令牌），14dp 位移为魔数 |
| `TodayCoursePreviewPage` | 已改共用GlassMotion.enter映射route.animation；路由不再整层Slide/Fade |
| `course_detail_page.dart:161` | 硬写 `Interval(0.25, 1, Curves.easeOut)` |
| `glass_sheet.dart:29-34` | 魔数：backgroundScale 0.018、maxBlur 14、maxDim 0.16、closeThreshold 0.72、flickVelocity 900 |
| `liquid_add_button.dart:116` | 唯一使用 `SizeTransition`（逐帧 layout） |
| `app.dart:47-49` | 主题动画用框架常量 `kThemeAnimationDuration`（200ms），不属 GlassMotion |
| 4 个 Snackbar 调用点 | 未使用 `glassSnackBarStyle`：`import_entry_page.dart:212`、`import_preview_page.dart:437,442`、`import_web_page.dart:240,247`、`onboarding_page.dart:269,277,302,306` |

---

## 7. 已知问题与技术债

> **评级口径已更正**：第一轮把两个性能项定为 P0；第二阶段只读复核（`report_2026-09-28_adversarial_random_audit.md`，TASK-AUDIT-02）判定「无可靠逐帧耗时 → 不能列为 P0」，改列 **PERF-HYPOTHESIS**，并要求「不要以该评级直接决定重构优先级」。本表按更正后口径重排。

### P0（本轮确认的行为/数据问题，非性能）

- **P0-3 已修复**：X 与编辑现走同一退出动画；完整详情依旧保留 Preview，属于现有详情返回合同。单次关闭有 Widget 回归，真实设备仍未验。
- **P0-R 已修复（Widget）**：Weekly 内嵌 Preview 由 `PopScope` 消费 Back 并关闭；双 Back 与关闭中 Back 的根页保留已测。Android 真机 predictive back 仍待验（→ `framework_navigation.md` §4.3）。
- 数据层另有两个已确认 P0（跨学期导入主键冲突、导入多段写入无整体事务）→ `framework_import.md` §12、`framework_data.md` §8。

### P1

- **P1-S 已修复（Widget）**：关闭中忽略新拖动和重复关闭；退出动画由 `TickerFuture.then` 只在正常完成时回调，不再使用取消也回调的 `whenCompleteOrCancel`。极端真实设备手势仍待验。
- **P1-1 已修（Widget）** Weekly Preview 现在将实际 source/destination rect 变换到 Host-local 后插值；透明测量帧避免错误首帧，未对完整 Preview 做非等比缩放。两个 viewport、10 节与 14 节滚动 source、反向回程、source 失效 fallback 及 Reduced Motion 有 Widget 覆盖；设备实画尚未执行。
- **P1-2历史**：Today现保留独立路由关闭合同，但已去掉Hero/整路由0.14位移，改固定大小面板平移；Weekly仍是Sheet宿主。
- **P1-3（已更正表述）**：`/course/:id`（hero 路径）用 `MaterialPage` → 走平台默认过渡。本机 Flutter 3.47.2 的 Android 默认 builder 是 `PredictiveBackPageTransitionsBuilder`，普通导航回退 **FadeForwards**（**不是 zoom**），且随 Flutter 版本变化。
- **P1-4** 一级切换期间分数 opacity 下两页同绘（端点 0/1 走 `RenderOpacity` 快路径，**不应算两个分数层**）。
- **P1-5** 主题明暗只动一半（→ `framework_theme.md` §8）。
- **P1-6** Loading / Empty / Error 三态无过渡。
- **覆盖缺口**：`_viewportWidth` 在旋转/尺寸变化时的行为未测（`week_swipe.dart:280-284`）；阈值附近的速度/距离组合、拖动中课程流发射、跨午夜、DST 均未覆盖。

### PERF-HYPOTHESIS 与 profile 证据

- TASK-PERF-BLUR-01：API 36/60 Hz 模拟器分层对照后，仅 Weekly Preview 三个按钮取消
  嵌套 blur，父面板与 Sheet 保留。最终 open Raster 峰值 17.553–18.441 ms，仍超预算；
  UI 未超预算。没有运动/静止质量切换，不改变 progress、几何或 dismiss；
  明暗与实际 Reduced Motion 抽查通过，连续真机视觉未验证。详见 2026-10-01 专项报告。

- Preview open 的整组 blur 与模拟器 Raster 峰值存在重复 A/B 关联：启用时 34.9–37.2 ms，临时绕过 `GlassSurface` 与 Sheet blur 后 5.9–7.2 ms。此证据仅限 API 36 AVD；Sheet 遮罩和下层玻璃尚未分层归因（→ `framework_glass.md` §8、`report_2026-09-28_weekly_perf_profile_01.md`）
- Weekly 起手帧挂载相邻整周网格（`week_swipe.dart:302-313`，代码路径 `CONFIRMED`，**「因此起手卡顿」未实测**）
- 切周记录到超过 16.7 ms 的 UI/Raster 代表帧；慢帧频率、持续掉帧以及 cold/warm 因果仍未确认
- 落位帧重算三周 agenda 与网格（静止时邻页不在 pager 绘制树中，**三份计算 ≠ 三张网格都 layout/paint**）
- 分数 opacity 期间两页参与绘制
- 单页 `RepaintBoundary` 与逐帧重录的因果链（**已撤回**，见 §4.4 与复核 §I）

### P2

见审计报告 §13；其中 P2-1（课程块未接 Reduced Motion）、P2-4（死令牌）已在本文件 §3、§4.5 登记。**已撤回的 P2**：原 P2-10「冲突列表选课沿用陈旧 `sourceRect`」——打开冲突列表时 rect 已清空，随后选课得到 null rect。

---

## 8. 未验证边界

- 真机、iOS、release mode、14+ 节滚动与其它刷新率：`UNVERIFIED`。本次仅取得 Android API 36 模拟器 profile/DevTools 帧 timing；具体慢帧频率与独立 repaint 证据未取得。
- 模拟器上的 `Skipped 31 frames`（启动）与 Sheet 高度 346dp 实测仅代表模拟器 + profile，不得当作真机结论。

---

## 9. 更新记录

| 日期 | 变更 | 依据 |
| --- | --- | --- |
| 2026-10-01 | 同步分层 profile 与按钮局部 blur 优化；几何和状态机未变 | `report_2026-10-01_perf_blur_01.md` |
| 2026-09-28 | TASK-WEEKLY-PERF-PROFILE-01：补入切周代表帧、Preview blur A/B 与设备范围限制 | `report_2026-09-28_weekly_perf_profile_01.md` |
| 2026-09-28 | TASK-PREVIEW-GEOMETRY-01：以实际 RenderBox Rect 重建 Weekly Preview 容器几何，并保留 Back 状态机 | `report_2026-09-28_preview_geometry_01.md` |
| 2026-09-28 | 首次建立：令牌全表、唯一/绕过位置清单、问题索引 | TASK-MOTION-AUDIT-01 |
