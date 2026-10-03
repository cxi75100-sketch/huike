import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huike_timetable/app.dart';
import 'package:huike_timetable/core/database/app_database.dart';
import 'package:huike_timetable/core/database/database_provider.dart';
import 'package:huike_timetable/core/glass/glass_sheet.dart';
import 'package:huike_timetable/features/import/services/course_repository.dart';
import 'package:huike_timetable/features/schools/services/school_repository.dart';
import 'package:huike_timetable/features/timetable/pages/timetable_page.dart';
import 'package:huike_timetable/models/course.dart';

const _courseBlock = ValueKey('course-block-preview-dismiss');
const _rootSwitcher = ValueKey('root-switcher');

Future<void> _pumpWeeklyPreview(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final db = AppDatabase(NativeDatabase.memory());
  final schools = SchoolRepository(db);
  final school = await schools.createSchool(
    displayName: 'Preview QA',
    adapterId: '',
    loginUrl: '',
    confirmedHosts: const [],
  );
  final today = DateTime.now();
  final monday = today.subtract(Duration(days: today.weekday - 1 + 21));
  final semester = await schools.createSemester(
    schoolId: school.id,
    firstWeekMonday: DateTime(monday.year, monday.month, monday.day),
    totalWeeks: 16,
  );
  await CourseRepository(db).addManualCourse(
    schoolId: school.id,
    semesterId: semester.id,
    course: Course(
      id: 'preview-dismiss',
      schoolId: school.id,
      semesterId: semester.id,
      name: '预览课程',
      weekday: today.weekday,
      startSection: 1,
      endSection: 2,
      weeks: const [4],
    ),
  );
  await schools.setActiveSchool(school.id);
  await CourseRepository(db).addManualCourse(
    schoolId: school.id,
    semesterId: semester.id,
    course: Course(
      id: 'preview-next',
      schoolId: school.id,
      semesterId: semester.id,
      name: '下一课程',
      weekday: today.weekday % 7 + 1,
      startSection: 1,
      endSection: 2,
      weeks: const [4],
    ),
  );
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
  await tester.tap(find.byKey(_courseBlock));
  await tester.pumpAndSettle();
  expect(find.byTooltip('关闭课程预览'), findsOneWidget);
}

