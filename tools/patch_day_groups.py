# -*- coding: utf-8 -*-
"""日列按时段（上午/下午/晚上）分段渲染。运行一次即可。"""
import io

P = 'lib/features/timetable/pages/timetable_page.dart'
s = io.open(P, encoding='utf-8').read()

marker = '/// 一天的列：日期头（当天朱砂强调）+ 发丝线 + 课程纵列。'
head = s[:s.index(marker)]

new_tail = '''/// 一天的列：日期头（当天朱砂强调）+ 发丝线 + 课程按时段分段。
///
/// 上午 / 下午 / 晚间各自成段，段头有小组标题，段与段之间用发丝线 + 留白
/// 分开；作息表缺该节次时按通用规则（<=4 上午，<=8 下午，其余晚上）归类。
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

  static SectionGroup _groupOf(Course course, BellSchedule schedule) {
    final spec = schedule.section(course.startSection);
    if (spec != null) return spec.group;
    if (course.startSection <= 4) return SectionGroup.morning;
    if (course.startSection <= 8) return SectionGroup.afternoon;
    return SectionGroup.evening;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
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
                  : ListView(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      children: _groupedSections(context, schedule),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _groupedSections(BuildContext context, BellSchedule schedule) {
    final palette = AppTheme.paletteOf(context);
    final groups = <SectionGroup, List<Course>>{};
    for (final course in courses) {
      (groups[_groupOf(course, schedule)] ??= []).add(course);
    }
    final widgets = <Widget>[];
    var first = true;
    for (final group in SectionGroup.values) {
      final items = groups[group];
      if (items == null || items.isEmpty) continue;
      if (!first) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Divider(height: 1, thickness: 1, color: palette.hairline),
          ),
        );
      }
      widgets.add(
        Padding(
          padding: EdgeInsets.only(top: first ? 6 : 8, bottom: 2),
          child: Row(
            children: [
              Container(width: 3, height: 10, color: palette.accent),
              const SizedBox(width: 6),
              Text(
                sectionGroupName(group),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: palette.inkTertiary,
                ),
              ),
            ],
          ),
        ),
      );
      for (final course in items) {
        widgets.add(_courseTile(context, course, schedule));
      }
      first = false;
    }
    return widgets;
  }

  Widget _courseTile(BuildContext context, Course course, BellSchedule schedule) {
    final palette = AppTheme.paletteOf(context);
    final range = const CourseTimeService().resolve(course, schedule);
    final tint = courseTint(course.colorKey, Theme.of(context).brightness);
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
                    color: tint.onChip.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  range == null ? '时间未定' : range.$1,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
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
                    fontFeatures: const [FontFeature.tabularFigures()],
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
            if (course.classroom.isNotEmpty || course.teacher.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                [
                  if (course.classroom.isNotEmpty) course.classroom,
                  if (course.teacher.isNotEmpty) course.teacher,
                ].join('  '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: palette.inkSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
'''

s = head + new_tail
io.open(P, 'w', encoding='utf-8', newline='\n').write(s)
print('grouped day column installed')
