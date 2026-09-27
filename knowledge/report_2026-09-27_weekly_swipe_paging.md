# TASK-020A — Weekly Timetable Swipe Paging

日期：2026-09-27 +08:00；保留既有未提交工作；无reset/clean/commit/push。

## 根因与证据边界

`CONFIRMED`：原实现drag start直接stop动画、清target并从现有offset继续；没有手势资格/消费门禁，允许新触摸接管尚未完成的落位。缺少cancel处理，Flutter水平drag recognizer取消pointer后可能调用end并用剩余位移提交。新增cancel行为测试在原实现失败：期望第4周，实际第5周。

`UNVERIFIED`：用户描述的单次高速/超长拖动连跳多周，没有在原实现widget测试中直接复现。原实现没有在drag update调用week step，也没有发现selectedWeek与page index双重修改；不把猜测作为已确认根因。此次用明确session约束消除重复消费与动画接管的可能路径。

## 实现

- `week_swipe.dart`：down锁定资格，target存在或controller动画中则整次忽略；start重置累计位移；end先consume再决定唯一0/±1目标。动画完成只走既有一次onCommit。
- pointer cancel仅取消参与拖动的第一pointer，回弹不提交；第二指取消不会干扰第一指。
- 原三页1:1跟手和±1页位移限制保持。未达条件弹簧回零；新手势只有在上次落位/回弹结束后开始才有效。
- 判据未改：松手速度绝对值≥380px/s取速度方向；否则最终可见位移绝对值≥15%页宽取位置方向；都不足为0。Reduced Motion用累计位移，原有不位移动效保持。
- controller listener把共享offset同步到弹簧进度；标题/网格唯一周次提交仍在同一onCommit/setState。日期栏位于同一网格页面，随网格一起移动；行为测试核对标题week和网格周一日期。
- 箭头沿用原step路径，每次正常点击±1；按钮接管正在拖动时使该拖动失效，避免松手另加一步。不更换PageView，不新增package，不做全局动画重构。

## 文件范围

代码：`lib/features/timetable/widgets/week_swipe.dart`。

测试：`test/week_agenda_ui_test.dart`。

知识库：`README.md`、`architecture.md`、`changelog.md`、`current_state.md`、`design.md`、`tasks.md`、`testing.md`及本报告。

用户全部禁止范围本轮未修改。开始时这些文件中部分已有改动；本轮保留，不将其归入TASK-020A。

## 行为回归

新增12例widget测试：普通左/右（2）、高velocity短fling左/右（2）、超长持续drag左/右（2）、阈值以下回弹再两次独立左滑（1）、动画中按下并跨动画完成持续长拖（1）、cancel及左右箭头（1）、动画中按下等落位后才移动并两次独立右滑（1）、Reduced Motion长拖/取消/独立手势（1）、第二指cancel不干扰第一指（1）。

核心断言为最终week和网格日期；长拖期间断言week不变，回弹后断言网格回到原位置。既有跟手/超拖回拉测试保持通过。源码复审无剩余发现。

## 验证

- 基线：git status / diff stat已读取；analyze无问题；全量217/217通过。
- 最终：`flutter analyze --no-pub`无问题；`flutter test --no-pub` **229/229通过**（217+12）；`flutter build apk --debug --no-pub`生产入口构建成功，产物 `build/app/outputs/flutter-apk/app-debug.apk`；`git diff --check`无空白错误。未跟踪代码/测试/报告另以no-index --check检查，无空白诊断，仅LF/CRLF提示。
- 本轮未安装或操作设备；模拟器真人滑动、真机与iOS为 `UNVERIFIED`。

任务完成后停止，不开始Today或全局Motion。
