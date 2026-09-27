# Architecture

## TASK-020B root switcher（2026-09-27）

仅既有`/today`和`/`接入StatefulShellRoute两个preload分支，页面/Navigator持续挂载。
TimetableRootShell拥有一条动画进度；RetainedTimetablePages用paint wrappers切换，child不逐帧build。
非活动分支隔离input/focus/semantics/ticker/Hero；顶层子路由保留原push/pop和Preview transition。
Switcher监听routerDelegate.state.uri.path，避免imperative push后routeInformationProvider URI恢复root造成误显示。
Weekly inline Preview由RootSwitcherScope notifier隐藏栏；其它Preview/子页由顶层path隐藏。
相关报告为report_2026-09-27_root_switcher.md，历史顶部Today按钮/返回Weekly约定已由本次root切换替代。

## TASK-022B 启动接线（2026-09-27）

main预读保存主题并仅为真实主题初始化defer首帧。app级launchReadiness复用既有provider，
初始root不挂载未解析的默认空值；ready后一次性latch，后续状态不重新遮挡。
LaunchReveal只包初始root，180ms/4dp/0.92opacity，Reduced直接；router/DB结构不改。
详见launch_motion报告，性能与设备验证边界不得扩大。

## TASK-022A 普通route与overlay接线（2026-09-27）

app_router普通route调用core/router/glass_page.dart，非iOS用CustomTransitionPage +
GlassTransition；iOS用MaterialPageRoute合同保留Cupertino交互返回。Preview来源Detail与
Today Preview继续原有route分支。showGlassDialog保留DialogRoute焦点/barrier合同，仅改绘制transition。
GlassMotion集中时长/曲线；业务页面只显式传普通Snackbar样式。完整分类与边界见motion_audit报告。

## Overview

Flutter 单机应用。Riverpod 3 负责依赖与状态，GoRouter（单实例 + refreshListenable
响应式 redirect）导航，Drift + SQLite 持久化。无后端、无账号、无云同步。
多校是数据模型的内生维度：学校（School）是一等实体，学期/课程/作息都挂在它下面。

## Structure

