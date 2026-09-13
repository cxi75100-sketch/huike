import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/course_colors.dart';
import '../../../models/bell_schedule.dart';
import '../../../models/course.dart';
import '../../../services/course_time_service.dart';

/// 历书式课程条目：左侧时间栏、发丝线分隔、小块课程签色。
///
/// 结构约束（knowledge/design.md）：不用卡片；条目之间的分隔是
/// 1px 发丝线；签色只出现在时间签这一小块面上。
class CourseListingRow extends StatelessWidget {
  const CourseListingRow({
    super.key,
    required this.course,
    required this.schedule,
    this.onTap,
  });

  final Course course;
  final BellSchedule? schedule;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    final brightness = Theme.of(context).brightness;
    final tint = courseTint(course.colorKey, brightness);
    final timeService = const CourseTimeService();
    final range = timeService.resolve(course, schedule ?? BellSchedule.fallback());

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 6,
              height: 40,
              decoration: BoxDecoration(
                color: tint.onChip.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 76,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    range == null ? '时间未定' : range.$1,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontWeight: FontWeight.w600,
                      color: palette.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sectionRangeText(course),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: palette.inkTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: palette.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _metaLine(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: palette.inkSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String sectionRangeText(Course course) =>
      course.startSection == course.endSection
      ? '第 ${course.startSection} 节'
      : '第 ${course.startSection}-${course.endSection} 节';

  String _metaLine() {
    final parts = <String>[
      if (course.classroom.isNotEmpty) course.classroom,
      if (course.teacher.isNotEmpty) course.teacher,
    ];
    return parts.isEmpty ? ' ' : parts.join('  ');
  }
}

/// 空状态：历书式的空白页，只有一句说明。
class EmptyDayPlate extends StatelessWidget {
  const EmptyDayPlate({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: palette.hairlineStrong),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  letterSpacing: 6,
                  fontWeight: FontWeight.w500,
                  color: palette.inkSecondary,
                ),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 10),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: palette.inkTertiary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
