import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/course_colors.dart';
import '../../../models/bell_schedule.dart';
import '../../../models/course.dart';
import '../../../services/course_time_service.dart';

/// 今日时间轴：左侧节次时刻与贯穿轴线，课程为全宽编辑排印条目。
///
/// 与整周的槽位网格刻意区分——今日是「一天的故事」：轴线圆点标记每节
/// 开始，进行中的节次用朱砂强调；课程条目挂在轴右侧，贴内容高度，
/// 信息完整（名称 / 教室·教师 / 起止时间 / 节次）。
class DayTimeline extends StatelessWidget {
  const DayTimeline({
    super.key,
    required this.courses,
    required this.schedule,
  });

  final List<Course> courses;
  final BellSchedule schedule;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    final specs = [...schedule.sections]
      ..sort((a, b) => a.index.compareTo(b.index));
    final byStart = {for (final c in courses) c.startSection: c};
    final nowMinutes = DateTime.now().hour * 60 + DateTime.now().minute;

    final children = <Widget>[];
    SectionGroup? previousGroup;
    var skip = 0;

    for (final spec in specs) {
      if (spec.group != previousGroup) {
        if (children.isNotEmpty) {
          children.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Divider(height: 1, thickness: 1, color: palette.hairline),
            ),
          );
        }
        final groupSpecs = schedule.groupByPeriod()[spec.group];
        final range = (groupSpecs == null || groupSpecs.isEmpty)
            ? null
            : (groupSpecs.first.start, groupSpecs.last.end);
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 6),
            child: Row(
              children: [
                Text(
                  sectionGroupName(spec.group),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                    color: palette.inkTertiary,
                  ),
                ),
                const Spacer(),
                Text(
                  range == null ? '' : '${range.$1} - ${range.$2}',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: palette.inkTertiary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        );
        previousGroup = spec.group;
      }

      if (skip > 0) {
        skip--;
        continue;
      }

      final isCurrent =
          nowMinutes >= _minutes(spec.start) && nowMinutes < _minutes(spec.end);

      final course = byStart[spec.index];
      if (course == null) {
        children.add(_emptyRow(context, spec, isCurrent, palette));
        continue;
      }
      final span = course.endSection - course.startSection + 1;
      children.add(_courseRow(context, course, span, isCurrent, palette));
      skip = span - 1;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
      children: children,
    );
  }

  Widget _emptyRow(
    BuildContext context,
    SectionSpec spec,
    bool isCurrent,
    AppPalette palette,
  ) {
    return SizedBox(
      height: 46,
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              spec.start,
              style: TextStyle(
                fontSize: 11.5,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: isCurrent
                    ? palette.accent
                    : palette.inkTertiary.withValues(alpha: 0.8),
              ),
            ),
          ),
          _railCell(
            context,
            isCurrent,
            isCurrent ? palette.accent : palette.hairlineStrong,
          ),
          const SizedBox(width: 12),
          Text(
            '第 ${spec.index} 节',
            style: TextStyle(
              fontSize: 12,
              color: palette.inkTertiary.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }

  Widget _courseRow(
    BuildContext context,
    Course course,
    int span,
    bool isCurrent,
    AppPalette palette,
  ) {
    final tint = courseTint(course.colorKey, Theme.of(context).brightness);
    final range = const CourseTimeService().resolve(course, schedule);
    final height = 66.0 * span + 6 * (span - 1);

    return GestureDetector(
      onTap: () => context.push('/course/${course.id}'),
      child: SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 44,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    range == null ? '' : range.$1,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: isCurrent ? palette.accent : palette.inkSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${course.startSection}-${course.endSection}节',
                    style: TextStyle(
                      fontSize: 10,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: palette.inkTertiary,
                    ),
                  ),
                ],
              ),
            ),
            _railCell(
              context,
              isCurrent,
              isCurrent ? palette.accent : palette.hairlineStrong,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 卡片贴内容高度，跨多节时不被拉成大空块。
                    _courseCard(context, course, isCurrent, tint, range, palette),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _courseCard(
    BuildContext context,
    Course course,
    bool isCurrent,
    CourseTint tint,
    (String, String)? range,
    AppPalette palette,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: tint.chip,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrent
              ? palette.accent.withValues(alpha: 0.55)
              : tint.onChip.withValues(alpha: 0.25),
          width: isCurrent ? 1.3 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            margin: const EdgeInsets.only(top: 2, bottom: 2),
            decoration: BoxDecoration(
              color: tint.onChip.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        course.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: tint.onChip,
                        ),
                      ),
                    ),
                    if (isCurrent)
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
                          '进行中',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: palette.onAccent,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    if (course.classroom.isNotEmpty) course.classroom,
                    if (course.teacher.isNotEmpty) course.teacher,
                  ].join('  '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: tint.onChip.withValues(alpha: 0.8),
                  ),
                ),
                if (range != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${range.$1} - ${range.$2}',
                    style: TextStyle(
                      fontSize: 11,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: tint.onChip.withValues(alpha: 0.68),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 轴线单元格：一条贯穿的细线 + 节次圆点；进行中为朱砂实心点。
  Widget _railCell(BuildContext context, bool isCurrent, Color lineColor) {
    final palette = AppTheme.paletteOf(context);
    return SizedBox(
      width: 14,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(width: 1.5, color: lineColor),
          Container(
            width: isCurrent ? 10 : 7,
            height: isCurrent ? 10 : 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCurrent ? palette.accent : palette.background,
              border: Border.all(
                color: isCurrent ? palette.accent : palette.inkTertiary,
                width: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _minutes(String hhmm) {
    final parts = hhmm.split(':');
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }
}
