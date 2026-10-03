# 2026-09-28 全 App 动画 / 过渡现状审计报告（TASK-MOTION-AUDIT-01）

日期：2026-09-28 +08:00
基线：master `7bc4f10`，开工与收尾时工作区均干净
范围：**纯审查**。不改代码、不改测试、不改资源、不改配置、不格式化、不重构、不新增 package、不 commit、不 push。
验证：`flutter analyze --no-pub` 无问题（`S:\` 下 58.7s）；`flutter test --no-pub` **283/283**；Android 模拟器 profile 模式只读运行一次。
未验证：真机、iOS、GPU 逐帧耗时（见 §11）。

事实标记：`CONFIRMED` 有代码或运行证据；`INFERRED` 由代码推断未实测；`UNVERIFIED` 未验证。

## ⚠️ 更正声明（2026-09-28 第二阶段复核后加入）

同日第二阶段只读复核（TASK-AUDIT-02，见 `report_2026-09-28_adversarial_random_audit.md`）逐条核验了本报告的结论，判定 **5 条 `INCORRECT`、6 条 `PARTIALLY CONFIRMED`**。**本文件保留当初原样作为历史记录；凡与第二阶段冲突处以后者为准**，并已在 `framework_index.md`、`framework_motion.md`、`framework_glass.md`、`framework_navigation.md` 等框架报告中回填。

**已撤回 / 更正的结论：**

| 本报告原说法 | 更正 | 位置 |
| --- | --- | --- |
| 静止 Weekly 6 层玻璃、Preview 约 11 层 | 实际约 **8** / **13**（漏计周导航岛的两个箭头按钮，它们默认 `regular` 也带滤镜） | §3、§8 |
| 「3 处嵌套 BackdropFilter，含 ClipRRect」 | `ClipRRect` 包住单个滤镜**不是**嵌套（那只是裁剪成本）；真正的嵌套含周导航外层 + 两箭头 | §8 |
| 「整页单一 RepaintBoundary → 逐帧重录两周 / 全部玻璃重算模糊」 | 因果链不成立，降级为 **PERF-HYPOTHESIS** | §4、§8 |
| 「Android 上 MaterialPage 就是 Material 默认 zoom」 | 本机 Flutter 3.47.2 的 Android 默认是 `PredictiveBackPageTransitionsBuilder`，普通导航回退 **FadeForwards**，不是 zoom | §7 |
| 「点『完整详情』先关闭 Preview，导致 Hero 源同帧消失」 | `onDetails` **不**关闭 Preview（`timetable_page.dart:204-209`），该推断撤回 | §6 |
| 「从 `+N` 冲突列表选课沿用陈旧 `sourceRect`」（P2-10） | 打开冲突列表时 rect 已清空，选课得到 null rect | §13 |
| 「Root 两整页 opacity 一直产生两个 saveLayer」 | 端点 0/1 走 `RenderOpacity` 快路径，只有分数 opacity 期间两页参与绘制 | §5 |
| 两个性能项定为 P0-1 / P0-2 | 无可靠逐帧耗时 → 改列 **PERF-HYPOTHESIS**，不得据此决定重构优先级 | §13 |

**保留下来的结论**（第二阶段判定 `CONFIRMED`）：路由过渡不一致、Reduced Motion 缺口（课块仍缩放）、Sheet 关闭路径不一致、Root switcher 状态保留、启动状态连续性（真机部分仍 `UNVERIFIED`）。

---

## 1. Executive Summary

1. `CONFIRMED` **这不是一个「没有动画体系」的项目。** 三层结构已存在：令牌层 `lib/core/glass/glass_motion.dart`（9 个时长 + 3 条曲线 + 4 条弹簧）、物理层 `lib/core/glass/press_physics.dart`（全 App 唯一一份指针代码）、路由层 `lib/core/glass/glass_page.dart` + `glass_transition.dart`。切周、Sheet、弹层、一级切换、按压都接在真实控制器上。
2. `CONFIRMED` **全项目只有 2 处 `BackdropFilter` 源码点**（`glass_surface.dart:197`、`glass_sheet.dart:176`），但通过 `GlassSurface` 被 22 个文件、32 处调用点实例化。Weekly 静止时同屏 **6 层模糊**（顶部两个图标 16、周导航 18、星期栏 12、加课按钮 20、底部切换器 10）。
3. `CONFIRMED` **最重的性能点在课程预览的打开过程**：`glass_sheet.dart:176-189` 在全屏 `BackdropFilter` 上**逐帧改写 blur sigma（0→14）**，同时 `:168-171` 对整个课表做 `Transform.scale`，Sheet 内部再叠 1 层 22 + 3 个按钮各 16（**嵌套 BackdropFilter**）。此刻同屏玻璃层数从 6 涨到约 11。
4. `CONFIRMED` **预览的「从课程块飞出来」几何是错的，并已实测复现**：`glass_sheet.dart:229` 把 Sheet 高度硬编码为 `size.height * 0.5`。模拟器实测该预览 Sheet 实际高 **908px（346dp）**，代码假设 1200px（457dp），误差 **292px ≈ 111dp**。中间帧显示面板在**被点课程块下方约 500px** 出现并向下方扩张，不是从块长出来。「Preview 打开不够自然」的第一原因是飞行起点错了，不是时长或曲线。
5. `CONFIRMED` **Sheet 的关闭路径不对称**：背景点按、向下拖 → 弹簧动画退出；点 X 按钮 /「完整详情」/「编辑」 → `timetable_page.dart:229` 直接 `_sheet = null`，`glass_sheet.dart:85-87` 执行 `progress.value = 0`，**没有退出动画，瞬间消失**。
6. `CONFIRMED` **Weekly 拖动的第一帧要挂载一整周网格**：`week_swipe.dart:306-313` 静止时不渲染相邻周，`offset != 0` 的**第一帧**才第一次挂载邻居网格（build + layout + 逐块文字测量）。这是「起手发粘」最具体的候选原因。
7. `CONFIRMED` 整个 Weekly 页在同一个 `RepaintBoundary` 里（`timetable_root_shell.dart:152`），因此拖动时网格位移会**逐帧让重叠其上的 3–4 层玻璃重新执行模糊**，并重新录制 2 整周网格的画面（约 50 个课程块的渐变 + 边框 + 两层阴影）。
8. `CONFIRMED` 一次周切换提交后，`timetable_page.dart:97-120` 会在**落位后的那一帧**重算 3 周议程、重建 3 个网格，并对每个课程块重跑 `TextPainter` 测量（`timetable_course_block.dart:216-230`）。抖动最可能出现在「松手刚停住」的瞬间。
9. `CONFIRMED` 路由动画有三种方言同时存在：`GlassTransition`（12dp + fade，280/180ms）、Today 预览的 `FadeTransition + SlideTransition(0, 0.14)`（≈120dp，`app_router.dart:121`）、以及 `/course/:id`（预览→详情）用的 **`MaterialPage`（Android 上即 Material 默认 zoom）**（`app_router.dart:186`）。`/onboarding`、`/import/web`、`/import/preview` 与两个 Shell 分支走 GoRouter 默认页，同样未接 GlassTransition。
10. `CONFIRMED` 事实性缺口：`GlassMotion.emphasized`、`GlassMotion.flicksPast()`、`GlassMotion.simulation()`、`GlassMetrics.edgeWidth` 定义但全项目无调用；`GlassSheetHost` 控制器的 `duration: GlassMotion.slow` 因全程 `animateWith` 而实际不生效；课程块与 `+N` 冲突签的按压缩放**没有接 Reduced Motion**（`timetable_course_block.dart:102`、`:329`）。

---

## 2. Animation Architecture

### 2.1 审计基线

| 项目 | 结果 |
| --- | --- |
| `git status` / `git diff --stat` | 工作区干净，无未提交修改（与任务描述中「大量未提交修改」不符；`current_state.md:11-12` 记载 2026-09-27 已归档推送，与此一致） |
| `flutter analyze --no-pub` | 中文路径下 LSP 异常退出；映射 `S:` 后 `No issues found! (ran in 58.7s)` |
| `flutter test --no-pub` | 283/283 通过 |
| 规模 | `lib/` 80 个 Dart 文件、17,522 行 |

### 2.2 体系分层

**令牌层 —— `lib/core/glass/glass_motion.dart`**

- 时长：`fast` 110ms、`reducedHero`/`reduced` 90ms、`standard` 180ms、`slow`/`pageEnter` 280ms、`menu` 220ms、`weekLabel` 260ms、`todayPulse` 460ms、`touchFollow` 90ms、`pageExit`=standard、`dialog`=standard、`snackEnter`=standard、`snackExit`=fast。
- 曲线：`enter`=easeOutCubic、`exit`=easeInCubic、`emphasized`=easeOutQuart（**未使用**）。
- 弹簧：`releaseSpring`(520/34)、`sheetSpring`(300/35)、`weekSpring`(340/37)、`returnSpring`(420/36)。
- `simulation()`、`flicksPast()` 为死代码；两个真实调用点各自直接 `new SpringSimulation(...)`（`glass_sheet.dart:104`、`week_swipe.dart:216`），速度比较也各自内联（`glass_sheet.dart:125-127`、`week_swipe.dart:74`）。

**物理层 —— `press_physics.dart`**：全 App 唯一指针实现。两个控制器（`_press` 110ms、`_follow` 90ms），`pressDriver` / `touchDriver` 允许外部进度接管（Sheet 拖动、切周高光、周导航）。`Listenable.merge` + `child:` 保证按压期间只重排外壳、不重建子树（`:168-178`）。

**材质层 —— `glass_surface.dart`**：五层结构；`RepaintBoundary` 自包裹；`_maybeBlur()` 在 sigma ≤ 0 时完全不建滤镜层（`:195-201`）；`shouldRepaint` 比较 8 个字段。

**路由层 —— `glass_page.dart` / `glass_transition.dart`**：`GlassTransition` 只做 `Opacity` + `Transform.translate`，用 `CurvedAnimation` 的 `reverseCurve` 与 `clamp(0,1)` 处理中途反向；有测试断言「中途反向保持 geometry 连续」且「内容不随帧重建」（`test/motion_audit_test.dart:112-175`）。iOS 走 `_GlassNativeRoute extends MaterialPageRoute` 以保留原生边缘返回手势。

**Reduced Motion**：接入面很广——路由、`GlassTransition`、`PressPhysics`、`GlassSurface`、`GlassSheetHost`（开/拖/落位/飞行全判）、`WeekSwipePager`（不位移，只按阈值提交）、根切换器、加课菜单、周标签、今日脉冲、启动 reveal、Snackbar 时长、Dialog、学期 Sheet、Hero（退化普通 child）、详情页元信息淡入、`GlassTextField`。判定统一走 `MediaQuery.disableAnimationsOf`，口径正确。

**State / 保留**：`StatefulShellRoute` + `RetainedTimetablePages`（`timetable_root_shell.dart:132-192`）让两个分支常驻，用 `Offstage` + `TickerMode` + `ExcludeFocus` + `ExcludeSemantics` + `IgnorePointer` + `Opacity` + `Transform.translate` 控制可见性。**`RenderOffstage` 在 offstage 时仍以同一 constraints 布局 child**（已核对 Flutter 源码 `rendering/proxy_box.dart`），因此切 tab 不会让 Weekly 网格重新计算节高。测试断言切换后 `TimetablePage`/`TodayPage` 的 State 为同一实例、第 5 周保持（`test/root_switcher_test.dart:209-214`）。

---

## 3. Animation Inventory

| 场景 | 文件 | 实现 | Duration | Curve | GlassMotion | Reduced | 动画对象 | 风险 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 冷启动 reveal | `launch_reveal.dart:19-73` | 1×AnimationController + CurvedAnimation | 180ms | enter | ✅ standard/enter | ✅ 直达 1 | transform + 全 App opacity | 中：全屏 Opacity = 首帧 saveLayer |
| Native splash → 首帧 | `app.dart:41-77`、`main.dart:10-23`、`android/.../launch_colors.xml` | deferFirstFrame + 主题解析 + 一次性 reveal | — | — | ✅ | ✅ | 颜色连续性 | 低：底色 `#F5F6F9`/`#111319` 与 `AppPalette.background` 完全一致 |
| 一级切换胶囊 | `timetable_root_shell.dart:51-81, 205-254` | animateTo + `Transform.translate(cell*progress)` | 280ms | enter | ✅ slow/enter | ✅ 直接赋值 | transform | 低-中：位置动画（非 crossfade），但每帧重建 2 图标+2 文字的 Color.lerp |
| 一级切换页面 | `timetable_root_shell.dart:148-188` | Opacity crossfade + `Transform.translate(12dp)` + Offstage | 280ms | enter | ✅ slow/enter | ✅ 位移归 0 | opacity + transform + layout(Offstage) | 中-高：两页同时绘制；整页 Opacity=saveLayer |
| 切周 拖动跟手 | `week_swipe.dart:233-244, 302-330` | 直接写 controller.value，1:1 | 手势 | — | — | ✅ 不位移 | transform | 高：首帧挂载整周；逐帧重录 2 周 |
| 切周 落位 | `week_swipe.dart:200-218, 246-268` | SpringSimulation | 弹簧 | — | ✅ week/return Spring | ✅ 立即提交 | transform | 中：完成后父级 setState 重算 3 周 |
| 切周 箭头 | `week_navigation.dart:105-155` → `week_swipe.dart:191-198` | 同一 pager，velocity=0 | 弹簧 | — | ✅ weekSpring | ✅ | transform | 中：与手势共用过渡（设计正确），同样触发邻居挂载 |
| 周次标签换字 | `week_navigation.dart:181-295` | 2 份文本 crossfade + 14dp | 260ms | 硬写 easeOutCubic | 部分（仅时长） | ✅ 直达 1 | transform + opacity | 低；14dp 为魔数 |
| 周导航玻璃高光 | `week_navigation.dart:47-83, 94-100` | pressDriver/touchDriver 驱动 GlassSurface | 跟随手势 | — | — | 间接 | paint + transform | 中：拖动时该玻璃模糊因背景位移重算 |
| 今日脉冲 | `weekday_header.dart:37-40, 64-69, 189-195` | `Transform.scale(1+0.11·sin(πt))` | 460ms | sin | ✅ todayPulse | ✅ 提前 return | transform | 低 |
| 按压物理（全部玻璃控件） | `press_physics.dart:70-78, 134-164` | 110ms 进 + releaseSpring 出 | 110ms/弹簧 | enter | ✅ | ✅ 不缩放 | transform + paint | 低；每个交互面 2 个 ticker |
| 课程块按压 | `timetable_course_block.dart:93-162` | 复用 PressPhysics，scale 0.024 | 110ms/弹簧 | enter | ✅（经 PressPhysics） | ❌ **未接** | transform + paint（渐变/边框/2 阴影逐帧重算） | 中：无 RepaintBoundary |
| `+N` 冲突签按压 | `timetable_course_block.dart:301-356` | scale 0.04 | 110ms/弹簧 | enter | ✅ | ❌ **未接** | transform + paint | 低 |
| 加课菜单展开 | `liquid_add_button.dart:31-58, 81-123` | CurvedAnimation + SizeTransition + FadeTransition + Offstage | 220 开 / 180 收 | enter/exit | ✅ menu/standard | ✅ 直接赋值 | layout（SizeTransition）+ opacity | 中：逐帧 layout；菜单玻璃模糊区逐帧变形 |
| FAB 滚动淡出 | `liquid_add_button.dart:69-76` | AnimatedOpacity | 110ms | enter | ✅ fast | ✅ Duration.zero | opacity | 低 |
| Sheet 打开 | `glass_sheet.dart:96-105, 158-259` | sheetSpring + sigma 0→14 + dim 0→0.16 + bg scale→0.982 + 圆角 26→20 | 弹簧 | — | ✅ sheetSpring | ✅ 直达 | transform + blur + opacity + clip | 最高（见 §8） |
| Sheet 拖拽关闭 | `glass_sheet.dart:110-133` | progress -= delta/sheetHeight，clamp | 手势 | — | — | ✅ 禁用 | transform | 中：`_sheetHeight` 首帧回退到 0.5×屏高 |
| Sheet 退出（点背景/拖） | `glass_sheet.dart:135-153` | sheetSpring → onDismissed | 弹簧 | — | ✅ | ✅ | transform + blur + opacity | 中 |
| Sheet 退出（X/详情/编辑） | `timetable_page.dart:227-231` + `glass_sheet.dart:85-87` | `progress.value = 0` 瞬切 | 0 | — | ❌ | — | 无 | 高：无退出动画（P0-3） |
| Today 课程预览 | `app_router.dart:93-129` | CustomTransitionPage + Hero | 180/180ms | easeOutCubic/easeInCubic | ❌ 硬写 | ✅ 90ms | opacity + transform(0.14) + Hero flight | 中-高：位移远大于 12dp 语言；Hero 与滑入叠加 |
| 课程详情（从预览进入） | `app_router.dart:186` | `MaterialPage` | 平台默认 | 平台默认 | ❌ | ✅ 分支 | 平台默认（Android=zoom） | 中-高：唯一完全绕过 Glass 的页面路径 |
| 普通路由（import/course new/settings*） | `glass_page.dart:8-27` + `glass_transition.dart` | CustomTransitionPage + GlassTransition | 280 进 / 180 退 | enter/exit | ✅ | ✅ 90ms 无位移 | opacity + transform(12dp) | 低（有测试保证不重建内容） |
| Shell 分支与 `/onboarding`、`/import/web`、`/import/preview` | `app_router.dart:76-92, 130-150` | GoRouter `builder` → 平台默认页 | 平台默认 | 平台默认 | ❌ | 平台 | 平台 | 中：Material 默认动画混入 |
| Dialog | `glass_dialog.dart:13-60` | DialogRoute 子类 + GlassTransition | 180/180ms | enter/exit | ✅ dialog/standard | ✅ 90ms | opacity + transform(8dp) | 低 |
| 学期进度 Sheet | `week_navigation.dart:298-321` | showModalBottomSheet + AnimationStyle | 280/180ms | enter/exit | 部分 | ✅ noAnimation | 平台 BottomSheet | 中：与 GlassSheetHost 并列的第二套 Sheet 机制 |
| Snackbar | `glass_transition.dart:80-86` | glassSnackBarStyle | 180/110ms | Material 默认 | 部分 | ✅ 0 | opacity + transform | 中：仅 school_manage、course_edit 使用 |
| 详情页元信息淡入 | `course_detail_page.dart:153-165` | FadeTransition + Interval(0.25,1) | 随路由 | 硬写 easeOut | ❌ | ✅ | opacity | 低 |
| 主题明暗切换 | `app.dart:47-49` | Material AnimatedTheme | 200ms（kThemeAnimationDuration） | Material | ❌ | — | 颜色 | 中：AppPalette 不是 ThemeExtension，paletteOf 只看 brightness → 自定义颜色瞬时跳变 |
| 表单聚焦描边 | `glass_form.dart:61-70` | AnimatedContainer | 110ms | enter | ✅ fast | ✅ 0 | paint | 低 |
| 日期/时间选择器、PopupMenu | `semester_settings_page.dart:176`、`bell_settings_page.dart:128,134`、`onboarding_page.dart:251`、`calendar_exception_page.dart:101,317`、`school_manage_page.dart:86` | Material 默认 | 平台 | 平台 | ❌ | 平台 | 平台 | 中：与 Glass 语言无关 |
| Loading / Empty / Error | `timetable_grid.dart:113-117, 482-592` | 无动画，直接替换 | — | — | ❌ | — | — | 中：状态切换是硬切；loading 用无限 CircularProgressIndicator |

