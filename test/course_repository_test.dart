import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huike_timetable/core/database/app_database.dart';
import 'package:huike_timetable/features/import/models/adapter_batch.dart';
import 'package:huike_timetable/features/import/services/course_repository.dart';
import 'package:huike_timetable/features/schools/services/school_repository.dart';
import 'package:huike_timetable/models/bell_schedule.dart';
import 'package:huike_timetable/models/course.dart';

void main() {
  late AppDatabase db;
  late SchoolRepository schools;
  late CourseRepository courses;
  late String schoolId;
  late String semesterId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    schools = SchoolRepository(db);
    courses = CourseRepository(db);
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

  AdapterCourseDraft draft(
    String name, {
    int day = 1,
    int start = 1,
    int end = 2,
    List<int> weeks = const [1, 2],
  }) => AdapterCourseDraft(
    name: name,
    weekday: day,
    startSection: start,
    endSection: end,
    weeks: weeks,
  );

  group('replaceImportedCourses', () {
    test('写入后可按 id 读回且来源为 imported', () async {
      await courses.replaceImportedCourses(
        schoolId: schoolId,
        semesterId: semesterId,
        drafts: [draft('高等数学', start: 3, end: 4)],
        schedule: BellSchedule.fallback(),
      );
      final rows = await (db.select(db.courseEntries)).get();
      expect(rows, hasLength(1));
      expect(rows.single.source, CourseSource.imported);
      expect(rows.single.name, '高等数学');
      expect(rows.single.weeksJson, '[1,2]');
    });

    test('重新导入只替换 imported，手动课程保留', () async {
      await courses.replaceImportedCourses(
        schoolId: schoolId,
        semesterId: semesterId,
        drafts: [draft('导入课A')],
        schedule: BellSchedule.fallback(),
      );
      await courses.addManualCourse(
        schoolId: schoolId,
        semesterId: semesterId,
        course: Course(
          id: 'manual-1',
          schoolId: schoolId,
          semesterId: semesterId,
          name: '手动课',
          weekday: 3,
          startSection: 5,
          endSection: 6,
          weeks: const [1],
        ),
      );
      await courses.replaceImportedCourses(
        schoolId: schoolId,
        semesterId: semesterId,
        drafts: [draft('导入课B')],
        schedule: BellSchedule.fallback(),
      );

      final rows = await (db.select(db.courseEntries)).get();
      expect(rows, hasLength(2));
      final names = rows.map((r) => r.name).toSet();
      expect(names, {'导入课B', '手动课'});
      expect(
        rows.singleWhere((r) => r.name == '手动课').source,
        CourseSource.manual,
      );
    });

    test('其它学校的导入课程不受影响', () async {
      final otherSchool = await schools.createSchool(
        displayName: '另一所大学',
        adapterId: '',
        loginUrl: '',
        confirmedHosts: const [],
      );
      await courses.replaceImportedCourses(
        schoolId: otherSchool.id,
        semesterId: semesterId,
        drafts: [draft('别校课')],
        schedule: BellSchedule.fallback(),
      );
      await courses.replaceImportedCourses(
        schoolId: schoolId,
        semesterId: semesterId,
        drafts: [draft('本校课')],
        schedule: BellSchedule.fallback(),
      );
      final rows = await (db.select(db.courseEntries)).get();
      expect(rows.map((r) => r.name), containsAll(['别校课', '本校课']));
      expect(rows, hasLength(2));
    });

    test('课程 id 由内容指纹决定，同内容同 id', () {
      final a = CourseRepository.importedCourseId(schoolId, draft('数学'));
      final b = CourseRepository.importedCourseId(schoolId, draft('数学'));
      expect(a, b);
    });

    test('周次段不同则 id 不同（同教学班多段）', () {
      final a = CourseRepository.importedCourseId(
        schoolId,
        draft('数学', weeks: [1, 2, 3]),
      );
      final b = CourseRepository.importedCourseId(
        schoolId,
        draft('数学', weeks: [4, 5]),
      );
      expect(a, isNot(b));
    });
  });

  group('作息播种', () {
    test('创建学校播种一次通用作息', () async {
      final rows = await (db.select(db.sectionTimeEntries)
            ..where((t) => t.schoolId.equals(schoolId)))
          .get();
      expect(rows, hasLength(12));
      expect(rows.first.start, '08:00');
    });

    test('resetSectionTimes 是唯一的重置路径且可重复', () async {
      await schools.updateSectionTime(
        schoolId,
        1,
        start: '09:00',
        end: '09:45',
      );
      await schools.resetSectionTimes(schoolId);
      final rows = await (db.select(db.sectionTimeEntries)
            ..where((t) => t.schoolId.equals(schoolId)))
          .get();
      expect(rows.singleWhere((r) => r.sectionIndex == 1).start, '08:00');
    });

    test('删除学校清空其全部数据', () async {
      await courses.replaceImportedCourses(
        schoolId: schoolId,
        semesterId: semesterId,
        drafts: [draft('课')],
        schedule: BellSchedule.fallback(),
      );
      await schools.deleteSchool(schoolId);
      final leftCourses = await (db.select(db.courseEntries)).get();
      final leftSchools = await (db.select(db.schools)).get();
      final leftBells = await (db.select(db.sectionTimeEntries)).get();
      final leftSemesters = await (db.select(db.semesters)).get();
      expect(leftCourses, isEmpty);
      expect(leftSchools, isEmpty);
      expect(leftBells, isEmpty);
      expect(leftSemesters, isEmpty);
    });
  });

  group('settings', () {
    test('读写与缺失回退', () async {
      expect(await db.settingValue('nope', fallback: 'x'), 'x');
      await db.setSetting('key', 'v1');
      await db.setSetting('key', 'v2');
      expect(await db.settingValue('key'), 'v2');
    });
  });
}
