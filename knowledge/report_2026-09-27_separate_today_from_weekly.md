# TASK-020B — Separate Today From Weekly

日期：2026-09-27 +08:00。保留全部既有未提交改动，无commit/push/reset/clean。

## 最终行为

Weekly只展示本周七日课程。删除整块Today摘要横条（今日课程数量、下一节时间/课名、课已上完或无课提示）、横条前的间距与摘要计算。顶部结构为学校/页面行 → 周切换器 → 星期/日期栏 → Weekly grid，没有原横条占位。

原横条是Today唯一可见入口，因此在既有学校行加入「今日」文字按钮，复用GlassButton和原`onToday -> context.push('/today')`。入口有44dp点击目标和「查看今日课程」语义；不携带所选周，进入原TodayPage仍按今天查课。

没有新建Today页面，没有修改GoRouter、route或Navigation架构。Today内部布局、课程预览/详情/Hero均保持原实现。

## 本轮文件

- 修改 `lib/features/timetable/pages/timetable_page.dart`：移除todayAgenda/summary、_summaryOf/_minutesOf和无用import。
- 修改 `lib/features/timetable/widgets/timetable_header.dart`：去除TodaySummary参数与strip，学校行增加独立今日按钮。
- 删除 `lib/features/timetable/widgets/today_glass_shortcut.dart`：已无调用方的专用Today摘要组件/数据类。
- 修改 `test/week_agenda_ui_test.dart`、`test/app_shell_test.dart`：改用新入口并补回归。
- 修改 `test/course_block_content_test.dart`：14节回归从旧视口高度假设改为断言实际可滚动且星期栏固定。
- 同步知识库README/current_state/tasks/architecture/design/testing/changelog与本报告。

开工前保存整个lib文件SHA256，结束对比仅上述两份代码修改、一份组件删除。其余既有lib文件内容未变；包括Weekly paging、Course Block、TodayPage/Timeline、Preview、Import、数据库、WebView/Adapter/Bridge、Android Back、FAB、App icon、全局Motion。

## 测试

新增3例：360/390/430dp均用1.3倍字体，确认Weekly没有Today摘要文本、课程和七列仍可见，header后直接衔接grid且没有空洞；今日入口至少44dp。

每例先切到下一周再点今日，核对实际GoRouterState路径为`/today`、TodayPage存在、今天课程数量与课程仍显示，返回Weekly保留第5周且无overflow。原今日课程→预览→详情→返回/Hero用例继续运行，10/12节一屏保留既有回归。

第一次全量231通过、1失败：14节旧断言要求grid本体大于整个滚动viewport；移除横条后viewport为746dp而本体728dp，原滚动内容还包含星期栏与底部padding，实际仍可滚动。将测试改为maxScrollExtent>0、drag后pixels增加且星期栏Rect不变；没有修改production网格或课程块。该文件13/13通过。

## 验证与边界

- 开始：git status、git diff --stat已检查；analyze无问题，全量229/229通过。
- 两份相关测试：45/45通过；源码审查无问题。
- 最终：`flutter analyze --no-pub`无问题；`flutter test --no-pub` **232/232通过**（229+3）；`flutter build apk --debug --no-pub`生产入口成功，产物 `build/app/outputs/flutter-apk/app-debug.apk`；`git diff --check`退出0。未跟踪header/测试/报告另做no-index --check，无空白诊断，仅LF/CRLF提示。
- 无设备操作；模拟器实画、真机与iOS为 `UNVERIFIED`。

严格没有开始duration线性高度、Semantic Timeline、Today card高度、课间gap或当前时间indicator重构。任务完成后停止。
