import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huike_timetable/core/theme/app_theme.dart';
import 'package:huike_timetable/features/timetable/models/course_block_layout.dart';
import 'package:huike_timetable/features/timetable/models/timetable_layout.dart';
import 'package:huike_timetable/features/timetable/widgets/timetable_course_block.dart';
import 'package:huike_timetable/models/bell_schedule.dart';
import 'package:huike_timetable/models/course.dart';

void main() {
  Future<void> pumpBlock(
    WidgetTester tester, {
    double height = 100,
    bool dark = false,
    String room = '九龙湖校区明志楼404',
    String teacher = '张冠男',
    int colorKey = 0,
  }) async {
    final theme = dark ? AppTheme.dark() : AppTheme.light();
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 48,
              height: height,
              child: TimetableCourseBlock(
                course: Course(
                  id: 'qa',
                  schoolId: 's',
                  semesterId: 't',
                  name: '大学英语III',
                  weekday: 1,
                  startSection: 1,
                  endSection: height < 60 ? 1 : 2,
                  classroom: room,
                  teacher: teacher,
                  startTime: '08:20',
                  endTime: '09:50',
                  weeks: [1],
                  colorKey: colorKey,
                ),
                schedule: BellSchedule.fallback(),
                typography: CourseBlockTypography.compact.colored(
                  ink: theme.colorScheme.onSurface,
                  secondary: theme.colorScheme.onSurfaceVariant,
                  tertiary: theme.colorScheme.onSurfaceVariant,
                ),
                density: TimetableDensity.compact,
                displayWeekday: 1,
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final dark in [false, true]) {
    testWidgets(
      'small text keeps contrast across sixteen solid colors in ${dark ? "dark" : "light"}',
      (tester) async {
        void checkContrast() {
          final decoration =
              tester
                      .widget<DecoratedBox>(
                        find.byKey(const ValueKey('course-block-qa')),
                      )
                      .decoration
                  as BoxDecoration;
          final textColor = tester.widget<Text>(find.text('张冠男')).style!.color!;
          expect(decoration.gradient, isNull);
          final surface = decoration.color!;
          expect(surface.a, 1);
          final a = textColor.computeLuminance();
          final b = surface.computeLuminance();
          final ratio = a > b
              ? (a + 0.05) / (b + 0.05)
              : (b + 0.05) / (a + 0.05);
          expect(ratio, greaterThanOrEqualTo(4.5));
        }

        for (var key = 0; key < 16; key++) {
          await pumpBlock(tester, dark: dark, colorKey: key);
          checkContrast();
          final gesture = await tester.startGesture(
            tester.getCenter(find.byKey(const ValueKey('course-block-qa'))),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          checkContrast();
          await gesture.up();
          await tester.pumpAndSettle();
        }
      },
    );
    testWidgets('three readable fields in ${dark ? "dark" : "light"} block', (
      tester,
    ) async {
      await pumpBlock(tester, dark: dark);
      for (final text in ['大学英语III', '明志楼404', '张冠男']) {
        final finder = find.text(text);
        expect(finder, findsOneWidget);
        expect(
          (tester.renderObject(finder) as RenderParagraph).didExceedMaxLines,
          isFalse,
        );
      }
      expect(find.text('08:20'), findsNothing);
      expect(find.text('09:50'), findsNothing);
      final block = find.byKey(const ValueKey('course-block-qa'));
      expect(
        find.descendant(of: block, matching: find.byType(Row)),
        findsNothing,
      );
      expect(
        find.descendant(of: block, matching: find.byType(Container)),
        findsNothing,
      );
      expect(tester.getSize(find.text('大学英语III')).width, 46);
      expect(tester.takeException(), isNull);
    });
    testWidgets(
      'solid colors distinguish courses and stay single during press in ${dark ? "dark" : "light"}',
      (tester) async {
        BoxDecoration decoration() =>
            tester
                    .widget<DecoratedBox>(
                      find.byKey(const ValueKey('course-block-qa')),
                    )
                    .decoration
                as BoxDecoration;
        await pumpBlock(tester, dark: dark, colorKey: 0);
        final first = decoration();
        await pumpBlock(tester, dark: dark, colorKey: 2);
        final second = decoration();
        expect(second.color, isNot(first.color));
        expect(second.gradient, isNull);
        final border = second.border! as Border;
        expect(border.left, border.right);
        expect(border.left, border.top);
        expect(border.left.width, lessThanOrEqualTo(1));
        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(const ValueKey('course-block-qa'))),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(decoration().color, second.color);
        expect(decoration().gradient, isNull);
        expect(decoration().border, isNot(second.border));
        await gesture.up();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('short block degrades without overflow or increasing height', (
    tester,
  ) async {
    await pumpBlock(tester, height: 20);
    expect(find.text('大学英语III'), findsOneWidget);
    expect(find.text('明志楼404'), findsNothing);
    expect(find.text('张冠男'), findsNothing);
    expect(
      tester.getSize(find.byKey(const ValueKey('course-block-qa'))).height,
      20,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('missing location does not hide or relabel teacher', (
    tester,
  ) async {
    await pumpBlock(tester, room: '');
    expect(find.text('张冠男'), findsOneWidget);
    expect(find.byType(Text), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
