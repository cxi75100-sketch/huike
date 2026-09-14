import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../models/calendar_exception.dart';

/// 校历例外的写路径。作用域是 (schoolId, semesterId)，跨校跨学期天然隔离。
///
/// 同一天只保留一条：再写入即覆盖，语义是「这一天到底上不上课」，
/// 而不是叠加多条规则让用户去猜优先级。
class CalendarExceptionRepository {
  CalendarExceptionRepository(this._db);

  final AppDatabase _db;

  Future<CalendarException> save({
    String? id,
    required String schoolId,
    required String semesterId,
    required DateTime date,
    required CalendarExceptionKind kind,
    int? makeupWeekday,
    String note = '',
  }) async {
    final day = DateTime(date.year, date.month, date.day);
    final target = id ?? 'cal-${DateTime.now().microsecondsSinceEpoch}';
    final weekday = kind == CalendarExceptionKind.makeup
        ? (makeupWeekday ?? day.weekday).clamp(1, 7)
        : null;

    await _db.transaction(() async {
      // 换日期编辑时旧记录要一起清掉，否则同一天的旧安排会留下。
      await (_db.delete(
        _db.calendarExceptions,
      )..where((t) => t.id.equals(target))).go();
      await (_db.delete(_db.calendarExceptions)
            ..where(
              (t) =>
                  t.schoolId.equals(schoolId) &
                  t.semesterId.equals(semesterId) &
                  t.dateIso.equals(_isoDate(day)),
            ))
          .go();
      await _db
          .into(_db.calendarExceptions)
          .insert(
            CalendarExceptionsCompanion.insert(
              id: target,
              schoolId: schoolId,
              semesterId: semesterId,
              dateIso: _isoDate(day),
              kind: kind,
              makeupWeekday: Value(weekday),
              note: Value(note),
            ),
          );
    });

    return CalendarException(
      id: target,
      schoolId: schoolId,
      semesterId: semesterId,
      date: day,
      kind: kind,
      makeupWeekday: weekday,
      note: note,
    );
  }

  Future<void> deleteById(String id) async {
    await (_db.delete(
      _db.calendarExceptions,
    )..where((t) => t.id.equals(id))).go();
  }

  String _isoDate(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }
}

final calendarExceptionRepositoryProvider = Provider<CalendarExceptionRepository>(
  (ref) => CalendarExceptionRepository(ref.watch(databaseProvider)),
);
