import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huike_timetable/core/database/app_database.dart';
import 'package:huike_timetable/features/import/models/adapter_batch.dart';
import 'package:huike_timetable/features/import/services/course_repository.dart';
import 'package:huike_timetable/features/schools/services/school_repository.dart';
import 'package:huike_timetable/models/bell_schedule.dart';
import 'package:huike_timetable/models/course.dart';

class _FailAfterSemesterUpdate extends SchoolRepository {
  _FailAfterSemesterUpdate(super.db);

  @override
  Future<void> updateSemester(
    String semesterId, {
    DateTime? firstWeekMonday,
    int? totalWeeks,
  }) async {
    await super.updateSemester(
      semesterId,
      firstWeekMonday: firstWeekMonday,
      totalWeeks: totalWeeks,
    );
    throw StateError('injected after semester update');
  }
}

void main() {
  late AppDatabase db;
  late SchoolRepository schools;
  late CourseRepository courses;
  late String schoolId;
  late String semesterId;

  const oldSlot = AdapterTimeSlot(
    number: 1,
    startTime: '08:00',
    endTime: '08:45',
  );
  const newSlot = AdapterTimeSlot(
    number: 1,
    startTime: '09:00',
    endTime: '09:45',
  );
  const sameCourse = AdapterCourseDraft(
    name: '数学',
    weekday: 1,
    startSection: 1,
    endSection: 2,
    weeks: [1, 2],
  );

  AdapterImportBatch batch(List<AdapterCourseDraft> drafts) =>
      AdapterImportBatch(
        courses: drafts,
        timeSlots: const [newSlot],
        courseConfig: AdapterCourseConfig(
          semesterStartDate: DateTime(2026, 9, 7),
          totalWeeks: 18,
        ),
        invalidCount: 0,
        invalidReasons: const [],
      );

  Future<void> seedOldData() async {
    await courses.replaceSectionTimes(schoolId, const [oldSlot]);
    await courses.replaceImportedCourses(
      schoolId: schoolId,
      semesterId: semesterId,
      drafts: const [sameCourse],
      schedule: BellSchedule.fallback(),
    );
  }

  Future<List<Object>> snapshot() async {
    final sections = await db.select(db.sectionTimeEntries).get();
    final courseRows = await db.select(db.courseEntries).get();
    final semesters = await db.select(db.semesters).get();
    return [sections, courseRows, semesters];
  }

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
    semesterId = (await schools.createSemester(
      schoolId: schoolId,
      firstWeekMonday: DateTime(2026, 8, 31),
      totalWeeks: 20,
    )).id;
  });

  tearDown(() => db.close());

  test('相同学校不同学期的同课程共存，ID 按学期隔离且稳定', () async {
    final otherSemesterId = (await schools.createSemester(
      schoolId: schoolId,
      firstWeekMonday: DateTime(2027, 2, 22),
      totalWeeks: 20,
    )).id;
    for (final id in [semesterId, otherSemesterId]) {
      await courses.replaceImportedCourses(
        schoolId: schoolId,
        semesterId: id,
        drafts: const [sameCourse],
        schedule: BellSchedule.fallback(),
      );
    }
    final rows = await db.select(db.courseEntries).get();
    expect(rows, hasLength(2));
    expect(rows.map((row) => row.id).toSet(), hasLength(2));
    expect(rows.map((row) => row.id).toSet(), {
      CourseRepository.importedCourseId(schoolId, semesterId, sameCourse),
      CourseRepository.importedCourseId(schoolId, otherSemesterId, sameCourse),
    });
    expect(
      CourseRepository.importedCourseId(schoolId, semesterId, sameCourse),
      CourseRepository.importedCourseId(schoolId, semesterId, sameCourse),
    );
  });

  test('同学期重复导入保持 ID 和单条数据，随后只替换本学期', () async {
    await seedOldData();
    final before = (await db.select(db.courseEntries).get()).single.id;
    await courses.replaceImportedCourses(
      schoolId: schoolId,
      semesterId: semesterId,
      drafts: const [sameCourse],
      schedule: BellSchedule.fallback(),
    );
    var rows = await db.select(db.courseEntries).get();
    expect(rows, hasLength(1));
    expect(rows.single.id, before);
    await courses.replaceImportedCourses(
      schoolId: schoolId,
      semesterId: semesterId,
      drafts: const [
        AdapterCourseDraft(
          name: '物理',
          weekday: 2,
          startSection: 3,
          endSection: 4,
          weeks: [1],
        ),
      ],
      schedule: BellSchedule.fallback(),
    );
    rows = await db.select(db.courseEntries).get();
    expect(rows.single.name, '物理');
    expect(rows.single.id, isNot(before));
  });

  test('不同学校的相同语义课程和学期分别保留', () async {
    final otherSchool = await schools.createSchool(
      displayName: '另一所大学',
      adapterId: '',
      loginUrl: '',
      confirmedHosts: const [],
    );
    final otherSemester = await schools.createSemester(
      schoolId: otherSchool.id,
      firstWeekMonday: DateTime(2026, 8, 31),
      totalWeeks: 20,
    );
    for (final (school, semester) in [
      (schoolId, semesterId),
      (otherSchool.id, otherSemester.id),
    ]) {
      await courses.replaceImportedCourses(
        schoolId: school,
        semesterId: semester,
        drafts: const [sameCourse],
        schedule: BellSchedule.fallback(),
      );
    }
    final rows = await db.select(db.courseEntries).get();
    expect(rows, hasLength(2));
    expect(rows.map((row) => row.id).toSet(), hasLength(2));
    expect(rows.map((row) => row.schoolId).toSet(), {schoolId, otherSchool.id});
  });

  test('旧格式导入 ID 在同学期重导时由范围删除自然替换', () async {
    await courses.addManualCourse(
      schoolId: schoolId,
      semesterId: semesterId,
      course: Course(
        id: 'imp-$schoolId-legacyfingerprint',
        schoolId: schoolId,
        semesterId: semesterId,
        source: CourseSource.imported,
        name: sameCourse.name,
        weekday: sameCourse.weekday,
        startSection: sameCourse.startSection,
        endSection: sameCourse.endSection,
        weeks: sameCourse.weeks,
      ),
    );
    await courses.replaceImportedCourses(
      schoolId: schoolId,
      semesterId: semesterId,
      drafts: const [sameCourse],
      schedule: BellSchedule.fallback(),
    );
    final rows = await db.select(db.courseEntries).get();
    expect(rows, hasLength(1));
    expect(
      rows.single.id,
      CourseRepository.importedCourseId(schoolId, semesterId, sameCourse),
    );
  });

  test('确认导入成功时作息、课程和学期配置一同写入', () async {
    await seedOldData();
    await courses.confirmImport(
      schoolId: schoolId,
      semesterId: semesterId,
      batch: batch(const [
        AdapterCourseDraft(
          name: '物理',
          weekday: 2,
          startSection: 1,
          endSection: 1,
          weeks: [1],
        ),
      ]),
      schedule: BellSchedule.fallback(),
      schoolRepository: schools,
      replaceSchedule: true,
      applyConfig: true,
    );
    final sections = await db.select(db.sectionTimeEntries).get();
    final rows = await db.select(db.courseEntries).get();
    final semester = (await db.select(db.semesters).get()).single;
    expect(sections, hasLength(1));
    expect(sections.single.start, '09:00');
    expect(rows, hasLength(1));
    expect(rows.single.name, '物理');
    expect(semester.firstWeekMondayIso, '2026-09-07');
    expect(semester.totalWeeks, 18);
  });

  test('课程插入失败会回滚此前作息替换并保留全部旧数据', () async {
    await seedOldData();
    final before = await snapshot();
    await expectLater(
      courses.confirmImport(
        schoolId: schoolId,
        semesterId: semesterId,
        batch: batch(const [sameCourse, sameCourse]),
        schedule: BellSchedule.fallback(),
        schoolRepository: schools,
        replaceSchedule: true,
        applyConfig: true,
      ),
      throwsA(isA<Exception>()),
    );
    expect(await snapshot(), before);
  });

  test('学期更新后的失败会回滚作息、课程和元数据并保留旧数据', () async {
    await seedOldData();
    final before = await snapshot();
    await expectLater(
      courses.confirmImport(
        schoolId: schoolId,
        semesterId: semesterId,
        batch: batch(const [
          AdapterCourseDraft(
            name: '物理',
            weekday: 2,
            startSection: 1,
            endSection: 1,
            weeks: [1],
          ),
        ]),
        schedule: BellSchedule.fallback(),
        schoolRepository: _FailAfterSemesterUpdate(db),
        replaceSchedule: true,
        applyConfig: true,
      ),
      throwsStateError,
    );
    expect(await snapshot(), before);
  });
}
