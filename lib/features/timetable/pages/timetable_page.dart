import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/course_colors.dart';
import '../../../models/bell_schedule.dart';
import '../../../models/course.dart';
import '../../../models/semester.dart';
import '../../../services/calendar_exception_service.dart';
import '../../../services/course_time_service.dart';
import '../../../services/semester_service.dart';
import '../../schools/providers/calendar_exception_providers.dart';
import '../../schools/providers/school_providers.dart';
import '../providers/timetable_providers.dart';
import '../widgets/course_listing_row.dart';

/// 课表首页：今日历牌 / 整周周历两个栏目。
class TimetablePage extends ConsumerStatefulWidget {
  const TimetablePage({super.key});

  @override
  ConsumerState<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends ConsumerState<TimetablePage> {
  bool _showWeek = false;
  int _weekOffset = 0;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    final school = ref.watch(activeSchoolProvider);
    final semester = ref.watch(activeSemesterRefProvider);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text(school?.displayName ?? '汇课'),
        actions: [
          IconButton(
            tooltip: '导入教务课表',
            icon: const Icon(Icons.download_outlined),
            onPressed: () => context.push('/import'),
          ),
          IconButton(
            tooltip: '设置',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/course/new'),
        backgroundColor: palette.accent,
        foregroundColor: palette.onAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        icon: const Icon(Icons.add),
        label: const Text('加课'),
      ),
      body: semester == null
          ? _noSemesterBody(context, school?.id)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _modeSwitch(context),
                _showWeek
                    ? _WeekHeader(
                        semester: semester,
                        weekOffset: _weekOffset,
                        onMove: (delta) => setState(() => _weekOffset += delta),
                      )
                    : const _TodayHero(),
                Expanded(
                  child: _showWeek
                      ? _WeekBoard(
                          semester: semester,
                          week: _currentWeek(semester),
                        )
                      : _TodayList(
                          onShowWeek: () => setState(() => _showWeek = true),
                        ),
                ),
              ],
            ),
    );
  }

  int _currentWeek(Semester semester) {
    final service = const SemesterService();
    final base = service.currentWeek(semester, DateTime.now());
    final target = base == 0 ? 1 : base;
    return (target + _weekOffset).clamp(1, semester.totalWeeks);
  }

  Widget _modeSwitch(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    return Container(
      height: 58,
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.hairline),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeChip(
              label: '今日',
              selected: !_showWeek,
              onTap: () => setState(() {
                _showWeek = false;
                _weekOffset = 0;
              }),
            ),
          ),
          Expanded(
            child: _ModeChip(
              label: '整周',
              selected: _showWeek,
              onTap: () => setState(() => _showWeek = true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _noSemesterBody(BuildContext context, String? schoolId) {
    final palette = AppTheme.paletteOf(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '还没有设置学期',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '先填好开学第一周的周一，周次才有锚点。',
            style: TextStyle(fontSize: 13, color: palette.inkSecondary),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: schoolId == null
                ? null
                : () => context.push('/settings/semester'),
            child: const Text('去设置学期'),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 48),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? palette.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: selected ? palette.accent : palette.inkSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// 今日历牌：巨大日期数字 + 周次 + 学期状态提示。
class _TodayHero extends ConsumerWidget {
  const _TodayHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppTheme.paletteOf(context);
    final semester = ref.watch(activeSemesterRefProvider);
    final now = DateTime.now();
    final weekLabel = semester == null ? '' : _weekLabel(ref, semester, now);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${now.month}月${now.day}日',
                style: TextStyle(
                  fontSize: 34,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: palette.ink,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '星期${'一二三四五六日'[now.weekday - 1]}',
                style: TextStyle(fontSize: 15, color: palette.inkSecondary),
              ),
              const Spacer(),
              Text(
                weekLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: palette.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (semester != null &&
              const SemesterService().termStatus(semester, now) !=
                  TermStatus.within)
            _termBanner(context, semester, now),
        ],
      ),
    );
  }

  String _weekLabel(WidgetRef ref, Semester semester, DateTime now) {
    final service = const SemesterService();
    final status = service.termStatus(semester, now);
    return switch (status) {
      TermStatus.before => '开学前 · 第 1 周备中',
      TermStatus.after => '学期已结束',
      TermStatus.within => '第 ${service.currentWeek(semester, now)} 周',
    };
  }

  Widget _termBanner(BuildContext context, Semester semester, DateTime now) {
    final palette = AppTheme.paletteOf(context);
    final status = const SemesterService().termStatus(semester, now);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InkWell(
        onTap: () => context.push('/settings/semester'),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: palette.accentSoft,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            status == TermStatus.before
                ? '学期尚未开始（开学周一 ${DateFormat('M月d日').format(semester.firstWeekMonday)}），点按去核对'
                : '教学周已超出 ${semester.totalWeeks} 周，课表仅供回看，点按去核对学期设置',
            style: TextStyle(fontSize: 12.5, color: palette.inkSecondary),
          ),
        ),
      ),
    );
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({
    required this.semester,
    required this.weekOffset,
    required this.onMove,
  });

  final Semester semester;
  final int weekOffset;
  final ValueChanged<int> onMove;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    final service = const SemesterService();
    final week =
        (service.currentWeek(semester, DateTime.now()) == 0
                ? 1
                : service.currentWeek(semester, DateTime.now()))
            .clamp(1, semester.totalWeeks);
    final current = (week + weekOffset).clamp(1, semester.totalWeeks);
    final monday = service.weekMonday(semester, current);
    final sunday = monday.add(const Duration(days: 6));

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: '上一周',
            icon: const Icon(Icons.chevron_left),
            onPressed: current > 1 ? () => onMove(-1) : null,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '第 $current 周',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: palette.ink,
                  ),
                ),
                Text(
                  '${DateFormat('M.d').format(monday)} - ${DateFormat('M.d').format(sunday)}',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: palette.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '下一周',
            icon: const Icon(Icons.chevron_right),
            onPressed: current < semester.totalWeeks ? () => onMove(1) : null,
          ),
        ],
      ),
    );
  }
}

