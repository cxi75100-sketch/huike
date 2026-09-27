import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huike_timetable/app.dart';
import 'package:huike_timetable/core/database/app_database.dart';
import 'package:huike_timetable/core/database/database_provider.dart';
import 'package:huike_timetable/core/router/app_router.dart';
import 'package:huike_timetable/core/theme/theme_preference.dart';
import 'package:huike_timetable/core/theme/theme_preference_provider.dart';
import 'package:huike_timetable/features/import/services/course_repository.dart';
import 'package:huike_timetable/features/schools/services/school_repository.dart';
import 'package:huike_timetable/features/timetable/pages/timetable_page.dart';
import 'package:huike_timetable/features/timetable/pages/today_page.dart';
import 'package:huike_timetable/models/course.dart';

const todayTab = ValueKey('root-tab-today');
const weeklyTab = ValueKey('root-tab-weekly');
const barKey = ValueKey('root-switcher');
const capsuleKey = ValueKey('root-active-capsule');

Future<ProviderContainer> fixture(
  WidgetTester tester, {
  double width = 390,
  bool dark = false,
  bool reduced = false,
  double bottom = 24,
  int courseCount = 0,
  double scale = 1.3,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  tester.view.viewPadding = FakeViewPadding(bottom: bottom);
  tester.view.padding = FakeViewPadding(bottom: bottom);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: reduced);
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  final db = AppDatabase(NativeDatabase.memory());
  await db.setSetting('theme_mode', dark ? 'dark' : 'light');
  final schools = SchoolRepository(db);
  final school = await schools.createSchool(
    displayName: 'Switcher QA',
    adapterId: '',
    loginUrl: '',
    confirmedHosts: [],
  );
  final now = DateTime.now();
  final monday = now.subtract(Duration(days: now.weekday - 1 + 21));
  final semester = await schools.createSemester(
    schoolId: school.id,
    firstWeekMonday: DateTime(monday.year, monday.month, monday.day),
    totalWeeks: 16,
  );
  for (var i = 0; i < courseCount; i++) {
    await CourseRepository(db).addManualCourse(
      schoolId: school.id,
      semesterId: semester.id,
      course: Course(
        id: 'switch-$i',
        schoolId: school.id,
        semesterId: semester.id,
        name: '课程 $i',
        teacher: '测试教师',
        classroom: '测试楼',
        weekday: now.weekday,
        startSection: i * 2 + 1,
        endSection: i * 2 + 2,
        weeks: [4],
        colorKey: i,
      ),
    );
  }
  await schools.setActiveSchool(school.id);
  final container = ProviderContainer(
    overrides: [databaseProvider.overrideWithValue(db)],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await tester.pump();
    await tester.runAsync(db.close);
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const HuikeApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

bool selected(WidgetTester tester, Key tab) =>
    tester
        .widget<Semantics>(
          find
              .ancestor(
                of: find.byKey(tab),
                matching: find.byWidgetPredicate(
                  (widget) =>
                      widget is Semantics && widget.properties.selected != null,
                ),
              )
              .first,
        )
        .properties
        .selected ==
    true;

void main() {
  for (final width in [360.0, 390.0, 430.0]) {
    for (final dark in [false, true]) {
      for (final reduced in [false, true]) {
        testWidgets(
          'root switch $width dark=$dark reduced=$reduced / 1.3 / inset',
          (tester) async {
            final container = await fixture(
              tester,
              width: width,
              dark: dark,
              reduced: reduced,
              bottom: width == 430 ? 48 : 24,
            );
            final router = container.read(appRouterProvider);
            expect(find.byType(TimetablePage), findsOneWidget);
            expect(selected(tester, weeklyTab), isTrue);
            expect(find.textContaining('下一节'), findsNothing);
            final bar = tester.getRect(find.byKey(barKey));
            expect(bar.left, greaterThanOrEqualTo(16));
            expect(bar.right, lessThanOrEqualTo(width - 16));
            expect(
              bar.bottom,
              lessThanOrEqualTo(844 - (width == 430 ? 48 : 24) - 16),
            );
            final fab = tester.getRect(
              find.byWidgetPredicate(
                (widget) =>
                    widget is Semantics && widget.properties.label == '打开添加菜单',
              ),
            );
            expect(fab.overlaps(bar), isFalse);
            await tester.tap(find.byTooltip('下一周'));
            await tester.pumpAndSettle();
            expect(find.text('第 5 周'), findsOneWidget);
            final before = tester.getRect(find.byKey(capsuleKey));
            await tester.tap(find.byKey(todayTab));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 70));
            final during = tester.getRect(find.byKey(capsuleKey));
            expect(during.left, lessThan(before.left));
            if (!reduced) expect(during.left, greaterThan(bar.left + 6));
            await tester.pumpAndSettle();
            expect(router.routeInformationProvider.value.uri.path, '/today');
            expect(find.byType(TodayPage), findsOneWidget);
            expect(selected(tester, todayTab), isTrue);
            expect(router.canPop(), isFalse);
            await tester.tap(find.byKey(todayTab));
            await tester.pumpAndSettle();
            expect(router.routeInformationProvider.value.uri.path, '/today');
            await tester.tap(find.byKey(weeklyTab));
            await tester.pumpAndSettle();
            expect(find.text('第 5 周'), findsOneWidget);
            expect(selected(tester, weeklyTab), isTrue);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets(
    'retains Today scroll and both page states; swipe only changes week',
    (tester) async {
      await fixture(tester, courseCount: 8, scale: 1);
      final weeklyState = tester.state(find.byType(TimetablePage));
      final todayState = tester.state(
        find.byType(TodayPage, skipOffstage: false),
      );
      await tester.drag(
        find.byKey(const ValueKey('weekly-grid')),
        const Offset(-160, 0),
      );
      await tester.pumpAndSettle();
      expect(find.text('第 5 周'), findsOneWidget);
      expect(selected(tester, weeklyTab), isTrue);
      await tester.tap(find.byKey(todayTab));
      await tester.pumpAndSettle();
      final scroll = find.descendant(
        of: find.byKey(const ValueKey('today-timeline-scroll')),
        matching: find.byType(Scrollable),
      );
      await tester.drag(
        find.byKey(const ValueKey('today-timeline-scroll')),
        const Offset(0, -360),
      );
      await tester.pumpAndSettle();
      final pixels = tester.state<ScrollableState>(scroll).position.pixels;
      expect(pixels, greaterThan(100));
      // Horizontal movement in Today cannot switch roots.
      await tester.drag(
        find.byKey(const ValueKey('today-timeline-scroll')),
        const Offset(150, 0),
      );
      await tester.pumpAndSettle();
      expect(selected(tester, todayTab), isTrue);
      await tester.tap(find.byKey(weeklyTab));
      await tester.pumpAndSettle();
      expect(tester.state(find.byType(TimetablePage)), same(weeklyState));
      expect(find.text('第 5 周'), findsOneWidget);
      await tester.tap(find.byKey(todayTab));
      await tester.pumpAndSettle();
      expect(tester.state(find.byType(TodayPage)), same(todayState));
      expect(
        tester.state<ScrollableState>(scroll).position.pixels,
        closeTo(pixels, .01),
      );
    },
  );

  testWidgets(
    'root-only chrome hides for children and both preview types; back restores root',
    (tester) async {
      final container = await fixture(tester, courseCount: 1, scale: 1);
      final router = container.read(appRouterProvider);
      await tester.tap(find.byKey(const ValueKey('course-block-switch-0')));
      await tester.pumpAndSettle();
      expect(find.byKey(barKey), findsNothing);
      await tester.tap(find.byTooltip('关闭课程预览'));
      await tester.pumpAndSettle();
      expect(find.byKey(barKey), findsOneWidget);
      for (final path in ['/settings', '/course/new', '/import']) {
        router.push(path);
        await tester.pumpAndSettle();
        expect(find.byKey(barKey), findsNothing);
        router.pop();
        await tester.pumpAndSettle();
        expect(find.byKey(barKey), findsOneWidget);
      }
      await tester.tap(find.byKey(todayTab));
      await tester.pumpAndSettle();
      await tester.tap(find.text('课程 0'));
      await tester.pumpAndSettle();
      expect(find.byKey(barKey), findsNothing);
      tester.view.viewPadding = const FakeViewPadding(bottom: 48);
      tester.view.padding = const FakeViewPadding(bottom: 48);
      await container
          .read(themePreferenceProvider.notifier)
          .set(ThemePreference.dark);
      await tester.pumpAndSettle();
      expect(find.byKey(barKey), findsNothing);
      await tester.tap(find.text('完整详情'));
      await tester.pumpAndSettle();
      expect(find.byKey(barKey), findsNothing);
      router.pop();
      await tester.pumpAndSettle();
      router.pop();
      await tester.pumpAndSettle();
      expect(find.byType(TodayPage), findsOneWidget);
      expect(find.byKey(barKey), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 1));
    },
  );

  testWidgets(
    'active tap is silent; interrupted capsule reverses continuously; no per-frame page builds',
    (tester) async {
      await fixture(tester);
      var haptics = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') haptics++;
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.tap(find.byKey(weeklyTab));
      await tester.pump();
      expect(haptics, 0);
      final weekly = tester.element(find.byType(TimetablePage));
      var pageBuilds = 0;
      final oldCallback = debugOnRebuildDirtyWidget;
      debugOnRebuildDirtyWidget = (element, builtOnce) {
        if (element == weekly) pageBuilds++;
      };
      addTearDown(() => debugOnRebuildDirtyWidget = oldCallback);
      await tester.tap(find.byKey(todayTab));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 45));
      final x = tester.getRect(find.byKey(capsuleKey)).left;
      await tester.tap(find.byKey(weeklyTab));
      await tester.pump();
      expect(tester.getRect(find.byKey(capsuleKey)).left, closeTo(x, .01));
      for (var i = 0; i < 18; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(haptics, 2);
      expect(pageBuilds, lessThan(4));
      expect(selected(tester, weeklyTab), isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