---

## 4. Weekly Swipe Deep Dive

### 4.1 状态流程（`week_swipe.dart`）

```
onHorizontalDragDown    :220-224  资格在 pointer down 锁定：_gestureAccepted = (_target == null && !_offset.isAnimating)
onHorizontalDragStart   :226-231  仅当已接受：_dragActive = true，_dragPixels = 0，state.dragging = true
onHorizontalDragUpdate  :233-244  _dragPixels += delta；next = clamp(_offset.value + delta/width, -1, 1)
                                  越界方向直接 return（不橡皮筋）；_offset.value = next → 通知 → state.offset = next
onPointerCancel         :290-294  先于 drag recognizer 的 end 消费取消 → _handleDragCancel → _settle(0)
onHorizontalDragEnd     :246-268  先 consume（_dragActive=false, _gestureAccepted=false, dragging=false），
                                  再取 primaryVelocity → weekSwipeTarget(...) → 0 或 ±1 → _settle(target, velocity/width)
_settle                 :200-218  目标 0 → returnSpring；±1 → weekSpring；velocity 与拖动连续
AnimationStatus 监听     :163-178  收敛到 completed/dismissed → target==0 时显式归零 + state.reset()
                                  target≠0 → _finish(target)
_finish                 :180-185  先 _offset.value = 0 再 onCommit → 同帧等价交换，无闪
onCommit → _commitWeek  :244-251  setState(_weekOffset = target - base)；回本周时 _todayPulse.fire()
                                  并 HapticFeedback.selectionClick()
```