```text
lib/
  main.dart                     # 入口；ProviderScope
  app.dart                      # MaterialApp.router + 明暗主题 + 中文本地化
  core/
    database/
      app_database.dart         # Drift schema v3（含 v1→v2 addColumn、v2→v3 createTable）+ 行→模型扩展
      database_provider.dart    # 全局库（NativeDatabase.createInBackground；测试注入内存库）
    router/app_router.dart      # 路由表 + onboarding redirect
    glass/
      glass_surface.dart      # 玻璃材质
      glass_button.dart       # 玻璃操作和触控语义
      glass_sheet.dart        # Sheet 与背景联动
      glass_form.dart         # 文本框、单选、勾选、选项和选择器
      glass_dialog.dart       # 共用确认/提示框及危险操作
      glass_motion.dart       # 动效令牌
      glass_metrics.dart      # 尺寸与模糊令牌
    widgets/ambient_backdrop.dart # 全局环境光背景
    theme/
      app_palette.dart          # 独立浅色/graphite 深色语义调色板
      app_theme.dart            # ThemeData（圆角系统锁、发丝线、组件样式）
      course_colors.dart        # 8 色课程签 + 名称散列定色
      theme_preference.dart     # system/light/dark 模型
      theme_preference_provider.dart
  models/
    school_profile.dart         # 学校档案 + 确认主机
    semester.dart               # 学期（开学周一锚点 + 总周数）
    bell_schedule.dart          # 节次规范 + 时段分组 + 通用兜底 + equalsFallback
    course.dart                 # Course + CourseSource{manual, imported}
    calendar_exception.dart     # 校历例外（停课 / 调休补课）
  services/
    week_parser.dart              # 1-16周(单) 解析/格式化
    semester_service.dart         # currentWeek / termStatus / dateFor / weekdayOf / readingProgress
    course_time_service.dart      # 显式时间 > 作息表；缺失节次不猜；sectionRangeLabel
    section_count_resolver.dart   # 作息节次与旧课程节次的统一上限
    calendar_exception_service.dart # 例外 → 某天按哪天的课表（纯 Dart，UI 共用）

  features/
    schools/
      services/adapter_catalog.dart   # assets/adapters/catalog.json 加载
      services/login_url_policy.dart  # 教务地址校验（建校/改址/导入入口三处共用）
      services/school_repository.dart # 建校/切换/删除/学期/作息（播种只一次）
      services/calendar_exception_repository.dart # 调休/停课写路径（同日覆盖）
      providers/school_providers.dart # 学校流/激活学校/激活学期/作息流
      providers/calendar_exception_providers.dart # 例外流 + 激活学校解析器
    import/
      models/adapter_batch.dart       # 脚本回传数据规范化（无效条目计数）
      services/adapter_bridge.dart    # shiguangBridge* 契约桥（8 处理器）
      services/import_session.dart    # 内存暂存 + 合并规范化
      services/navigation_policy.dart # scheme（http/https）+ host 白名单（纯 Dart 可测）
      services/import_diff.dart       # added/removed/changed
      services/course_repository.dart # 导入替换事务 + 手动 CRUD + 内容指纹 id
      services/import_session_cleaner.dart
      pages/import_entry_page.dart    # 风险门（明文额外警示）+ 地址确认（共用 checkLoginUrl）
      pages/import_web_page.dart      # 受限 WebView + 跨域逐主机确认 + 自动探测 + 原生桥弹窗
      pages/import_preview_page.dart  # 差异四类明细 + 附加选项 + 确认写入
      widgets/import_widgets.dart     # 分组标题 / 风险确认块
    timetable/
      providers/timetable_providers.dart
      models/timetable_layout.dart     # responsive metrics + 课程放置/冲突结果模型
      services/week_agenda.dart       # 一周模型：自然日期 + 例外折算 + 今天下标
      services/course_collision_layout.dart # 纯展示层 interval 分簇与 lane 分配
      pages/timetable_page.dart       # Weekly Timetable 组合、周状态与路由交互
      pages/today_page.dart           # 独立今日页、时钟与既有预览路由页
      widgets/today_timeline.dart     # Today内容高度节点、语义空档/当前时间轴
      widgets/course_hero.dart         # weekly/today 来源身份与详情 Hero 共用材质
      pages/course_detail_page.dart   # 编辑排印详情
      pages/course_edit_page.dart     # 手动加课/编辑表单
      widgets/timetable_header.dart   # 学校行/今日按钮 + 周导航/学期进度入口
      widgets/weekday_header.dart     # 固定七日表头与今天/调休/停课语义
      widgets/timetable_grid.dart     # 节次轴、七列、课程定位、状态叠层
      widgets/timetable_course_block.dart # 专用课程块与冲突入口
      widgets/course_preview_sheet.dart # 首次点按预览/冲突列表
      widgets/liquid_add_button.dart  # 添加课程/导入/单周事件菜单
      widgets/week_swipe.dart         # 三页跟手切周
      widgets/week_navigation.dart    # 周次导航与学期进度
      models/course_block_layout.dart # 网格字级样式与旧测量工具
    settings/
      pages/settings_page.dart        # 学校/学期/作息/调休停课/外观/关于
      pages/school_manage_page.dart   # 切换/菜单（改网址/删除）
      pages/semester_settings_page.dart
      pages/bell_settings_page.dart
      pages/calendar_exception_page.dart # 调休/停课：按日期维护例外
    onboarding/pages/onboarding_page.dart  # 创建学校 + 第一学期（必经）
```

## Data Model（schema v3；v1→v2 为 `addColumn`，v2→v3 为 `createTable`）

- `schools(id PK, displayName, adapterId, presetId, loginUrl, acceptedHostsJson,
  scheduleVariantsJson, createdAt)`
  —— 没有默认学校；空表 = 引导页。`presetId`/`scheduleVariantsJson` 为 v2 新增。
- `semesters(id PK, schoolId, firstWeekMondayIso, totalWeeks)` —— 生成类名
  `SemesterRow`（@DataClassName，避免与模型 Semester 重名）。
- `course_entries(id PK, schoolId, semesterId, source enum, name, teacher, classroom,
  weekday, startSection, endSection, weeksJson, startTime?, endTime?, note, colorKey)`。
- `section_time_entries(schoolId+sectionIndex PK, start, end, periodGroup enum)`。
- `calendar_exceptions(id PK, schoolId, semesterId, dateIso, kind enum, makeupWeekday?,
  note)` —— 校历例外；同一天只保留一条（写路径保证），空表 = 没有例外。
- `settings(key PK, value)` —— theme_mode / active_school_id / active_semester:<sid>。

## Data Flow

页面 → Riverpod provider → repository → Drift → SQLite；列表页全部 watch 流，
写入后自动刷新。激活学校决定首页内容；没有激活学校时路由 redirect 到引导页。

导入：入口确认（地址 + 明文 HTTP 额外警示 + 风险勾选）→ WebView（主框架新主机弹窗确认，
确认后只增不减）→ 桥处理器把三类 JSON
规范化进内存会话 → `notifyTaskCompletion` 触发跳预览 → 差异与选项确认 →
事务替换 imported + 可选替换作息/学期配置 → 清理会话与 HTTP 缓存（保留 Cookie）。
探测期间不展示逐个尝试的过程（DEC-007）。