class _TodayList extends ConsumerWidget {
  const _TodayList({required this.onShowWeek});

  final VoidCallback onShowWeek;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courses = ref.watch(todayCoursesProvider);
    final bell = ref.watch(bellForActiveSchoolProvider);
    final schedule = ref.watch(todayDayScheduleProvider);

    if (schedule?.suspended == true) {
      return const EmptyDayPlate(
        title: '今天停课',
        subtitle: '校历例外里的停课日；在「设置 → 调休 / 停课」可修改',
      );
    }
    // 调休提示要先于「今日无课」判定：这天到底上不上课由校历决定，
    // 光说一句「无课」会让用户以为课表错了。
    final makeup = schedule?.isMakeup == true
        ? _MakeupLine(
            weekday: schedule!.weekday,
            note: schedule.exception?.note ?? '',
          )
        : null;
    if (courses.isEmpty) {
      return Column(
        children: [
          ?makeup,
          Expanded(child: _EmptyTodayPanel(onShowWeek: onShowWeek)),
        ],
      );
    }
    return Column(
      children: [
        ?makeup,
        _NextCourseLine(courses: courses, bell: bell),
        Expanded(
          child: ListView.separated(
            key: const ValueKey('today-agenda'),
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
            itemCount: courses.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 1,
              color: AppTheme.paletteOf(context).hairline,
            ),
            itemBuilder: (context, index) {
              final course = courses[index];
              return CourseListingRow(
                course: course,
                schedule: bell ?? BellSchedule.fallback(),
                onTap: () => context.push('/course/${course.id}'),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EmptyTodayPanel extends StatelessWidget {
  const _EmptyTodayPanel({required this.onShowWeek});

  final VoidCallback onShowWeek;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const EmptyDayPlate(title: '今日无课', subtitle: '可以看看整周，也可以从教务或手动补充课程'),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 88),
          child: Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.view_week_outlined,
                  label: '看整周',
                  onTap: onShowWeek,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickAction(
                  icon: Icons.add_circle_outline,
                  label: '加课程',
                  onTap: () => context.push('/course/new'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickAction(
                  icon: Icons.download_outlined,
                  label: '教务导入',
                  onTap: () => context.push('/import'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    return Material(
      color: palette.surface.withValues(alpha: 0.86),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: palette.hairline),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 19, color: palette.accent),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: palette.inkSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 调休提示条：今天上的是别的星期那天的课。
class _MakeupLine extends StatelessWidget {
  const _MakeupLine({required this.weekday, required this.note});

  final int weekday;
  final String note;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: palette.accentSoft,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Text(
              '调休',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: palette.accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '今天按${CalendarExceptionService.weekdayName(weekday)}的课表上课'
                '${note.isEmpty ? '' : ' · $note'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: palette.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 「下一节」提示条：按作息表结束时间找今天还没下课/没开始的最近一节。
class _NextCourseLine extends StatelessWidget {
  const _NextCourseLine({required this.courses, required this.bell});

  final List<Course> courses;
  final BellSchedule? bell;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    final schedule = bell ?? BellSchedule.fallback();
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;

    Course? next;
    for (final course in courses) {
      final range = const CourseTimeService().resolve(course, schedule);
      if (range == null) continue;
      final endParts = range.$2.split(':');
      final endMinutes =
          (int.tryParse(endParts[0]) ?? 0) * 60 +
          (int.tryParse(endParts[1]) ?? 0);
      if (endMinutes > nowMinutes) {
        next = course;
        break;
      }
    }
    if (next == null) return const SizedBox.shrink();

    final range = const CourseTimeService().resolve(next, schedule);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: palette.accentSoft,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Text(
              '下一节',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: palette.accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${range == null ? '' : range.$1} ${next.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: palette.ink,
                ),
              ),
            ),
            Text(
              next.startSection == next.endSection
                  ? '第 ${next.startSection} 节'
                  : '${next.startSection}-${next.endSection}节',
              style: TextStyle(
                fontSize: 11.5,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: palette.inkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 整周议程：七天按日期分组，只展开真实课程。
///
/// 空日只占一行，不再为 1–10 节预留空白。当前教学周仍以今天开头，
/// 过去/未来周按周一到周日排列。
class _WeekBoard extends ConsumerWidget {
  const _WeekBoard({required this.semester, required this.week});

  final Semester semester;
  final int week;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final school = ref.watch(activeSchoolProvider);
    final courses = school == null
        ? const <Course>[]
        : (ref.watch(coursesForProvider((school.id, semester.id))).value ??
              const <Course>[]);
    final bell = ref.watch(bellForActiveSchoolProvider);
    final calendarService = ref.watch(activeCalendarServiceProvider);
    final service = const SemesterService();
    final now = DateTime.now();
    final todayWeekday = service.weekdayOf(now);
    final todayWeek = service.currentWeek(semester, now);
    final isCurrentWeek = todayWeek == week;

    // 当前周：今天优先循环排列；其他周：周一到周日。
    final order = <int>[
      if (isCurrentWeek)
        for (var i = 0; i < 7; i++) ((todayWeekday - 1 + i) % 7) + 1
      else
        for (var d = 1; d <= 7; d++) d,
    ];

    return ListView.builder(
      key: const ValueKey('week-agenda'),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
      itemCount: 7,
      itemBuilder: (context, index) {
        final weekday = order[index];
        final date = service.dateFor(semester, week, weekday);
        // 这一天到底按哪天的课表上课，由例外表决定（停课 → 空列）。
        final daySchedule = calendarService.resolve(date);
        final dayCourses = daySchedule.suspended
            ? const <Course>[]
            : (courses
                  .where(
                    (course) =>
                        course.weekday == daySchedule.weekday &&
                        course.weeks.contains(week),
                  )
                  .toList()
                ..sort((a, b) => a.startSection.compareTo(b.startSection)));
        final isToday = isCurrentWeek && todayWeekday == weekday;
        return _WeekAgendaDay(
          orderIndex: index,
          date: date,
          weekday: weekday,
          isToday: isToday,
          courses: dayCourses,
          bell: bell,
          daySchedule: daySchedule,
        );
      },
    );
  }
}

class _WeekAgendaDay extends StatelessWidget {
  const _WeekAgendaDay({
    required this.orderIndex,
    required this.date,
    required this.weekday,
    required this.isToday,
    required this.courses,
    required this.bell,
    required this.daySchedule,
  });

  final int orderIndex;
  final DateTime date;
  final int weekday;
  final bool isToday;
  final List<Course> courses;
  final BellSchedule? bell;
  final DaySchedule daySchedule;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);

    final stateLabel = daySchedule.suspended
        ? '停课'
        : courses.isEmpty
        ? '无课'
        : '${courses.length} 门';

    return Container(
      key: ValueKey('week-day-$orderIndex-$weekday'),
      decoration: BoxDecoration(
        color: isToday ? palette.accentSoft.withValues(alpha: 0.42) : null,
        border: Border(bottom: BorderSide(color: palette.hairline)),
      ),
      child: Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: Text(
                      '周${'一二三四五六日'[weekday - 1]}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
                        color: isToday ? palette.accent : palette.ink,
                      ),
                    ),
                  ),
                  Text(
                    '${date.month}月${date.day}日',
                    style: TextStyle(
                      fontSize: 12,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: palette.inkTertiary,
                    ),
                  ),
                  if (daySchedule.isMakeup) ...[
                    const SizedBox(width: 8),
                    Text(
                      '按${CalendarExceptionService.weekdayName(daySchedule.weekday)}上课',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: palette.accent,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    stateLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: courses.isEmpty
                          ? FontWeight.w400
                          : FontWeight.w600,
                      color: courses.isEmpty
                          ? palette.inkTertiary
                          : palette.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (final course in courses)
            _WeekCourseRow(
              course: course,
              schedule: bell ?? BellSchedule.fallback(),
            ),
        ],
      ),
    );
  }
}

class _WeekCourseRow extends StatelessWidget {
  const _WeekCourseRow({required this.course, required this.schedule});

  final Course course;
  final BellSchedule schedule;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    final tint = courseTint(course.colorKey, Theme.of(context).brightness);
    final range = const CourseTimeService().resolve(course, schedule);
    final section = course.startSection == course.endSection
        ? '${course.startSection}节'
        : '${course.startSection}-${course.endSection}节';

    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 0, 8, 8),
      child: Material(
        color: tint.chip,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => context.push('/course/${course.id}'),
          borderRadius: BorderRadius.circular(10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 64,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          range?.$1 ?? '待定',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: tint.onChip,
                          ),
                        ),
                        Text(
                          section,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: tint.onChip.withValues(alpha: 0.68),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 3,
                    height: 32,
                    color: tint.onChip.withValues(alpha: 0.72),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          course.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: tint.onChip,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (course.classroom.isNotEmpty) course.classroom,
                            if (course.teacher.isNotEmpty) course.teacher,
                          ].join('  '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: tint.onChip.withValues(alpha: 0.76),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: palette.inkTertiary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
