import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huike_timetable/app.dart';
import 'package:huike_timetable/core/database/app_database.dart';
import 'package:huike_timetable/core/database/database_provider.dart';
import 'package:huike_timetable/features/import/services/course_repository.dart';
import 'package:huike_timetable/features/schools/services/adapter_catalog.dart';
import 'package:huike_timetable/features/schools/services/school_repository.dart';
import 'package:huike_timetable/models/course.dart';
import 'package:flutter/rendering.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  Future<void> pumpWeek(
    WidgetTester tester, {
    required double width,
    required int sections,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final schools = SchoolRepository(db);
    final repository = CourseRepository(db);
    final school = await schools.createSchool(
      displayName: 'Layout University',
      adapterId: '',
      loginUrl: '',
      confirmedHosts: const [],
    );
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final first = monday.subtract(const Duration(days: 21));
    final semester = await schools.createSemester(
      schoolId: school.id,
      firstWeekMonday: DateTime(first.year, first.month, first.day),
      totalWeeks: 16,
    );
    for (var day = 1; day <= 7; day++) {
      await repository.addManualCourse(
        schoolId: school.id,
        semesterId: semester.id,
        course: Course(
          id: 'course-$day',
          schoolId: school.id,
          semesterId: semester.id,
          name: [
            '大学英语III',
            '工程力学',
            '工程材料',
            '大学物理II',
            '马克思主义基本原理',
            '线性代数A',
            '艺术鉴赏',
          ][day - 1],
          weekday: day,
          startSection: day == 1 ? sections - 1 : 3,
          endSection: day == 1 ? sections : 4,
          classroom: day == 3 ? '九龙湖校区西区实训中心3-A010' : '九龙湖校区明志楼404',
          teacher: '张冠男',
          weeks: const [4],
        ),
      );
    }
    await schools.setActiveSchool(school.id);
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        adapterCatalogProvider.overrideWith(
          (ref) async => const AdapterCatalog(entries: []),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const HuikeApp()),
    );
    await tester.pumpAndSettle();
  }

  for (final width in [360.0, 390.0, 430.0]) {
    for (final scale in [1.0, 1.3]) {
      for (final sections in [10, 12]) {
        testWidgets('$width dp / $scale text / $sections sections fit viewport', (
          tester,
        ) async {
          await pumpWeek(
            tester,
            width: width,
            sections: sections,
            textScale: scale,
          );
          expect(tester.takeException(), isNull);
          final grid = tester.getRect(
            find.byKey(const ValueKey('weekly-grid')),
          );
          final viewport = tester.getRect(
            find.byKey(const ValueKey('weekly-grid-scroll')),
          );
          expect(grid.bottom, lessThanOrEqualTo(viewport.bottom + 0.5));
          expect(
            find.byKey(ValueKey('section-axis-${sections - 1}')),
            findsOneWidget,
          );
          for (var day = 1; day <= 7; day++) {
            final header = tester.getRect(find.byKey(ValueKey('weekday-$day')));
            expect(header.left, greaterThanOrEqualTo(0));
            expect(header.right, lessThanOrEqualTo(width + 0.5));
            final block = find.byKey(ValueKey('course-block-course-$day'));
            expect(block, findsOneWidget);
            final rect = tester.getRect(block);
            expect(rect.top, greaterThanOrEqualTo(viewport.top));
            expect(rect.bottom, lessThanOrEqualTo(viewport.bottom + 0.5));
            final text = find.descendant(
              of: block,
              matching: find.byType(Text),
            );
            expect(text, findsNWidgets(3));
            final location = day == 3 ? '实训中心3-A010' : '明志楼404';
            expect(
              find.descendant(of: block, matching: find.text(location)),
              findsOneWidget,
            );
            expect(
              find.descendant(of: block, matching: find.text('张冠男')),
              findsOneWidget,
            );
            for (final element in text.evaluate()) {
              final paragraph = element.findRenderObject()! as RenderParagraph;
              final textRect = tester.getRect(find.byWidget(element.widget));
              expect(textRect.top, greaterThanOrEqualTo(rect.top));
              expect(textRect.bottom, lessThanOrEqualTo(rect.bottom + 0.5));
              expect(paragraph.size.height, greaterThan(0));
              if ((element.widget as Text).data == location ||
                  (element.widget as Text).data == '张冠男') {
                expect(
                  paragraph.didExceedMaxLines,
                  isFalse,
                  reason:
                      '$width/$scale/$sections ${(element.widget as Text).data} must remain readable',
                );
              }
              expect((element.widget as Text).data, isNot(contains('校区')));
              expect(
                (element.widget as Text).data,
                isNot(matches(r'\d{2}:\d{2}')),
              );
            }
          }
        });
      }
    }
  }

  testWidgets('14 sections scroll inside fixed weekday header', (tester) async {
    await pumpWeek(tester, width: 390, sections: 14);
    final scroll = find.descendant(
      of: find.byKey(const ValueKey('weekly-grid-scroll')),
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(scroll).position;
    final headerBefore = tester.getRect(
      find.byKey(const ValueKey('weekday-header')),
    );
    final before = position.pixels;
    expect(position.maxScrollExtent, greaterThan(0));
    await tester.drag(
      find.byKey(const ValueKey('weekly-grid-scroll')),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    expect(position.pixels, greaterThan(before));
    expect(
      tester.getRect(find.byKey(const ValueKey('weekday-header'))),
      headerBefore,
    );
    expect(find.byKey(const ValueKey('weekday-header')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
