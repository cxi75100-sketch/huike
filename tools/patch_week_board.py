# -*- coding: utf-8 -*-
"""把整周视图替换为横向周历（今天优先）。运行一次即可。"""
import io

P = 'lib/features/timetable/pages/timetable_page.dart'
s = io.open(P, encoding='utf-8').read()

marker = 'class _WeekList extends ConsumerWidget {'
head = s[:s.index(marker)]

new_tail = '''/// 整周横向周历：一天一列，可横滑翻页。
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
      controller: PageController(viewportFraction: 0.58),
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

/// 一天的列：日期头（当天朱砂强调）+ 发丝线 + 课程纵列。
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
    final timeService = const CourseTimeService();
    final schedule = bell ?? BellSchedule.fallback();

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
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
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
            const SizedBox(height: 8),
            Divider(height: 1, thickness: 1, color: palette.hairline),
            Expanded(
              child: courses.isEmpty
                  ? Center(
                      child: Text(
                        '无课',
                        style: TextStyle(
                          fontSize: 13,
                          letterSpacing: 3,
                          color: palette.inkTertiary,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: courses.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        thickness: 1,
                        color: palette.hairline,
                      ),
                      itemBuilder: (context, index) {
                        final course = courses[index];
                        final range = timeService.resolve(course, schedule);
                        final tint = courseTint(
                          course.colorKey,
                          Theme.of(context).brightness,
                        );
                        return InkWell(
                          onTap: () => context.push('/course/${course.id}'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 5,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: tint.onChip.withValues(
                                          alpha: 0.85,
                                        ),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      range == null ? '时间未定' : range.$1,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                        color: palette.ink,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      course.startSection == course.endSection
                                          ? '第 ${course.startSection} 节'
                                          : '${course.startSection}-${course.endSection}节',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                        color: palette.inkTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  course.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    height: 1.3,
                                    fontWeight: FontWeight.w600,
                                    color: palette.ink,
                                  ),
                                ),
                                if (course.classroom.isNotEmpty ||
                                    course.teacher.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    [
                                      if (course.classroom.isNotEmpty)
                                        course.classroom,
                                      if (course.teacher.isNotEmpty)
                                        course.teacher,
                                    ].join('  '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: palette.inkSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
'''

s = head + new_tail

s = s.replace(
    '''                      ? _WeekList(
                          semester: semester,
                          week: _currentWeek(semester),
                        )''',
    '''                      ? _WeekBoard(
                          semester: semester,
                          week: _currentWeek(semester),
                        )''',
)

s = s.replace(
    "import '../../../core/theme/app_theme.dart';",
    "import '../../../core/theme/app_theme.dart';\n"
    "import '../../../core/theme/course_colors.dart';",
)
s = s.replace(
    "import '../../../services/semester_service.dart';",
    "import '../../../services/course_time_service.dart';\n"
    "import '../../../services/semester_service.dart';",
)

io.open(P, 'w', encoding='utf-8', newline='\n').write(s)
print('week board installed')
