import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:huike_timetable/core/router/glass_page.dart';
import 'package:huike_timetable/app.dart';
import 'package:huike_timetable/core/database/app_database.dart';
import 'package:huike_timetable/core/database/database_provider.dart';
import 'package:huike_timetable/core/glass/glass_button.dart';
import 'package:huike_timetable/core/glass/glass_dialog.dart';
import 'package:huike_timetable/core/glass/glass_motion.dart';
import 'package:huike_timetable/core/glass/glass_transition.dart';
import 'package:huike_timetable/core/router/app_router.dart';
import 'package:huike_timetable/features/import/services/course_repository.dart';
import 'package:huike_timetable/features/schools/services/adapter_catalog.dart';
import 'package:huike_timetable/features/schools/services/school_repository.dart';
import 'package:huike_timetable/features/settings/pages/settings_page.dart';
import 'package:huike_timetable/features/timetable/pages/course_detail_page.dart';
import 'package:huike_timetable/features/timetable/widgets/liquid_add_button.dart';
import 'package:huike_timetable/models/course.dart';

void main() {
  for (final reduced in [false, true]) {
    testWidgets('iOS普通页面保留边缘返回手势 reduced=$reduced', (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: TextButton(
                onPressed: () => context.push('/next'),
                child: const Text('open'),
              ),
            ),
          ),
          GoRoute(
            path: '/next',
            pageBuilder: (context, state) => glassPage(
              context: context,
              state: state,
              child: const Scaffold(body: Center(child: Text('next'))),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          theme: ThemeData(platform: TargetPlatform.iOS),
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            child: child!,
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(router.canPop(), isTrue);
      await tester.dragFrom(const Offset(2, 300), const Offset(650, 0));
      await tester.pumpAndSettle();
      expect(router.canPop(), isFalse);
      expect(find.text('open'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  setUpAll(() async {
    if (Platform.environment['HUIKE_MOTION_QA_DIR'] == null) return;
    TestWidgetsFlutterBinding.ensureInitialized();
    await (FontLoader('Roboto')..addFont(
          File('C:/Windows/Fonts/msyh.ttc')
              .readAsBytes()
              .then(ByteData.sublistView),
        ))
        .load();
    await (FontLoader('Ahem')..addFont(
          File('C:/Windows/Fonts/msyh.ttc')
              .readAsBytes()
              .then(ByteData.sublistView),
        ))
        .load();
    await (FontLoader('MaterialIcons')..addFont(
          File(
            'D:/Tools/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
          ).readAsBytes().then(ByteData.sublistView),
        ))
        .load();
  });

  Future<void> capture(WidgetTester tester, String name) async {
    final directory = Platform.environment['HUIKE_MOTION_QA_DIR'];
    if (directory == null) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('motion-qa-screen')),
    );
    await tester.runAsync(() async {
      final picture = await boundary.toImage();
      final data = await picture.toByteData(format: ui.ImageByteFormat.png);
      await Directory(directory).create(recursive: true);
      await File('$directory/$name.png')
          .writeAsBytes(data!.buffer.asUint8List());
      picture.dispose();
    });
  }

  testWidgets('普通transition只做短距离绘制变换，内容不随帧重建', (tester) async {
    final controller = AnimationController(
      vsync: tester,
      duration: GlassMotion.pageEnter,
    );
    addTearDown(controller.dispose);
    var builds = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: GlassTransition(
          animation: controller,
          child: Builder(
            builder: (_) {
              builds++;
              return const SizedBox.expand(key: ValueKey('content'));
            },
          ),
        ),
      ),
    );
    controller.forward();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('content'))).dy,
      inInclusiveRange(0, 12),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(const ValueKey('content'))).dy, 0);
    expect(builds, 1);
    controller.reverse();
    await tester.pumpAndSettle();
    expect(builds, 1);
  });

  testWidgets('普通transition中途反向保持当前geometry连续', (tester) async {
    final controller = AnimationController(
      vsync: tester,
      duration: GlassMotion.pageEnter,
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: GlassTransition(
          animation: controller,
          child: const SizedBox.expand(key: ValueKey('reverse-content')),
        ),
      ),
    );
    controller.forward();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));
    final before = tester.getTopLeft(
      find.byKey(const ValueKey('reverse-content')),
    );
    controller.reverse();
    await tester.pump();
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('reverse-content'))),
      before,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reduced Motion按压不缩放，功能仍可立即触发', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: GlassButton(label: '操作', onPressed: () => taps++),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('操作')),
    );
    await tester.pump();
    for (final transform in tester.widgetList<Transform>(
      find.byType(Transform),
    )) {
      expect(transform.transform.entry(0, 0), 1);
      expect(transform.transform.entry(1, 1), 1);
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('菜单收起期间保留内容但不接受操作，结束才卸载可见树', (tester) async {
    final scrolling = ValueNotifier(false);
    addTearDown(scrolling.dispose);
    var actions = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.bottomRight,
          child: LiquidAddButton(
            scrolling: scrolling,
            onPressed: () => actions++,
          ),
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel('打开添加菜单'));
    await tester.pumpAndSettle();
    expect(find.text('添加课程'), findsOneWidget);
    final openTop = tester.getTopLeft(find.text('添加课程')).dy;
    await tester.tap(find.bySemanticsLabel('关闭添加菜单'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(find.text('添加课程'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('添加课程')).dy,
      greaterThanOrEqualTo(openTop),
    );
    await tester.tap(find.text('添加课程'), warnIfMissed: false);
    expect(actions, 0);
    await tester.pumpAndSettle();
    expect(find.text('添加课程'), findsNothing);
  });

  for (final dark in [false, true]) {
    for (final reduced in [false, true]) {
      testWidgets('Motion页面/overlay journey dark=$dark reduced=$reduced', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            FakeAccessibilityFeatures(disableAnimations: reduced);
        addTearDown(tester.view.reset);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        final db = AppDatabase(NativeDatabase.memory());
        final schools = SchoolRepository(db);
        final school = await schools.createSchool(
          displayName: 'Motion QA',
          adapterId: '',
          loginUrl: '',
          confirmedHosts: const [],
        );
        final now = DateTime.now();
        final monday = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: now.weekday - 1 + 21));
        final semester = await schools.createSemester(
          schoolId: school.id,
          firstWeekMonday: monday,
          totalWeeks: 16,
        );
        final course = Course(
          id: 'motion-course',
          schoolId: school.id,
          semesterId: semester.id,
          name: '线性代数',
          teacher: 'QA教师',
          classroom: 'A201',
          weekday: now.weekday,
          startSection: 1,
          endSection: 2,
          weeks: const [4],
          startTime: '08:20',
          endTime: '09:50',
        );
        await CourseRepository(db).addManualCourse(
          schoolId: school.id,
          semesterId: semester.id,
          course: course,
        );
        await schools.setActiveSchool(school.id);
        await db.setSetting('theme_mode', dark ? 'dark' : 'light');
        final container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            adapterCatalogProvider.overrideWith(
              (ref) async => const AdapterCatalog(entries: []),
            ),
          ],
        );
        addTearDown(() async {
          container.dispose();
          await db.close();
        });
        await tester.pumpWidget(
          RepaintBoundary(
            key: const ValueKey('motion-qa-screen'),
            child: UncontrolledProviderScope(
              container: container,
              child: const HuikeApp(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final tag =
            '${dark ? 'dark' : 'light'}-${reduced ? 'reduced' : 'normal'}';
        await capture(tester, '$tag-weekly');

        final router = container.read(appRouterProvider);
        for (final route in [
          '/today',
          '/settings',
          '/course/motion-course',
          '/course/new',
          '/import',
        ]) {
          router.push(route);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 50));
          final name = route == '/course/motion-course'
              ? 'detail'
              : route == '/course/new'
              ? 'edit'
              : route.substring(1);
          if (route == '/settings') {
            final position = tester.getTopLeft(find.byType(SettingsPage));
            expect(position.dy, reduced ? 0 : inInclusiveRange(0, 12));
          }
          await capture(tester, '$tag-$name-mid');
          await tester.pumpAndSettle();
          if (route == '/course/motion-course') {
            expect(find.byType(CourseDetailPage), findsOneWidget);
          }
          expect(tester.takeException(), isNull);
          await capture(tester, '$tag-$name');
          if (route == '/course/new') {
            await tester.tap(find.text('添加课程'));
            await tester.pump();
            await tester.pump(GlassMotion.snackEnter);
            expect(find.text('课程名不能为空'), findsOneWidget);
            await capture(tester, '$tag-snackbar');
            ScaffoldMessenger.of(tester.element(find.byType(SnackBar)))
                .removeCurrentSnackBar();
          }
          router.pop();
          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('weekly-grid')), findsOneWidget);
        }

        final context = tester.element(
          find.byKey(const ValueKey('weekly-grid')),
        );
        Object? result;
        showGlassDialog<String>(
          context: context,
          builder: (dialogContext) => GlassDialog(
            title: const Text('Motion Dialog'),
            content: const Text('普通确认框的连续过渡'),
            actions: [
              GlassDialogAction(
                label: '确认',
                onPressed: () => Navigator.of(dialogContext).pop('ok'),
              ),
            ],
          ),
        ).then((value) => result = value);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await capture(tester, '$tag-dialog-mid');
        await tester.pumpAndSettle();
        await capture(tester, '$tag-dialog');
        await tester.tap(find.text('确认'));
        await tester.pumpAndSettle();
        expect(result, 'ok');
        expect(find.byType(GlassDialog), findsNothing);

        await tester.longPress(find.text('第 4 周'));
        await tester.pumpAndSettle();
        expect(find.text('第 4 / 16 周'), findsOneWidget);
        await capture(tester, '$tag-sheet');
        await tester.tapAt(const Offset(10, 220));
        await tester.pumpAndSettle();
        expect(find.text('第 4 / 16 周'), findsNothing);

        await tester.tap(find.bySemanticsLabel('打开添加菜单'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await capture(tester, '$tag-menu-mid');
        await tester.pumpAndSettle();
        await capture(tester, '$tag-menu');
        await tester.tap(find.text('添加事件'));
        await tester.pumpAndSettle();
        expect(find.text('添加事件'), findsWidgets);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
