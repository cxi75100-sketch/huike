import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../models/calendar_exception.dart';
import '../../../models/semester.dart';
import '../../../services/calendar_exception_service.dart';
import 'school_providers.dart';

/// 一所学校某个学期的校历例外，按日期升序。
final calendarExceptionsProvider = StreamProvider.family
    .autoDispose<List<CalendarException>, (String, String)>((ref, ids) {
      final (schoolId, semesterId) = ids;
      final db = ref.watch(databaseProvider);
      final query = db.select(db.calendarExceptions)
        ..where(
          (t) =>
              t.schoolId.equals(schoolId) & t.semesterId.equals(semesterId),
        )
        ..orderBy([(t) => OrderingTerm.asc(t.dateIso)]);
      return query.watch().map(
        (rows) => rows.map((row) => row.toModel()).toList(),
      );
    });

/// 激活学校 + 激活学期的例外解析器。
///
/// 今日视图、整周视图与后续的上课提醒都用它，避免「某天到底按谁的课表」
/// 在不同界面各算一次（同 `login_url_policy` 的口径）。
final activeCalendarServiceProvider = Provider.autoDispose<CalendarExceptionService>((
  ref,
) {
  final school = ref.watch(activeSchoolProvider);
  if (school == null) return const CalendarExceptionService();
  final Semester? semester = ref.watch(activeSemesterProvider(school.id));
  if (semester == null) return const CalendarExceptionService();
  final exceptions =
      ref.watch(calendarExceptionsProvider((school.id, semester.id))).value ??
      const <CalendarException>[];
  return CalendarExceptionService(exceptions);
});
