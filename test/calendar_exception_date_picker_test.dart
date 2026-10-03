import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huike_timetable/app.dart';
import 'package:huike_timetable/core/database/app_database.dart';
import 'package:huike_timetable/core/database/database_provider.dart';
import 'package:huike_timetable/features/schools/services/adapter_catalog.dart';
import 'package:huike_timetable/features/schools/services/calendar_exception_repository.dart';
import 'package:huike_timetable/features/schools/services/school_repository.dart';
import 'package:huike_timetable/models/calendar_exception.dart';

void main() {
  late AppDatabase db;
  late SchoolRepository schools;
  late String schoolId;
  late String semesterId;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    schools = SchoolRepository(db);
  });

  tearDown(() => db.close());

  Future<void> pumpCalendar(
    WidgetTester tester, {
    required DateTime monday,
    int totalWeeks = 16,
    DateTime? existingDate,
  }) async {
    final school = await schools.createSchool(
      displayName: '校历测试大学',
      adapterId: '',
      loginUrl: '',
      confirmedHosts: const [],
    );
    schoolId = school.id;
    final semester = await schools.createSemester(
      schoolId: schoolId,
      firstWeekMonday: monday,
      totalWeeks: totalWeeks,
    );
    semesterId = semester.id;
    await schools.setActiveSchool(schoolId);
    if (existingDate != null) {
      await CalendarExceptionRepository(db).save(
        schoolId: schoolId,
        semesterId: semesterId,
        date: existingDate,
        kind: CalendarExceptionKind.holiday,
      );
    }

    const catalog = AdapterCatalog(entries: []);
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        adapterCatalogProvider.overrideWith((ref) async => catalog),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const HuikeApp()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('调休 / 停课'));
    await tester.pumpAndSettle();
  }

  Future<DatePickerDialog> openPicker(
    WidgetTester tester, {
    bool edit = false,
  }) async {
    if (edit) {
      await tester.tap(find.byTooltip('更多'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('修改'));
    } else {
      await tester.tap(find.text('添加'));
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    return tester.widget<DatePickerDialog>(find.byType(DatePickerDialog));
  }

  testWidgets('当前学期新增：今天在范围内时默认选今天，范围不变', (tester) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1));
    await pumpCalendar(tester, monday: monday);

    final picker = await openPicker(tester);
    expect(picker.initialDate, today);
    expect(picker.firstDate, monday.subtract(const Duration(days: 30)));
    expect(picker.lastDate, monday.add(const Duration(days: 16 * 7 + 30)));
  });

  testWidgets('历史学期新增：今天晚于范围时以 lastDate 打开', (tester) async {
    final monday = DateTime(2020, 1, 6);
    await pumpCalendar(tester, monday: monday);

    final picker = await openPicker(tester);
    expect(picker.initialDate, picker.lastDate);
    expect(picker.firstDate, monday.subtract(const Duration(days: 30)));
    expect(picker.lastDate, monday.add(const Duration(days: 16 * 7 + 30)));
  });

  testWidgets('未来学期新增：今天早于范围时以 firstDate 打开', (tester) async {
    final monday = DateTime(2032, 1, 5);
    await pumpCalendar(tester, monday: monday);

    final picker = await openPicker(tester);
    expect(picker.initialDate, picker.firstDate);
    expect(picker.firstDate, monday.subtract(const Duration(days: 30)));
    expect(picker.lastDate, monday.add(const Duration(days: 16 * 7 + 30)));
  });

  testWidgets('编辑范围内的已有例外：保持原日期', (tester) async {
    final monday = DateTime(2020, 1, 6);
    final existing = DateTime(2020, 1, 20);
    await pumpCalendar(tester, monday: monday, existingDate: existing);

    final picker = await openPicker(tester, edit: true);
    expect(picker.initialDate, existing);
    expect(picker.firstDate, monday.subtract(const Duration(days: 30)));
    expect(picker.lastDate, monday.add(const Duration(days: 16 * 7 + 30)));
  });

  testWidgets('编辑意外超范围的已有例外：初始值夹到边界', (tester) async {
    final monday = DateTime(2020, 1, 6);
    await pumpCalendar(
      tester,
      monday: monday,
      existingDate: DateTime(2019, 1, 1),
    );

    final picker = await openPicker(tester, edit: true);
    expect(picker.initialDate, picker.firstDate);
    expect(picker.firstDate, monday.subtract(const Duration(days: 30)));
    expect(picker.lastDate, monday.add(const Duration(days: 16 * 7 + 30)));
  });
}
