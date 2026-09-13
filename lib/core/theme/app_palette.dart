import 'package:flutter/material.dart';

/// 「新历书」设计语言调色板。
///
/// 规则（见 knowledge/design.md）：
/// - 全 App 只有一个强调色：朱砂。不再引入第二种饱和色。
/// - 中性色是墨与纸：日间冷纸白，夜间深墨蓝黑，均不用纯黑/纯白。
/// - 结构靠发丝线（hairline）而不是卡片堆叠。
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
    background: Color(0xFFFAFAF8),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF1F0EC),
    ink: Color(0xFF1D1C19),
    inkSecondary: Color(0xFF63615B),
    inkTertiary: Color(0xFF8F8D86),
    hairline: Color(0xFFDEDCD5),
    hairlineStrong: Color(0xFFC4C2BA),
    accent: Color(0xFFC3402B),
    onAccent: Color(0xFFFFF8F5),
    accentSoft: Color(0xFFF7E5E0),
    danger: Color(0xFFA63A22),
  );

  static const dark = AppPalette(
    background: Color(0xFF151418),
    surface: Color(0xFF1E1D22),
    surfaceAlt: Color(0xFF26252B),
    ink: Color(0xFFE9E7E2),
    inkSecondary: Color(0xFFA5A39D),
    inkTertiary: Color(0xFF7B7974),
    hairline: Color(0xFF37363C),
    hairlineStrong: Color(0xFF4A4950),
    accent: Color(0xFFE0604A),
    onAccent: Color(0xFF1C0E0A),
    accentSoft: Color(0xFF3A2621),
    danger: Color(0xFFE4796A),
  );
}
