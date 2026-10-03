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
import 'package:huike_timetable/models/course.dart';

const _sourceCourse = ValueKey('course-block-preview-geometry');
const _lateCourse = ValueKey('course-block-preview-geometry-late');
const _geometryContainer = ValueKey('glass-sheet-geometry-container');
const _measuredSheet = ValueKey('glass-sheet-measured-content');

Future<void> _pumpWeeklyPreview(
  WidgetTester tester, {
  required double height,
  bool includeLateCourse = false,
  bool reducedMotion = false,
}) async {
  tester.view.physicalSize = Size(390, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  if (reducedMotion) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }

  final db = AppDatabase(NativeDatabase.memory());
  final schools = SchoolRepository(db);
  final school = await schools.createSchool(
    displayName: 'Preview Geometry QA',
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
  final courses = CourseRepository(db);
  await courses.addManualCourse(
    schoolId: school.id,
    semesterId: semester.id,
    course: Course(
      id: 'preview-geometry',
      schoolId: school.id,
      semesterId: semester.id,
      name: '几何预览课程',
      weekday: today.weekday,
      startSection: 1,
      endSection: 2,
      weeks: const [4],
    ),
  );
  if (includeLateCourse) {
    await courses.addManualCourse(
      schoolId: school.id,
      semesterId: semester.id,
      course: Course(
        id: 'preview-geometry-late',
        schoolId: school.id,
        semesterId: semester.id,
        name: '纵向滚动课程',
        weekday: today.weekday,
        startSection: 13,
        endSection: 14,
        weeks: const [4],
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
}

Future<void> _tapCourseAtCurrentFrame(
  WidgetTester tester,
  Finder course,
) async {
  final gesture = await tester.startGesture(tester.getCenter(course));
  await tester.pump();
  await gesture.up();
  await tester.pump();
  await tester.pump();
}

void _expectSameRect(Rect actual, Rect expected, {double tolerance = 1}) {
  expect(actual.left, closeTo(expected.left, tolerance));
  expect(actual.top, closeTo(expected.top, tolerance));
  expect(actual.width, closeTo(expected.width, tolerance));
  expect(actual.height, closeTo(expected.height, tolerance));
}

Future<
  (
    GlobalKey<GlassSheetHostState>,
    Rect,
    ValueNotifier<int>,
    ValueNotifier<Rect>,
  )
>
_pumpGeometryHarness(
  WidgetTester tester, {
  bool withSource = true,
  bool sourceAvailableOnDismiss = true,
}) async {
  const sourceRect = Rect.fromLTWH(24, 80, 110, 64);
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final sourceKey = GlobalKey();
  final hostKey = GlobalKey<GlassSheetHostState>();
  final dismissals = ValueNotifier(0);
  final liveSource = ValueNotifier(sourceRect);
  var visible = false;
  late StateSetter update;
  addTearDown(dismissals.dispose);
  addTearDown(liveSource.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return GlassSheetHost(
              key: hostKey,
              background: Stack(
                children: [
                  ValueListenableBuilder<Rect>(
                    valueListenable: liveSource,
                    builder: (context, rect, child) =>
                        Positioned.fromRect(rect: rect, child: child!),
                    child: Container(key: sourceKey, color: Colors.blue),
                  ),
                ],
              ),
              sourceRect: withSource ? sourceRect : null,
              sourceRectProvider: sourceAvailableOnDismiss
                  ? () => tester.getRect(find.byKey(sourceKey))
                  : () => null,
              sheet: visible
                  ? GlassSheetPanel(
                      title: '几何测试',
                      child: const SizedBox(height: 180, child: Text('详情')),
                    )
                  : null,
              onDismissed: () => dismissals.value++,
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final measuredSource = tester.getRect(find.byKey(sourceKey));
  update(() => visible = true);
  await tester.pumpAndSettle();
  return (hostKey, measuredSource, dismissals, liveSource);
}

void main() {
  for (final height in [640.0, 1000.0]) {
    testWidgets('真实 Preview destination 跟随 $height dp viewport 布局', (
      tester,
    ) async {
      await _pumpWeeklyPreview(tester, height: height);
      final source = tester.getRect(find.byKey(_sourceCourse));
      await tester.tap(find.byKey(_sourceCourse));
      await tester.pumpAndSettle();

      final container = tester.getRect(find.byKey(_geometryContainer));
      final content = tester.getRect(find.byKey(_measuredSheet));
      _expectSameRect(container, content);
      expect(container.left, closeTo(0, 1));
      expect(container.right, closeTo(390, 1));
      expect(container.bottom, lessThanOrEqualTo(height));
      expect(container.height, greaterThan(source.height));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Weekly preview slides at full width with grid stationary', (
    tester,
  ) async {
    await _pumpWeeklyPreview(tester, height: 844);
    final source = tester.getRect(find.byKey(_sourceCourse));
    await _tapCourseAtCurrentFrame(tester, find.byKey(_sourceCourse));
    await tester.pump(const Duration(milliseconds: 16));

    final starting = tester.getRect(find.byKey(_geometryContainer));
    expect(starting.width, 390);
    _expectSameRect(tester.getRect(find.byKey(_sourceCourse)), source);
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.getRect(find.byKey(_geometryContainer)).width, 390);
    _expectSameRect(tester.getRect(find.byKey(_sourceCourse)), source);
    await tester.pumpAndSettle();
    _expectSameRect(
      tester.getRect(find.byKey(_geometryContainer)),
      tester.getRect(find.byKey(_measuredSheet)),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('14 节滚动布局打开 Preview 不缩放或移动课程块', (tester) async {
    await _pumpWeeklyPreview(tester, height: 844, includeLateCourse: true);
    final scroll = find.byKey(const ValueKey('weekly-grid-scroll'));
    await tester.drag(scroll, const Offset(0, -500));
    await tester.pumpAndSettle();
    final course = find.byKey(_lateCourse);
    expect(course, findsOneWidget);
    final source = tester.getRect(course);
    await _tapCourseAtCurrentFrame(tester, course);
    await tester.pump(const Duration(milliseconds: 16));

    expect(tester.getRect(find.byKey(_geometryContainer)).width, 390);
    _expectSameRect(tester.getRect(course), source);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reduced Motion 直接显示实际 destination geometry', (tester) async {
    await _pumpWeeklyPreview(tester, height: 640, reducedMotion: true);
    await tester.tap(find.byKey(_sourceCourse));
    await tester.pumpAndSettle();

    _expectSameRect(
      tester.getRect(find.byKey(_geometryContainer)),
      tester.getRect(find.byKey(_measuredSheet)),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('viewport resize 后不用旧 destination rect', (tester) async {
    await _pumpWeeklyPreview(tester, height: 1000);
    await tester.tap(find.byKey(_sourceCourse));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(390, 640);
    await tester.pumpAndSettle();

    final container = tester.getRect(find.byKey(_geometryContainer));
    _expectSameRect(container, tester.getRect(find.byKey(_measuredSheet)));
    expect(container.bottom, lessThanOrEqualTo(640));
    expect(tester.takeException(), isNull);
  });

  testWidgets('geometry dismiss 沿原矩形反向返回且只回调一次', (tester) async {
    final (hostKey, source, dismissals, _) = await _pumpGeometryHarness(tester);
    hostKey.currentState!.close();
    await tester.pumpAndSettle();

    _expectSameRect(tester.getRect(find.byKey(_geometryContainer)), source);
    expect(dismissals.value, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('source 在关闭前失效时沿 fallback 关闭且不崩溃', (tester) async {
    final (hostKey, _, dismissals, _) = await _pumpGeometryHarness(
      tester,
      sourceAvailableOnDismiss: false,
    );
    hostKey.currentState!.close();
    await tester.pumpAndSettle();

    final fallbackRect = tester.getRect(find.byKey(_geometryContainer));
    expect(fallbackRect.left, closeTo(0, 1));
    expect(fallbackRect.top, greaterThan(600));
    expect(dismissals.value, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('attached source 移位后反向使用关闭时的实际位置', (tester) async {
    final (hostKey, _, dismissals, liveSource) = await _pumpGeometryHarness(
      tester,
    );
    final movedSource = liveSource.value.shift(const Offset(46, 28));
    liveSource.value = movedSource;
    await tester.pump();
    hostKey.currentState!.close();
    await tester.pumpAndSettle();

    _expectSameRect(
      tester.getRect(find.byKey(_geometryContainer)),
      movedSource,
    );
    expect(dismissals.value, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('drag 中 container rect 使用原始 progress，短拖回到 destination', (
    tester,
  ) async {
    final (hostKey, source, _, _) = await _pumpGeometryHarness(tester);
    final destination = tester.getRect(find.byKey(_geometryContainer));
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('详情')),
    );
    await tester.pump();
    await gesture.moveBy(const Offset(0, 60));
    await tester.pump();

    final expectedDuringDrag = Rect.lerp(
      source,
      destination,
      hostKey.currentState!.progress.value,
    )!;
    _expectSameRect(
      tester.getRect(find.byKey(_geometryContainer)),
      expectedDuringDrag,
    );
    await gesture.up();
    await tester.pumpAndSettle();
    _expectSameRect(
      tester.getRect(find.byKey(_geometryContainer)),
      tester.getRect(find.byKey(_measuredSheet)),
    );
    expect(tester.takeException(), isNull);
  });
}
