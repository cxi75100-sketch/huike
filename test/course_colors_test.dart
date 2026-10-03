import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huike_timetable/core/theme/course_colors.dart';

void main() {
  for (final brightness in Brightness.values) {
    test('course colors cover warm and cool hue sectors: $brightness', () {
      final sectors = <int>{};
      for (var key = 0; key < 16; key++) {
        final hue = HSLColor.fromColor(courseTint(key, brightness).card).hue;
        sectors.add((hue / 45).floor() % 8);
      }
      expect(sectors, hasLength(8));
    });
    test('16 distinct opaque course fills with readable text: $brightness', () {
      final colors = <Color>{};
      for (var key = 0; key < 16; key++) {
        final tint = courseTint(key, brightness);
        colors.add(tint.card);
        expect(tint.card.a, 1);
        final foreground = tint.onCard.computeLuminance();
        final background = tint.card.computeLuminance();
        final lighter = foreground > background ? foreground : background;
        final darker = foreground < background ? foreground : background;
        expect((lighter + 0.05) / (darker + 0.05), greaterThanOrEqualTo(4.5));
        expect(courseTint(key, brightness).card, tint.card);
      }
      expect(colors, hasLength(16));
      expect(courseTint(-3, brightness).card, courseTint(3, brightness).card);
    });
  }
}
