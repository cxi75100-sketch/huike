import 'package:flutter/material.dart';

/// Shared course hues for chips and opaque, single-color timetable cards.
/// Names keep a stable hash; display colors are resolved from the shared palette.
class CourseTint {
  const CourseTint({
    required this.chip,
    required this.onChip,
    required this.card,
    required this.onCard,
  });

  /// 小签底色。
  final Color chip;

  /// 小签上的文字色。
  final Color onChip;
  final Color card;
  final Color onCard;
}

const List<(int, int)> _courseColors = [
  (0xFFEAB8B8, 0xFF602E2E), // coral
  (0xFFEACBB8, 0xFF60412E), // apricot
  (0xFFEADEB8, 0xFF60542E), // amber
  (0xFFE4EAB8, 0xFF5A602E), // lemon
  (0xFFD1EAB8, 0xFF47602E), // lime
  (0xFFBEEAB8, 0xFF35602E), // green
  (0xFFB8EAC4, 0xFF2E603B), // mint
  (0xFFB8EAD7, 0xFF2E604E), // sea green
  (0xFFB8EAEA, 0xFF2E6060), // teal
  (0xFFB8D7EA, 0xFF2E4E60), // sky
  (0xFFB8C4EA, 0xFF2E3B60), // blue
  (0xFFBEB8EA, 0xFF352E60), // indigo
  (0xFFD1B8EA, 0xFF472E60), // violet
  (0xFFE4B8EA, 0xFF5A2E60), // orchid
  (0xFFEAB8DE, 0xFF602E54), // rose
  (0xFFEAB8CB, 0xFF602E41), // berry
];

CourseTint courseTint(int colorKey, Brightness brightness) {
  final (light, dark) = _courseColors[colorKey.abs() % _courseColors.length];
  if (brightness == Brightness.dark) {
    // 夜间：签底用同色相深调压暗，文字用提亮同色相，保证深底可读。
    final hue = Color(dark);
    final hsl = HSLColor.fromColor(hue);
    final onChip = hsl.withLightness(0.82).toColor();
    return CourseTint(
      chip: Color(dark).withValues(alpha: 0.9),
      onChip: onChip,
      card: Color(dark),
      onCard: const Color(0xFFF3F6FA),
    );
  }
  return CourseTint(
    chip: Color(light).withValues(alpha: 0.13),
    onChip: Color(dark),
    card: Color(light),
    onCard: const Color(0xFF172033),
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
