# Architecture

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
      app_database.dart         # Drift schema v1 + 行→模型扩展
      database_provider.dart    # 全局库（LazyDatabase；测试注入内存库）
    router/app_router.dart      # 路由表 + onboarding redirect
    theme/
      app_palette.dart          # 「新历书」明暗调色板（单朱砂强调色）
      app_theme.dart            # ThemeData（圆角系统锁、发丝线、组件样式）
      course_colors.dart        # 8 色课程签 + 名称散列定色
      theme_preference.dart     # system/light/dark 模型
      theme_preference_provider.dart
  models/
    school_profile.dart         # 学校档案 + 确认主机
    semester.dart               # 学期（开学周一锚点 + 总周数）
    bell_schedule.dart          # 节次规范 + 时段分组 + 通用兜底 + equalsFallback
    course.dart                 # Course + CourseSource{manual, imported}
  services/
    week_parser.dart            # 1-16周(单) 解析/格式化
    semester_service.dart       # currentWeek / termStatus / dateFor / weekdayOf
    course_time_service.dart    # 显式时间 > 作息表；缺失节次不猜
  features/
    schools/
      services/adapter_catalog.dart   # assets/adapters/catalog.json 加载
      services/school_repository.dart # 建校/切换/删除/学期/作息（播种只一次）
      providers/school_providers.dart # 学校流/激活学校/激活学期/作息流
    import/
      models/adapter_batch.dart       # 脚本回传数据规范化（无效条目计数）
      services/adapter_bridge.dart    # shiguangBridge* 契约桥（8 处理器）
      services/import_session.dart    # 内存暂存 + 合并规范化
      services/navigation_policy.dart # https + host 白名单（纯 Dart 可测）
      services/import_diff.dart       # added/removed/changed
      services/course_repository.dart # 导入替换事务 + 手动 CRUD + 内容指纹 id
      services/import_session_cleaner.dart
      pages/import_entry_page.dart    # 风险门 + HTTPS 强制 + URL 确认
      pages/import_web_page.dart      # 受限 WebView + 执行导入 + 原生桥弹窗
      pages/import_preview_page.dart  # 差异四类明细 + 附加选项 + 确认写入
      widgets/import_widgets.dart     # 分组标题 / 风险确认块
    timetable/
      providers/timetable_providers.dart
      pages/timetable_page.dart       # 今日历牌 / 整周周历
      pages/course_detail_page.dart   # 编辑排印详情
      pages/course_edit_page.dart     # 手动加课/编辑表单
      widgets/course_listing_row.dart # EmptyDayPlate（列表行已由槽位网格取代）
      widgets/section_slot_board.dart # 节次槽位网格（今日宽版 / 整周窄列共用）
    settings/
      pages/settings_page.dart        # 学校/学期/作息/外观/关于
      pages/school_manage_page.dart   # 切换/菜单（改网址/删除）
      pages/semester_settings_page.dart
      pages/bell_settings_page.dart
    onboarding/pages/onboarding_page.dart  # 创建学校 + 第一学期（必经）
```

## Data Model（schema v1）

- `schools(id PK, displayName, adapterId, loginUrl, acceptedHostsJson, createdAt)`
  —— 没有默认学校；空表 = 引导页。
- `semesters(id PK, schoolId, firstWeekMondayIso, totalWeeks)` —— 生成类名
  `SemesterRow`（@DataClassName，避免与模型 Semester 重名）。
- `course_entries(id PK, schoolId, semesterId, source enum, name, teacher, classroom,
  weekday, startSection, endSection, weeksJson, startTime?, endTime?, note, colorKey)`。
- `section_time_entries(schoolId+sectionIndex PK, start, end, periodGroup enum)`。
- `settings(key PK, value)` —— theme_mode / active_school_id / active_semester:<sid>。

## Data Flow

页面 → Riverpod provider → repository → Drift → SQLite；列表页全部 watch 流，
写入后自动刷新。激活学校决定首页内容；没有激活学校时路由 redirect 到引导页。

导入：入口确认（HTTPS + 风险勾选）→ WebView（白名单）→ 桥处理器把三类 JSON
规范化进内存会话 → `notifyTaskCompletion` 触发跳预览 → 差异与选项确认 →
事务替换 imported + 可选替换作息/学期配置 → 清理会话与 HTTP 缓存（保留 Cookie）。

## Conventions

- 生成代码只进 `*.g.dart`（build_runner）；schema 变更必须升 version 并写迁移。
- 枚举入库用 `textEnum`；周次与主机列表用 JSON 文本列（`encodeWeeks` / `encodeHosts`）。
- 时间字符串一律 `HH:mm`（24 小时制，手动格式化，禁止依赖 locale format）。
- 日期锚点存 `yyyy-MM-dd` ISO 文本（字典序即可排序）。
