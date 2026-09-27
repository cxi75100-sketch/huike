import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/glass/glass_button.dart';
import '../../../core/glass/glass_motion.dart';
import '../../../core/glass/glass_sheet.dart';
import '../../../core/glass/glass_surface.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/semester.dart';
import '../../../services/semester_service.dart';
import 'week_swipe.dart';

/// 周导航玻璃 island。
///
/// 左右箭头、周次、日期范围是**同一块玻璃**：不是「左边一个按钮 + 中间一张卡 +
/// 右边一个按钮」。切周时它还跟着手势走：拖动方向会让高光偏移、强度上升，
/// 松手回位后高光淡回左上。
class WeekNavigation extends StatefulWidget {
  const WeekNavigation({
    super.key,
    required this.semester,
    required this.week,
    required this.currentWeek,
    required this.onPrevious,
    required this.onNext,
    required this.onCurrent,
    required this.onSemesterProgress,
    this.swipe,
  });

  final Semester semester;
  final int week;
  final int currentWeek;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onCurrent;
  final VoidCallback onSemesterProgress;
  final WeekSwipeState? swipe;

  @override
  State<WeekNavigation> createState() => _WeekNavigationState();
}

class _WeekNavigationState extends State<WeekNavigation> {
  final _press = ValueNotifier<double>(0);
  final _highlight = ValueNotifier<Alignment>(GlassSurface.restHighlight);

  @override
  void initState() {
    super.initState();
    widget.swipe?.addListener(_syncSwipe);
  }

  @override
  void didUpdateWidget(covariant WeekNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.swipe != widget.swipe) {
      oldWidget.swipe?.removeListener(_syncSwipe);
      widget.swipe?.addListener(_syncSwipe);
    }
  }

  @override
  void dispose() {
    widget.swipe?.removeListener(_syncSwipe);
    _press.dispose();
    _highlight.dispose();
    super.dispose();
  }

  /// 手势方向 → 玻璃状态：往哪边拉，高光就往哪边偏一点、亮一点。
  void _syncSwipe() {
    final offset = widget.swipe?.offset ?? 0;
    final magnitude = math.min(1.0, offset.abs());
    _press.value = magnitude;
    _highlight.value = Alignment(
      GlassSurface.restHighlight.x - offset * 0.85,
      GlassSurface.restHighlight.y + magnitude * 0.2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = const SemesterService();
    final monday = service.weekMonday(widget.semester, widget.week);
    final sunday = monday.add(const Duration(days: 6));
    final range =
        '${monday.month}.${monday.day} – ${sunday.month}.${sunday.day}';
    final isCurrent = widget.week == widget.currentWeek;

    return GlassSurface(
      radius: 18,
      intensity: GlassIntensity.regular,
      blurSigma: 18,
      depth: 1.4,
      pressDriver: _press,
      touchDriver: _highlight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          children: [
            GlassButton.icon(
              icon: Icons.chevron_left_rounded,
              tooltip: '上一周',
              semanticLabel: '上一周',
              onPressed: widget.onPrevious,
              size: 34,
              iconSize: 22,
              depth: 0.15,
            ),
            Expanded(
              child: Semantics(
                button: true,
                label:
                    '第 ${widget.week} 周，$range。'
                    '${isCurrent ? '' : '点按回本周，'}长按查看学期进度',
                onTap: isCurrent ? null : widget.onCurrent,
                onLongPress: () {
                  HapticFeedback.selectionClick();
                  widget.onSemesterProgress();
                },
                child: ExcludeSemantics(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: isCurrent
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            widget.onCurrent();
                          },
                    onLongPress: () {
                      HapticFeedback.selectionClick();
                      widget.onSemesterProgress();
                    },
                    child: _WeekLabel(
                      week: widget.week,
                      range: range,
                      isCurrent: isCurrent,
                    ),
                  ),
                ),
              ),
            ),
            GlassButton.icon(
              icon: Icons.chevron_right_rounded,
              tooltip: '下一周',
              semanticLabel: '下一周',
              onPressed: widget.onNext,
              size: 34,
              iconSize: 22,
              depth: 0.15,
            ),
          ],
        ),
      ),
    );
  }
}

/// 周次与日期：换周时旧值滑出、新值从切周方向滑入（14dp）。
///
/// 不做整页飞行，也不让数字瞬间跳变——空间连续性只体现在这一小段位移里。
class _WeekLabel extends StatefulWidget {
  const _WeekLabel({
    required this.week,
    required this.range,
    required this.isCurrent,
  });

  final int week;
  final String range;
  final bool isCurrent;

  @override
  State<_WeekLabel> createState() => _WeekLabelState();
}

class _WeekLabelState extends State<_WeekLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: GlassMotion.weekLabel,
    value: 1,
  );

  late int _previousWeek = widget.week;
  late String _previousRange = widget.range;
  late bool _previousCurrent = widget.isCurrent;
  var _direction = 1;

  @override
  void didUpdateWidget(covariant _WeekLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.week == widget.week) return;
    _previousWeek = oldWidget.week;
    _previousRange = oldWidget.range;
    _previousCurrent = oldWidget.isCurrent;
    _direction = widget.week > oldWidget.week ? 1 : -1;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(_controller.value);
        return ClipRect(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (t < 1)
                  _content(
                    palette: palette,
                    week: _previousWeek,
                    range: _previousRange,
                    isCurrent: _previousCurrent,
                    opacity: 1 - t,
                    dx: -_direction * 14 * t,
                  ),
                _content(
                  palette: palette,
                  week: widget.week,
                  range: widget.range,
                  isCurrent: widget.isCurrent,
                  opacity: t,
                  dx: _direction * 14 * (1 - t),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _content({
    required AppPalette palette,
    required int week,
    required String range,
    required bool isCurrent,
    required double opacity,
    required double dx,
  }) {
    return Transform.translate(
      offset: Offset(dx, 0),
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '第 $week 周',
              style: TextStyle(
                fontSize: 16,
                height: 1.15,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: palette.ink,
              ),
            ),
            Text(
              isCurrent ? range : '$range · 点按回本周',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.2,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: isCurrent ? palette.inkTertiary : palette.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 长按周次弹出的学期进度：仍然是玻璃材质，但不抢手势进度。
Future<void> showSemesterProgressSheet({
  required BuildContext context,
  required Semester semester,
  required int week,
}) {
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.24),
    sheetAnimationStyle: reduceMotion
        ? AnimationStyle.noAnimation
        : const AnimationStyle(
            duration: GlassMotion.slow,
            reverseDuration: GlassMotion.standard,
            curve: GlassMotion.enter,
            reverseCurve: GlassMotion.exit,
          ),
    builder: (sheetContext) => GlassSheetPanel(
      maxHeightFactor: 0.5,
      child: _SemesterProgressBody(semester: semester, week: week),
    ),
  );
}

class _SemesterProgressBody extends StatelessWidget {
  const _SemesterProgressBody({required this.semester, required this.week});

  final Semester semester;
  final int week;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    final reading = const SemesterService().readingProgress(
      semester,
      week,
      DateTime.now(),
    );
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 6),
          Text(
            '$week',
            style: TextStyle(
              fontSize: 54,
              height: 1,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: palette.accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '第 $week / ${semester.totalWeeks} 周',
            style: TextStyle(color: palette.inkSecondary),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: reading.progress,
              minHeight: 6,
              backgroundColor: palette.surfaceAlt,
              color: palette.accent,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            reading.mark,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: palette.accent,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
