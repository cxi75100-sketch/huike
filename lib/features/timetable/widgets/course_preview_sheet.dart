import 'package:flutter/material.dart';

import '../../../core/glass/glass_button.dart';
import '../../../core/glass/glass_sheet.dart';
import '../../../core/glass/glass_surface.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/course_colors.dart';
import '../../../models/bell_schedule.dart';
import '../../../models/course.dart';
import '../../../services/calendar_exception_service.dart';
import '../../../services/course_time_service.dart';
import 'course_hero.dart';

/// 课程预览 Glass Sheet。
///
/// 点课程不再直接把用户带走：先看到完整信息（名称、节次、时间、地点、教师、
/// 周次、备注），再决定编辑或进入完整详情。
///
/// 这里同时是「完整显示」的第二道保障：课表里已经被完整画出来的信息，
/// 在这里再给一份更宽松的排印版本，而不是用来弥补课表里的省略。
class CoursePreviewSheet extends StatelessWidget {
  const CoursePreviewSheet({
    super.key,
    required this.course,
    required this.schedule,
    required this.heroSource,
    required this.onEdit,
    required this.onDetails,
    required this.onClose,
  });

  final Course course;
  final BellSchedule schedule;
  final CourseHeroSourceContext heroSource;
  final VoidCallback onEdit;
  final VoidCallback onDetails;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    final tint = courseTint(course.colorKey, Theme.of(context).brightness);
    final range = const CourseTimeService().resolve(course, schedule);

    return GlassSheetPanel(
      tint: tint.onChip.withValues(alpha: 0.5),
      onClose: onClose,
      closeLabel: '关闭课程预览',
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GlassButton.icon(
                  icon: Icons.close_rounded,
                  tooltip: '关闭课程预览',
                  semanticLabel: '关闭课程预览',
                  onPressed: onClose,
                  size: 34,
                  iconSize: 18,
                  depth: 0.2,
                ),
              ],
            ),
            const SizedBox(height: 4),
            CourseHero(
              tag: CourseHeroTag.forDetails(course, heroSource),
              child: CourseHeroSurface(course: course, range: range),
            ),
            const SizedBox(height: 12),
            _InfoLine(
              icon: Icons.calendar_today_outlined,
              text:
                  '周${CalendarExceptionService.weekdayName(course.weekday)} · ${_weeksLabel(course.weeks)}',
            ),
            if (course.classroom.isNotEmpty)
              _InfoLine(icon: Icons.place_outlined, text: course.classroom),
            if (course.teacher.isNotEmpty)
              _InfoLine(
                icon: Icons.person_outline_rounded,
                text: course.teacher,
              ),
            if (course.note.isNotEmpty)
              _InfoLine(icon: Icons.notes_rounded, text: course.note),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GlassButton(
                    label: '完整详情',
                    semanticLabel: '${course.name} 的完整详情',
                    onPressed: onDetails,
                    shape: GlassButtonShape.square,
                    size: 44,
                    depth: 0.6,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GlassButton(
                    icon: Icons.edit_outlined,
                    label: '编辑',
                    semanticLabel: '编辑 ${course.name}',
                    onPressed: onEdit,
                    shape: GlassButtonShape.square,
                    size: 44,
                    iconSize: 17,
                    depth: 0.6,
                    iconColor: palette.accent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 同一节次的全部课程（三路以上冲突时从 `+N` 进来）。
class ConflictCoursesSheet extends StatelessWidget {
  const ConflictCoursesSheet({
    super.key,
    required this.courses,
    required this.schedule,
    required this.onSelected,
    required this.onClose,
  });

  final List<Course> courses;
  final BellSchedule schedule;
  final ValueChanged<Course> onSelected;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    return GlassSheetPanel(
      title: '同一节次的课程',
      subtitle: '共 ${courses.length} 门',
      onClose: onClose,
      closeLabel: '关闭冲突列表',
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: courses.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          thickness: 1,
          color: palette.hairline.withValues(alpha: 0.7),
        ),
        itemBuilder: (context, index) {
          final course = courses[index];
          final range = const CourseTimeService().resolve(course, schedule);
          return GlassSurface(
            interactive: true,
            onTap: () => onSelected(course),
            radius: 12,
            intensity: GlassIntensity.subtle,
            blurSigma: 0,
            depth: 0,
            showEdge: false,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            semanticLabel: '${course.name}，${sectionRangeLabel(course)}',
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.name,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: palette.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${sectionRangeLabel(course)}'
                        '${range == null ? '' : ' · ${range.$1}–${range.$2}'}',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: palette.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: palette.inkTertiary),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: palette.inkTertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.35,
                color: palette.inkSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _weeksLabel(List<int> weeks) {
  if (weeks.isEmpty) return '周次未定';
  final sorted = {...weeks}.toList()..sort();
  final parts = <String>[];
  var start = sorted.first;
  var previous = start;
  for (final week in sorted.skip(1)) {
    if (week == previous + 1) {
      previous = week;
      continue;
    }
    parts.add(start == previous ? '$start' : '$start–$previous');
    start = previous = week;
  }
  parts.add(start == previous ? '$start' : '$start–$previous');
  return '第 ${parts.join('、')} 周';
}
