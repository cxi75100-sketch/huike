import 'package:flutter/material.dart';

import '../../../core/glass/press_physics.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/course_colors.dart';
import '../../../models/bell_schedule.dart';
import '../../../models/course.dart';
import '../../../services/calendar_exception_service.dart';
import '../../../services/course_time_service.dart';
import '../models/course_block_layout.dart';
import '../models/timetable_layout.dart';
import '../services/weekly_location_formatter.dart';

/// 网格里的课程块。
///
/// 一体化轻量玻璃轮廓；课程颜色融入整面 tint、环境高光与细边缘，
/// 不划分独立装饰区域，不逐卡模糊。
///
/// 高度由固定网格决定。内部按名称、紧凑地点、教师分配文字空间，
/// 不显示时间，也不让内容反向扩大网格行高。
class TimetableCourseBlock extends StatefulWidget {
  const TimetableCourseBlock({
    super.key,
    required this.course,
    required this.schedule,
    required this.typography,
    required this.density,
    required this.displayWeekday,
    required this.onTap,
    this.onSourceTap,
    this.conflictCount = 0,
    this.onConflictTap,
  });

  final Course course;
  final BellSchedule schedule;
  final CourseBlockTypography typography;
  final TimetableDensity density;
  final int displayWeekday;

  /// 同一时段还有别的课：块顶会有一条 `+N` 小签，文字让出它的高度。
  final int conflictCount;
  final VoidCallback? onConflictTap;

  final VoidCallback onTap;
  final ValueChanged<Rect>? onSourceTap;

  bool get _conflicted => conflictCount > 0;

  @override
  State<TimetableCourseBlock> createState() => _TimetableCourseBlockState();
}

class _TimetableCourseBlockState extends State<TimetableCourseBlock> {
  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    final brightness = Theme.of(context).brightness;
    final dark = brightness == Brightness.dark;
    final tint = courseTint(widget.course.colorKey, brightness);
    final glassTint = HSLColor.fromColor(tint.onChip)
        .withSaturation(0.70)
        .withLightness(dark ? 0.58 : 0.46)
        .toColor();
    final compact = widget.density == TimetableDensity.compact;
    final baseTypography = widget._conflicted
        ? widget.typography.withConflictBadge()
        : widget.typography;
    // Stronger course hues need stronger small text, without changing size.
    final typography = baseTypography.colored(
      ink: baseTypography.nameStyle.color ?? palette.ink,
      secondary: Color.lerp(palette.inkSecondary, palette.ink, 0.5)!,
      tertiary: baseTypography.timeStyle.color ?? palette.inkTertiary,
    );
    final range = const CourseTimeService().resolve(
      widget.course,
      widget.schedule,
    );
    final content = typography.contentOf(
      name: widget.course.name,
      classroom: compactWeeklyLocation(widget.course.classroom),
      teacher: widget.course.teacher,
      range: null,
      stackedTime: compact,
    );
    final radius = compact ? 8.0 : 11.0;