阈值：`weekSwipeTarget`（`week_swipe.dart:67-79`）——速度 ≥ **380px/s** 直接按方向提交；否则位置 ≥ **15% 页宽** 提交；都不够 → 回弹。

### 4.2 逐条回答

- **visual offset 与 week state 谁是 source of truth**：几何唯一权威是 `_offset`（AnimationController，范围 ±1.05，`:117-123`）。`WeekSwipeState.offset` 只是广播镜像（`:161`）。业务周次权威是 `_weekOffset`，**只在落位回调里改一次**。三者不冲突。
- **是否有两个 controller / 两份状态**：几何只有 1 个 controller；`WeekSwipeState` 是 ChangeNotifier 镜像，不是第二份权威。`WeekNavigation` 的 2 个 ValueNotifier（press/highlight）由 `_syncSwipe`（`:75-83`）单向派生。
- **drag 中是否会 rebuild 整个 timetable**：不会。`AnimatedBuilder` 只在 pager 内部（`:302-315`），父页不参与；`widget.page` 是上一次父级 build 留下的同一 Widget 实例，元素 diff 直接跳过其 build。
- **一次 drag 每帧做什么计算**：`_handleDragUpdate` 只有 1 次 clamp + 1 次赋值；`_offset.value = next` 触发 `_syncOffset`（`:161`）→ `state.offset = next` 通知 1 次（第 243 行 `widget.state.offset = next` 因 setter 的 0.0005 早退而**不产生第二次通知**，属冗余但无害）→ `WeekNavigation._syncSwipe` 写 2 个 ValueNotifier → `PressPhysics` 重建包装层 + `_GlassSurfacePainter` 重绘（在自己的 RepaintBoundary 内）。骨架侧：Stack + 2–3 个 Positioned.fill + Transform.translate 重建。
- **是否重复计算 conflict layout**：拖动帧不重算；`layoutCourseCollisions` 只在 `TimetableGrid.build`（`timetable_grid.dart:63-65`）里跑。
- **是否重新查询课程**：拖动帧不查。`coursesForProvider` 是 Drift `watch()` 流，只在 DB 变化时发射。
- **跟手比例**：1:1（`delta / _viewportWidth`，`:239`），到边界即停（`:240-241`），无橡皮筋、无比例失真。
- **松手后是否突然换 animation model**：会换，但连续。拖动是直接赋值，松手进入 SpringSimulation，初始速度由 `primaryVelocity / _viewportWidth` 传入（`:264, :267`）。真正的「换模型」在 `_finish`：先 `_offset.value = 0` 再把周的 Widget 换到 slot 0（`:180-185`）。同帧完成、新页面正是原先挂在 ±1 的那一个，画面等价。
- **箭头与手势是否同一套 transition**：是。箭头 → `WeekSwipeState.stepRequest` → `_step`（`:191-198`）→ 先取消手势资格，再 `_settle(±1, velocity: 0)` → 同一弹簧、同一条 `_finish` 路径。
- **是否可能「粘 / 突 / 卡」**：
  1. **起手粘**：`offset != 0` 的第一帧才第一次挂载邻居整周网格（`:306-313`）。这一帧要做该周 7 列 build + layout + 每个课程块的 TextPainter 测量 + 星期栏/轴标，属一次性重帧。
  2. **拖动中卡**：每帧重录 2 整周网格画面（约 50 个课程块，每块 3 段渐变 + 0.9dp 边框 + 2 层阴影 + 文本），并让与网格重叠的玻璃（星期栏 12、FAB 20、切换器 10）重新执行模糊。原因是整页只包一层 RepaintBoundary（`timetable_root_shell.dart:152`）。
  3. **落位一瞬卡**：`_finish` → `onCommit` → `TimetablePage.setState` → build 里对 3 周各跑一次 buildWeekAgenda + SectionCountResolver + layoutCourseCollisions，并重建 3 个 TimetableGrid（含全部课程块文字测量）。这一帧就在动画结束的下一帧。