课表显示：课程本身以「周次 × 星期 × 起止节次」表达，某一天到底按哪天的课表上课由
`calendar_exceptions` 经 `CalendarExceptionService` 折算，Weekly Timetable 据此决定当天
列取哪个星期的课以及停课/调休标记。**新增任何「按天取课」的消费方
（小组件、提醒）都必须走同一个折算**，不要各自判星期。

日期顺序只有一个来源：`buildWeekAgenda` 一次性给出「第 N 周 / 周一 → 周日 / 例外折算
后的星期 / 当天课程 / isToday」，以及今天在七天里的下标。`TimetableGrid` 固定渲染七列；
纵向像素只由 `startSection..endSection` 与 responsive `sectionHeight` 推导，不以分钟定位。
Compact 下两节共用一个视觉分隔区，但 section 仍是碰撞与定位的最小单位。

碰撞布局在 Widget 外由 `layoutCourseCollisions` 纯函数完成：按闭区间稳定排序、合并相交簇、
贪心复用 lane。UI 只显示 lane 0 的完整宽度课程块；`+N` 与冲突列表使用
`CourseCollisionLayoutResult.overlapping(course)` 返回的直接重叠课程，不能把传递闭包的
整簇成员都算成该课程的冲突对象。10/12 节由视口均分高度，超过 12 节允许网格滚动。

课程预览进入详情时使用 Flutter `Hero`。`CourseHeroTag` 绑定 courseId、schoolId、semesterId、
来源上下文（weekly/today）和详情目标；预览和详情共用 `CourseHeroSurface`。Weekly 课程块到
预览仍由同页 `GlassSheetHost` 驱动几何过渡。Today 课程预览使用透明的 PageRoute 叠层，
因此 Today 卡片 → 预览 → 详情均处于可参与 Hero 配对的页面路由中；普通 PopupRoute 不参与
Flutter PageRoute 间的 Hero 配对。Reduced Motion 下不挂载 Hero，详情路由用短淡入。

用户可见输入、单选/勾选/紧凑选项、选择器和确认框共用 `GlassTextField`、
`GlassSelectionRow`、`GlassToggleRow`、`GlassChoiceChip`、`GlassPickerRow`、`GlassDialog`。
它们保留原生 `TextField`、Navigator 焦点与系统键盘行为；系统日期/时间选择器仍用 Flutter
平台选择器。

## Conventions

TASK-021：TodayTimeline复用CourseTimeService取时间并排序，课程高度由有限行预算与
内容自然布局确定，不按节次/分钟定位。连续左轴、课程节点和16/24/40dp间隔保留时间语义；
当前时间标记属于课程、课间或首尾状态，非精确分钟Y坐标。TodayPage每30秒检查分钟更新，
跨日刷新today providers，dispose取消定时器。Preview类及所有Weekly代码保持原文。

TASK-020B：Weekly只组合本周七日数据，不计算TodaySummary。学校行「今日」按钮仍由
`onToday -> context.push('/today')`进入原TodayPage；今日摘要组件已删除，不保留布局占位。
GoRouter与Today Timeline内部实现不变。

TASK-020A：`WeekSwipePager` 在 drag down 锁定本次资格，落位期间新手势不可接管；
drag end 在启动弹簧前消费会话，pointer cancel 回弹。位移与速度仅返回0/±1，
完成回调是唯一周次提交点；共享 `WeekSwipeState.offset` 同步拖动和弹簧进度。

- 生成代码只进 `*.g.dart`（build_runner）；schema 变更必须升 version 并写迁移。
- 枚举入库用 `textEnum`；周次与主机列表用 JSON 文本列（`encodeWeeks` / `encodeHosts`）。
- 时间字符串一律 `HH:mm`（24 小时制，手动格式化，禁止依赖 locale format）。
- 日期锚点存 `yyyy-MM-dd` ISO 文本（字典序即可排序）。
# TASK-019 Weekly 展示层补充（2026-09-26）

TASK-019B：`TimetableCourseBlock` 删除装饰 Row 与色条 Container，直接绘制全宽内容。
颜色只存在于外壳 gradient/border/shadow，按压由现有 PressPhysics 驱动；marker 常量已删除。

`weekly_location_formatter.dart` 是纯展示函数，仅由 `TimetableCourseBlock` 调用；
Course 数据仍含原始地点。课程块内部量字分配固定高度，网格没有接入 `requiredHeight`。
普通两节块绘制名称、compact 地点、教师；辅助字段字号最低 10sp，时钟时间不绘制。
