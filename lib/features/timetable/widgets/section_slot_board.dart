import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/course_colors.dart';
import '../../../models/bell_schedule.dart';
import '../../../models/course.dart';
import '../../../services/course_time_service.dart';

/// 节次槽位网格：一节一格，课程卡按起止节次占位撑高，
/// 空槽显示淡节次号与开始时间。上午/下午/晚上作为分隔带。
///
/// 整周窄列（compact=true）与今日宽版（compact=false）共用同一结构，
/// 只是槽高与卡片信息密度不同——这是「不空」的关键：
/// 结构（槽位、分隔带、节次号）填满版面，而不是靠课程数量。
class SectionSlotBoard extends StatelessWidget {
  const SectionSlotBoard({
    super.key,
    required this.courses,
    required this.schedule,
    required this.compact,
    this.onCourseTap,
  });

  final List<Course> courses;
  final BellSchedule schedule;
  final bool compact;
  final void Function(Course course)? onCourseTap;

  static const _gap = 3.0;

  double get _slotHeight => compact ? 64 : 58;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    final specs = [...schedule.sections]
      ..sort((a, b) => a.index.compareTo(b.index));
    final byStart = {for (final c in courses) c.startSection: c};

    final children = <Widget>[];
    SectionGroup? previousGroup;
    var skip = 0;

    for (final spec in specs) {
      if (spec.group != previousGroup) {
        if (children.isNotEmpty) {
          children.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Divider(height: 1, thickness: 1, color: palette.hairline),
            ),
          );
        }
        children.add(_groupHeader(context, spec.group, schedule, palette));
        previousGroup = spec.group;
      }

      if (skip > 0) {
        skip--;
        continue;
      }

      final course = byStart[spec.index];
      if (course == null) {
        children.add(_emptySlot(spec, palette));
        continue;
      }
      final span = course.endSection - course.startSection + 1;
      children.add(_courseCard(context, course, span, palette));
      skip = span - 1;
    }

    return ListView(
      padding: EdgeInsets.symmetric(vertical: compact ? 4 : 6),
      children: children,
    );
  }

  Widget _groupHeader(
    BuildContext context,
    SectionGroup group,
    BellSchedule schedule,
    AppPalette palette,
  ) {
    final specs = schedule.groupByPeriod()[group];
    final range = (specs == null || specs.isEmpty)
        ? null
        : (specs.first.start, specs.last.end);
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 4),
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
          const SizedBox(width: 8),
          Text(
            range == null ? '' : '${range.$1} - ${range.$2}',
            style: TextStyle(
              fontSize: 10,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: palette.inkTertiary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptySlot(SectionSpec spec, AppPalette palette) => SizedBox(
    height: _slotHeight,
    child: Row(
      children: [
        const SizedBox(width: 4),
        Text(
          '${spec.index}',
          style: TextStyle(
            fontSize: 10.5,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: palette.inkTertiary.withValues(alpha: 0.68),
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Text(
            spec.start,
            style: TextStyle(
              fontSize: 9.5,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: palette.inkTertiary.withValues(alpha: 0.55),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _courseCard(
    BuildContext context,
    Course course,
    int span,
    AppPalette palette,
  ) {
    final tint = courseTint(course.colorKey, Theme.of(context).brightness);
    final range = const CourseTimeService().resolve(course, schedule);
    final width = MediaQuery.of(context).size.width;
    final isNarrow = width < 420 && compact;

    return GestureDetector(
      onTap: () => onCourseTap?.call(course),
      child: Container(
        height: _slotHeight * span + _gap * (span - 1),
        margin: const EdgeInsets.symmetric(vertical: _gap / 2),
        padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
        decoration: BoxDecoration(
          color: tint.chip,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: tint.onChip.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course.name,
              maxLines: span >= 2 ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isNarrow ? 12.5 : 14,
                height: 1.25,
                fontWeight: FontWeight.w600,
                color: tint.onChip,
              ),
            ),
            // 信息紧跟课程名，不留中段空白；跨节次时多余高度留在卡底。
            if (range != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${range.$1}-${range.$2}',
                  style: TextStyle(
                    fontSize: 10,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: tint.onChip.withValues(alpha: 0.72),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                [
                  if (course.classroom.isNotEmpty) course.classroom,
                  if (course.teacher.isNotEmpty) course.teacher,
                ].join('  '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  color: tint.onChip.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
