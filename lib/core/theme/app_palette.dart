import 'package:flutter/material.dart';

/// Shared light and graphite palettes for the glass system.
class AppPalette {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.ink,
    required this.inkSecondary,
    required this.inkTertiary,
    required this.hairline,
    required this.hairlineStrong,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.danger,
  });

  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color ink;
  final Color inkSecondary;
  final Color inkTertiary;
  final Color hairline;
  final Color hairlineStrong;
  final Color accent;
  final Color onAccent;
  final Color accentSoft;
  final Color danger;

  static const light = AppPalette(
    background: Color(0xFFF5F6F9),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEDEEF2),
    ink: Color(0xFF17191F),
    inkSecondary: Color(0xFF5D616C),
    inkTertiary: Color(0xFF848995),
    hairline: Color(0xFFDDE0E7),
    hairlineStrong: Color(0xFFC3C8D2),
    accent: Color(0xFF007AFF),
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFDEECFF),
    danger: Color(0xFFD92D3A),
  );

  static const dark = AppPalette(
    background: Color(0xFF111319),
    surface: Color(0xFF252830),
    surfaceAlt: Color(0xFF2E323C),
    ink: Color(0xFFF4F5F8),
    inkSecondary: Color(0xFFB8BDC8),
    inkTertiary: Color(0xFF8D93A1),
    hairline: Color(0xFF363B47),
    hairlineStrong: Color(0xFF555C69),
    accent: Color(0xFF62A7FF),
    onAccent: Color(0xFF071D39),
    accentSoft: Color(0xFF1B354F),
    danger: Color(0xFFFF777F),
  );
}