---

## 5. Today / Weekly Switching

按真实代码审计：**Floating Liquid Glass Switcher 已实现**，不是需求假设。

- **实现**：`StatefulShellRoute`（`app_router.dart:64-92`）+ `TimetableRootShell`，分支默认 Weekly/`/`，Today 为 `/today`，两分支 `preload: true`。
- **active capsule 怎么动**：**位置动画，不是两个背景 crossfade**。索引映射为单一 AnimationController 数值域（`:51-55`，初值 = currentIndex），`_move()` 用 `animateTo(280ms, enter)`（`:70-81`），胶囊是 `Transform.translate(Offset(cell * progress, 0))`（`:251-254`）。宽度 `cell = (width - 12) / 2`，胶囊作为单一 RepaintBoundary 子树复用。模拟器实测：切换器内容区 199–881px、每格 341px（=130dp），progress=1 时胶囊正好落在第二格，与代码一致。
- **页面容器**：`RetainedTimetablePages`（`:132-192`），不是 IndexedStack、不是 route、不是 AnimatedSwitcher。两分支常驻同一 Stack，用 Offstage + Opacity + Transform.translate 控制。
- **是否保留页面 state**：保留。测试断言切换回来后 State 为同一实例（`test/root_switcher_test.dart:209-214`）。
- **Weekly 当前周是否保留**：保留，测试断言「第 5 周」在来回切换后仍显示（同文件 `:210`）。
- **Today scroll 是否保留**：元素常驻 + Offstage 以同一 constraints 布局，滚动位置由保留的 ScrollPosition 持有（测试 `:205-214`）。
- **tab 切换是否重新创建 Provider**：不会。两页 `ref.watch` 同一个 `coursesForProvider((schoolId, semesterId))`，同参数即同实例，不重查 DB。
- **capsule 与 page transition 是否同步**：同一个 controller，天然同步。
- **blur 是否参与每帧动画**：胶囊本身是位置动画（不重建模糊层）；但两分支在 crossfade 期间都 onstage 且都绘制 → 该 280ms 内 overdraw 翻倍。
- **是否可能发生 layout animation**：胶囊侧没有（纯 transform）。页面侧 Offstage 翻转触发 `markNeedsLayoutForSizedByParentChange()`，每次切换约 2 次子树 layout 标记；但不改变网格节高，不存在「页面突然 resize」。
- **风险点**：Opacity 作用在整页子树上（`:167-181`），迫使整页 saveLayer；两分支在过渡中都绘制。

---

## 6. Course Preview

Current 真实程度：**两套机制并存**。

### A. Weekly 预览（`GlassSheetHost`，`timetable_page.dart:160-189`）

- 原 Course Block **不参与 transition**。只提供全局坐标矩形：`TimetableCourseBlock._handleTap`（`timetable_course_block.dart:167-173`）用 `findRenderObject().localToGlobal` 取 rect → `_courseSourceRect` → 传给 `GlassSheetHost.sourceRect`。
- 初始 geometry 来自 `glass_sheet.dart:220-250`：`Transform.translate` + 非等比 `Transform.scale(alignment: topLeft)` 作用在**整块 Sheet（含其内部模糊）**上；`scaleX = source.width/screenWidth`，`scaleY = source.height/height`。
- **没有用 Hero**（Weekly 路径完全没用 Hero）。
- **geometry 缺陷（已实测复现）**：`glass_sheet.dart:229` 把 height 硬编码为 `size.height * 0.5`，而 Sheet 实际高度由内容决定。视口 914.3dp，假设高度 457dp；实测该预览 Sheet 高 **346dp**，误差 **111dp ≈ 292px**。数学上 t→0 时面板左上落在 `屏幕高 - Sheet高 + (source.top - 屏幕高/2) = 568.3 - 264.1 = 304.2dp`，而被点块在 **193dp** —— 面板起始位置比课程块**低 111dp**。中间帧显示面板出现在被点块下方约 500px、并继续向下移动，同时非等比缩放让文字明显纵向压扁。
- overlay / blur / dim：全屏 BackdropFilter（sigma 0→14）＋黑色 dim 0→0.16，与 progress 同一条弹簧曲线升起（`:172-189`）。**没有独立入场曲线，也没有错峰**：背景缩放、模糊、压暗、面板位移、圆角、边缘高光全部由同一个 progress 线性映射。
- content 与 container 是否同时动画：同时（同一 progress）。
- 是否存在 layout jump：飞行期间 `Positioned(left:0,right:0,bottom:0)` 盒子按最终内容尺寸布局，Sheet 内部无 layout 变化；非线性来自 transform。但 `sourceRect == null` 时走 `FractionalTranslation`（`:222-225`），是另一套几何。
- dismiss 怎么实现：背景点按（`:190-196`）、面板纵向拖动（`:203-211`）、X 按钮（→ **瞬切**）。三段行为三种结果。
- 附带（`INFERRED`，未运行时验证）：`onDetails` 先 `_closeSheet()` 再 push，「完整详情」的 Hero 源（预览内 CourseHeroSurface）会在同一帧从树上消失，共享元素飞行很可能退化为平台默认过渡。

### B. Today 预览（`/today/course/:id`，`today_page.dart:136-190` + `app_router.dart:93-129`）

- 是**路由**（CustomTransitionPage，`opaque: false`），不是 Sheet 宿主；底部对齐 `Align(bottomCenter)`。
- 过渡：FadeTransition + SlideTransition(begin: `Offset(0, 0.14)`) = 屏高 14%（≈120dp），easeOutCubic/easeInCubic，180/180ms。
- **有 Hero**：TodayTimeline 卡片与预览内 CourseHeroSurface 共享 tag（`today_timeline.dart:305-308`、`course_preview_sheet.dart:69-72`），两者都在 PageRoute 上，会真的产生共享元素飞行。
- overlay：静态 `Colors.black.withValues(alpha: 0.18)`（`today_page.dart:166`），**不参与动画**；没有全屏模糊。
- 无拖动关闭；关闭 = 点背景或 X（都 Navigator.pop）。

**结论**：同一个 `CoursePreviewSheet` 被两种不同宿主包裹，入场语言（飞行 vs Hero+滑入）、遮罩语言（动画模糊+压暗 vs 静态 dim）、关闭语言（弹簧 / 瞬切 / pop）都不一致。

---

## 7. Route Transitions

| 路由 | 页面类型 | 时长 | 语言 | 判定 |
| --- | --- | --- | --- | --- |
| `/`（Weekly）、`/today` | Shell 分支，builder → GoRouter 默认页 | 平台默认 | Material zoom（Android） | ⚠️ 非 Glass，但为一级页，进入即根 |
| `/import`、`/course/new`、`/event/new`、`/course/:id/edit`、`/settings`、`/settings/schools`、`/settings/semester`、`/settings/bell`、`/settings/calendar` | `_ordinaryRoute` → `glassPage` → CustomTransitionPage + GlassTransition | 280 进 / 180 退（reduced 90） | 12dp 上移 + fade | ✅ Apple-like，iOS 保留原生边缘返回 |
| `/course/:id`（带 CourseHeroSourceContext，即预览→完整详情） | **MaterialPage** | 平台默认 | **Android = Material zoom** | ❌ 明显 Flutter/Material 默认动画（`app_router.dart:186`） |
| `/course/:id`（直接进入，无 extra） | glassPage | 280/180 | 12dp + fade | ✅ |
| `/course/:id`（reduced） | CustomTransitionPage 纯 fade | 90ms | fade | ✅ |
| `/today/course/:id`（Today 预览） | CustomTransitionPage | 180/180（reduced 90） | fade + 14% 屏高滑入 | ⚠️ 位移量与本项目 8/12dp 语言差一个数量级 |
| `/onboarding` | builder → 平台默认页 | 平台默认 | Material zoom | ⚠️ 非 Glass |
| `/import/web`、`/import/preview` | builder → 平台默认页 | 平台默认 | Material zoom | ⚠️ 非 Glass |
| Dialog（全局） | DialogRoute 子类 | 180/180 | 8dp + fade | ✅ |
| 学期进度 | showModalBottomSheet + AnimationStyle | 280/180 | Material BottomSheet 自身滑动 | ⚠️ 第二套 Sheet 机制 |

