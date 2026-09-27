import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_theme.dart';

/// LEVEL 0 环境底色。
///
/// Subtle ambient light gives translucent surfaces something to transmit.
class AmbientBackdrop extends StatelessWidget {
  const AmbientBackdrop({super.key, required this.child, this.accentBloom = 1});

  final Widget child;
  final double accentBloom;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(
      painter: _AmbientPainter(
        palette: palette,
        dark: dark,
        bloom: accentBloom,
      ),
      child: child,
    );
  }
}

class _AmbientPainter extends CustomPainter {
  const _AmbientPainter({
    required this.palette,
    required this.dark,
    required this.bloom,
  });

  final AppPalette palette;
  final bool dark;
  final double bloom;

  static const _coolLight = Color(0xFFE8EEFA);
  static const _warmLight = Color(0xFFF9F5F0);
  static const _coolDark = Color(0xFF1A263A);
  static const _warmDark = Color(0xFF272228);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final background = palette.background;

    canvas.drawRect(rect, Paint()..color = background);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: const Alignment(0.65, 0.75),
          colors: [
            (dark ? _coolDark : _coolLight).withValues(
              alpha: dark ? 0.9 : 0.95,
            ),
            background.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomRight,
          end: const Alignment(0.3, 0.4),
          colors: [
            (dark ? _warmDark : _warmLight).withValues(
              alpha: dark ? 0.85 : 0.9,
            ),
            background.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );

    final accent = palette.accent;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.85, -0.95),
          radius: 1.05,
          colors: [
            accent.withValues(alpha: (dark ? 0.1 : 0.055) * bloom),
            accent.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _AmbientPainter old) =>
      old.palette != palette || old.dark != dark || old.bloom != bloom;
}