    return Semantics(
      button: true,
      label: _semanticsLabel(range),
      onTap: () => _handleTap(context),
      child: ExcludeSemantics(
        child: PressPhysics(
          onTap: () => _handleTap(context),
          child: _BlockBody(
            content: content,
            conflictCount: widget._conflicted ? widget.conflictCount : null,
            onConflictTap: widget.onConflictTap,
          ),
          builder: (context, press, touch, child) {
            return Transform.scale(
              scale: 1 - 0.024 * press,
              child: DecoratedBox(
                key: ValueKey('course-block-${widget.course.id}'),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.alphaBlend(
                        glassTint.withValues(
                          alpha: (dark ? 0.16 : 0.10) + 0.015 * press,
                        ),
                        Color.lerp(
                          palette.surface,
                          Colors.white,
                          0.08,
                        )!.withValues(alpha: 0.76),
                      ),
                      Color.alphaBlend(
                        glassTint.withValues(
                          alpha: (dark ? 0.12 : 0.08) + 0.010 * press,
                        ),
                        palette.surface.withValues(alpha: 0.64),
                      ),
                      Color.alphaBlend(
                        glassTint.withValues(
                          alpha: (dark ? 0.14 : 0.09) + 0.010 * press,
                        ),
                        palette.surface.withValues(alpha: 0.70),
                      ),
                    ],
                    stops: const [0, 0.6, 1],
                  ),
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: Color.alphaBlend(
                      glassTint.withValues(alpha: 0.06),
                      Color.lerp(palette.hairlineStrong, Colors.white, 0.45)!,
                    ).withValues(alpha: (dark ? 0.38 : 0.72) + 0.04 * press),
                    width: 0.9,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: dark ? 0.20 : 0.06),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                    BoxShadow(
                      color: tint.onChip.withValues(
                        alpha: (dark ? 0.015 : 0.008) + 0.005 * press,
                      ),
                      blurRadius: 5,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    final render = context.findRenderObject();
    if (render is RenderBox && render.hasSize) {
      widget.onSourceTap?.call(render.localToGlobal(Offset.zero) & render.size);
    }
    widget.onTap();
  }

  String _semanticsLabel((String, String)? range) {
    final course = widget.course;
    final parts = <String>[
      course.name,
      CalendarExceptionService.weekdayName(widget.displayWeekday),
      sectionRangeLabel(course),
      if (range != null) '${range.$1}至${range.$2}',
      if (course.classroom.isNotEmpty) course.classroom,
      if (course.teacher.isNotEmpty) course.teacher,
    ];
    return parts.join('，');
  }
}

/// Measure within the fixed block; reserve a line per field before wrapping.
class _BlockBody extends StatelessWidget {
  const _BlockBody({
    required this.content,
    this.conflictCount,
    this.onConflictTap,
  });

  final CourseBlockContent content;
  final int? conflictCount;
  final VoidCallback? onConflictTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, bounds) {
        final scaler = MediaQuery.textScalerOf(context);
        final top = conflictCount == null ? 4.0 : 17.0;
        final available = (bounds.maxHeight - top - 2).clamp(
          0.0,
          double.infinity,
        );
        final width = (bounds.maxWidth - 2).clamp(1.0, double.infinity);
        final counts = <int>[];
        final heights = <double>[];
        final desired = <int>[];
        final styles = <TextStyle>[];
        for (final line in content.lines) {
          final style = DefaultTextStyle.of(context).style.merge(line.style);
          styles.add(style);
          final painter = TextPainter(
            text: TextSpan(text: line.text, style: style),
            textDirection: Directionality.of(context),
            textScaler: scaler,
          )..layout(maxWidth: width);
          final rows = painter.computeLineMetrics();
          heights.add(
            rows.fold<double>(0, (h, row) => h > row.height ? h : row.height),
          );
          desired.add(rows.length);
          painter.dispose();
        }
        var used = 0.0;
        for (var i = 0; i < heights.length; i++) {
          final cost = heights[i] + (i == 0 ? 0 : content.gap);
          final fits =
              counts.every((count) => count > 0) && used + cost <= available;
          counts.add(fits ? 1 : 0);
          if (fits) used += cost;
        }
        // Complete the room and teacher before giving the remaining lines
        // to a long title; all fields have their first line reserved.
        for (final i in [
          if (counts.length > 1) 1,
          if (counts.length > 2) 2,
          if (counts.isNotEmpty) 0,
        ]) {
          final limit = i == 0 ? 4 : desired[i];
          while (counts[i] > 0 &&
              counts[i] < desired[i] &&
              counts[i] < limit &&
              used + heights[i] <= available) {
            counts[i]++;
            used += heights[i];
          }
        }
        return Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(1, top, 1, 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < counts.length; i++)
                    if (counts[i] > 0) ...[
                      if (i > 0) SizedBox(height: content.gap),
                      SizedBox(
                        height: heights[i] * counts[i],
                        child: Text(
                          content.lines[i].text,
                          style: styles[i],
                          maxLines: counts[i],
                          overflow: TextOverflow.fade,
                          softWrap: true,
                        ),
                      ),
                    ],
                ],
              ),
            ),
            if (conflictCount != null)
              Positioned(
                left: 3,
                right: 1,
                top: 1,
                height: 13,
                child: TimetableConflictIndicator(
                  count: conflictCount!,
                  onTap: onConflictTap ?? () {},
                ),
              ),
          ],
        );
      },
    );
  }
}

/// 多路冲突时的 `+N` 入口：同一套按压物理，不是 InkWell。
///
/// 七列手机宽度下把课程列劈成两半会让两边都无法排下中文，
/// 因此冲突改为「一门课全宽完整显示 + 这枚小签进全部课程」，不做并排。
class TimetableConflictIndicator extends StatefulWidget {
  const TimetableConflictIndicator({
    super.key,
    required this.count,
    required this.onTap,
  });

  final int count;
  final VoidCallback onTap;

  @override
  State<TimetableConflictIndicator> createState() =>
      _TimetableConflictIndicatorState();
}

class _TimetableConflictIndicatorState
    extends State<TimetableConflictIndicator> {
  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    return Semantics(
      button: true,
      label: '还有 ${widget.count} 门冲突课程，点按查看',
      onTap: widget.onTap,
      child: ExcludeSemantics(
        child: PressPhysics(
          onTap: widget.onTap,
          builder: (context, press, touch, child) => Transform.scale(
            scale: 1 - 0.04 * press,
            child: DecoratedBox(
              key: const ValueKey('course-conflict-indicator'),
              decoration: BoxDecoration(
                color: palette.accentSoft.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: palette.accent.withValues(alpha: 0.32 + 0.3 * press),
                ),
              ),
              child: Center(
                child: Text(
                  '+${widget.count}',
                  style: TextStyle(
                    fontSize: 9,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: palette.accent,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