**明确会出现 Material 默认动画的点**：`/course/:id`（hero 进入详情）、`/onboarding`、`/import/web`、`/import/preview`、两个 Shell 分支初次出现、showDatePicker、showTimePicker、PopupMenuButton、未使用 glassSnackBarStyle 的 4 个 SnackBar 调用点。
**已经符合 Apple-like 语言的**：全部 `_ordinaryRoute`、Dialog、Sheet、一级切换、Weekly 切周。

---

## 8. Glass / BackdropFilter Cost Audit

1. **全项目 BackdropFilter 源码点**：**2 处**——`glass_surface.dart:197`（GlassSurface 通用载体）与 `glass_sheet.dart:176`（Sheet 全屏遮罩）。`ImageFilter.blur` 也只在这两处。
2. **是否存在嵌套 BackdropFilter**：**是，至少 3 处**：
   - `glass_sheet.dart:332` 的 GlassSheetPanel（sigma 22）内含 GlassButton（默认 regular=16）×关闭按钮 +「完整详情」+「编辑」→ 面板 22 套 3 个 16。
   - `course_edit_page.dart:197` 底部操作栏（未传 blurSigma → prominent=22）内含 `GlassButton`（`:209`，默认 16）。
   - `glass_surface.dart:144` 的 ClipRRect 包住 BackdropFilter（`:146-147`），使每次模糊都要走一次圆角裁剪 + saveLayer。
3. **Weekly / Today 同屏玻璃层数**：Weekly 静止 **6 层**（顶部导入 16、设置 16、周导航 18、星期栏 12、FAB 20、底部切换器 subtle=10）；打开课程预览再叠 **全屏 14（动画中）+ 面板 22 + 3 个按钮 16 = 5 层**，合计约 **11 层**。Today 静止为 1 层（切换器 10），因为时间轴卡片刻意 `blurSigma: 0`（`today_timeline.dart:323`）——项目里最节省的一屏。
4. **Bottom bar / Preview / Dialog 出现时是否再叠全屏 blur**：**Preview 会**（`glass_sheet.dart:176`，全屏、含动画 sigma）；Dialog **不会**（`glass_dialog.dart` 只给面板 blur 22，背景靠 DialogRoute 默认 barrier 颜色）——这也是视觉不一致：Dialog 无玻璃遮罩，Preview 有。
5. **是否在动画过程中修改 blur sigma**：**是**（唯一一处）：`sigmaX/sigmaY = maxBlur * value`，maxBlur = 14，逐帧重建 ImageFilter（`:177-180`）。这是全局最贵的一行动画代码：每帧都是新滤镜 + 新 saveLayer + 对整屏的模糊采样。同一动画还叠加背景 `Transform.scale`（`:168-171`，无 RepaintBoundary 隔离）→ 被模糊的背景内容本身每帧都在变，模糊无法复用。
6. **是否大量使用 ClipRRect 包住 BackdropFilter**：全都包。所有模糊实例都经过 `glass_surface.dart:144-169` 的 `ClipRRect → BackdropFilter → CustomPaint` 结构。圆角正确，但每条玻璃 = 1 次 clip + 1 次 saveLayer。
7. **是否有本可以只动画 transform/opacity、却动了 fill/border/blur/layout 的地方**：
   - **布局**：加课菜单用 SizeTransition（`liquid_add_button.dart:116`）。
   - **模糊**：Sheet 全屏遮罩的 sigma。
   - **填充/边框**：课程块按压缩放时 BoxDecoration（3 段渐变 + 0.9dp 边框 + 2 层阴影）随 press 逐帧重建（`timetable_course_block.dart:105-157`），无 RepaintBoundary。
   - GlassSurface 按压时同时改 boxShadow 的 alpha/blurRadius/offset、渐变 alpha、边缘 alpha（`glass_surface.dart:130-158, 225-336`）——比纯 transform 贵，但有 RepaintBoundary 且面积小。
8. **是否存在 Glass Widget 自己 rebuild 导致 blur 子树每帧 rebuild**：基本没有。GlassSurface 用 Listenable.merge + `child:` 保留子树（`press_physics.dart:168-178`），`_FloatingSwitcher` 把胶囊放进 RepaintBoundary（`timetable_root_shell.dart:220`），课程块也把内容通过 `child:` 传入。唯一例外是 `_FloatingSwitcher` 的 builder 每帧重建 Row（2 个 Icon + 2 个 Text + Color.lerp，`:249-320`），但在 RepaintBoundary 之内，代价可控。
9. **是否可能形成 GPU overdraw / saveLayer 压力**：会，集中在三处：(a) 预览/Sheet 打开全过程（全屏动画模糊 + 背景缩放 + 11 层玻璃）；(b) Weekly 拖动时（网格位移迫使 3–4 层玻璃逐帧重算模糊 + 2 整周网格重录）；(c) 一级切换 crossfade 的 280ms（两整页同绘，整页 Opacity 各自 saveLayer）。

---

## 9. Rebuild / State Retention Audit

- **一级页面**：不重建（StatefulShellRoute + 常驻分支 + Offstage 同 constraints 布局）。Provider 不重建（同参数 family）。DB 不重查。这一块是强项。
- **Weekly 内部**：WeekSwipePager 用内部 AnimatedBuilder，拖动不触发页面 build（有测试保证，`test/motion_audit_test.dart:112-145`）。
- **但页面级 setState 的代价偏高**：`TimetablePage.build` 为 3 周各构造一个 TimetableGrid（`:106-120`），`TimetableGrid.build` 内含 SectionCountResolver.resolve + 7 × layoutCourseCollisions（`timetable_grid.dart:56-75`），所有课程块的 `_BlockBody` 会重新跑 TextPainter.layout（`timetable_course_block.dart:216-230`）。触发点：`_openSheet`、`_closeSheet`、`_commitWeek`，以及 coursesForProvider 的每次流发射。**没有缓存/记忆化**。
- **Offstage 的副作用**：翻转触发 `markNeedsLayoutForSizedByParentChange()`，但以相同 constraints 布局，故 sectionHeight 与滚动位置保持，不存在「页面切换时 resize」。
- **动画完成再改业务 state**：Weekly 是「先归零、同帧换页、再提交」（`week_swipe.dart:180-185`），没有二次跳变；但提交帧与重算帧重合（见 §4.2）。
- **动画期间 setState**：PressPhysics 在 MouseRegion 的 enter/exit 上 setState（`:193-194`）——移动端不触发；桌面端悬停会重建 PressPhysics 外壳（子树仍保留）。
- **TodayPage 的 30s 定时器**（`today_page.dart:32-46`）：分钟变化时 setState 重建整页时间轴；跨天时还会 invalidate 两个 Provider。属「非动画驱动的周期重建」。
- `_DayNumber` 脉冲在 `_pulse.isAnimating` 时跳过重入（`weekday_header.dart:65`），不会叠加。

---

## 10. Startup Motion Audit

