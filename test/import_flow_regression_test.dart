import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huike_timetable/app.dart';
import 'package:huike_timetable/core/database/app_database.dart';
import 'package:huike_timetable/core/database/database_provider.dart';
import 'package:huike_timetable/core/glass/glass_button.dart';
import 'package:huike_timetable/core/glass/glass_form.dart';
import 'package:huike_timetable/core/router/app_router.dart';
import 'package:huike_timetable/features/import/pages/import_entry_page.dart';
import 'package:huike_timetable/features/import/pages/import_web_page.dart';
import 'package:huike_timetable/features/import/services/import_session.dart';
import 'package:huike_timetable/features/schools/providers/school_providers.dart';
import 'package:huike_timetable/features/timetable/pages/timetable_page.dart';
import 'package:huike_timetable/features/schools/services/adapter_catalog.dart';
import 'package:huike_timetable/features/schools/services/school_repository.dart';
import 'package:huike_timetable/models/school_profile.dart';

/// TASK-018A：导入流程回归。
///
/// 页面正文曾整块消失、CTA 恒为 disabled：`GlassButton` 在
/// `Scaffold.bottomNavigationBar` 的松约束下纵向撑满整屏，body 被挤成 0 高，
/// ListView 不构建任何子项，`RiskConfirmTile` 不在树里，勾选状态永远无法置位。
/// 离开导入 WebView 时还有两条 dispose 期异常，导致内存会话没被清掉。
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  const testCatalog = AdapterCatalog(entries: []);

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        adapterCatalogProvider.overrideWith((ref) async => testCatalog),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  void useViewport(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1,
  }) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  Future<SchoolProfile> seedSchool({String? loginUrl}) async {
    final schools = SchoolRepository(db);
    final school = await schools.createSchool(
      displayName: '导入测试大学',
      adapterId: '',
      loginUrl: loginUrl ?? '',
      confirmedHosts: const [],
    );
    await schools.setActiveSchool(school.id);
    return school;
  }

  /// 走真实路由（`/import`）打开导入入口页。
  Future<ProviderContainer> pumpImportRoute(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    useViewport(tester, size: size, textScale: textScale);

    final container = makeContainer();
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const HuikeApp()),
    );
    await tester.pumpAndSettle();
    container.read(appRouterProvider).push('/import');
    await tester.pumpAndSettle();
    return container;
  }

  /// 直接挂载页面：空 / 加载 / 失败这些状态下路由会重定向，不能走 `/import`。
  Future<void> pumpImportPage(
    WidgetTester tester,
    ProviderContainer container, {
    Size size = const Size(390, 844),
    double textScale = 1,
    bool settle = true,
  }) async {
    useViewport(tester, size: size, textScale: textScale);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ImportEntryPage()),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  GlassButton cta(WidgetTester tester) => tester.widget<GlassButton>(
    find.widgetWithText(GlassButton, '确认并进入教务登录'),
  );

  /// 命令式 `push` 之后 go_router 的 location 访问器仍返回基线位置，
  /// 路由断言一律用页面 widget 本身，也顺带验证了路由参数的接线。
  /// 被压在下层的路由仍留在树里但不可见，所以按默认跳过 offstage 判定。
  void expectOnImportEntry({required bool visible}) {
    expect(find.byType(ImportEntryPage), visible ? findsOneWidget : findsNothing);
  }

  /// WebView 在 widget test 里没有平台实现；消费掉这条预期内的断言，
  /// 返回页面 widget 以便断言 route / arguments 是否传对。
  ImportWebPage webPage(WidgetTester tester) {
    final finder = find.byType(ImportWebPage, skipOffstage: false);
    expect(finder, findsOneWidget);
    final exception = '${tester.takeException()}';
    expect(exception, contains('InAppWebViewPlatform'));
    return tester.widget<ImportWebPage>(finder);
  }

  testWidgets('打开导入页正文非空白，且 CTA 未满足条件时 disabled', (tester) async {
    await seedSchool(loginUrl: 'https://jw.example.edu.cn');
    await pumpImportRoute(tester);
    // 正文不是空白：标题、学校、步骤、网址输入、确认门都在。
    expect(find.text('导入教务课表'), findsOneWidget);
    expect(find.text('学校'), findsOneWidget);
    expect(find.text('导入测试大学'), findsOneWidget);
    expect(find.text('导入步骤'), findsOneWidget);
    expect(find.text('教务网址'), findsOneWidget);
    expect(find.byType(GlassTextField), findsOneWidget);
    expect(find.text('登录安全提示'), findsOneWidget);
    expect(
      find.text('我确认以上地址是我学校自己的教务系统'),
      findsOneWidget,
    );

    // body 有真实可用高度，不是被底部按钮挤成 0。
    final body = tester.getRect(find.byType(ListView));
    expect(body.height, greaterThan(300));

    // 前置条件未满足：CTA 禁用。
    expect(cta(tester).onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('勾选确认项后 CTA 启用，点击进入教务登录路由', (tester) async {
    final school = await seedSchool(loginUrl: 'https://jw.example.edu.cn');
    final container = await pumpImportRoute(tester);
    expect(cta(tester).onPressed, isNull);

    // 真实点击页面上的确认项，不走 onPressed 直调。
    await tester.tap(find.text('我确认以上地址是我学校自己的教务系统'));
    await tester.pumpAndSettle();

    expect(cta(tester).onPressed, isNotNull);
    expectOnImportEntry(visible: true);

    await tester.tap(find.text('确认并进入教务登录'));
    await tester.pumpAndSettle();

    // 先出确认弹窗，确认后才进入 WebView 登录路由。
    expect(find.text('进入教务登录页'), findsOneWidget);
    expect(find.textContaining('jw.example.edu.cn'), findsWidgets);
    await tester.tap(find.text('继续'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // 进入 WebView 路由，且 host / 初始地址按候选地址传参。
    final page = webPage(tester);
    expect(page.host, 'jw.example.edu.cn');
    expect(page.initialUrl, 'https://jw.example.edu.cn');
    expectOnImportEntry(visible: false);

    // 候选地址已写入该学校确认过的主机，导航白名单随之更新。
    expect(
      container.read(activeSchoolProvider)!.acceptedHosts,
      contains('jw.example.edu.cn'),
    );
    expect(
      container.read(activeSchoolProvider)!.id,
      school.id,
    );
  });

  testWidgets('取消确认弹窗不进入 WebView', (tester) async {
    await seedSchool(loginUrl: 'https://jw.example.edu.cn');
    await pumpImportRoute(tester);

    await tester.tap(find.text('我确认以上地址是我学校自己的教务系统'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认并进入教务登录'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expectOnImportEntry(visible: true);
    expect(find.byType(ImportWebPage, skipOffstage: false), findsNothing);
    expect(cta(tester).onPressed, isNotNull);
  });

  testWidgets('非法网址停在导入页并给出提示', (tester) async {
    await seedSchool();
    await pumpImportRoute(tester);

    await tester.enterText(
      find.byType(TextField),
      'ftp://jw.example.edu.cn',
    );
    await tester.tap(find.text('我确认以上地址是我学校自己的教务系统'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认并进入教务登录'));
    await tester.pumpAndSettle();

    expect(find.text('进入教务登录页'), findsNothing);
    expect(find.byType(ImportWebPage, skipOffstage: false), findsNothing);
    expectOnImportEntry(visible: true);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('学校信息加载中显示加载态而不是空白页', (tester) async {
    await pumpImportPage(
      tester,
      // 永不发射的流：保持首次加载状态。
      ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          adapterCatalogProvider.overrideWith((ref) async => testCatalog),
          schoolsProvider.overrideWith((ref) => const Stream.empty()),
        ],
      ),
      settle: false,
    );

    expect(find.byKey(const ValueKey('import-loading')), findsOneWidget);
    expect(find.text('正在读取学校信息…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(GlassTextField), findsNothing);
  });

  testWidgets('学校信息读取失败显示错误态与重试', (tester) async {
    await pumpImportPage(
      tester,
      ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          adapterCatalogProvider.overrideWith((ref) async => testCatalog),
          schoolsProvider.overrideWith(
            (ref) => Stream<List<SchoolProfile>>.error(StateError('boom')),
          ),
        ],
      ),
    );

    expect(find.byKey(const ValueKey('import-error')), findsOneWidget);
    expect(find.text('读不到学校信息，请重试。'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);

    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('import-error')), findsOneWidget);
  });

  testWidgets('确实没有学校时显示空状态并能去建校', (tester) async {
    await pumpImportPage(tester, makeContainer());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('import-empty')), findsOneWidget);
    expect(find.text('先创建学校再导入'), findsOneWidget);
    expect(find.text('去创建学校'), findsOneWidget);
    // 没有学校时不给出会永远 disabled 的伪 CTA。
    expect(find.text('确认并进入教务登录'), findsNothing);
  });

  testWidgets('390dp 视口无 overflow，CTA 固定在底部安全区', (tester) async {
    await seedSchool(loginUrl: 'https://jw.example.edu.cn');
    await pumpImportRoute(tester, size: const Size(390, 844));

    final button = tester.getRect(
      find.widgetWithText(GlassButton, '确认并进入教务登录'),
    );
    expect(button.bottom, lessThanOrEqualTo(844));
    expect(button.height, greaterThanOrEqualTo(44));
    expect(tester.takeException(), isNull);
  });

  testWidgets('text scale 1.3 无 overflow', (tester) async {
    await seedSchool(loginUrl: 'https://jw.example.edu.cn');
    await pumpImportRoute(tester, textScale: 1.3);

    expect(find.text('导入步骤'), findsOneWidget);
    expect(find.text('确认并进入教务登录'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('键盘弹起时网址输入与 CTA 仍可见且可滚动', (tester) async {
    await seedSchool(loginUrl: 'https://jw.example.edu.cn');
    await pumpImportRoute(tester);

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 336);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();

    expect(find.byType(GlassTextField), findsOneWidget);
    final button = tester.getRect(
      find.widgetWithText(GlassButton, '确认并进入教务登录'),
    );
    expect(button.bottom, lessThanOrEqualTo(844 - 336));
    expect(tester.takeException(), isNull);

    // 正文仍可滚动到确认项。
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(find.text('登录安全提示'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('系统返回可从导入页回到上一级', (tester) async {
    await seedSchool(loginUrl: 'https://jw.example.edu.cn');
    final container = await pumpImportRoute(tester);
    expectOnImportEntry(visible: true);

    // Android system back / iOS pop 都走路由返回，这里不涉及根路由双返回。
    final router = container.read(appRouterProvider);
    expect(router.canPop(), isTrue);
    router.pop();
    await tester.pumpAndSettle();

    expectOnImportEntry(visible: false);
    expect(find.byType(ImportWebPage, skipOffstage: false), findsNothing);
    // 回到课表首页（本用例未设学期，首页是种子学校 + 建学期提示）。
    expect(find.byType(TimetablePage), findsOneWidget);
    expect(find.text('导入测试大学'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('导入入口页保持原有步骤文案与适配器免选择说明', (tester) async {
    await seedSchool(loginUrl: 'https://jw.example.edu.cn');
    await pumpImportRoute(tester);

    // 学生不需要选教务系统类型：步骤里直接写「执行导入」自动适配。
    expect(find.text('教务网址'), findsOneWidget);
    expect(find.textContaining('点右上角「执行导入」'), findsOneWidget);
    expect(
      find.textContaining('账号密码只在贵校官方页面输入'),
      findsOneWidget,
    );
  });

  testWidgets('离开导入 WebView 会清空内存导入会话', (tester) async {
    await seedSchool(loginUrl: 'https://jw.example.edu.cn');
    final container = await pumpImportRoute(tester);

    await tester.tap(find.text('我确认以上地址是我学校自己的教务系统'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认并进入教务登录'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('继续'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    webPage(tester);

    // 模拟桥写入的原始数据（只驻留内存）。
    container
        .read(importSessionProvider.notifier)
        .stageCourses('[{"name":"城市设计","weekday":1,"section":1}]');
    await tester.pump();
    expect(container.read(importSessionProvider).rawCourses, isNotNull);

    // 离开导入页：会话必须被清掉，且离开过程不抛异常。
    container.read(appRouterProvider).pop();
    await tester.pumpAndSettle();

    expect(container.read(importSessionProvider).rawCourses, isNull);
    expect(container.read(importSessionProvider).rawTimeSlots, isNull);
    expect(container.read(importSessionProvider).normalized, isNull);
    expect(find.byType(ImportWebPage, skipOffstage: false), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
