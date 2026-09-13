# -*- coding: utf-8 -*-
"""今日页与整周日列接入 SectionSlotBoard 槽位网格。运行一次即可。"""
import io

P = 'lib/features/timetable/pages/timetable_page.dart'
s = io.open(P, encoding='utf-8').read()

# ---------- Patch A：替换 _TodayList ----------
start = s.index('class _TodayList extends ConsumerWidget {')
end = s.index('/// 整周横向周历')
new_today = '''class _TodayList extends ConsumerWidget {
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
          child: SectionSlotBoard(
            courses: courses,
            schedule: bell ?? BellSchedule.fallback(),
            compact: false,
            onCourseTap: (course) => context.push('/course/${course.id}'),
          ),
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

'''
s = s[:start] + new_today + s[end:]

# ---------- Patch B：替换 _DayColumn（到文件尾） ----------
marker = 'class _DayColumn extends StatelessWidget {'
head = s[:s.index(marker)]
new_day = '''/// 一天的列：日期头（当天朱砂强调）+ 节次槽位网格。
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
'''
s = head + new_day

# ---------- imports ----------
s = s.replace(
    "import '../widgets/course_listing_row.dart';",
    "import '../widgets/course_listing_row.dart';\n"
    "import '../widgets/section_slot_board.dart';",
)
# course_colors 在页面里已不再直接使用（卡片色在 board 里）
s = s.replace("import '../../../core/theme/course_colors.dart';\n", '')

io.open(P, 'w', encoding='utf-8', newline='\n').write(s)
print('slot board wired')