- **Native splash 与 Flutter 首帧**：`values/launch_colors.xml` = `#F5F6F9`、`values-night` = `#111319`，与 `AppPalette.background`（`app_palette.dart:34, 49`）**逐字节一致**；`values-v31` 与 `values-night-v31` 另设 `windowSplashScreenBackground`。`CONFIRMED`：不存在底色跳变。
- **首帧前是否出现 loading**：不出现。`main.dart:10-23` 用 `deferFirstFrame()`，等 `themePreferenceProvider.future` 完成后 `allowFirstFrame()`；LaunchReveal 在 ready 之前只画 AmbientBackdrop（`launch_reveal.dart:58-73`）。launchReadinessProvider 覆盖主题、学校、学期、作息、课程、校历，全部 settle 后才 reveal——不画临时的空默认值。设计意图正确。
- **代价**：首帧被一次 DB 读取（+ 若干 Provider）门控。模拟器 profile 实测 `Displayed … +1s894ms`。
- **首帧后布局突变**：`_themeSettled` 用 addPostFrameCallback 触发一次额外 setState（`app.dart:32-37`），只为把 themeAnimationDuration 从 0 切到 200ms；本身不改变布局。
- **system UI 设置时机**：`main.dart:19` 调 `SystemChrome.setEnabledSystemUIMode(edgeToEdge)` 但**未 await**，可能在首帧之后才生效；原生主题已用同色 windowBackground 覆盖，视觉影响有限。
- **首屏多动画同时启动**：只有 1 个（reveal），无并发。
- `CONFIRMED` 运行时观察（模拟器、profile、Impeller/OpenGLES）：启动日志出现 `I/Choreographer: Skipped 31 frames!`。**注意**：这是模拟器 + profile + 首帧引擎/管线预热的组合结果，**不能**当作真机结论。
- **reveal 的自身代价**：`Opacity(0.92→1)` 包住整个 App（`launch_reveal.dart:66-69`），在引擎最冷的 180ms 内迫使整屏 saveLayer。启动段唯一可优化的动画。

---

## 11. Runtime Profile

### 做过的（`CONFIRMED`）

- 环境：`ncpu_api36` AVD（1080×2400 @420dpi，`sdk_gphone64_x86_64`）。
- `flutter run --profile --no-pub` 成功：`Built app-profile.apk (32.2MB)`、`I/flutter: Using the Impeller rendering backend (OpenGLES)`。
- 启动：`Displayed … +1s894ms`；`I/Choreographer: Skipped 31 frames!`（仅模拟器）。
- UI Automator 实测布局（可作后续回归基线）：底部切换器内容区 199–881px、每格 341px（=130dp，与 `cell = (width-12)/2` 一致）；tab 高 44px 换算 52dp（`RootSwitcherLayout.height - 12`）；加课菜单项 489×126px = 186×48dp（与 `158 + 14×2` 一致）；课程块 136×182px = 51.8×69.3dp。
- 交互确认：箭头切周（第 2 周 → 第 6 周）工作、周次标签滑动而非跳变；加课菜单展开；新建课程后网格出现课程块；打开 Weekly 预览成功；背景模糊 + 压暗确实生效。
- **预览几何实测（本次最重的运行证据）**：Sheet 实际高 **908px ≈ 346dp**，代码假设 `size.height × 0.5 = 1200px ≈ 457dp`，误差 **292px ≈ 111dp**；中间帧显示面板起始位置在被点课程块**下方约 500px**、内容被非等比缩放压扁，随后向下方/终位移动。

### 没做成的（必须说明）

- **没有拿到可靠的逐帧 UI/Raster 帧耗时**：`adb shell dumpsys gfxinfo com.huike.huike_timetable` 返回 `Total frames rendered: 0`（Flutter/Impeller 不填充 HWUI 统计）；`adb shell dumpsys SurfaceFlinger --latency <SurfaceView layer>` 对所有候选层只返回刷新周期 16666666ns（60Hz）与空/零行。
- 因此：**未做运行时帧耗时 profile**。本报告的 jank 判断来自静态代码路径 + 现有测试约束 + 上述几何/启动实测；**没有**用 Debug 模式帧率当结论，也**没有**为测量改动任何源码。

### 审计过程中对环境（非仓库）的改动

- 建了 `subst S: "D:\桌面\汇课"`（`AGENTS.md` 推荐的既有做法，未删除）。
- 启动并随后**已关闭** AVD `ncpu_api36`（审计前无设备在运行）。
- 在模拟器 App 数据库新建了一门课 `AuditQA`（周一 1–2 节，第 1–16 周）用于打开预览；仅存在于模拟器应用数据，不属于仓库。

---

## 12. Motion Maturity Score

| 维度 | 分数 | 事实依据 |
| --- | --- | --- |
| Motion Token System | **3** | 令牌已集中且被 Sheet/Swipe/Press/Menu/RootSwitcher/Dialog/普通路由采用；但 `week_navigation.dart:221`、`app_router.dart:114-115`、`glass_sheet.dart:231`、`course_detail_page.dart:161` 硬写曲线；emphasized/flicksPast()/simulation()/GlassMetrics.edgeWidth 定义未用；大量魔数（0.024、0.04、0.018、14、0.16、0.14、900、380、0.15、14dp、12/16/18/20/22 五档 sigma）；`app.dart:47` 用框架常量 200ms |
| Route Transition | **3** | 普通路由与 Dialog 统一在 GlassTransition，iOS 保留原生手势；但 `/course/:id`（hero 路径）用 MaterialPage，`/onboarding`、`/import/web`、`/import/preview` 与两个 Shell 分支走 GoRouter 平台默认页，Today 预览另起一套 0.14 位移 + Hero |
| Gesture-driven Motion | **4** | 1:1 跟手、位置+速度双阈值、弹簧继承松手速度、down 时锁资格、cancel 正确处理、Reduced 只按阈值提交、箭头与手势共用过渡，并有 12 个 widget 行为测试；扣分：无过界橡皮筋、Sheet 拖动高度首帧回退到 0.5×屏高、Today 预览无拖动、起手首帧要挂载整周 |
| Glass Animation | **3** | 单一 PressPhysics + driver 复用、_maybeBlur 在 0 时彻底省掉滤镜、每块玻璃自带 RepaintBoundary、课程块刻意不模糊；扣分：全屏 sigma 逐帧动画、3 处嵌套模糊、ClipRRect 恒包 BackdropFilter、Dialog 无玻璃遮罩而 Preview 有 |
| State Retention | **4** | Shell 分支常驻、Offstage 保布局、TickerMode/焦点/语义/命中全部处理、Provider 与 DB 不重建、测试断言 State 与周次保留；扣分：过渡期间两页同绘、页面级 setState 缺记忆化 |
| Reduced Motion | **4** | 覆盖路由、GlassTransition、PressPhysics、GlassSurface、Sheet 全流程、切周、根切换、菜单、脉冲、reveal、Snackbar、Dialog、Hero、表单；但课程块与 `+N` 签的按压缩放未接（`timetable_course_block.dart:102`、`:329`），Reduced 下仍会瞬间缩小；日期/时间选择器与 PopupMenu 只能跟随框架 |
| Performance Awareness | **3** | 明确的性能约定且大多落地（单一模糊载体、child: 保子树、RepaintBoundary、paint-only 路由过渡、有「模糊只在导航与弹层、课程块不含 BackdropFilter」的测试）；扣分：整页单一边界导致拖动时全玻璃重算、3 周无缓存重算、逐块逐帧文字测量、动画模糊 sigma |
| Startup Continuity | **4** | 原生底色与 App 背景逐字节一致、12+ splash 也设了、首帧门控避免主题闪与空态闪、一次性 reveal、Reduced 直达；扣分：首帧被 DB 读取门控、edgeToEdge 未 await、reveal 用全屏 Opacity |
| Preview Transition | **2** | 有真实飞行与非等比缩放，但高度假设 50% 导致实测起点偏差 111dp；X/详情/编辑使退出无动画；Weekly 与 Today 两套宿主三套关闭语义；没有交互式反向飞行回课程块；入场时背景 scale + 模糊 + dim 与面板共用一条曲线 |
| Overall Motion Cohesion | **3** | 核心控件共享同一套节奏（110/180/280ms + 3 条弹簧）与唯一按压物理，手势与按钮走同一条过渡；但 Sheet（sheetSpring）、Today 预览（0.14 位移 + Hero）、`/course/:id`（Material zoom）、Material SnackBar/DatePicker/PopupMenu/BottomSheet 形成多条并行方言 |

---

## 13. P0 / P1 / P2 Issues

### P0 —— 明确可能造成实际 jank 或行为错误

**P0-1　Sheet 打开/关闭过程中逐帧改写全屏 blur sigma，并叠加背景缩放与嵌套模糊**
- 证据：`glass_sheet.dart:176-189`（`ImageFilter.blur(sigmaX: maxBlur * value)`，maxBlur=14，逐帧新建 filter）、`:168-171`（整页 Transform.scale，无 RepaintBoundary）、`:332`（面板 sigma 22 内含 3 个 16）、实测同屏玻璃层从 6 增至约 11。
- 位置：`lib/core/glass/glass_sheet.dart`
- 可能原因：把「背景模糊强度」当作可插值标量；被模糊的背景自身又在缩放，模糊结果无法复用。
- 外部研究：值得（Glassmorphism 在 Flutter 上的经典坑）。

