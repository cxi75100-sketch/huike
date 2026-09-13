import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/bell_schedule.dart';
import '../../../models/course.dart';
import '../../../models/semester.dart';
import '../../../services/course_time_service.dart';
import '../../../services/semester_service.dart';
import '../../schools/providers/school_providers.dart';
import '../providers/timetable_providers.dart';
import '../widgets/course_listing_row.dart';
import '../widgets/section_slot_board.dart';
import '../widgets/day_timeline.dart';

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
                _showWeek
                    ? _WeekHeader(
                        semester: semester,
                        weekOffset: _weekOffset,
                        onMove: (delta) =>
                            setState(() => _weekOffset += delta),
                      )
                    : const _TodayHero(),
                const SizedBox(height: 4),
                _modeSwitch(context),
                Expanded(
                  child: _showWeek
                      ? _WeekBoard(
                          semester: semester,
                          week: _currentWeek(semester),
                        )
                      : const _TodayList(),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          _ModeChip(
            label: '今日',
            selected: !_showWeek,
            onTap: () => setState(() {
              _showWeek = false;
              _weekOffset = 0;
            }),
          ),
          const SizedBox(width: 8),
          _ModeChip(
            label: '整周',
            selected: _showWeek,
            onTap: () => setState(() => _showWeek = true),
          ),
          const Spacer(),
          Text(
            '第 ${_currentWeek(ref.watch(activeSemesterRefProvider)!)} 周',
            style: TextStyle(
              fontSize: 12.5,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: palette.inkTertiary,
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
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: palette.ink),
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
        borderRadius: BorderRadius.circular(4),
        child: Container(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 32),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? palette.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: selected ? palette.accent : palette.hairlineStrong,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: selected ? palette.onAccent : palette.inkSecondary,
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
    final weekLabel = semester == null
        ? ''
        : _weekLabel(ref, semester, now);

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
    final week = (service.currentWeek(semester, DateTime.now()) == 0
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
  const _TodayList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courses = ref.watch(todayCoursesProvider);
    final bell = ref.watch(bellForActiveSchoolProvider);

    if (courses.isEmpty) {
      return const EmptyDayPlate(title: '今日无课', subtitle: '加课或导入教务课表都会显示在这里');
    }
    return Column(
      children: [
        _NextCourseLine(courses: courses, bell: bell),
        Expanded(
          child: DayTimeline(courses: courses, schedule: bell ?? BellSchedule.fallback()),
        ),
      ],
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
          (int.tryParse(endParts[0]) ?? 0) * 60 + (int.tryParse(endParts[1]) ?? 0);
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

/// 整周横向周历：一天一列，可横滑翻页。
///
/// 「打开整周时眼前必须是当天」由两层保证：
/// 1. 当前教学周的列序是「今天 → 之后的日期 → 本周已过去的日期」循环排列；
/// 2. 每次从「今日」切到「整周」，PageView 都是新插入的，停在第 0 页。
/// 其他教学周（过去/未来）不适用循环——今天不在那一周里，按周一到周日排。
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
    final service = const SemesterService();
    final now = DateTime.now();
    final todayWeekday = service.weekdayOf(now);
    final todayWeek = service.currentWeek(semester, now);
    final isCurrentWeek = todayWeek == week;

    // 当前周：今天优先循环排列；其他周：周一到周日。
    final order = <int>[
      if (isCurrentWeek)
        for (var i = 0; i < 7; i++)
          ((todayWeekday - 1 + i) % 7) + 1
      else
        for (var d = 1; d <= 7; d++) d,
    ];

    return PageView.builder(
      allowImplicitScrolling: true,
      itemCount: 7,
      controller: PageController(viewportFraction: 0.5),
      itemBuilder: (context, index) {
        final weekday = order[index];
        final date = service.dateFor(semester, week, weekday);
        final dayCourses = courses
            .where(
              (course) =>
                  course.weekday == weekday && course.weeks.contains(week),
            )
            .toList()
          ..sort((a, b) => a.startSection.compareTo(b.startSection));
        final isToday = isCurrentWeek && todayWeekday == weekday;
        return _DayColumn(
          date: date,
          weekday: weekday,
          isToday: isToday,
          courses: dayCourses,
          bell: bell,
        );
      },
    );
  }
}

/// 一天的列：日期头（当天朱砂强调）+ 发丝线 + 课程按时段分段。
///
/// 上午 / 下午 / 晚间各自成段，段头有小组标题，段与段之间用发丝线 + 留白
/// 分开；作息表缺该节次时按通用规则（<=4 上午，<=8 下午，其余晚上）归类。
/// 一天的列：日期头（当天朱砂强调）+ 节次槽位网格。
class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.date,
    required this.weekday,
    required this.isToday,
    required this.courses,
    required this.bell,
  });

  final DateTime date;
  final int weekday;
  final bool isToday;
  final List<Course> courses;
  final BellSchedule? bell;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
      child: Container(
        decoration: BoxDecoration(
          color: isToday ? palette.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isToday ? palette.accent : palette.hairline,
            width: isToday ? 1.2 : 1,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '周${'一二三四五六日'[weekday - 1]}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
                    color: isToday ? palette.accent : palette.ink,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${date.month}.${date.day}',
                  style: TextStyle(
                    fontSize: 12,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: palette.inkTertiary,
                  ),
                ),
                const Spacer(),
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: palette.accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '今',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: palette.onAccent,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Divider(height: 1, thickness: 1, color: palette.hairline),
            Expanded(
              child: SectionSlotBoard(
                courses: courses,
                schedule: bell ?? BellSchedule.fallback(),
                compact: true,
                onCourseTap: (course) => context.push('/course/${course.id}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
