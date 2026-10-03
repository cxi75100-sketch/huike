import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huike_timetable/core/theme/app_theme.dart';
import 'package:huike_timetable/features/timetable/services/week_agenda.dart';
import 'package:huike_timetable/features/timetable/widgets/timetable_grid.dart';
import 'package:huike_timetable/models/bell_schedule.dart';
import 'package:huike_timetable/models/course.dart';
import 'package:huike_timetable/models/semester.dart';
import 'package:huike_timetable/services/calendar_exception_service.dart';

void main() {
  setUpAll(() async {
    if (!const bool.fromEnvironment('HUIKE_CAPTURE_VISUAL')) return;
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final name in ['Ahem', 'Roboto']) {
      await (FontLoader(name)..addFont(
            File('C:/Windows/Fonts/msyh.ttc')
                .readAsBytes()
                .then(ByteData.sublistView),
          ))
          .load();
    }
  });
  for (final dark in [false, true]) {
    for (final width in [360.0, 430.0]) {
      testWidgets('节次提示有文字且完全在轴内 dark=$dark width=$width', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final now = DateTime.now();
        final semester = Semester(
          id: 'qa',
          schoolId: 'qa',
          firstWeekMonday: DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(Duration(days: now.weekday - 1)),
          totalWeeks: 16,
        );
        final courses = [
          for (var i = 0; i < 16; i++)
            Course(
              id: 'qa-$i',
              schoolId: 'qa',
              semesterId: 'qa',
              name: '示例课程${i + 1}',
              weekday: i % 7 + 1,
              startSection: (i ~/ 7) * 2 + 1,
              endSection: (i ~/ 7) * 2 + 2,
              weeks: const [1],
              colorKey: i,
              classroom: '示例楼201',
              teacher: '示例教师',
            ),
        ];
        final schedule = BellSchedule(
          sections: [
            for (var i = 1; i <= 10; i++)
              SectionSpec(
                index: i,
                start: i == 4 ? '00:00' : '',
                end: i == 4 ? '23:59' : '',
                group: SectionGroup.morning,
              ),
          ],
        );
        final capture = GlobalKey();
        Widget app(int week) => RepaintBoundary(
          key: capture,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: dark ? AppTheme.dark() : AppTheme.light(),
            home: Scaffold(
              appBar: AppBar(
                title: const Text('配色预览 · 合成数据'),
                titleTextStyle: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 18,
                  color: dark ? Colors.white : Colors.black,
                ),
              ),
              body: TimetableGrid(
                agenda: buildWeekAgenda(
                  semester: semester,
                  week: week,
                  courses: courses,
                  calendar: const CalendarExceptionService(),
                ),
                schedule: schedule,
                onCourseTap: (_) {},
                onConflictTap: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpWidget(app(1));
        await tester.pumpAndSettle();
        final marker = find.byKey(const ValueKey('timetable-now-indicator'));
        expect(find.text('当前\n4节'), findsOneWidget);
        final badgeText = tester.widget<Text>(find.text('当前\n4节'));
        final badge = tester.widget<DecoratedBox>(
          find.descendant(of: marker, matching: find.byType(DecoratedBox)),
        );
        final background = (badge.decoration as BoxDecoration).color!
            .computeLuminance();
        final foreground = badgeText.style!.color!.computeLuminance();
        final lighter = foreground > background ? foreground : background;
        final darker = foreground < background ? foreground : background;
        expect((lighter + 0.05) / (darker + 0.05), greaterThanOrEqualTo(4.5));
        final markerRect = tester.getRect(marker);
        final axisRect = tester.getRect(
          find.byKey(const ValueKey('section-axis-3')),
        );
        expect(markerRect.left, greaterThanOrEqualTo(axisRect.left));
        expect(markerRect.right, lessThanOrEqualTo(axisRect.right));
        for (final course in courses) {
          expect(
            markerRect.overlaps(
              tester.getRect(find.byKey(ValueKey('course-block-${course.id}'))),
            ),
            isFalse,
          );
        }
        if (const bool.fromEnvironment('HUIKE_CAPTURE_VISUAL')) {
          await tester.runAsync(() async {
            final boundary =
                capture.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final file = File(
              'build/today-color-${dark ? 'dark' : 'light'}-${width.toInt()}.png',
            );
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.pumpWidget(app(2));
        await tester.pumpAndSettle();
        expect(marker, findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
