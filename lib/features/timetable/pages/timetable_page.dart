import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/glass/glass_button.dart';
import '../../../core/glass/glass_sheet.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ambient_backdrop.dart';
import '../../../models/bell_schedule.dart';
import '../../../models/course.dart';
import '../../../models/semester.dart';
import '../../../services/semester_service.dart';
import '../../schools/providers/calendar_exception_providers.dart';
import '../../schools/providers/school_providers.dart';
import '../providers/timetable_providers.dart';
import '../services/week_agenda.dart';
import '../widgets/course_preview_sheet.dart';
import '../widgets/course_hero.dart';
import '../widgets/liquid_add_button.dart';
import '../widgets/timetable_grid.dart';
import '../widgets/timetable_header.dart';
import '../widgets/week_navigation.dart';
import '../widgets/week_swipe.dart';
import '../widgets/weekday_header.dart';
import '../widgets/timetable_root_shell.dart';

/// 课表首页。
///
/// 层级（见 `knowledge/design.md`）：
/// LEVEL 0 环境底色 → LEVEL 1 网格 → LEVEL 2 课程块 → LEVEL 3 今日上下文
/// （星期栏里的今天选择器）→ LEVEL 4 浮动玻璃导航与加课 → LEVEL 5 玻璃 Sheet。
///
/// 页面只做组合：网格、切周、Sheet、玻璃控制各自独立，
/// 唯一的共享状态是 [WeekSwipeState]（一个手势喂给网格位移与导航高光）。
class TimetablePage extends ConsumerStatefulWidget {
  const TimetablePage({super.key});

  @override
  ConsumerState<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends ConsumerState<TimetablePage> {
  final _swipe = WeekSwipeState();
  final _todayPulse = TodayPulse();
  final _scrolling = ValueNotifier<bool>(false);
  final _sheetHostKey = GlobalKey<GlassSheetHostState>();

  int _weekOffset = 0;
  _TimetableSheet? _sheet;
  bool _sheetClosing = false;
  int _sheetGeneration = 0;
  VoidCallback? _afterSheetDismiss;

  @override
  void dispose() {
    _swipe.dispose();
    _todayPulse.dispose();
    _scrolling.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    final school = ref.watch(activeSchoolProvider);
    final semester = ref.watch(activeSemesterRefProvider);

    if (semester == null) {
      return Scaffold(
        backgroundColor: palette.background,
        appBar: AppBar(
          title: Text(school?.displayName ?? '汇课'),
          actions: [
            GlassButton.icon(
              icon: Icons.settings_outlined,
              tooltip: '设置',
              semanticLabel: '设置',
              onPressed: () => context.push('/settings'),
              size: 36,
            ),
          ],
        ),
        body: _NoSemesterBody(schoolId: school?.id),
      );
    }

    final currentWeek = _baseWeek(semester);
    final week = _visibleWeek(semester);
    final coursesAsync = school == null
        ? const AsyncValue<List<Course>>.data([])
        : ref.watch(coursesForProvider((school.id, semester.id)));
    final courses = coursesAsync.value ?? const <Course>[];
    final calendar = ref.watch(activeCalendarServiceProvider);
    final schedule =
        ref.watch(bellForActiveSchoolProvider) ?? BellSchedule.fallback();

    WeekAgenda agendaFor(int value) => buildWeekAgenda(
      semester: semester,
      week: value,
      courses: courses,
      calendar: calendar,
    );

    final agenda = agendaFor(week);

    Widget gridFor(int value, Key key) => TimetableGrid(
      key: key,
      agenda: value == week ? agenda : agendaFor(value),
      schedule: schedule,
      loading: coursesAsync.isLoading && !coursesAsync.hasValue,
      errorMessage: coursesAsync.hasError ? '${coursesAsync.error}' : null,
      onRetry: school == null
          ? null
          : () => ref.invalidate(coursesForProvider((school.id, semester.id))),
      onCourseTap: (course) => _openSheet(_CourseSheet(course)),
      onConflictTap: (items) => _openSheet(_ConflictSheet(items)),
      onScrolling: _onScrolling,
      todayPulse: _todayPulse,
    );

    final body = SafeArea(
      bottom: false,
      child: Column(
        children: [
          TimetableHeader(
            schoolName: school?.displayName ?? '汇课',
            semester: semester,
            week: week,
            currentWeek: currentWeek,
            swipe: _swipe,
            onPrevious: week > 1 ? () => _swipe.step(-1) : null,
            onNext: week < semester.totalWeeks ? () => _swipe.step(1) : null,
            onCurrent: () => _goCurrent(semester),
            onImport: () => context.push('/import'),
            onSettings: () => context.push('/settings'),
            onSemesterProgress: () => showSemesterProgressSheet(
              context: context,
              semester: semester,
              week: week,
            ),
          ),
          Expanded(
            child: WeekSwipePager(
              state: _swipe,
              onCommit: (direction) => _commitWeek(direction, semester),
              previous: week > 1
                  ? gridFor(week - 1, const ValueKey('weekly-grid-previous'))
                  : null,
              next: week < semester.totalWeeks
                  ? gridFor(week + 1, const ValueKey('weekly-grid-next'))
                  : null,
              page: gridFor(week, const ValueKey('weekly-grid-current')),
            ),
          ),
        ],
      ),
    );

    return PopScope(
      canPop: _sheet == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _sheet != null) _requestSheetDismiss();
      },
      child: Scaffold(
        backgroundColor: palette.background,
        body: AmbientBackdrop(
          child: GlassSheetHost(
            key: _sheetHostKey,
            background: Stack(
              children: [
                Positioned.fill(child: body),
                Positioned(
                  right: 14,
                  bottom:
                      14 +
                      MediaQuery.viewPaddingOf(context).bottom +
                      (RootSwitcherScope.maybeOf(context) == null
                          ? 0
                          : RootSwitcherLayout.fabLift),
                  child: LiquidAddButton(
                    onPressed: () => context.push('/course/new'),
                    onImport: () => context.push('/import'),
                    onAddEvent: () => context.push('/event/new'),
                    scrolling: _scrolling,
                  ),
                ),
              ],
            ),
            sheet: _sheet == null
                ? null
                : KeyedSubtree(
                    key: ValueKey(_sheetGeneration),
                    child: _sheetWidget(schedule)!,
                  ),
            // Keep the grid sharp and stationary; the panel slides at its
            // final layout size instead of collapsing into a course cell.
            backgroundScale: 0,
            maxBlur: 0,
            onDismissStarted: () => _sheetClosing = true,
            onDismissed: _finishSheetDismiss,
          ),
        ),
      ),
    );
  }

  Widget? _sheetWidget(BellSchedule schedule) {
    return switch (_sheet) {
      null => null,
      _CourseSheet(course: final course) => CoursePreviewSheet(
        course: course,
        schedule: schedule,
        heroSource: CourseHeroSourceContext.weeklyTimetable,
        onClose: _requestSheetDismiss,
        onEdit: () => _requestSheetDismiss(
          after: () => context.push('/course/${course.id}/edit'),
        ),
        onDetails: () {
          context.push(
            '/course/${course.id}',
            extra: CourseHeroSourceContext.weeklyTimetable,
          );
        },
      ),
      _ConflictSheet(courses: final items) => ConflictCoursesSheet(
        courses: items,
        schedule: schedule,
        onClose: _requestSheetDismiss,
        onSelected: (course) => _openSheet(_CourseSheet(course)),
      ),
    };
  }

  void _openSheet(_TimetableSheet sheet) {
    // An edit already requested owns the pending navigation. Ordinary closes
    // can be interrupted by another course, including reopening the same one.
    if (_afterSheetDismiss != null || (!_sheetClosing && _sheet == sheet)) {
      return;
    }
    setState(() {
      _sheet = sheet;
      _sheetClosing = false;
      _sheetGeneration++;
    });
    RootSwitcherScope.maybeOf(context)?.previewVisible.value = true;
  }

  void _requestSheetDismiss({VoidCallback? after}) {
    if (_sheet == null || _sheetClosing) return;
    _sheetClosing = true;
    _afterSheetDismiss = after;
    _sheetHostKey.currentState?.close();
  }

  void _finishSheetDismiss() {
    if (!mounted || _sheet == null) return;
    final after = _afterSheetDismiss;
    _afterSheetDismiss = null;
    _sheetClosing = false;
    setState(() => _sheet = null);
    RootSwitcherScope.maybeOf(context)?.previewVisible.value = false;
    after?.call();
  }

  void _onScrolling(bool active) => _scrolling.value = active;

  int _baseWeek(Semester semester) {
    final base = const SemesterService().currentWeek(semester, DateTime.now());
    return (base == 0 ? 1 : base).clamp(1, semester.totalWeeks);
  }

  int _visibleWeek(Semester semester) =>
      (_baseWeek(semester) + _weekOffset).clamp(1, semester.totalWeeks);

  /// pager 走完过渡后回调：进入下一周（+1）或回到上一周（-1）。
  void _commitWeek(int direction, Semester semester) {
    final current = _visibleWeek(semester);
    final target = (current + direction).clamp(1, semester.totalWeeks);
    if (target == current) return;
    setState(() => _weekOffset = target - _baseWeek(semester));
    if (target == _baseWeek(semester)) _todayPulse.fire();
    unawaited(HapticFeedback.selectionClick());
  }

  void _goCurrent(Semester semester) {
    final current = _visibleWeek(semester);
    final target = _baseWeek(semester);
    if (target == current) {
      _todayPulse.fire();
      return;
    }
    if ((target - current).abs() == 1) {
      // 相邻周就交给跟手 pager 走完，保留空间连续性。
      _swipe.step(target > current ? 1 : -1);
      return;
    }
    setState(() => _weekOffset = 0);
    _todayPulse.fire();
  }
}

