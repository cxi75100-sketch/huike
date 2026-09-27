import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/glass/glass_surface.dart';
import '../../../core/glass/glass_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../models/timetable_layout.dart';
import '../services/week_agenda.dart';

/// 星期栏（sticky）。
///
/// 属于玻璃浮层而不是表格表头：半透明材质 + 模糊，课程块从它下面滑过时
/// 会被真正折射。今天用一枚小型「液体选择器」表达——日期数字落在一个
/// 圆角胶囊里，而不是整列刷粉红。
///
/// [pulse] 被通知时选择器做一次很轻的缩放起伏（回本周时用），
/// 只播一次，不做循环呼吸动画。
class WeekdayHeader extends StatefulWidget {
  const WeekdayHeader({
    super.key,
    required this.agenda,
    required this.metrics,
    this.pulse,
  });

  final WeekAgenda agenda;
  final TimetableLayoutMetrics metrics;
  final Listenable? pulse;

  @override
  State<WeekdayHeader> createState() => _WeekdayHeaderState();
}

class _WeekdayHeaderState extends State<WeekdayHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: GlassMotion.todayPulse,
  );

  @override
  void initState() {
    super.initState();
    widget.pulse?.addListener(_playPulse);
  }

  @override
  void didUpdateWidget(covariant WeekdayHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pulse != widget.pulse) {
      oldWidget.pulse?.removeListener(_playPulse);
      widget.pulse?.addListener(_playPulse);
    }
  }

  @override
  void dispose() {
    widget.pulse?.removeListener(_playPulse);
    _pulse.dispose();
    super.dispose();
  }

  void _playPulse() {
    if (!mounted || _pulse.isAnimating) return;
    if (MediaQuery.disableAnimationsOf(context)) return;
    if (widget.agenda.anchorIndex == null) return;
    _pulse.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    final metrics = widget.metrics;
    final compact = metrics.isCompact;

    return GlassSurface(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      intensity: GlassIntensity.subtle,
      blurSigma: 12,
      depth: 0.8,
      child: SizedBox(
        key: const ValueKey('weekday-header'),
        height: metrics.dayHeaderHeight,
        child: Row(
          children: [
            SizedBox(
              width: metrics.axisWidth,
              child: Center(
                child: Text(
                  '节',
                  style: TextStyle(fontSize: 10, color: palette.inkTertiary),
                ),
              ),
            ),
            for (final day in widget.agenda.days)
              Expanded(
                child: Semantics(
                  header: true,
                  label:
                      '${day.weekdayLabel}，${day.date.month}月${day.date.day}日'
                      '${day.isToday ? '，今天' : ''}'
                      '${day.suspended ? '，停课' : ''}'
                      '${day.isMakeup ? '，${day.makeupLabel}' : ''}',
                  child: ExcludeSemantics(
                    child: Container(
                      key: ValueKey('weekday-${day.weekday}'),
                      margin: EdgeInsets.symmetric(
                        horizontal: compact ? 0.5 : 3,
                        vertical: 4,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            compact
                                ? day.weekdayLabel.substring(1)
                                : day.weekdayLabel,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: compact ? 10 : 12,
                              height: 1.1,
                              fontWeight: FontWeight.w600,
                              color: day.isToday
                                  ? palette.accent
                                  : palette.inkSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          _DayNumber(day: day, compact: compact, pulse: _pulse),
                          if (day.suspended || day.isMakeup)
                            Text(
                              day.suspended
                                  ? (compact ? '休' : '停课')
                                  : (compact ? '调' : '调休'),
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 9.5,
                                height: 1.05,
                                color: palette.accent,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 日期数字：今天落在一枚液体选择器里。
class _DayNumber extends StatelessWidget {
  const _DayNumber({
    required this.day,
    required this.compact,
    required this.pulse,
  });

  final WeekAgendaDay day;
  final bool compact;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    final number = Text(
      '${day.date.day}',
      style: TextStyle(
        fontSize: compact ? 13 : 15,
        height: 1,
        fontFeatures: const [FontFeature.tabularFigures()],
        fontWeight: day.isToday ? FontWeight.w800 : FontWeight.w600,
        color: day.isToday ? palette.accent : palette.ink,
      ),
    );

    if (!day.isToday) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: number,
      );
    }

    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        // 一次性的柔和起伏：0 → 峰值 → 0，不做循环呼吸。
        final swell = 1 + 0.11 * math.sin(math.pi * pulse.value);
        return Transform.scale(scale: swell, child: child);
      },
      child: Container(
        key: const ValueKey('today-selector'),
        width: compact ? 24 : 28,
        height: compact ? 20 : 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.accentSoft.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(compact ? 8 : 10),
          border: Border.all(color: palette.accent.withValues(alpha: 0.32)),
        ),
        child: number,
      ),
    );
  }
}

/// 一次性的「回本周」脉冲：只在需要时触发，不做常驻动画。
class TodayPulse extends ChangeNotifier {
  void fire() => notifyListeners();
}