Future<void> _pumpSheetHarness(
  WidgetTester tester,
  GlobalKey<GlassSheetHostState> hostKey,
  ValueNotifier<int> dismissals,
) async {
  final open = ValueNotifier(false);
  addTearDown(open.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ValueListenableBuilder<bool>(
          valueListenable: open,
          builder: (context, visible, _) => GlassSheetHost(
            key: hostKey,
            background: Center(
              child: ElevatedButton(
                onPressed: () => open.value = true,
                child: const Text('打开'),
              ),
            ),
            sheet: visible
                ? GlassSheetPanel(
                    title: '测试面板',
                    onClose: () => hostKey.currentState?.close(),
                    child: const SizedBox(height: 150, child: Text('面板内容')),
                  )
                : null,
            onDismissed: () {
              dismissals.value++;
              open.value = false;
            },
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('打开'));
  await tester.pumpAndSettle();
  expect(find.text('面板内容'), findsOneWidget);
}

void main() {
  for (final reduced in [false, true]) {
    testWidgets('关闭后立即点下一课程不等待动画 reduced=$reduced', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: reduced);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await _pumpWeeklyPreview(tester);
      await tester.tap(find.byTooltip('关闭课程预览'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      await tester.tap(find.byKey(const ValueKey('course-block-preview-next')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      expect(find.byTooltip('关闭课程预览'), findsOneWidget);
      expect(find.text('下一课程'), findsWidgets);
      await tester.pumpAndSettle();
      expect(find.byTooltip('关闭课程预览'), findsOneWidget);
      await tester.tap(find.byTooltip('关闭课程预览'));
      await tester.pump();
      await tester.tap(find.byKey(_courseBlock));
      await tester.pumpAndSettle();
      expect(find.byTooltip('关闭课程预览'), findsOneWidget);
      expect(find.text('预览课程'), findsWidgets);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byTooltip('关闭课程预览'), findsNothing);
      expect(find.byType(TimetablePage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('关闭中立即重开同一课程不会被旧完成回调清除', (tester) async {
    await _pumpWeeklyPreview(tester);
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.tap(find.byKey(_courseBlock));
    await tester.pumpAndSettle();
    expect(find.byTooltip('关闭课程预览'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('完整详情返回仍保留预览，再关闭不出现收缩胶囊', (tester) async {
    await _pumpWeeklyPreview(tester);
    await tester.tap(find.text('完整详情'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byTooltip('关闭课程预览'), findsOneWidget);
    final panel = find.byKey(const ValueKey('glass-sheet-geometry-container'));
    final before = tester.getRect(panel);
    await tester.tap(find.byTooltip('关闭课程预览'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final during = tester.getRect(panel);
    expect(during.width, before.width);
    expect(during.height, before.height);
    expect(during.top, greaterThan(before.top));
    await tester.pumpAndSettle();
    expect(find.byTooltip('关闭课程预览'), findsNothing);
    expect(find.byKey(_courseBlock), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Android Back 先关闭 Weekly Preview，根页和分支仍在', (tester) async {
    await _pumpWeeklyPreview(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byTooltip('关闭课程预览'), findsNothing);
    expect(find.byType(TimetablePage), findsOneWidget);
    expect(find.byKey(_rootSwitcher), findsOneWidget);
    expect(find.byKey(_courseBlock), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Preview 关闭后子路由仍按原 Back 行为返回', (tester) async {
    await _pumpWeeklyPreview(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('设置').first);
    await tester.pumpAndSettle();
    expect(find.text('当前学校'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(TimetablePage), findsOneWidget);
    expect(find.byKey(_rootSwitcher), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('连续两次 Back 只关闭一次，页面不退出', (tester) async {
    await _pumpWeeklyPreview(tester);

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(TimetablePage), findsOneWidget);
    expect(find.byKey(_rootSwitcher), findsOneWidget);
    expect(find.byTooltip('关闭课程预览'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('X 开始关闭后再按 Back 不穿透路由', (tester) async {
    await _pumpWeeklyPreview(tester);

    await tester.tap(find.byTooltip('关闭课程预览'));
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(TimetablePage), findsOneWidget);
    expect(find.byKey(_rootSwitcher), findsOneWidget);
    expect(find.byTooltip('关闭课程预览'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('编辑入口先完成同一关闭流程再进入编辑页', (tester) async {
    await _pumpWeeklyPreview(tester);

    await tester.tap(find.text('编辑'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('关闭课程预览'), findsNothing);
    expect(find.text('编辑课程'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('背景关闭再触发程序化关闭，完成回调只执行一次', (tester) async {
    final hostKey = GlobalKey<GlassSheetHostState>();
    final dismissals = ValueNotifier(0);
    addTearDown(dismissals.dispose);
    await _pumpSheetHarness(tester, hostKey, dismissals);

    await tester.tapAt(const Offset(20, 40));
    await tester.pump();
    hostKey.currentState?.close();
    await tester.pumpAndSettle();

    expect(dismissals.value, 1);
    expect(find.text('面板内容'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('下拖关闭与短拖回弹仍正常', (tester) async {
    final hostKey = GlobalKey<GlassSheetHostState>();
    final dismissals = ValueNotifier(0);
    addTearDown(dismissals.dispose);
    await _pumpSheetHarness(tester, hostKey, dismissals);

    await tester.drag(find.text('面板内容'), const Offset(0, 15));
    await tester.pumpAndSettle();
    expect(dismissals.value, 0);
    expect(find.text('面板内容'), findsOneWidget);

    await tester.drag(find.text('面板内容'), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(dismissals.value, 1);
    expect(find.text('面板内容'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reduced Motion 下重复关闭仍只完成一次', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final hostKey = GlobalKey<GlassSheetHostState>();
    final dismissals = ValueNotifier(0);
    addTearDown(dismissals.dispose);
    await _pumpSheetHarness(tester, hostKey, dismissals);

    hostKey.currentState?.close();
    hostKey.currentState?.close();
    await tester.pumpAndSettle();

    expect(dismissals.value, 1);
    expect(find.text('面板内容'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('关闭后重新打开是新周期，各自只完成一次', (tester) async {
    final hostKey = GlobalKey<GlassSheetHostState>();
    final dismissals = ValueNotifier(0);
    addTearDown(dismissals.dispose);
    await _pumpSheetHarness(tester, hostKey, dismissals);

    hostKey.currentState?.close();
    await tester.pumpAndSettle();
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    hostKey.currentState?.close();
    hostKey.currentState?.close();
    await tester.pumpAndSettle();

    expect(dismissals.value, 2);
    expect(find.text('面板内容'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
