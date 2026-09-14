import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../models/bell_schedule.dart';
import '../../../models/course.dart';
import '../../../models/semester.dart';
import '../../../services/calendar_exception_service.dart';
import '../../../services/semester_service.dart';
import '../../schools/providers/calendar_exception_providers.dart';
import '../../schools/providers/school_providers.dart';

/// 一所学校当前学期的全部课程（含手动与导入）。
final coursesForProvider = StreamProvider.family
    .autoDispose<List<Course>, (String, String)>((ref, ids) {
      final (schoolId, semesterId) = ids;
      final db = ref.watch(databaseProvider);
      final query = db.select(db.courseEntries)
        ..where(
          (t) =>
              t.schoolId.equals(schoolId) & t.semesterId.equals(semesterId),
        )
        ..orderBy([(t) => OrderingTerm.asc(t.startSection)]);
      return query
          .watch()
          .map((rows) => rows.map((row) => row.toModel()).toList());
    });

/// 今天（按设备日期）经过校历例外解析后的实际上课安排。
///
/// 学期之外返回 null（与今日课表口径一致）。调休日这里返回的是
/// 「按哪个星期的课表上课」，停课日 [DaySchedule.suspended] 为真。
final todayDayScheduleProvider = Provider.autoDispose<DaySchedule?>((ref) {
  final school = ref.watch(activeSchoolProvider);
  if (school == null) return null;
  final semester = ref.watch(activeSemesterProvider(school.id));
  if (semester == null) return null;
  final now = DateTime.now();
  if (const SemesterService().termStatus(semester, now) != TermStatus.within) {
    return null;
  }
  return ref.watch(activeCalendarServiceProvider).resolve(now);
});

/// 今天（按设备日期）的课程：先由例外表决定「今天按哪天的课表」，
/// 再过滤教学周与星期，按开始节次排序。停课日为空。
final todayCoursesProvider = Provider.autoDispose<List<Course>>((ref) {
  final school = ref.watch(activeSchoolProvider);
  if (school == null) return const [];
  final semester = ref.watch(activeSemesterProvider(school.id));
  if (semester == null) return const [];
  final schedule = ref.watch(todayDayScheduleProvider);
  if (schedule == null || schedule.suspended) return const [];
  final courses =
      ref.watch(coursesForProvider((school.id, semester.id))).value;
  if (courses == null) return const [];
  final now = DateTime.now();
  final week = const SemesterService().currentWeek(semester, now);
  final weekday = schedule.weekday;
  return courses
      .where((course) => course.weekday == weekday && course.weeks.contains(week))
      .toList()
    ..sort((a, b) => a.startSection.compareTo(b.startSection));
});

/// 按 id 查课程（详情/编辑页使用）。
final courseByIdProvider = StreamProvider.autoDispose
    .family<Course?, String>((ref, id) {
      final db = ref.watch(databaseProvider);
      final query = db.select(db.courseEntries)..where((t) => t.id.equals(id));
      return query.watchSingleOrNull().map((row) => row?.toModel());
    });

final bellForActiveSchoolProvider = Provider.autoDispose<BellSchedule?>((ref) {
  final school = ref.watch(activeSchoolProvider);
  if (school == null) return null;
  return ref.watch(schoolBellProvider(school.id));
});

final activeSemesterRefProvider = Provider.autoDispose<Semester?>((ref) {
  final school = ref.watch(activeSchoolProvider);
  if (school == null) return null;
  return ref.watch(activeSemesterProvider(school.id));
});