**P0-2　Weekly 拖动起手要挂载整周、拖动中重录 2 周网格、落位帧重算 3 周**
- 证据：`week_swipe.dart:306-313`、`timetable_root_shell.dart:152`、`timetable_page.dart:97-120`、`timetable_grid.dart:63-65`、`timetable_course_block.dart:216-230`。
- 位置：`week_swipe.dart`、`timetable_root_shell.dart`、`timetable_page.dart`、`timetable_grid.dart`
- 可能原因：为省静止成本把邻居页做成「按需挂载」，代价落在起手帧；页面级 build 没有按周记忆化。
- 外部研究：值得（预挂载 / 保留邻居 / 可复用布局缓存）。

**P0-3　Sheet 的三条关闭路径语义不一致，其中两条完全没有退出动画**
- 证据：`timetable_page.dart:227-231` → `glass_sheet.dart:85-87`（`progress.value = 0` 瞬切）；而 `:190-196`（点背景）与 `:203-211`（拖动）走 `_settle` 弹簧。`CoursePreviewSheet` 的 X、「完整详情」、「编辑」都直接调 `_closeSheet`（`course_preview_sheet.dart:57-66`、`timetable_page.dart:200-209`）。
- 位置：`lib/features/timetable/pages/timetable_page.dart`、`lib/core/glass/glass_sheet.dart`
- 可能原因：`onDismissed` 被两用——既当「动画结束回调」又当「立即关闭命令」。
- 外部研究：中等（主要靠内部修）。

### P1 —— 明显影响「丝滑感」

- **P1-1　预览飞行的几何起点错误（实测偏差 111dp）** —— `glass_sheet.dart:229` 的 `size.height * 0.5` 假设。实测 Sheet 346dp vs 假设 457dp。表现：面板在被点课程块下方出现并向下扩张，非等比缩放压扁文字。这是「Preview 打开不自然」的第一原因。
- **P1-2　Today 预览与 Weekly 预览是两套心脏** —— `today_page.dart:136-190`（路由 + Hero + 0.14 屏高滑入 + 静态 dim）vs `glass_sheet.dart`（Sheet 宿主 + 自绘飞行 + 动画模糊 + 拖动）。同一份 CoursePreviewSheet，两种入场、两种遮罩、三种关闭。
- **P1-3　`/course/:id`（预览进详情）走 MaterialPage，Android 上是 Material 默认 zoom** —— `app_router.dart:186`。唯一完全绕过 Glass 语言的页面跳转，恰是用户从预览进入详情的主动作。
- **P1-4　一级切换期间两页同时绘制** —— `timetable_root_shell.dart:148-188`：整页 Opacity crossfade + Offstage 在 0/1 端才翻转，280ms 内两屏玻璃同时存在并各自 saveLayer。
- **P1-5　主题明暗切换只动一半** —— `app.dart:47-49` 交给 Material AnimatedTheme（200ms），但 AppPalette 不是 ThemeExtension，paletteOf 只读 brightness（`app_theme.dart:178-182`），所有自绘玻璃/环境底色瞬时跳变。
- **P1-6　素材性动画缺位** —— Loading / Empty / Error 三态在 `timetable_grid.dart:113-117` 直接替换，无任何过渡。

### P2 —— 视觉一致性 / polish

- **P2-1** 课块与 `+N` 签按压缩放未接 Reduced Motion（`timetable_course_block.dart:102`、`:329`）。
- **P2-2** SnackBar 动画风格只用在 2 处（`school_manage_page.dart:209, 219`、`course_edit_page.dart:260, 278`）；`import_entry_page.dart:212`、`import_preview_page.dart:437, 442`、`import_web_page.dart:240, 247`、`onboarding_page.dart:269, 277, 302, 306` 走 Material 默认。SnackBar 本身仍是 Material 组件而非玻璃。
- **P2-3** 魔数与令牌并存：`week_navigation.dart:235, 243` 的 14dp、`glass_sheet.dart:29-32` 的 0.018/14/0.16、`:229` 的 0.5、`week_swipe.dart:72-73` 的 0.15/380、`glass_sheet.dart:33` 的 0.72、`:34` 的 900、`timetable_course_block.dart:102` 的 0.024、`:329` 的 0.04。五档 blur sigma 未语义命名。
- **P2-4** `GlassMetrics.edgeWidth`、`GlassMotion.emphasized`、`GlassMotion.flicksPast()`、`GlassMotion.simulation()` 为死代码；`GlassSheetHost` 控制器 `duration: GlassMotion.slow` 从不生效。
- **P2-5** 两个 Sheet 机制并存：GlassSheetHost（自绘、有拖动与飞行）与 showModalBottomSheet + GlassSheetPanel（`week_navigation.dart:298-321`，Material 宿主，静态圆角）。后者打开时 `GlassSheetScope.progressOf` 为 null，面板固定用 `panel(1)`（`glass_sheet.dart:354`）。
- **P2-6** Dialog 没有玻璃遮罩，Preview 有全屏模糊+压暗——同为「层 5」两种遮罩语言。
- **P2-7** showDatePicker/showTimePicker/PopupMenuButton 与整体语言无关（4 处日期、2 处时间、2 处菜单）。
- **P2-8** 每个交互面持有 2 个 AnimationController；一周约 25 个课块 + 约 10 个玻璃控件 ≈ 70 个控制器 / 140 个 ticker（空闲不 tick，可接受但可合并）。
- **P2-9** FAB 滚动时只降到 0.82（`liquid_add_button.dart:71-76`），与「轻微后退」的设计意图不完全一致。
- **P2-10** 「从 `+N` 冲突列表选课」时会沿用上一次点课块留下的**陈旧 rect**（`timetable_page.dart:220-225` 只在非 `_CourseSheet` 时清空），该路径飞行起点错误。

---

## 14. GitHub Research Targets

> 关键词全部由本次审计的具体问题推导。

**① 玻璃与模糊的每帧成本（对应 P0-1、§8）**
- 问题：如何在动画期间不重算 BackdropFilter？能否用静态模糊快照替代动画中的实时模糊？动 sigma 与动 opacity/transform 的代价差多少？
- 关键词：`Flutter BackdropFilter performance glassmorphism overdraw`、`Flutter animate ImageFilter.blur sigma expensive`、`Flutter Impeller backdrop blur cost`、`Flutter saveLayer ClipRRect BackdropFilter`、`Flutter nested BackdropFilter glass`、`Flutter frozen backdrop blur snapshot animation`
- 想找到：把模糊层在动画开始前烘焙成一张图、动画中只改 opacity；或对 backdrop 区域降采样；或明确禁止动画中改 sigma 的工程约定（含 benchmark 数据）。

**② 从被点元素长出来的容器变换（对应 P1-1）**
- 问题：如何在不知道目标高度时，从源 rect 做正确的容器变换？官方 animations 包怎么做 OpenContainer？
- 关键词：`Flutter container transform OpenContainer animations package`、`Flutter Hero flightShuttleBuilder RectTween custom flight`、`Flutter shared element from grid item to bottom sheet`、`Flutter measure destination size before transition`
- 想找到：基于 RectTween + 目的尺寸实测（LayoutBuilder/GlobalKey 后测）而非固定比例的飞行；OpenContainer 的 closed/open builder 契约。

**③ 保留导航与同屏两页的切换（对应 P1-4、§5）**
- 关键词：`Flutter StatefulShellRoute retained branches`、`Flutter IndexedStack vs Offstage tab switch animation`、`Flutter animate between tabs without rebuilding page`、`Flutter PageView bottom navigation sync indicator`
- 想找到：go_router + StatefulShellRoute 的 crossfade 变体；用 FadeTransition 只包「即将离场」的一页；双页位移方案。

**④ 滑动胶囊指示器（对应 §5 可改进点）**
- 关键词：`Flutter animated tab indicator shared pill`、`Flutter segmented control animated capsule`、`Flutter tab indicator progress driven AnimationController`、`Flutter morphing indicator different label widths`
- 想找到：与 TabController 进度绑定的指示器；SegmentedButton 的选中形状动画；胶囊宽度随目标 label 尺寸插值的实现。

