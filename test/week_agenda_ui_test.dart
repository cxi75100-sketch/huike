import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:huike_timetable/app.dart';
import 'package:huike_timetable/core/database/app_database.dart';
import 'package:huike_timetable/core/database/database_provider.dart';
import 'package:huike_timetable/features/import/services/course_repository.dart';
import 'package:huike_timetable/features/schools/services/adapter_catalog.dart';
import 'package:huike_timetable/features/schools/services/school_repository.dart';
import 'package:huike_timetable/features/timetable/services/week_agenda.dart';
import 'package:huike_timetable/features/timetable/widgets/course_hero.dart';
import 'package:huike_timetable/features/timetable/widgets/timetable_grid.dart';
import 'package:huike_timetable/features/timetable/widgets/timetable_header.dart';
import 'package:huike_timetable/features/timetable/widgets/week_swipe.dart';
import 'package:huike_timetable/features/timetable/pages/today_page.dart';
import 'package:huike_timetable/models/bell_schedule.dart';
import 'package:huike_timetable/models/course.dart';
import 'package:huike_timetable/models/semester.dart';
import 'package:huike_timetable/services/calendar_exception_service.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
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

  Future<ProviderContainer> pumpWeeklyHome(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1,
    List<Course> courses = const [],
  }) async {
    final schools = SchoolRepository(db);
    final courseRepository = CourseRepository(db);
    final school = await schools.createSchool(
      displayName: 'Weekly University',
      adapterId: '',
      loginUrl: '',
      confirmedHosts: const [],
    );
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final firstMonday = monday.subtract(const Duration(days: 21));
    final semester = await schools.createSemester(
      schoolId: school.id,
      firstWeekMonday: DateTime(
        firstMonday.year,
        firstMonday.month,
        firstMonday.day,
      ),
      totalWeeks: 16,
    );
    for (final course in courses) {
      await courseRepository.addManualCourse(
        schoolId: school.id,
        semesterId: semester.id,
        course: course.copyWith(
          schoolId: school.id,
          semesterId: semester.id,
          weeks: const [4],
        ),
      );
    }
    await schools.setActiveSchool(school.id);
    return pumpApp(tester, size: size, textScale: textScale);
  }

  Course course(String id, {int weekday = 1, int start = 1, int end = 2}) =>
      Course(
        id: id,
        schoolId: 'school',
        semesterId: 'semester',
        name: 'Course $id',
        teacher: 'Teacher $id',
        classroom: 'A201',
        weekday: weekday,
        startSection: start,
        endSection: end,
        weeks: const [4],
        colorKey: id.hashCode,
      );

  void expectSevenDaysInsideViewport(WidgetTester tester, double width) {
    for (var day = 1; day <= 7; day++) {
      final finder = find.byKey(ValueKey('weekday-$day'));
      expect(finder, findsOneWidget);
      final rect = tester.getRect(finder);
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(width + 0.01));
    }
  }

  testWidgets('默认首页就是完整 Weekly Timetable，360dp 七天同时可见', (tester) async {
    await pumpWeeklyHome(tester, size: const Size(360, 800));

    expect(find.byKey(const ValueKey('weekly-grid')), findsOneWidget);
    expect(find.byKey(const ValueKey('weekday-header')), findsOneWidget);
    expect(find.byTooltip('今日课程'), findsOneWidget);
    expect(find.text('整周'), findsNothing);
    expectSevenDaysInsideViewport(tester, 360);
    expect(find.byKey(const ValueKey('section-axis-1')), findsOneWidget);
    expect(find.text('1–2'), findsOneWidget);
    expect(find.text('9–10'), findsOneWidget);
    expect(find.byKey(const ValueKey('section-axis-9')), findsOneWidget);
    expect(
      tester.getRect(find.byKey(const ValueKey('weekly-grid'))).bottom,
      closeTo(800, 0.01),
    );
  });

  for (final width in [360.0, 390.0, 430.0]) {
    testWidgets('TASK-020B $width dp Weekly无Today摘要，底部入口保留Today功能', (
      tester,
    ) async {
      await pumpWeeklyHome(
        tester,
        size: Size(width, 844),
        textScale: 1.3,
        courses: [course('separate-today', weekday: DateTime.now().weekday)],
      );
      expect(find.textContaining('今天 ·'), findsNothing);
      expect(find.textContaining('下一节'), findsNothing);
      expect(find.textContaining('今天课已上完'), findsNothing);
      expect(find.textContaining('今天无课'), findsNothing);
      expect(find.byKey(const ValueKey('weekly-grid')), findsOneWidget);
      expect(find.text('Course separate-today'), findsOneWidget);
      expectSevenDaysInsideViewport(tester, width);
      final header = tester.getRect(find.byType(TimetableHeader));
      final grid = tester.getRect(
        find.byKey(const ValueKey('weekly-grid-current')),
      );
      expect(grid.top, closeTo(header.bottom, 0.01));
      final entry = tester.getRect(find.byTooltip('今日课程'));
      expect(entry.top, greaterThan(header.bottom));
      expect(entry.width, greaterThanOrEqualTo(44));
      expect(entry.height, greaterThanOrEqualTo(44));
      expect(tester.takeException(), isNull);

      // 查看其它周不影响Today入口，也不让Today跟随所选周。
      await tester.tap(find.byTooltip('下一周'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('今日课程'));
      await tester.pumpAndSettle();
      expect(find.byType(TodayPage), findsOneWidget);
      expect(
        GoRouterState.of(tester.element(find.byType(TodayPage))).uri.path,
        '/today',
      );
      expect(find.text('今日课程'), findsOneWidget);
      expect(find.text('今天有 1 门课程'), findsOneWidget);
      expect(find.text('Course separate-today'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('root-tab-weekly')));
      await tester.pumpAndSettle();
      expect(find.text('第 5 周'), findsOneWidget);
      expect(find.byKey(const ValueKey('weekly-grid')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('390dp 七列正确布局，1.3 倍字体无溢出', (tester) async {
    await pumpWeeklyHome(
      tester,
      size: const Size(390, 844),
      textScale: 1.3,
      courses: [
        for (var day = 1; day <= 7; day++)
          course(
            'long-$day',
            weekday: day,
            start: 3,
            end: 4,
          ).copyWith(name: '很长的课程名称 $day'),
      ],
    );

    expectSevenDaysInsideViewport(tester, 390);
    expect(tester.takeException(), isNull);
    await tester.drag(
      find.byKey(const ValueKey('weekly-grid-scroll')),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('课程块按 startSection 到 endSection 跨越正确行数', (tester) async {
    await pumpWeeklyHome(
      tester,
      courses: [
        course('span', weekday: DateTime.now().weekday, start: 1, end: 2),
      ],
    );

    final rect = tester.getRect(
      find.byKey(const ValueKey('course-position-span')),
    );
    final firstRow = tester.getRect(
      find.byKey(const ValueKey('section-axis-1')),
    );
    expect(rect.height, closeTo(firstRow.height - 3, 0.01));
    expect(rect.top, closeTo(firstRow.top + 1.5, 0.01));
    expect(find.bySemanticsLabel(RegExp('.*A201.*')), findsWidgets);
    expect(find.bySemanticsLabel(RegExp('.*Teacher span.*')), findsWidgets);
  });

  testWidgets('两门冲突课程折叠为一门完整课 + 可访问的 +1 入口', (tester) async {
    final weekday = DateTime.now().weekday;
    await pumpWeeklyHome(
      tester,
      courses: [
        course('a', weekday: weekday, start: 1, end: 2),
        course('b', weekday: weekday, start: 1, end: 2),
      ],
    );

    // 不再把 51dp 宽的课程列劈成两半：并排会让两边都排不下中文，
    // 等于被迫省略。这里保持一门课全宽、信息完整，其余走 +1 入口。
    final a = tester.getRect(find.byKey(const ValueKey('course-position-a')));
    expect(find.byKey(const ValueKey('course-position-b')), findsNothing);
    final column = tester.getRect(find.byKey(ValueKey('weekday-$weekday')));
    expect(a.width, closeTo(column.width - 3, 0.01));
    expect(find.text('Course a'), findsOneWidget);

    expect(
      find.byKey(const ValueKey('course-conflict-indicator')),
      findsOneWidget,
    );
    expect(find.text('+1'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == '还有 1 门冲突课程，点按查看',
      ),
      findsOneWidget,
    );

    // 点开小签能看到同一时段的所有课程。
    await tester.tap(find.byKey(const ValueKey('course-conflict-indicator')));
    await tester.pumpAndSettle();
    expect(find.text('同一节次的课程'), findsOneWidget);
    expect(find.text('Course a'), findsWidgets);
    expect(find.text('Course b'), findsWidgets);
  });

  testWidgets('三路冲突折叠为可访问的 +N 指示', (tester) async {
    final weekday = DateTime.now().weekday;
    await pumpWeeklyHome(
      tester,
      courses: [
        course('a', weekday: weekday),
        course('b', weekday: weekday),
        course('c', weekday: weekday),
      ],
    );

    expect(
      find.byKey(const ValueKey('course-conflict-indicator')),
      findsOneWidget,
    );
    expect(find.text('+2'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == '还有 2 门冲突课程，点按查看',
      ),
      findsOneWidget,
    );
  });

  testWidgets('空周仍显示完整网格，只叠加轻量提示', (tester) async {
    await pumpWeeklyHome(tester);

    expect(find.byKey(const ValueKey('weekly-grid')), findsOneWidget);
    expect(find.byKey(const ValueKey('timetable-empty')), findsOneWidget);
    expect(find.text('本周暂无课程'), findsOneWidget);
    expectSevenDaysInsideViewport(tester, 390);
  });

  testWidgets('Loading 不会误显示本周暂无课程', (tester) async {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final semester = Semester(
      id: 'semester',
      schoolId: 'school',
      firstWeekMonday: monday,
      totalWeeks: 16,
    );
    final agenda = buildWeekAgenda(
      semester: semester,
      week: 1,
      courses: const [],
      calendar: const CalendarExceptionService(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TimetableGrid(
            agenda: agenda,
            schedule: BellSchedule.fallback(),
            loading: true,
            onCourseTap: (_) {},
            onConflictTap: (_) {},
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('timetable-loading')), findsOneWidget);
    expect(find.text('本周暂无课程'), findsNothing);
    expect(find.byKey(const ValueKey('weekly-grid')), findsOneWidget);
  });

  testWidgets('上一周、下一周与点按周标题回本周', (tester) async {
    await pumpWeeklyHome(tester);

    expect(find.text('第 4 周'), findsOneWidget);
    await tester.tap(find.byTooltip('上一周'));
    await tester.pumpAndSettle();
    expect(find.text('第 3 周'), findsOneWidget);
    expect(find.textContaining('点按回本周'), findsOneWidget);

    await tester.tap(find.text('第 3 周'));
    await tester.pumpAndSettle();
    expect(find.text('第 4 周'), findsOneWidget);

    await tester.tap(find.byTooltip('下一周'));
    await tester.pumpAndSettle();
    expect(find.text('第 5 周'), findsOneWidget);
  });

  testWidgets('水平 swipe 切周，垂直滚动不切周', (tester) async {
    await pumpWeeklyHome(tester);

    await tester.drag(
      find.byKey(const ValueKey('weekly-grid')),
      const Offset(0, -180),
    );
    await tester.pumpAndSettle();
    expect(find.text('第 4 周'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('weekly-grid')),
      const Offset(-100, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('第 5 周'), findsOneWidget);
  });

  testWidgets('课程首次点按打开预览 Sheet，再进入完整详情', (tester) async {
    final id = 'preview';
    await pumpWeeklyHome(
      tester,
      courses: [course(id, weekday: DateTime.now().weekday)],
    );

    await tester.tap(find.byKey(ValueKey('course-block-$id')));
    await tester.pumpAndSettle();
    expect(find.text('完整详情'), findsOneWidget);
    expect(find.text('编辑'), findsOneWidget);
    final previewTag =
        tester.widgetList<Hero>(find.byType(Hero)).single.tag as CourseHeroTag;
    expect(previewTag.courseId, id);
    expect(previewTag.source, CourseHeroSourceContext.weeklyTimetable);

    await tester.tap(find.text('完整详情'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('删除'), findsOneWidget);
    final detailHeroes = tester
        .widgetList<Hero>(find.byType(Hero, skipOffstage: false))
        .where(
          (hero) =>
              hero.tag is CourseHeroTag &&
              (hero.tag as CourseHeroTag).source ==
                  CourseHeroSourceContext.weeklyTimetable,
        );
    expect(detailHeroes, hasLength(2));
    expect(detailHeroes.map((hero) => hero.tag).toSet(), {previewTag});
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dark Mode 与 Reduced Motion 均可构建和切周', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await pumpWeeklyHome(tester, size: const Size(430, 932));
    expect(find.byKey(const ValueKey('weekly-grid')), findsOneWidget);

    await tester.tap(find.byTooltip('下一周'));
    await tester.pump();
    expect(find.text('第 5 周'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reduced Motion 下课程详情跳过 Hero 并使用短淡入', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final id = 'reduced-hero';
    await pumpWeeklyHome(
      tester,
      courses: [course(id, weekday: DateTime.now().weekday)],
    );

    await tester.tap(find.byKey(ValueKey('course-block-$id')));
    await tester.pumpAndSettle();
    expect(find.byType(Hero), findsNothing);
    await tester.tap(find.text('完整详情'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('删除'), findsOneWidget);
    expect(find.byType(Hero), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(768, 1024), const Size(1024, 768)]) {
    testWidgets('${size.width.toInt()}×${size.height.toInt()} 大屏使用完整七列', (
      tester,
    ) async {
      await pumpWeeklyHome(
        tester,
        size: size,
        courses: [
          course('tablet', weekday: DateTime.now().weekday, start: 2, end: 4),
        ],
      );

      expectSevenDaysInsideViewport(tester, size.width);
      expect(find.byKey(const ValueKey('course-block-tablet')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('长按周标题保留学期进度入口', (tester) async {
    await pumpWeeklyHome(tester);

    await tester.longPress(find.text('第 4 周'));
    await tester.pumpAndSettle();
    expect(find.text('第 4 / 16 周'), findsOneWidget);
    expect(find.text('阅至此处'), findsOneWidget);
  });

  /// 玻璃表面的压缩是绘制变换，布局尺寸不变，因此读变换矩阵的 x 轴尺度。
  double scaleOf(WidgetTester tester, Transform transform) =>
      transform.transform.entry(0, 0);

  Transform? ancestorTransform(WidgetTester tester, Finder finder) {
    final element = tester.element(finder);
    return element.findAncestorWidgetOfExactType<Transform>();
  }

  testWidgets('切周跟手：拖动中网格跟随手指，邻周同时在场，松手未达阈值回位', (tester) async {
    await pumpWeeklyHome(tester);

    final grid = find.byKey(const ValueKey('weekly-grid-current'));
    final rest = tester.getRect(grid);

    final gesture = await tester.startGesture(tester.getCenter(grid));
    // 手势识别后的视觉位置应与本次手指累计位移一致。
    await gesture.moveBy(const Offset(-24, 0));
    await tester.pump();
    // 继续 1:1 跟手。
    await gesture.moveBy(const Offset(-46, 0));
    await tester.pump();

    final during = tester.getRect(grid);
    expect(during.left, closeTo(rest.left - 70, 2));
    // 下一周已经在场，从右侧进入（上一周在另一侧，场外）。
    expect(find.byKey(const ValueKey('weekly-grid-next')), findsOneWidget);
    expect(
      tester.getRect(find.byKey(const ValueKey('weekly-grid-next'))).left,
      greaterThan(rest.left),
    );

    // 动画可被中断：反向拖回时从当前位置继续，而不是先播完上一段。
    await gesture.moveBy(const Offset(70, 0));
    await tester.pump();
    expect(tester.getRect(grid).left, closeTo(rest.left, 2));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('第 4 周'), findsOneWidget);
    expect(
      tester.getRect(find.byKey(const ValueKey('weekly-grid'))).left,
      closeTo(rest.left, 0.5),
    );
  });

  testWidgets('超过位置阈值即提交切换（慢速拖拽也按位置判断）', (tester) async {
    await pumpWeeklyHome(tester);

    // 慢速、超过 15% 页宽的拖拽：不靠速度也能提交。
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('weekly-grid-current'))),
    );
    await gesture.moveBy(const Offset(-20, 0)); // 越过手势识别阈值
    await tester.pump();
    for (var step = 0; step < 12; step++) {
      await gesture.moveBy(const Offset(-7, 0));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('第 5 周'), findsOneWidget);
  });

  testWidgets('切周拖过边界再回拉，以松手时的画面位置判定', (tester) async {
    await pumpWeeklyHome(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('weekly-grid-current'))),
    );
    await gesture.moveBy(const Offset(-600, 0));
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.moveBy(const Offset(350, 0));
    await tester.pump(const Duration(milliseconds: 400));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('第 4 周'), findsOneWidget);
  });

  int displayedWeek(WidgetTester tester) {
    final header = tester.widget<TimetableHeader>(find.byType(TimetableHeader));
    final grid = tester.widget<TimetableGrid>(
      find.byKey(const ValueKey('weekly-grid-current')),
    );
    expect(
      grid.agenda.days.first.date,
      header.semester.firstWeekMonday.add(
        Duration(days: (header.week - 1) * 7),
      ),
    );
    return header.week;
  }

  Future<void> slowSwipe(WidgetTester tester, double distance) async {
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(WeekSwipePager)),
    );
    await gesture.moveBy(Offset(distance.sign * 24, 0));
    await tester.pump();
    await gesture.moveBy(Offset(distance - distance.sign * 24, 0));
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
    await tester.pumpAndSettle();
  }

  for (final direction in [-1.0, 1.0]) {
    testWidgets('TASK-020A 普通滑动 $direction 只切一周', (tester) async {
      await pumpWeeklyHome(tester);
      await slowSwipe(tester, direction * 110);
      expect(displayedWeek(tester), 4 - direction.toInt());
      expect(find.text('第 ${displayedWeek(tester)} 周'), findsOneWidget);
    });

    testWidgets('TASK-020A 高速 fling $direction 只切一周', (tester) async {
      await pumpWeeklyHome(tester);
      await tester.fling(
        find.byType(WeekSwipePager),
        Offset(direction * 50, 0),
        6000,
      );
      await tester.pumpAndSettle();
      expect(displayedWeek(tester), 4 - direction.toInt());
    });

    testWidgets('TASK-020A 超长持续 drag $direction 只切一周', (tester) async {
      await pumpWeeklyHome(tester);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(WeekSwipePager)),
      );
      for (var i = 0; i < 8; i++) {
        await gesture.moveBy(Offset(direction * 300, 0));
        await tester.pump(const Duration(milliseconds: 100));
        expect(displayedWeek(tester), 4);
      }
      await gesture.up();
      await tester.pumpAndSettle();
      expect(displayedWeek(tester), 4 - direction.toInt());
    });
  }

  testWidgets('TASK-020A 阈值以下回弹后下一次独立手势正常切周', (tester) async {
    await pumpWeeklyHome(tester);
    final rest = tester.getRect(
      find.byKey(const ValueKey('weekly-grid-current')),
    );
    await slowSwipe(tester, -35);
    expect(displayedWeek(tester), 4);
    expect(
      tester.getRect(find.byKey(const ValueKey('weekly-grid-current'))),
      rest,
    );
    await slowSwipe(tester, -110);
    await slowSwipe(tester, -110);
    expect(displayedWeek(tester), 6);
  });

  testWidgets('TASK-020A 动画中按下的手势不能接管或产生第二次切周', (tester) async {
    await pumpWeeklyHome(tester);
    await tester.fling(
      find.byType(WeekSwipePager),
      const Offset(-100, 0),
      1500,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    expect(displayedWeek(tester), 4);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(WeekSwipePager)),
    );
    await gesture.moveBy(const Offset(-30, 0));
    await tester.pumpAndSettle();
    // 保持同一次 pointer session，跨过动画完成后继续长拖。
    await gesture.moveBy(const Offset(-700, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(displayedWeek(tester), 5);
    await slowSwipe(tester, -110);
    expect(displayedWeek(tester), 6);
  });

  testWidgets('TASK-020A cancel 回弹，不漂移；箭头仍各切一周', (tester) async {
    await pumpWeeklyHome(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(WeekSwipePager)),
    );
    await gesture.moveBy(const Offset(-130, 0));
    await tester.pump();
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(displayedWeek(tester), 4);
    await tester.tap(find.byTooltip('下一周'));
    await tester.pumpAndSettle();
    expect(displayedWeek(tester), 5);
    await tester.tap(find.byTooltip('上一周'));
    await tester.pumpAndSettle();
    expect(displayedWeek(tester), 4);
  });

  testWidgets('TASK-020A 动画中按下并等落位后才拖动，整次手势仍忽略', (tester) async {
    await pumpWeeklyHome(tester);
    await tester.tap(find.byTooltip('下一周'));
    await tester.pump();
    expect(displayedWeek(tester), 4);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(WeekSwipePager)),
    );
    await tester.pumpAndSettle();
    expect(displayedWeek(tester), 5);
    await gesture.moveBy(const Offset(-150, 0));
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(displayedWeek(tester), 5);
    await slowSwipe(tester, 110);
    await slowSwipe(tester, 110);
    expect(displayedWeek(tester), 3);
  });

  testWidgets('TASK-020A Reduced Motion 长拖、取消、独立手势均不漂移', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpWeeklyHome(tester);
    await slowSwipe(tester, -1500);
    expect(displayedWeek(tester), 5);
    await slowSwipe(tester, -35);
    expect(displayedWeek(tester), 5);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(WeekSwipePager)),
    );
    await gesture.moveBy(const Offset(-800, 0));
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(displayedWeek(tester), 5);
    await slowSwipe(tester, -110);
    expect(displayedWeek(tester), 6);
  });

  testWidgets('TASK-020A 第二指取消不会取消第一指的切周', (tester) async {
    await pumpWeeklyHome(tester);
    final center = tester.getCenter(find.byType(WeekSwipePager));
    final first = await tester.startGesture(center, pointer: 1);
    await first.moveBy(const Offset(-100, 0));
    await tester.pump();
    final second = await tester.startGesture(center, pointer: 2);
    await second.cancel();
    await tester.pump(const Duration(milliseconds: 500));
    await first.up();
    await tester.pumpAndSettle();
    expect(displayedWeek(tester), 5);
  });

  testWidgets('加号菜单能进入复用 Course 的单周事件编辑', (tester) async {
    await pumpWeeklyHome(tester);
    await tester.tap(find.bySemanticsLabel('打开添加菜单'));
    await tester.pumpAndSettle();
    expect(find.text('添加课程'), findsOneWidget);
    expect(find.text('导入课表'), findsOneWidget);
    expect(find.text('添加事件'), findsOneWidget);
    await tester.tap(find.text('添加事件'));
    await tester.pumpAndSettle();
    expect(find.text('添加事件'), findsOneWidget);
    expect(find.text('新增课程'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('提交判定同时看位置与速度：短距离快速 flick 也算提交', () {
    // 短距离 + 高速：按速度提交。
    expect(weekSwipeTarget(dragPixels: -20, velocityPx: -900, width: 390), -1);
    expect(weekSwipeTarget(dragPixels: 20, velocityPx: 900, width: 390), 1);
    // 长距离 + 慢速：按位置提交。
    expect(weekSwipeTarget(dragPixels: -80, velocityPx: -40, width: 390), -1);
    expect(weekSwipeTarget(dragPixels: 80, velocityPx: 40, width: 390), 1);
    // 都不够：回位。
    expect(weekSwipeTarget(dragPixels: -30, velocityPx: -120, width: 390), 0);
    // 方向由速度决定时，位置相反也不影响（用户的意图是甩动方向）。
    expect(weekSwipeTarget(dragPixels: 10, velocityPx: -1200, width: 390), -1);
  });

  testWidgets('周导航箭头也走同一段跟手过渡：周次标签滑入而不是瞬间跳变', (tester) async {
    await pumpWeeklyHome(tester);

    await tester.tap(find.byTooltip('下一周'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    // 过渡进行中：新旧周次同时在（旧值滑出、新值滑入）。
    expect(find.text('第 4 周'), findsWidgets);
    expect(find.textContaining('9.'), findsWidgets);

    await tester.pumpAndSettle();
    expect(find.text('第 5 周'), findsOneWidget);
    expect(find.text('第 4 周'), findsNothing);
  });

  testWidgets('点按课程有压缩反馈，随后升起课程预览 Sheet（课表不被顶掉）', (tester) async {
    final id = 'press';
    await pumpWeeklyHome(
      tester,
      courses: [course(id, weekday: DateTime.now().weekday)],
    );

    final block = find.byKey(ValueKey('course-block-$id'));
    final transformFinder = ancestorTransform(tester, block);
    expect(transformFinder, isNotNull);
    expect(scaleOf(tester, transformFinder!), closeTo(1, 0.001));

    final gesture = await tester.startGesture(tester.getCenter(block));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 140));
    final pressed = ancestorTransform(tester, block)!;
    expect(scaleOf(tester, pressed), lessThan(0.99));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('完整详情'), findsOneWidget);
    expect(find.text('编辑'), findsOneWidget);
    // 课表留在原位，只是退到 Sheet 后面。
    expect(find.byKey(const ValueKey('weekly-grid')), findsOneWidget);
  });

  testWidgets('顶部今日入口进入既有独立时间轴页', (tester) async {
    final weekday = DateTime.now().weekday;
    await pumpWeeklyHome(
      tester,
      courses: [course('today-1', weekday: weekday, start: 1, end: 2)],
    );

    await tester.tap(find.byTooltip('今日课程'));
    await tester.pumpAndSettle();
    expect(find.text('今日课程'), findsOneWidget);
    expect(find.text('Course today-1'), findsOneWidget);
    expect(find.textContaining('A201'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('今日课程可进入预览与详情', (tester) async {
    final weekday = DateTime.now().weekday;
    await pumpWeeklyHome(
      tester,
      courses: [
        course('today-detail', weekday: weekday, start: 1, end: 2),
        course('today-other', weekday: weekday, start: 3, end: 4),
      ],
    );
    await tester.tap(find.byTooltip('今日课程'));
    await tester.pumpAndSettle();
    final todayTags = tester
        .widgetList<Hero>(find.byType(Hero))
        .map((hero) => hero.tag as CourseHeroTag)
        .toList();
    expect(todayTags.map((tag) => tag.courseId).toSet(), {
      'today-detail',
      'today-other',
    });

    await tester.tap(find.text('Course today-detail'));
    await tester.pumpAndSettle();
    expect(find.text('完整详情'), findsOneWidget);
    expect(
      tester
          .widgetList<Hero>(find.byType(Hero))
          .where(
            (hero) =>
                (hero.tag as CourseHeroTag).courseId == 'today-detail' &&
                (hero.tag as CourseHeroTag).source ==
                    CourseHeroSourceContext.today,
          ),
      isNotEmpty,
    );
    await tester.tap(find.text('完整详情'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('删除'), findsOneWidget);
    final journeyTags = tester
        .widgetList<Hero>(find.byType(Hero, skipOffstage: false))
        .map((hero) => hero.tag)
        .whereType<CourseHeroTag>()
        .where((tag) => tag.courseId == 'today-detail')
        .toList();
    expect(journeyTags, hasLength(3));
    expect(journeyTags.map((tag) => tag.courseId).toSet(), {'today-detail'});
    expect(journeyTags.map((tag) => tag.source).toSet(), {
      CourseHeroSourceContext.today,
    });
    expect(journeyTags.map((tag) => tag.destination).toSet(), {
      CourseHeroDestination.fullDetails,
    });
    expect(tester.takeException(), isNull);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('完整详情'), findsOneWidget);
    await tester.tap(find.byTooltip('关闭课程预览'));
    await tester.pumpAndSettle();
    expect(find.text('今日课程'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('模糊只出现在导航与弹层：课程块本身不含 BackdropFilter', (tester) async {
    final weekday = DateTime.now().weekday;
    await pumpWeeklyHome(
      tester,
      courses: [course('blur-check', weekday: weekday, start: 1, end: 2)],
    );

    final blockFilters = tester.widgetList(
      find.descendant(
        of: find.byKey(const ValueKey('course-block-blur-check')),
        matching: find.byType(BackdropFilter),
      ),
    );
    expect(blockFilters, isEmpty);
    // 全屏玻璃数量受控：顶部（入口按钮 / 周导航）+ 星期栏。
    expect(tester.widgetList(find.byType(BackdropFilter)).length, lessThan(10));
  });
}
