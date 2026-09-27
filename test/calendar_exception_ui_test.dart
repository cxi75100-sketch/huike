import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huike_timetable/app.dart';
import 'package:huike_timetable/core/database/app_database.dart';
import 'package:huike_timetable/core/database/database_provider.dart';
import 'package:huike_timetable/features/schools/services/adapter_catalog.dart';
import 'package:huike_timetable/features/schools/services/calendar_exception_repository.dart';
import 'package:huike_timetable/features/schools/services/school_repository.dart';
import 'package:huike_timetable/models/calendar_exception.dart';

/// TASK-004 的界面接线：例外写进去之后，Weekly Grid 与设置页要如实反映。
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

  /// 建一所学校 + 一个「今天落在学期内」的学期并设为激活。
  /// 返回容器与 schoolId / semesterId，供测试直接写例外。
  Future<(ProviderContainer, String, String)> pumpSchool(
    WidgetTester tester,
  ) async {
    final container = await pumpApp(tester);
    final repository = container.read(schoolRepositoryProvider);
    final school = await repository.createSchool(
      displayName: '调休大学',
      adapterId: '',
      loginUrl: '',
      confirmedHosts: const [],
    );
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final semester = await repository.createSemester(
      schoolId: school.id,
      firstWeekMonday: DateTime(monday.year, monday.month, monday.day),
      totalWeeks: 16,
    );
    await repository.setActiveSchool(school.id);
    await tester.pumpAndSettle();
    return (container, school.id, semester.id);
  }

  testWidgets('今天标为停课时 Weekly Grid 的当天列明确标记停课', (tester) async {
    final (container, schoolId, semesterId) = await pumpSchool(tester);

    await container
        .read(calendarExceptionRepositoryProvider)
        .save(
          schoolId: schoolId,
          semesterId: semesterId,
          date: DateTime.now(),
          kind: CalendarExceptionKind.holiday,
          note: '国庆',
        );
    await tester.pumpAndSettle();

    expect(find.text('停课'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            (widget.properties.label ?? '').contains('今天，停课'),
      ),
      findsOneWidget,
    );
    expect(find.text('今日无课'), findsNothing);
  });

  testWidgets('今天标为调休时 Weekly Grid 的当天列说明折算星期', (tester) async {
    final (container, schoolId, semesterId) = await pumpSchool(tester);

    await container
        .read(calendarExceptionRepositoryProvider)
        .save(
          schoolId: schoolId,
          semesterId: semesterId,
          date: DateTime.now(),
          kind: CalendarExceptionKind.makeup,
          makeupWeekday: DateTime.friday,
        );
    await tester.pumpAndSettle();

    expect(find.text('调休'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            (widget.properties.label ?? '').contains('今天，按周五上课'),
      ),
      findsOneWidget,
    );
    expect(find.text('停课'), findsNothing);
  });

  testWidgets('设置里能进入「调休 / 停课」页，且列出已保存的例外', (tester) async {
    final (container, schoolId, semesterId) = await pumpSchool(tester);
    await container
        .read(calendarExceptionRepositoryProvider)
        .save(
          schoolId: schoolId,
          semesterId: semesterId,
          date: DateTime.now(),
          kind: CalendarExceptionKind.holiday,
        );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('设置'));
    await tester.pumpAndSettle();
    expect(find.text('当前学校'), findsOneWidget);
    expect(find.text('调休大学'), findsWidgets);
    await tester.tap(find.text('调休 / 停课'));
    await tester.pumpAndSettle();

    // 页面上出现编辑入口与这条约定；空状态文案不应出现。
    expect(find.text('添加'), findsOneWidget);
    expect(find.textContaining('停课'), findsWidgets);
    expect(find.text('还没有例外'), findsNothing);
  });
}
