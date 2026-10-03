import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/glass/glass_button.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/bell_schedule.dart';
import '../../../models/course.dart';
import '../../../services/section_count_resolver.dart';
import '../models/course_block_layout.dart';
import '../models/timetable_layout.dart';
import '../services/course_collision_layout.dart';
import '../services/week_agenda.dart';
import 'timetable_course_block.dart';
import 'weekday_header.dart';

/// 一周课表网格（LEVEL 1–2）。
///
/// Seven fixed columns. Up to 12 sections divide the available viewport;
/// longer schedules scroll below the pinned weekday header.
class TimetableGrid extends StatelessWidget {
  const TimetableGrid({
    super.key,
    required this.agenda,
    required this.schedule,
    required this.onCourseTap,
    this.onCourseSourceTap,
    required this.onConflictTap,
    this.loading = false,
    this.errorMessage,
    this.onRetry,
    this.scrollController,
    this.onScrolling,
    this.todayPulse,
  });

  final WeekAgenda agenda;
  final BellSchedule schedule;
  final ValueChanged<Course> onCourseTap;
  final void Function(Course, Rect, GlobalKey)? onCourseSourceTap;
  final ValueChanged<List<Course>> onConflictTap;
  final bool loading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final ScrollController? scrollController;

  /// 滚动状态回调：加课按钮据此轻微后退。
  final ValueChanged<bool>? onScrolling;
  final Listenable? todayPulse;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final baseMetrics = TimetableLayoutMetrics.of(constraints.maxWidth);
        final sectionCount = _sectionCount();
        final availableGridHeight = math.max(
          0.0,
          constraints.maxHeight - baseMetrics.dayHeaderHeight,
        );
        final typography = _typography(context, baseMetrics.density);
        final layouts = [
          for (final day in agenda.days) layoutCourseCollisions(day.courses),
        ];
        final scrollable = sectionCount > 12;
        final metrics = baseMetrics.withSectionHeight(
          scrollable
              ? math.max(
                  math.max(baseMetrics.sectionHeight, 52),
                  availableGridHeight / sectionCount,
                )
              : availableGridHeight / sectionCount,
        );
        final gridHeight = sectionCount * metrics.sectionHeight;
        final hasCourses = agenda.days.any((day) => day.courses.isNotEmpty);

        return Stack(
          children: [
            Positioned.fill(
              child: NotificationListener<ScrollNotification>(
                onNotification: _handleScrollNotification,
                child: SingleChildScrollView(
                  key: const ValueKey('weekly-grid-scroll'),
                  controller: scrollController,
                  // 不挂到 PrimaryScrollController：页面上不该有别人能滚它。
                  primary: false,
                  physics: scrollable
                      ? null
                      : const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.only(
                    top: metrics.dayHeaderHeight,
                    bottom: scrollable ? 32 : 0,
                  ),
                  child: SizedBox(
                    key: const ValueKey('weekly-grid'),
                    height: gridHeight,
                    child: _GridBody(
                      agenda: agenda,
                      schedule: schedule,
                      metrics: metrics,
                      sectionCount: sectionCount,
                      typography: typography,
                      layouts: layouts,
                      onCourseTap: onCourseTap,
                      onCourseSourceTap: onCourseSourceTap,
                      onConflictTap: onConflictTap,
                    ),
                  ),
                ),
              ),
            ),
            if (loading) const _LoadingOverlay(),
            if (!loading && errorMessage != null)
              _ErrorOverlay(message: errorMessage!, onRetry: onRetry),
            if (!loading && errorMessage == null && !hasCourses)
              const _EmptyOverlay(),
            // 星期栏是玻璃浮层：课程块滚到它下面时被真实折射。
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: WeekdayHeader(
                agenda: agenda,
                metrics: metrics,
                pulse: todayPulse,
              ),
            ),
          ],
        );
      },
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification ||
        notification is ScrollUpdateNotification) {
      onScrolling?.call(true);
    } else if (notification is ScrollEndNotification) {
      onScrolling?.call(false);
    }
    return false;
  }

  CourseBlockTypography _typography(
    BuildContext context,
    TimetableDensity density,
  ) {
    final palette = AppTheme.paletteOf(context);
    final base = switch (density) {
      TimetableDensity.compact => CourseBlockTypography.compact,
      TimetableDensity.medium => CourseBlockTypography.medium,
      TimetableDensity.expanded => CourseBlockTypography.expanded,
    };
    return base.colored(
      ink: palette.ink,
      secondary: palette.inkSecondary,
      tertiary: palette.inkTertiary,
    );
  }

  int _sectionCount() {
    return SectionCountResolver.resolve(
      schedule,
      courses: agenda.days.expand((day) => day.courses),
    );
  }
}