/// 玻璃 Sheet 的内容类型。
sealed class _TimetableSheet {
  const _TimetableSheet();
}

class _CourseSheet extends _TimetableSheet {
  const _CourseSheet(this.course);

  final Course course;

  @override
  bool operator ==(Object other) =>
      other is _CourseSheet && other.course.id == course.id;

  @override
  int get hashCode => course.id.hashCode;
}

class _ConflictSheet extends _TimetableSheet {
  const _ConflictSheet(this.courses);

  final List<Course> courses;

  @override
  bool operator ==(Object other) =>
      other is _ConflictSheet &&
      other.courses.length == courses.length &&
      other.courses.first.id == courses.first.id;

  @override
  int get hashCode => Object.hash(courses.length, courses.first.id);
}

class _NoSemesterBody extends StatelessWidget {
  const _NoSemesterBody({required this.schoolId});

  final String? schoolId;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              schoolId == null ? '你的课表，从这里开始' : '还没有设置学期',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: palette.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              schoolId == null
                  ? '导入学校课表后，每周课程都会出现在这里。'
                  : '设置开学第一周的周一后，就能生成完整周课表。',
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.inkSecondary),
            ),
            const SizedBox(height: 16),
            GlassButton(
              onPressed: schoolId == null
                  ? () => context.push('/import')
                  : () => context.push('/settings/semester'),
              label: schoolId == null ? '导入课表' : '设置学期',
              icon: schoolId == null
                  ? Icons.download_outlined
                  : Icons.edit_calendar_outlined,
              iconColor: palette.accent,
              size: 48,
            ),
          ],
        ),
      ),
    );
  }
}
