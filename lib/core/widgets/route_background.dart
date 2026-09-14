import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 「汇课」的低噪声校园线路背景。
///
/// 只承担空间层次，不承载交互与语义；两条线路与少量站点呼应课表的
/// 时间路径。透明度刻意压低，避免重复纹理抢夺课程内容。
class RouteBackground extends StatelessWidget {
  const RouteBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.surfaceAlt, palette.background],
          stops: const [0, 0.38],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ExcludeSemantics(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _RouteBackgroundPainter(
                  line: palette.accent.withValues(alpha: 0.065),
                  station: palette.inkTertiary.withValues(alpha: 0.10),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// 小型线路标记，可放在标题卡或详情头卡中作为品牌元素。
class RouteMark extends StatelessWidget {
  const RouteMark({super.key, this.height = 22, this.activeIndex = 2});

  final double height;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        child: CustomPaint(
          painter: _RouteMarkPainter(
            line: palette.hairlineStrong,
            active: palette.accent,
            surface: palette.surface,
            activeIndex: activeIndex.clamp(0, 3),
          ),
        ),
      ),
    );
  }
}

class _RouteMarkPainter extends CustomPainter {
  const _RouteMarkPainter({
    required this.line,
    required this.active,
    required this.surface,
    required this.activeIndex,
  });

  final Color line;
  final Color active;
  final Color surface;
  final int activeIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    const inset = 6.0;
    canvas.drawLine(
      Offset(inset, y),
      Offset(size.width - inset, y),
      Paint()
        ..color = line
        ..strokeWidth = 1.5,
    );
    for (var index = 0; index < 4; index++) {
      final x = inset + (size.width - inset * 2) * index / 3;
      final selected = index == activeIndex;
      canvas.drawCircle(
        Offset(x, y),
        selected ? 5 : 3.5,
        Paint()
          ..color = selected ? active : surface
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(x, y),
        selected ? 5 : 3.5,
        Paint()
          ..color = selected ? active : line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RouteMarkPainter oldDelegate) =>
      line != oldDelegate.line ||
      active != oldDelegate.active ||
      surface != oldDelegate.surface ||
      activeIndex != oldDelegate.activeIndex;
}

class _RouteBackgroundPainter extends CustomPainter {
  const _RouteBackgroundPainter({required this.line, required this.station});

  final Color line;
  final Color station;

  @override
  void paint(Canvas canvas, Size size) {
    final routePaint = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final stationPaint = Paint()
      ..color = station
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final upper = Path()
      ..moveTo(-24, size.height * 0.19)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.10,
        size.width * 0.62,
        size.height * 0.30,
        size.width + 28,
        size.height * 0.17,
      );
    final lower = Path()
      ..moveTo(-32, size.height * 0.76)
      ..cubicTo(
        size.width * 0.30,
        size.height * 0.62,
        size.width * 0.62,
        size.height * 0.91,
        size.width + 36,
        size.height * 0.72,
      );
    canvas.drawPath(upper, routePaint);
    canvas.drawPath(lower, routePaint);

    for (final point in <Offset>[
      Offset(size.width * 0.12, size.height * 0.16),
      Offset(size.width * 0.38, size.height * 0.19),
      Offset(size.width * 0.72, size.height * 0.22),
      Offset(size.width * 0.18, size.height * 0.70),
      Offset(size.width * 0.50, size.height * 0.76),
      Offset(size.width * 0.82, size.height * 0.78),
    ]) {
      canvas.drawCircle(point, 3.5, stationPaint);
      canvas.drawCircle(point, 1.1, Paint()..color = station);
    }
  }

  @override
  bool shouldRepaint(covariant _RouteBackgroundPainter oldDelegate) =>
      line != oldDelegate.line || station != oldDelegate.station;
}