class _GridBody extends StatelessWidget {
  const _GridBody({
    required this.agenda,
    required this.schedule,
    required this.metrics,
    required this.sectionCount,
    required this.typography,
    required this.layouts,
    required this.onCourseTap,
    this.onCourseSourceTap,
    required this.onConflictTap,
  });

  final WeekAgenda agenda;
  final BellSchedule schedule;
  final TimetableLayoutMetrics metrics;
  final int sectionCount;
  final CourseBlockTypography typography;
  final List<CourseCollisionLayoutResult> layouts;
  final ValueChanged<Course> onCourseTap;
  final void Function(Course, Rect, GlobalKey)? onCourseSourceTap;
  final ValueChanged<List<Course>> onConflictTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dayWidth =
            (constraints.maxWidth - metrics.axisWidth) / agenda.days.length;
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _TimetableGridPainter(
                    palette: AppTheme.paletteOf(context),
                    axisWidth: metrics.axisWidth,
                    sectionHeight: metrics.sectionHeight,
                    sectionCount: sectionCount,
                    todayIndex: agenda.anchorIndex,
                    pairCompactSections: metrics.isCompact,
                  ),
                ),
              ),
            ),
            for (var section = 1; section <= sectionCount; section++)
              if (!metrics.isCompact || section.isOdd)
                Positioned(
                  key: ValueKey('section-axis-$section'),
                  top: (section - 1) * metrics.sectionHeight,
                  left: 0,
                  width: metrics.axisWidth,
                  height:
                      metrics.sectionHeight *
                      (metrics.isCompact && section < sectionCount ? 2 : 1),
                  child: _SectionAxisLabel(
                    section: section,
                    endSection: metrics.isCompact && section < sectionCount
                        ? section + 1
                        : section,
                    spec: schedule.section(section),
                    compact: metrics.isCompact,
                  ),
                ),
            for (var dayIndex = 0; dayIndex < agenda.days.length; dayIndex++)
              ..._courseWidgets(
                context,
                agenda.days[dayIndex],
                layouts[dayIndex],
                dayIndex,
                dayWidth,
              ),
            ?_nowIndicator(context),
          ],
        );
      },
    );
  }

  List<Widget> _courseWidgets(
    BuildContext context,
    WeekAgendaDay day,
    CourseCollisionLayoutResult result,
    int dayIndex,
    double dayWidth,
  ) {
    final widgets = <Widget>[];

    for (final placement in result.placements) {
      // 冲突不再并排：第一门课占满整列（信息完整），其余走 +N 小签。
      if (placement.lane > 0) continue;
      final peers = result.overlapping(placement.course);
      final blockWidth = dayWidth - metrics.courseGap * 2;
      widgets.add(
        Positioned(
          key: ValueKey('course-position-${placement.course.id}'),
          left: metrics.axisWidth + dayIndex * dayWidth + metrics.courseGap,
          top:
              (placement.course.startSection - 1) * metrics.sectionHeight +
              metrics.courseGap,
          width: blockWidth,
          height:
              placement.sectionSpan * metrics.sectionHeight -
              metrics.courseGap * 2,
          child: TimetableCourseBlock(
            course: placement.course,
            schedule: schedule,
            typography: typography,
            density: metrics.density,
            displayWeekday: day.weekday,
            conflictCount: peers.length,
            onConflictTap: () => onConflictTap([placement.course, ...peers]),
            onTap: () => onCourseTap(placement.course),
            onSourceTap: (rect, key) =>
                onCourseSourceTap?.call(placement.course, rect, key),
          ),
        ),
      );
    }
    return widgets;
  }

  Widget? _nowIndicator(BuildContext context) {
    final todayIndex = agenda.anchorIndex;
    if (todayIndex == null) return null;
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    SectionSpec? current;
    for (final spec in schedule.sections) {
      final start = _minutes(spec.start);
      final end = _minutes(spec.end);
      if (start != null &&
          end != null &&
          nowMinutes >= start &&
          nowMinutes <= end) {
        current = spec;
        break;
      }
    }
    if (current == null) return null;
    return Positioned(
      key: const ValueKey('timetable-now-indicator'),
      left: 2,
      width: metrics.axisWidth - 4,
      top: (current.index - 0.5) * metrics.sectionHeight,
      child: IgnorePointer(
        child: Semantics(
          label: '当前第 ${current.index} 节，按学校作息标记',
          child: ExcludeSemantics(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.paletteOf(context).accentSoft,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(
                  '当前\n${current.index}节',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.paletteOf(context).ink,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  int? _minutes(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }
}

class _SectionAxisLabel extends StatelessWidget {
  const _SectionAxisLabel({
    required this.section,
    required this.endSection,
    required this.spec,
    required this.compact,
  });

  final int section;
  final int endSection;
  final SectionSpec? spec;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    return Semantics(
      label: endSection == section
          ? (spec == null ? '第 $section 节' : '第 $section 节，${spec!.start} 开始')
          : '第 $section 至第 $endSection 节${spec == null ? '' : '，${spec!.start} 开始'}',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Column(
            children: [
              Text(
                endSection == section ? '$section' : '$section–$endSection',
                style: TextStyle(
                  fontSize: compact ? 11 : 12.5,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: palette.inkSecondary,
                ),
              ),
              if (spec != null && !compact)
                Text(
                  spec!.start,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: palette.inkTertiary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimetableGridPainter extends CustomPainter {
  const _TimetableGridPainter({
    required this.palette,
    required this.axisWidth,
    required this.sectionHeight,
    required this.sectionCount,
    required this.todayIndex,
    required this.pairCompactSections,
  });

  final AppPalette palette;
  final double axisWidth;
  final double sectionHeight;
  final int sectionCount;
  final int? todayIndex;
  final bool pairCompactSections;

  @override
  void paint(Canvas canvas, Size size) {
    final dayWidth = (size.width - axisWidth) / 7;
    if (todayIndex != null) {
      final rect = Rect.fromLTWH(
        axisWidth + todayIndex! * dayWidth,
        0,
        dayWidth,
        size.height,
      );
      // 今天列：极浅朱砂洗 + 顶部一点点加强，几乎不参与对比度。
      canvas.drawRect(
        rect,
        Paint()..color = palette.accentSoft.withValues(alpha: 0.14),
      );
      canvas.drawRect(
        Rect.fromLTWH(rect.left, 0, rect.width, 26),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              palette.accentSoft.withValues(alpha: 0.4),
              palette.accentSoft.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromLTWH(rect.left, 0, rect.width, 26)),
      );
    }

    final horizontal = Paint()
      ..color = palette.hairline.withValues(alpha: 0.72)
      ..strokeWidth = 1;
    for (var row = 0; row <= sectionCount; row++) {
      if (pairCompactSections && row.isOdd) continue;
      final y = row * sectionHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), horizontal);
    }

    final vertical = Paint()
      ..color = palette.hairline.withValues(alpha: 0.42)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(axisWidth, 0),
      Offset(axisWidth, size.height),
      vertical,
    );
    for (var day = 1; day < 7; day++) {
      final x = axisWidth + day * dayWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), vertical);
    }
  }

  @override
  bool shouldRepaint(covariant _TimetableGridPainter oldDelegate) =>
      oldDelegate.palette != palette ||
      oldDelegate.axisWidth != axisWidth ||
      oldDelegate.sectionHeight != sectionHeight ||
      oldDelegate.sectionCount != sectionCount ||
      oldDelegate.todayIndex != todayIndex ||
      oldDelegate.pairCompactSections != pairCompactSections;
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    return IgnorePointer(
      child: Semantics(
        liveRegion: true,
        label: '正在整理本周课程',
        child: ExcludeSemantics(
          child: Container(
            key: const ValueKey('timetable-loading'),
            color: palette.background.withValues(alpha: 0.54),
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 76),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: palette.accent,
                  ),
                ),
                const SizedBox(width: 10),
                Text('正在整理本周课程', style: TextStyle(color: palette.inkSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorOverlay extends StatelessWidget {
  const _ErrorOverlay({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    return Center(
      child: Container(
        key: const ValueKey('timetable-error'),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.hairline),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '课表暂时没有加载成功',
              style: TextStyle(fontWeight: FontWeight.w700, color: palette.ink),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: palette.inkSecondary),
            ),
            const SizedBox(height: 8),
            GlassButton(
              onPressed: onRetry,
              label: '重试',
              iconColor: palette.accent,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyOverlay extends StatelessWidget {
  const _EmptyOverlay();

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, -0.35),
        child: Container(
          key: const ValueKey('timetable-empty'),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: palette.surface.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.hairline),
          ),
          child: Text(
            '本周暂无课程',
            style: TextStyle(fontSize: 13, color: palette.inkSecondary),
          ),
        ),
      ),
    );
  }
}
