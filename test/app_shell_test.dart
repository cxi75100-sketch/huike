import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huike_timetable/app.dart';
import 'package:huike_timetable/core/database/app_database.dart';
import 'package:huike_timetable/core/database/database_provider.dart';
import 'package:huike_timetable/features/schools/providers/school_providers.dart';
import 'package:huike_timetable/features/schools/services/adapter_catalog.dart';
import 'package:huike_timetable/features/schools/services/school_repository.dart';

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
      UncontrolledProviderScope(
        container: container,
        child: const HuikeApp(),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('全新安装先进入引导页', (tester) async {
    await pumpApp(tester);
    expect(find.text('欢迎使用汇课'), findsOneWidget);
    expect(find.text('创建学校'), findsOneWidget);
  });

  testWidgets('创建学校与学期后进入课表首页', (tester) async {
    final container = await pumpApp(tester);

    await tester.enterText(
      find.widgetWithText(TextField, '学校名称（必填）'),
      '测试大学',
    );
    await tester.tap(find.text('创建学校'));
    await tester.pumpAndSettle();

    final activeId = container.read(activeSchoolIdProvider).value;
    expect(activeId, isNotNull);

    // 首页出现「今日 / 整周」两个栏目与加课入口。
    expect(find.text('今日'), findsOneWidget);
    expect(find.text('整周'), findsOneWidget);
    expect(find.text('加课'), findsOneWidget);
  });

  testWidgets('空课日显示历书式空状态', (tester) async {
    final container = await pumpApp(tester);
    final repository = container.read(schoolRepositoryProvider);
    final school = await repository.createSchool(
      displayName: '空课大学',
      adapterId: '',
      loginUrl: '',
      confirmedHosts: const [],
    );
    // 开学周一放在很远的未来，今天必然「今日无课」且不在学期内。
    final future = DateTime.now().add(const Duration(days: 90));
    final monday = future.subtract(Duration(days: future.weekday - 1));
    await repository.createSemester(
      schoolId: school.id,
      firstWeekMonday: DateTime(monday.year, monday.month, monday.day),
      totalWeeks: 16,
    );
    await repository.setActiveSchool(school.id);
    await tester.pumpAndSettle();

    expect(find.text('今日无课'), findsOneWidget);
    // 学期未开始的提示条可见。
    expect(find.textContaining('学期尚未开始'), findsOneWidget);
  });
}
