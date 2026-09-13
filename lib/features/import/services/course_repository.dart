import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/theme/course_colors.dart';
import '../../../models/bell_schedule.dart';
import '../../../models/course.dart';
import '../models/adapter_batch.dart';

/// 导入写路径。
///
/// 事务语义：删除 (schoolId, semesterId, source=imported) 后整体插入；
/// 手动课程永不触碰。id 由「学校 + 课程内容指纹」决定，同一教学班
/// 不同周次段得到不同 id，与上次导入可比对。
class CourseRepository {
  CourseRepository(this._db);

  final AppDatabase _db;

  Future<void> replaceImportedCourses({
    required String schoolId,
    required String semesterId,
    required List<AdapterCourseDraft> drafts,
    required BellSchedule schedule,
  }) async {
    await _db.transaction(() async {
      await (_db.delete(_db.courseEntries)
            ..where(
              (t) =>
                  t.schoolId.equals(schoolId) &
                  t.semesterId.equals(semesterId) &
                  t.source.equals(CourseSource.imported.name),
            ))
          .go();
      for (final draft in drafts) {
        await _db
            .into(_db.courseEntries)
            .insert(
              CourseEntriesCompanion.insert(
                id: importedCourseId(schoolId, draft),
                schoolId: schoolId,
                semesterId: semesterId,
                source: CourseSource.imported,
                name: draft.name,
                teacher: Value(draft.teacher),
                classroom: Value(draft.classroom),
                weekday: draft.weekday,
                startSection: draft.startSection,
                endSection: draft.endSection,
                weeksJson: encodeWeeks(draft.weeks),
                startTime: Value(_resolveStart(draft, schedule)),
                endTime: Value(_resolveEnd(draft, schedule)),
                colorKey: Value(colorKeyForName(draft.name)),
              ),
            );
      }
    });
  }

  /// 适配器给了完整作息时整体替换（仅当用户在预览页勾选确认）。
  Future<void> replaceSectionTimes(
    String schoolId,
    List<AdapterTimeSlot> slots,
  ) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.sectionTimeEntries,
      )..where((t) => t.schoolId.equals(schoolId))).go();
      for (final slot in slots) {
        await _db
            .into(_db.sectionTimeEntries)
            .insert(
              SectionTimeEntriesCompanion.insert(
                schoolId: schoolId,
                sectionIndex: slot.number,
                start: slot.startTime,
                end: slot.endTime,
                periodGroup: _groupFor(slot.number),
              ),
            );
      }
    });
  }

  SectionGroup _groupFor(int index) {
    if (index <= 4) return SectionGroup.morning;
    if (index <= 8) return SectionGroup.afternoon;
    return SectionGroup.evening;
  }

  String? _resolveStart(AdapterCourseDraft draft, BellSchedule schedule) =>
      schedule.section(draft.startSection)?.start;

  String? _resolveEnd(AdapterCourseDraft draft, BellSchedule schedule) =>
      schedule.section(draft.endSection)?.end;

  /// 手动课程 CRUD。手动课程永不参与导入替换。
  Future<void> addManualCourse({
    required String schoolId,
    required String semesterId,
    required Course course,
  }) async {
    await _db
        .into(_db.courseEntries)
        .insert(_companionFromCourse(course, schoolId, semesterId));
  }

  Future<void> updateCourse(Course course) async {
    await (_db.update(_db.courseEntries)..where((t) => t.id.equals(course.id)))
        .write(_companionFromCourse(course, course.schoolId, course.semesterId));
  }

  Future<void> deleteCourse(String courseId) async {
    await (_db.delete(
      _db.courseEntries,
    )..where((t) => t.id.equals(courseId))).go();
  }

  CourseEntriesCompanion _companionFromCourse(
    Course course,
    String schoolId,
    String semesterId,
  ) => CourseEntriesCompanion.insert(
    id: course.id,
    schoolId: schoolId,
    semesterId: semesterId,
    source: course.source,
    name: course.name,
    teacher: Value(course.teacher),
    classroom: Value(course.classroom),
    weekday: course.weekday,
    startSection: course.startSection,
    endSection: course.endSection,
    weeksJson: encodeWeeks(course.weeks),
    startTime: Value(course.startTime),
    endTime: Value(course.endTime),
    note: Value(course.note),
    colorKey: Value(course.colorKey),
  );

  /// 稳定指纹：同内容同 id、内容变化即新 id，供差异比对。
  static String importedCourseId(String schoolId, AdapterCourseDraft draft) {
    final payload = [
      schoolId,
      draft.name,
      '${draft.weekday}',
      '${draft.startSection}',
      '${draft.endSection}',
      draft.weeks.join(','),
    ].join('|');
    var h1 = 0x811c9dc5;
    var h2 = 0x01000193;
    for (final code in payload.codeUnits) {
      h1 = ((h1 ^ code) * 0x01000193) & 0xFFFFFFFF;
      h2 = ((h2 + code) * 0x85EBCA6B) & 0xFFFFFFFF;
    }
    return 'imp-$schoolId-${h1.toRadixString(16)}${h2.toRadixString(16)}';
  }
}

final courseRepositoryProvider = Provider<CourseRepository>(
  (ref) => CourseRepository(ref.watch(databaseProvider)),
);