**⑤ 手势驱动翻页与松手落位（对应 §4）**
- 关键词：`Flutter PageScrollPhysics createBallisticSimulation velocity`、`Flutter custom page snapping spring AnimationController animateWith`、`Flutter drag to page transition threshold velocity`、`Flutter prebuild offscreen page during drag cacheExtent`、`Flutter overscroll rubber band custom physics`
- 想找到：ScrollPhysics 路线（PageView + 自定义 PageScrollPhysics，而不是手写 Transform）；相邻页 cacheExtent / 预挂载的实践。

**⑥ 手势期间的可达帧预算（对应 P0-2）**
- 关键词：`Flutter RepaintBoundary during transform animation`、`Flutter expensive build memoize layout computation`、`Flutter reduce TextPainter layout per frame`、`Flutter cache week layout precomputed`、`Flutter Impeller raster cache animated transform`
- 想找到：动画层与内容层分离（内容进 RepaintBoundary，动画只动外层）；TextPainter 结果或课程块布局缓存的模式。

**⑦ 模态 Sheet 的交互式关闭（对应 P0-3、P1-2）**
- 关键词：`Flutter interactive dismiss sheet reverse animation geometry`、`Flutter CupertinoSheetRoute`、`Flutter bottom sheet drag to dismiss spring`、`Flutter Hero reverse flight from modal sheet`
- 想找到：关闭时把几何交回源 rect 的反向飞行；DraggableScrollableSheet 之外的通用可控 Sheet；flutter/cupertino 的 sheet 实现。

**⑧ 主题过渡（对应 P1-5）**
- 关键词：`Flutter ThemeExtension lerp animated theme change`、`Flutter smooth dark mode transition custom colors`、`Flutter ThemeData lerp partial sub-themes`
- 想找到：把 AppPalette 改造成 ThemeExtension 并实现 lerp；或「禁用主题动画、改用一次性 crossfade 页面」的方案（尤其配合玻璃）。

**⑨ 启动连续性（对应 §10）**
- 关键词：`Flutter native splash to first frame continuity`、`Flutter deferFirstFrame splash`、`Flutter first frame jank Impeller warmup`、`Flutter shader warmup SkSL Impeller`
- 想找到：首帧前的预热策略；「首帧不做整屏 opacity」的启动 reveal 做法。

**⑩ Reduced Motion 的完整口径（对应 P2-1）**
- 关键词：`Flutter disableAnimations best practices`、`Flutter respect reduce motion custom widgets`、`Flutter semantics reduced motion test`
- 想找到：把「按压缩放」这类局部反馈统一在一个可被 Reduced 关闭的包装里，避免每个自绘组件各判一次。

---

## 15. Recommended Optimization Order

只给顺序与理由，不含实现。

1. **先修预览的关闭语义**（P0-3）：让 X /「完整详情」/「编辑」走与拖动同一条退出路径。面小、可感知度最高，且能让后续几何修复可被复测。
2. **再修预览飞行的几何起点**（P1-1）：把「假设高度」换成实测目的尺寸。与 1 同属一个文件，适合一次做完；完成后重复本次的中间帧对照法。
3. **把动画模糊从 Sheet 打开路径拿掉或冻结**（P0-1）：先测量「冻结 sigma / 只动 opacity」与现状差异，再定实现。这是全局唯一的动画 blur sigma，收益集中。
4. **降低 Weekly 拖动与落位的帧成本**（P0-2）：先做「起手帧预挂载邻居」与「周布局记忆化」这两项不需要动架构的改动，再评估是否为动画层加 RepaintBoundary。
5. **统一路由语言**（P1-3）：把 `/course/:id` 的 hero 路径从 MaterialPage 收到明确的 Glass 过渡（同时保住 iOS 原生返回手势与 Hero 飞行），并决定 `/onboarding`、`/import/web`、`/import/preview` 是否纳入。
6. **对齐两套预览与两个 Sheet 机制**（P1-2、P2-5）：决定「预览」是一种还是两种呈现；若保留两套，至少让位移量、遮罩与关闭手势一致。
7. **补素材性过渡**（P1-6）：Loading / Empty / Error 三态加过渡，并顺手统一 SnackBar 风格（P2-2）。
8. **主题过渡与 Reduced Motion 缺口**（P1-5、P2-1）。
9. **清理与命名**（P2-3、P2-4）：死令牌、魔数、五档 sigma 语义化。放最后，避免方案未定时先动令牌。

---

## 16. Files Relevant To Future Motion Work

**核心（必读，改动风险最高）**

1. `lib/core/glass/glass_motion.dart` —— 令牌与弹簧；决定整套节奏
2. `lib/core/glass/glass_sheet.dart` —— 全 App 最重的动画（飞行 + 动画模糊 + 拖动 + 关闭语义）
3. `lib/features/timetable/widgets/week_swipe.dart` —— 手势状态机与相邻页挂载策略
4. `lib/features/timetable/pages/timetable_page.dart` —— Sheet 开关、周提交、3 周议程构造点
5. `lib/features/timetable/widgets/timetable_root_shell.dart` —— 一级切换、保留分支、根切换器

**次核心（会直接影响手感或一致性）**

6. `lib/core/glass/glass_surface.dart` —— 五层玻璃与 BackdropFilter 唯一载体
7. `lib/core/glass/press_physics.dart` —— 全 App 唯一指针物理
8. `lib/core/router/app_router.dart` —— 路由动画方言的集中处
9. `lib/core/router/glass_page.dart` + `lib/core/glass/glass_transition.dart` —— 普通页与 overlay 过渡
10. `lib/features/timetable/widgets/timetable_grid.dart` —— 每周 build 的重算与文字测量入口

**外围（局部一致性）**

11. `lib/features/timetable/widgets/week_navigation.dart` —— 周标签换字、学期 Sheet、玻璃高光跟随
12. `lib/features/timetable/widgets/timetable_course_block.dart` —— 按压缩放与 Reduced Motion 缺口
13. `lib/features/timetable/widgets/liquid_add_button.dart` —— 唯一使用 SizeTransition（逐帧 layout）
14. `lib/features/timetable/pages/today_page.dart` —— Today 预览的第二套宿主
15. `lib/features/timetable/widgets/course_hero.dart` —— Hero 契约与 Reduced 退化
16. `lib/app.dart` + `lib/core/widgets/launch_reveal.dart` —— 启动 reveal 与主题动画时长
17. `test/motion_audit_test.dart`、`test/glass_interaction_test.dart`、`test/root_switcher_test.dart`、`test/week_agenda_ui_test.dart` —— 已有动效约束，改任何动画前先读，避免打破既有断言

---

## 17. 收尾核对与工具产物

```
git status                                   → nothing to commit, working tree clean
git diff --stat                              → (空)
git status --porcelain --untracked-files=all → (空)
```

本次审计**没有产生任何代码/测试/资源/配置修改**；仓库与开工时逐字节一致。唯一新增文件是本报告本身。

工具自动产生、需要报告的文件（均已被 `.gitignore` 覆盖，工作区仍为干净）：

- `flutter_01.log`（项目根，6.8KB）—— 第一次在中文路径下跑 `flutter test` 时 Flutter 工具崩溃自动写出；被 `.gitignore:3` 的 `*.log` 覆盖。
- `build/audit_*.png`（9 个）—— 本次审计的模拟器截图证据（预览中间帧、稳定帧、加课菜单、编辑页、Today 等）；被 `.gitignore:33` 的 `/build/` 覆盖。需要可保留，不需要可整体删除。
- `subst S:` 映射仍存在（`AGENTS.md` 推荐的既有做法）；AVD `ncpu_api36` 已在审计结束时关闭。
- 模拟器 App 数据中多了一门手工创建的课程 `AuditQA`（周一 1–2 节，第 1–16 周），仅存在于模拟器，不在仓库中。

## 18. 边界声明

- 本报告是**现状审计**，不含任何修复。§13 的问题全部保持未修状态。
- §15 只给顺序，不构成实施批准。
- 真机 / iOS / GPU 逐帧耗时仍未验证，相关条目一律标 `UNVERIFIED`；§11 的模拟器观测不得当作真机结论引用。
- 本报告不与其他课表项目产生任何归属或同步关系描述。
