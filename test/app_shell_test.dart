import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huike_timetable/app.dart';
import 'package:huike_timetable/core/database/app_database.dart';
import 'package:huike_timetable/core/database/database_provider.dart';
import 'package:huike_timetable/core/glass/glass_dialog.dart';
import 'package:huike_timetable/core/router/app_router.dart';
import 'package:huike_timetable/core/theme/theme_preference.dart';
import 'package:huike_timetable/core/theme/theme_preference_provider.dart';
import 'package:huike_timetable/features/import/services/course_repository.dart';
import 'package:huike_timetable/features/schools/providers/school_providers.dart';
import 'package:huike_timetable/features/schools/services/adapter_catalog.dart';
import 'package:huike_timetable/features/schools/services/school_repository.dart';
import 'package:huike_timetable/models/course.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<ProviderContainer> pumpApp(WidgetTester tester) async {
    const testCatalog = AdapterCatalog(entries: []);
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        adapterCatalogProvider.overrideWith((ref) async => testCatalog),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const HuikeApp()),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('全新安装直接进入首页且不创建学校', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpApp(tester);
    expect(find.text('你的课表，从这里开始'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(await db.select(db.schools).get(), isEmpty);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('今日课程'));
    await tester.pumpAndSettle();
    expect(find.text('还没有课程'), findsOneWidget);
    await tester.tap(find.text('导入课表'));
    await tester.pumpAndSettle();
    expect(find.text('准备导入课表'), findsOneWidget);
    expect(find.widgetWithText(TextField, '学校名称（必填）'), findsOneWidget);
    expect(await db.select(db.schools).get(), isEmpty);
  });

  testWidgets('创建学校与学期后进入课表首页', (tester) async {
    final container = await pumpApp(tester);
    container.read(appRouterProvider).push('/onboarding');
    await tester.pumpAndSettle();

    // 走真实交互：填名称 → 点底部 CTA。
    await tester.enterText(find.widgetWithText(TextField, '学校名称（必填）'), '测试大学');
    await tester.tap(find.text('创建学校'));
    await tester.pumpAndSettle();

    final activeId = container.read(activeSchoolIdProvider).value;
    expect(activeId, isNotNull);

    // 首页直接进入完整周课表，不再要求先选「今日 / 整周」。
    expect(find.byTooltip('今日课程'), findsOneWidget);
    expect(find.text('整周'), findsNothing);
    expect(find.byKey(const ValueKey('weekly-grid')), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == '打开添加菜单',
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp(r'^本周线路概览')), findsNothing);
    for (var day = 1; day <= 7; day++) {
      expect(find.byKey(ValueKey('weekday-$day')), findsOneWidget);
    }
  });

  testWidgets('首次导入建校后继续导入，返回仍可浏览首页', (tester) async {
    final container = await pumpApp(tester);
    await tester.tap(find.text('导入课表'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '学校名称（必填）'), '合成大学');
    await tester.tap(find.text('创建学校'));
    await tester.pumpAndSettle();
    expect(
      container.read(appRouterProvider).routerDelegate.state.uri.path,
      '/import',
    );
    expect(find.text('合成大学'), findsOneWidget);
    expect(find.text('确认并进入教务登录'), findsOneWidget);
    expect((await db.select(db.schools).get()).single.displayName, '合成大学');
    expect(container.read(appRouterProvider).canPop(), isTrue);
    container.read(appRouterProvider).pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('weekly-grid')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('导入时切换与新增学校保留原档案并更新网址', (tester) async {
    final repository = SchoolRepository(db);
    final first = await repository.createSchool(
      displayName: '合成甲大学',
      adapterId: '',
      loginUrl: 'https://first.example.edu.cn',
      confirmedHosts: const [],
    );
    final second = await repository.createSchool(
      displayName: '合成乙大学',
      adapterId: '',
      loginUrl: 'https://second.example.edu.cn',
      confirmedHosts: const [],
    );
    await repository.setActiveSchool(first.id);
    final container = await pumpApp(tester);
    container.read(appRouterProvider).push('/import');
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(TextField, 'https://first.example.edu.cn'),
      findsOneWidget,
    );
    await tester.tap(find.text('更换学校'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('合成乙大学'));
    await tester.pumpAndSettle();
    expect(container.read(activeSchoolIdProvider).value, second.id);
    expect(
      container.read(appRouterProvider).routerDelegate.state.uri.path,
      '/import',
    );
    expect(
      find.widgetWithText(TextField, 'https://second.example.edu.cn'),
      findsOneWidget,
    );
    await tester.tap(find.text('更换学校'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('添加学校'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '学校名称（必填）'), '合成丙大学');
    await tester.tap(find.text('创建学校'));
    await tester.pumpAndSettle();
    expect(
      container.read(appRouterProvider).routerDelegate.state.uri.path,
      '/import',
    );
    expect(find.text('合成丙大学'), findsOneWidget);
    expect(find.text('确认并进入教务登录'), findsOneWidget);
    expect(await db.select(db.schools).get(), hasLength(3));
    expect(
      (await db.select(db.schools).get())
          .firstWhere((s) => s.id == first.id)
          .loginUrl,
      'https://first.example.edu.cn',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('空课周仍显示完整周课表', (tester) async {
    final container = await pumpApp(tester);
    final repository = container.read(schoolRepositoryProvider);
    final school = await repository.createSchool(
      displayName: '空课大学',
      adapterId: '',
      loginUrl: '',
      confirmedHosts: const [],
    );
    // 开学周一放在很远的未来；仍应保留可浏览的完整周网格。
    final future = DateTime.now().add(const Duration(days: 90));
    final monday = future.subtract(Duration(days: future.weekday - 1));
    await repository.createSemester(
      schoolId: school.id,
      firstWeekMonday: DateTime(monday.year, monday.month, monday.day),
      totalWeeks: 16,
    );
    await repository.setActiveSchool(school.id);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('weekly-grid')), findsOneWidget);
    expect(find.text('本周暂无课程'), findsOneWidget);
    expect(find.byKey(const ValueKey('weekday-7')), findsOneWidget);
  });

  testWidgets('设置页的玻璃外观选项可以切换并保存', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final schools = SchoolRepository(db);
    final school = await schools.createSchool(
      displayName: '外观设置大学',
      adapterId: '',
      loginUrl: '',
      confirmedHosts: const [],
    );
    await schools.setActiveSchool(school.id);
    final container = await pumpApp(tester);

    await tester.tap(find.byTooltip('设置'));
    await tester.pumpAndSettle();
    expect(find.text('外观'), findsOneWidget);
    await tester.tap(find.text('夜间'));
    await tester.pumpAndSettle();

    expect(container.read(themePreferenceProvider).value, ThemePreference.dark);
    expect(tester.takeException(), isNull);
  });

  testWidgets('课程详情显示共享节次数线路', (tester) async {
    final schools = SchoolRepository(db);
    final courses = CourseRepository(db);
    final school = await schools.createSchool(
      displayName: '线路测试大学',
      adapterId: '',
      loginUrl: '',
      confirmedHosts: const [],
    );
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final semester = await schools.createSemester(
      schoolId: school.id,
      firstWeekMonday: DateTime(monday.year, monday.month, monday.day),
      totalWeeks: 16,
    );
    await courses.addManualCourse(
      schoolId: school.id,
      semesterId: semester.id,
      course: Course(
        id: 'route-detail-course',
        schoolId: school.id,
        semesterId: semester.id,
        name: '城市设计',
        weekday: now.weekday,
        startSection: 3,
        endSection: 4,
        weeks: const [1],
        startTime: '10:25',
        endTime: '12:00',
      ),
    );
    await schools.setActiveSchool(school.id);

    await pumpApp(tester);
    expect(find.byKey(const ValueKey('weekly-grid')), findsOneWidget);
    expect(find.byKey(ValueKey('weekday-${now.weekday}')), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('course-block-route-detail-course')),
    );
    await tester.pumpAndSettle();
    expect(find.text('完整详情'), findsOneWidget);
    await tester.tap(find.text('完整详情'));
    await tester.pumpAndSettle();

    expect(find.text('城市设计'), findsWidgets);
    expect(find.byTooltip('编辑'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == '一天 10 节，课程占用第 3 至第 4 节',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('删除'));
    await tester.pumpAndSettle();
    expect(find.byType(GlassDialog), findsOneWidget);
    expect(find.textContaining('此操作不可撤销'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('删除'), findsOneWidget);

    await tester.tap(find.byTooltip('删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(find.byType(GlassDialog), findsNothing);
    expect(
      find.byKey(const ValueKey('course-block-route-detail-course')),
      findsNothing,
    );
  });
}
