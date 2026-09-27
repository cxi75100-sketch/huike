# TASK-020B — Today / Weekly Floating Liquid Glass Switcher

2026-09-27。仅本次悬浮一级切换范围；保留开工前大量未提交工作，无commit/push/reset/clean/restore。

## 结构与交互

1. 原结构：Weekly是`/`，顶部Today按钮push`/today`，Today返回按钮回Weekly；并非两个保留一级分支。
2. 新接线：两条原路径成为StatefulShellRoute分支，默认Weekly；自定义保留容器持续挂载两个Navigator。其它子路由和Preview transition原文保留。
3. Weekly Today summary在此前同号任务已移除，本轮确认仍无；仅删除重复的顶部Today按钮，没有重新设计Header。
4. 一个capsule实例使用Transform沿左右cell移动。宽130dp/高52dp/圆角26dp固定，neutral tint与shadow固定，因此无背景替换或几何突变。图标文字颜色随同一progress插值。
5. capsule与页面共同使用GlassMotion.slow=280ms、GlassMotion.enter=easeOutCubic。页面opacity互补、位移GlassMetrics.pageTravel=12dp；无root横向手势、无stagger。快速反向从当前位置继续。
6. Reduced Motion直接设进度到目标；opacity到最终状态、translation为0，仍能正常切换；复用MediaQuery.disableAnimations，无第二套flag。
7. Today/Weekly StatefulWidget及分支Navigator保持挂载；共享既有ProviderContainer，没有切tab重建provider或重新加载loading。第一次预加载会构建两个页面，已有数据provider复用，未声称启动耗时经过benchmark。
8. Weekly选中非当前周后返回保留；widget测试第5周、Android QA第2周。Today同一个State/ScrollPosition回到原offset；Today横向drag不切root，Weeklydrag仍只切周。
9. 动画每帧仅paint包装/capsule/text颜色更新，AnimatedBuilder child保持；测试18帧内Weekly page build少于4次（允许导航状态更新），无每帧DB读或grid重新布局机制。非活动分支禁input/focus/semantics/ticker/Hero。Today既有30秒状态timer保持原逻辑。
10. 外层栏272×64dp、bottom=viewPadding+16dp；FAB在原bottom基础只lift80dp。Weekly viewport/row height不变；不修既有FAB课程遮挡。Today只给外层SafeArea滚动底部余量，Timeline内部原文不变。

## 文件

11. 本轮源码：新增`lib/features/timetable/widgets/timetable_root_shell.dart`；修改`lib/core/router/app_router.dart`、`lib/features/timetable/pages/timetable_page.dart`、`lib/features/timetable/pages/today_page.dart`、`lib/features/timetable/widgets/timetable_header.dart`。共五个源码文件。知识库同步current_state/tasks/README/architecture/design/testing/changelog及本报告。
12. 新增`test/root_switcher_test.dart`十五例；修改`test/week_agenda_ui_test.dart`底部入口/跨分支Hero断言、`test/today_timeline_test.dart`移除root返回按钮后的Surface数量。覆盖可见root选中、active静默、周/scroll retention、child back、inline/route Preview隐藏、透明Preview下theme/inset重建、haptic、反向连续、无逐帧page build。

## 验证与边界

13. 开工git status/diff stat已执行；基线268/268。最终283/283全部通过。12例矩阵覆盖360/390/430、Light/Dark、Reduced、font1.3和bottom inset24/48dp；课程滚动/Preview测试用font1.0以隔离既有grid测试字体约束。
14. `flutter analyze --no-pub`：No issues found。最终使用S盘映射执行，修复新增测试的unused/unnecessary imports后重跑。
15. `flutter build apk --debug --no-pub`成功，最终APK为`build/app/outputs/flutter-apk/app-debug.apk`，已安装API36模拟器。
16. `git diff --check`通过；仅现有LF/CRLF提示，无whitespace错误。禁止范围开工哈希69文件，收尾Changed=0。
17. Android API36 emulator-5554，1080×2400、density443约390dp、gesture navigation：Light/Dark两root已看；录制两个双向切换视频，15fps抽capsule与8fps抽全页。看见连续左右移动/文字颜色同步及小位移淡入，未观察黑白闪、突跳、长时间双页完整叠加；FAB不与栏重叠，栏高于gesture area。Weekly第1→2周→Today→Weekly仍第2周。首次QA截黑屏来自模拟器熄屏，唤醒后重新验；早期即时截图可能捕获动画中间帧，另取settled画面确认。拼帧末尾黑块为tile空位，不是应用帧。
18. 未改Course Block/tint/grid/分页/resolver/冲突、TodayTimeline内部、Preview实现/transition/dismiss、Import/WebView/adapter/bridge/NavigationPolicy、DB/model、App Icon、signing/dependencies。保护hash零变化，并审查路由Preview片段及Today局部diff；普通页transition未改。已有历史未提交修改仍保留，不应把相对HEAD的全diff算成本轮改动。

临时QA证据位于`%TEMP%/huike-switcher-qa/`：light.mp4、dark.mp4、四root PNG、motion拼帧、返回周XML。设备使用原有合成QA学校空课，没有记录真实课程/账户数据；density已恢复物理420，night恢复no。Android真机、iOS、3-button实机、真实非空课程设备、GPU帧耗时均UNVERIFIED。Widget inset覆盖不替代这些设备验证。代码审查通过，透明Preview重建回归也通过。

本轮完成并停止；不开始Semantic Timeline、全局Motion Audit或Preview Transition。
