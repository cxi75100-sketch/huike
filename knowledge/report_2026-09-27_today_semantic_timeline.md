# TASK-021 — Today Compact Semantic Timeline

日期：2026-09-27 +08:00；保留所有既有未提交工作；无commit/push/reset/clean。

## 原因与原算法

原 `lib/features/timetable/pages/today_page.dart` 的TodayPage使用固定 `rowHeight=164`，
课程top为 `(startSection-1)*rowHeight+2`，高度为
`max(66,(endSection-startSection+1)*rowHeight-4)`；整体高度取节次总数×164。
因此两节课约324dp、跨更多节继续增长，空课节也保留整行。并非真实分钟逐分钟计算，
而是节次线性映射，其效果同样造成巨大卡片和空白。旧当前时间线只在作息节次内出现。

## 新布局

`TodayTimeline`复用CourseTimeService取显式时间或学校作息/教室变体时间，按实际开始时间排序，
同时间依节次/id稳定排序。无有效时间的课程位于末尾，显示待定，不虚构精确时间。

保留连续左侧轨道、课程节点、开始/结束时间，右侧为Glass+tint课程内容，仍是时间轴。
课程高度与duration/节次跨度完全无关：最小134dp，以内容自然布局，名称最多两行，
时间/节次、状态、地点、教师、周次、备注全部保留；地点/教师/备注最多两行、周次一行。
长文本视觉省略时，完整原文仍在语义标签和既有Preview/Detail中。

普通卡目标134–180dp；当前普通样例在1.3字体下≤200dp。
90分钟与6小时、同内容的卡片高度测试相同；丰富名称/备注样例自然增高，
360dp/1.3测试≤290dp。不是机械固定所有课程高度，也不将真实duration转回像素；
有限行预算限制增长，超出测试字体范围时仍优先文字可读性，不宣称所有字体下硬性290dp上限。

课间：≤10分钟16dp、≤60分钟24dp、更大间隔40dp且显示实际间隔时长。
重叠课程用此前所有课程的最晚结束时间算空档，避免嵌套重叠造成虚假空白。
原30sp日期标题收至22sp并收紧垂直padding；没有改全局Navigation或页面transition。

## 当前时间

- 课程期间：单个当前时间标记关联第一个进行中课程的左轴节点，显示现在HH:mm，卡内状态进行中。
  同时重叠的其它课程仍分别正确显示状态，避免重复时间线。
- 课间：40dp状态带置于已结束课程与下一课之间，标注课间。
- 首课之前：首部状态带尚未开始；末课之后：尾部状态带今日课程已结束。
- 空Today或全部时间未知不伪造时间标记；停课/学期外不显示当前时间轴。
- 时间范围为[start,end)，精确结束时归课间/课后。不是精确分钟Y坐标，上课期间的标记位置不随分钟线性移动。
- TodayPage每30秒检查时间，分钟变化更新状态；跨日刷新今日providers，dispose取消timer。

## 行为与范围

点击仍 `context.push('/today/course/${course.id}',extra:course)`，CourseHero来源保持Today。
TodayCoursePreviewPage整段原文在整文件生成时保留并断言一致；router、Preview transition/dismiss不改。

开工保存整个lib源码SHA256快照，结束比较唯一既有代码改动为TodayPage，新增TodayTimeline。
所有Weekly代码、Weekly swipe/Course Block、Android Back、Import/数据库/App icon/全局页面transition
保持开工时内容；没有新增package或全App Motion改动。

## 文件

- 修改 `lib/features/timetable/pages/today_page.dart`。
- 新增 `lib/features/timetable/widgets/today_timeline.dart`。
- 新增 `test/today_timeline_test.dart`。
- 同步知识库README/current_state/tasks/architecture/design/testing/changelog及本报告。

## 验证

开始git status/diff stat已读取，analyze无问题，基线232/232。

新增20例widget行为测试：90min与长时长独立高度、内容增高/字段完整、实际时间排序/短长空档，
上课中/课间/精确结束/课前/课后，空/单课/未知时间/Glass tint与点击、嵌套重叠，
360/390/430dp×1.0/1.3字体×Light/Dark十二例真实TodayPage首屏密度与无overflow。
每个密度组合都断言前两门完整、第三门至少50dp可见；典型390dp渲染实际四门可见。
既有Weekly与Today预览/详情/Hero回归全部通过。

最终：`flutter analyze --no-pub`无问题；`flutter test --no-pub` **252/252通过**；
`flutter build apk --debug --no-pub`生产入口成功，产物`build/app/outputs/flutter-apk/app-debug.apk`。
`git diff --check`退出0；新增/未跟踪的源码、测试与报告另做no-index --check，
无空白诊断，仅LF/CRLF提示。

可选测试截图环境变量`HUIKE_TODAY_QA_DIR`指定输出目录时加载本机微软雅黑，生成390dp明暗图；
本轮已实际渲染并检查中文内容、时间信息、Glass和密度。截图：
`C:/Users/ninan/.codex/visualizations/2026/09/27/01a0e19d-4bf8-7d02-8d65-d03ee6bcb937/task021/today-light.png`
及同目录`today-dark.png`。测试中的Material图标仍使用测试字形，不能作为图标设备验收。

源码审查无发现。本轮未安装/操作模拟器或真机；iOS、设备滑动体验与GPU性能 `UNVERIFIED`。
任务完成后停止。
