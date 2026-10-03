import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huike_timetable/core/glass/glass_button.dart';
import 'package:huike_timetable/core/glass/glass_surface.dart';
import 'package:huike_timetable/core/theme/app_theme.dart';
import 'package:huike_timetable/features/timetable/widgets/course_hero.dart';
import 'package:huike_timetable/features/timetable/widgets/course_preview_sheet.dart';
import 'package:huike_timetable/models/bell_schedule.dart';
import 'package:huike_timetable/models/course.dart';

void main() {
  for (final dark in [false, true]) {
    for (final reduced in [false, true]) {
      for (final source in CourseHeroSourceContext.values) {
        final weekly = source == CourseHeroSourceContext.weeklyTimetable;
        testWidgets('Preview retains panel glass and button actions: '
            'source=$source dark=$dark reduced=$reduced', (tester) async {
          var closes = 0;
          var details = 0;
          var edits = 0;
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark() : AppTheme.light(),
              home: MediaQuery(
                data: MediaQueryData(
                  size: const Size(800, 600),
                  disableAnimations: reduced,
                ),
                child: Scaffold(
                  body: Column(
                    children: [
                      GlassButton(label: '普通按钮', onPressed: () {}),
                      CoursePreviewSheet(
                        course: const Course(
                          id: 'blur-qa',
                          schoolId: 'qa',
                          semesterId: 'qa',
                          name: '预览 QA',
                          weekday: 1,
                          startSection: 1,
                          endSection: 2,
                          weeks: [1],
                        ),
                        schedule: const BellSchedule(sections: []),
                        heroSource: source,
                        onClose: () => closes++,
                        onDetails: () => details++,
                        onEdit: () => edits++,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final preview = find.byType(CoursePreviewSheet);
          // The parent keeps real backdrop sampling; its three controls reuse it.
          expect(
            find.descendant(of: preview, matching: find.byType(BackdropFilter)),
            weekly ? findsOneWidget : findsNothing,
          );
          for (final button
              in find
                  .descendant(of: preview, matching: find.byType(GlassButton))
                  .evaluate()) {
            expect(
              find.descendant(
                of: find.byWidget(button.widget),
                matching: find.byType(BackdropFilter),
              ),
              findsNothing,
            );
            expect(
              find.descendant(
                of: find.byWidget(button.widget),
                matching: find.byType(GlassSurface),
              ),
              findsOneWidget,
            );
          }
          expect(find.byType(BackdropFilter), findsNWidgets(weekly ? 2 : 1));
          await tester.tap(find.byTooltip('关闭课程预览'));
          await tester.tap(find.text('完整详情'));
          await tester.tap(find.text('编辑'));
          await tester.pumpAndSettle();
          expect([closes, details, edits], [1, 1, 1]);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
