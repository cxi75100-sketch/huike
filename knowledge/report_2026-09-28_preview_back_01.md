# 2026-09-28 Weekly Preview 返回拦截修复报告（TASK-PREVIEW-BACK-01）

## 1. Root Cause

- Weekly Preview 是 `TimetablePage` 内的 `GlassSheetHost`，不是 Navigator route。原代码没有 Preview 专用 Back 处理；审计据此推断 Android Back 可能绕过 Sheet。本轮修复前未在设备上动态复现“退出根页”，因此不把该结果写成已证实事实。
- 背景点击与下拖调用 Host 的关闭动画，完成后回调 `_closeSheet`；X 和编辑直接调用父页 `_closeSheet`，立刻移除 child 并让 Host 把进度设为 0。清理入口分散，退出表现不一致。
- 原 `whenCompleteOrCancel` 在动画正常结束或被取消时都会运行回调；下次拖动会 `progress.stop()`。这是回调竞态的代码条件，先前未有动态故障复现，不能宣称已观察到重复回调。

## 2. Fix

- `TimetablePage` 用 `PopScope` 在 Preview 存在期间拦截 Back，调用统一的 `_requestSheetDismiss`；关闭中后续 Back 同样被消费。
- X、背景、下拖、编辑和程序化 `close()` 都进入 `GlassSheetHost` 的单次关闭流程。父页只在 Host 的 `onDismissed` 中清空 `_sheet`、恢复底部切换器；编辑路由在关闭完成后进入。
- Host 的 `_dismissing` / `_dismissed` 防止重复关闭和重复回调；关闭中忽略新拖动。退出动画使用 `TickerFuture.then`，仅正常完成才清理；dispose 或取消不会误报完成。Reduced Motion 同步完成，但走相同的一次性状态保护。

## 3. State Machine

```text
open → dismissing → dismissed → parent clear
```

首次关闭请求才进入 `dismissing`；期间重复关闭和拖动安全忽略。完成回调每次展示只运行一次；父页清理后再次打开会开始新的周期。短拖未达到阈值时回弹到 `open`，不进入关闭状态。

## 4. Close Paths

| Path | Result |
| --- | --- |
| Android Back | `PopScope` 消费，向 Host 请求 dismiss；关闭中仍消费，不 pop 根页 |
| X | 调用统一请求，完成退出动画后清理 |
| Backdrop | Host 直接进入同一关闭状态机 |
| Drag | 超过原速度/位置阈值则关闭；短拖按原逻辑回弹 |
| Programmatic dismiss | `GlassSheetHostState.close()` 幂等；编辑入口等关闭完成后导航 |

「完整详情」仍按原行为只 push 详情，保留 Preview 作为返回目标。

## 5. Files Changed

| 文件 | 目的 |
| --- | --- |
| `lib/core/glass/glass_sheet.dart` | 单次关闭状态、完成回调与取消语义 |
| `lib/features/timetable/pages/timetable_page.dart` | Back 拦截、统一关闭请求及唯一清理点 |
| `test/preview_dismiss_test.dart` | 9 个真实路由与 Sheet Widget 回归 |
| `knowledge/current_state.md`、`knowledge/tasks.md`、`knowledge/testing.md`、`knowledge/changelog.md` | 同步当前状态、验证及任务记录 |
| `knowledge/framework_motion.md`、`knowledge/framework_navigation.md`、`knowledge/framework_index.md` | 更新 Preview / Back 合同和已修事项；索引中同步此前已完成的导入及校历修复 |
| `knowledge/report_2026-09-28_preview_back_01.md` | 本报告 |

开工时工作区已有导入、校历、审计和其他知识库改动，均保留；本轮未 reset、clean、commit 或 push。

## 6. Tests

- 基线：`flutter analyze --no-pub` 无问题，`flutter test --no-pub` **295/295**。
- 新增 9 例：Back 关闭后根页保留、关闭后子路由原 Back 行为、双 Back、X 后 Back、编辑先关再导航、背景与程序化关闭交叉、下拖和短拖回弹、Reduced Motion 重复关闭、关闭后重开新周期。
- 定向 **9/9**，全量 **304/304** 通过；两种关闭源、双 Back 与重新打开均无重复回调或 Flutter 异常。

## 7. Validation

| 检查 | 结果 |
| --- | --- |
| `flutter analyze --no-pub` | 通过，无问题 |
| `flutter test --no-pub` | 304/304 通过 |
| `flutter build apk --debug --no-pub` | 本轮未运行；用户要求这批任务结束后统一构建一次 |
| `git diff --check` | 通过 |

Flutter 命令在 `S:\` 执行。

## 8. Unverified

Android 真机 predictive back、iOS 返回手势及极端高速并发触摸均为 `UNVERIFIED`；Widget 测试不等同设备验收。未做性能 profile。

## 9. Scope

未修改 Preview geometry / layout、Hero、Weekly swipe 架构、Today Preview、模糊或性能策略、JS Adapter / Bridge / NavigationPolicy、Drift schema、Android signing 或 package dependencies。未开始 Preview geometry reconstruction、Motion 优化或 Today Preview 修复。
