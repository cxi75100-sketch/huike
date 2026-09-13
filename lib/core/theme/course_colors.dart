import 'package:flutter/material.dart';

/// 课程签色：低饱和的编辑排印色板，只用在小块面（时间签、角标），
/// 不做整卡铺色。index 由课程名散列得到，同一课程永远同色。
class CourseTint {
  const CourseTint({required this.chip, required this.onChip});

  /// 小签底色。
  final Color chip;

  /// 小签上的文字色。
  final Color onChip;
}

const List<(int, int)> _courseColors = [
  (0xFFC3402B, 0xFF3A0E06), // 赤
  (0xFF2E6E63, 0xFF062A23), // 青
  (0xFF3D5A80, 0xFF0A1626), // 黛
  (0xFF96650F, 0xFF2A1B02), // 赭
  (0xFF6E5A7E, 0xFF1D1326), // 藤
  (0xFF5F7036, 0xFF161F04), // 苔
  (0xFF47698C, 0xFF0A1B2B), // 石
  (0xFF8E3B56, 0xFF2B0A14), // 绛
];

CourseTint courseTint(int colorKey, Brightness brightness) {
  final (light, dark) = _courseColors[colorKey.abs() % _courseColors.length];
  if (brightness == Brightness.dark) {
    // 夜间：签底用同色相深调压暗，文字用提亮同色相，保证深底可读。
    final hue = Color(light);
    final hsl = HSLColor.fromColor(hue);
    final onChip = hsl
        .withLightness((hsl.lightness + 0.3).clamp(0.0, 0.86))
        .toColor();
    return CourseTint(chip: Color(dark).withValues(alpha: 0.9), onChip: onChip);
  }
  return CourseTint(
    chip: Color(light).withValues(alpha: 0.13),
    onChip: Color(light),
  );
}

int colorKeyForName(String name) {
  var hash = 0x811c9dc5;
  for (final code in name.codeUnits) {
    hash ^= code;
    hash = (hash * 0x01000193) & 0x7FFFFFFF;
  }
  return hash;
}
