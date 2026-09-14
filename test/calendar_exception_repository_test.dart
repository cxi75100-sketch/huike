// drift 也导出 isNull/isNotNull，会和 flutter_test 的 matcher 撞名。
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huike_timetable/core/database/app_database.dart';
import 'package:huike_timetable/features/schools/services/calendar_exception_repository.dart';
import 'package:huike_timetable/features/schools/services/school_repository.dart';
import 'package:huike_timetable/models/calendar_exception.dart';
import 'package:huike_timetable/services/calendar_exception_service.dart';

void main() {
  late AppDatabase db;
  late SchoolRepository schools;
  late CalendarExceptionRepository calendar;
  late String schoolId;
  late String semesterId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    schools = SchoolRepository(db);
    calendar = CalendarExceptionRepository(db);
    final school = await schools.createSchool(
      displayName: '测试大学',
      adapterId: '',
      loginUrl: '',
      confirmedHosts: const [],
    );
    schoolId = school.id;
    final semester = await schools.createSemester(
      schoolId: schoolId,
      firstWeekMonday: DateTime(2026, 8, 31),
      totalWeeks: 20,
    );
    semesterId = semester.id;
  });

  tearDown(() async {
    await db.close();
  });

  Future<List<CalendarException>> readAll() async {
    final rows =
        await (db.select(db.calendarExceptions)
              ..where((t) => t.schoolId.equals(schoolId))
              ..orderBy([(t) => OrderingTerm.asc(t.dateIso)]))
            .get();
    return rows.map((row) => row.toModel()).toList();
  }

  test('写入停课后可读回，解析器据此判停课', () async {
    await calendar.save(
      schoolId: schoolId,
      semesterId: semesterId,
      date: DateTime(2026, 10, 1, 18, 30),
      kind: CalendarExceptionKind.holiday,
      note: '国庆',
    );

    final rows = await readAll();
    expect(rows.length, 1);
    expect(rows.single.kind, CalendarExceptionKind.holiday);
    expect(rows.single.date, DateTime(2026, 10, 1)); // 时刻被裁掉
    expect(rows.single.note, '国庆');
    expect(rows.single.makeupWeekday, isNull);

    final service = CalendarExceptionService(rows);
    expect(service.resolve(DateTime(2026, 10, 1)).suspended, isTrue);
  });

  test('调休写入 makeupWeekday；同一天写第二次是覆盖不是叠加', () async {
    await calendar.save(
      schoolId: schoolId,
      semesterId: semesterId,
      date: DateTime(2026, 10, 10),
      kind: CalendarExceptionKind.makeup,
      makeupWeekday: DateTime.thursday,
    );
    await calendar.save(
      schoolId: schoolId,
      semesterId: semesterId,
      date: DateTime(2026, 10, 10),
      kind: CalendarExceptionKind.holiday,
    );

    final rows = await readAll();
    expect(rows.length, 1);
    expect(rows.single.kind, CalendarExceptionKind.holiday);
  });

  test('带 id 编辑并把日期改到别的天，旧日期不残留', () async {
    final created = await calendar.save(
      schoolId: schoolId,
      semesterId: semesterId,
      date: DateTime(2026, 10, 1),
      kind: CalendarExceptionKind.holiday,
    );
    await calendar.save(
      id: created.id,
      schoolId: schoolId,
      semesterId: semesterId,
      date: DateTime(2026, 10, 2),
      kind: CalendarExceptionKind.makeup,
      makeupWeekday: DateTime.monday,
    );

    final rows = await readAll();
    expect(rows.length, 1);
    expect(rows.single.date, DateTime(2026, 10, 2));
    expect(rows.single.kind, CalendarExceptionKind.makeup);
    expect(rows.single.makeupWeekday, DateTime.monday);
  });

  test('停课写入时忽略传入的 makeupWeekday', () async {
    await calendar.save(
      schoolId: schoolId,
      semesterId: semesterId,
      date: DateTime(2026, 10, 1),
      kind: CalendarExceptionKind.holiday,
      makeupWeekday: DateTime.friday,
    );
    expect((await readAll()).single.makeupWeekday, isNull);
  });

  test('删除只删指定记录', () async {
    final first = await calendar.save(
      schoolId: schoolId,
      semesterId: semesterId,
      date: DateTime(2026, 10, 1),
      kind: CalendarExceptionKind.holiday,
    );
    await calendar.save(
      schoolId: schoolId,
      semesterId: semesterId,
      date: DateTime(2026, 10, 2),
      kind: CalendarExceptionKind.holiday,
    );

    await calendar.deleteById(first.id);

    final rows = await readAll();
    expect(rows.length, 1);
    expect(rows.single.date, DateTime(2026, 10, 2));
  });

  test('跨校隔离：另一所学校的同名日期互不影响', () async {
    final other = await schools.createSchool(
      displayName: '另一所大学',
      adapterId: '',
      loginUrl: '',
      confirmedHosts: const [],
    );
    final otherSemester = await schools.createSemester(
      schoolId: other.id,
      firstWeekMonday: DateTime(2026, 8, 31),
      totalWeeks: 20,
    );

    await calendar.save(
      schoolId: other.id,
      semesterId: otherSemester.id,
      date: DateTime(2026, 10, 1),
      kind: CalendarExceptionKind.holiday,
    );

    expect(await readAll(), isEmpty);
  });

  test('删除学校会级联清掉例外', () async {
    await calendar.save(
      schoolId: schoolId,
      semesterId: semesterId,
      date: DateTime(2026, 10, 1),
      kind: CalendarExceptionKind.holiday,
    );
    await schools.deleteSchool(schoolId);
    expect(await readAll(), isEmpty);
  });
}
