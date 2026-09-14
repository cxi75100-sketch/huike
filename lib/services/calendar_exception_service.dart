import '../models/calendar_exception.dart';

/// 某一天实际的上课安排。
///
/// [weekday] 是「这天按星期几的课表上课」，调休时与自然星期不同；
/// [suspended] 为真表示当天停课，此时 [weekday] 只用于展示自然星期。
class DaySchedule {
  const DaySchedule({
    required this.weekday,
    required this.suspended,
    this.exception,
  });

  final int weekday;
  final bool suspended;
  final CalendarException? exception;

  /// 调休补课：这天按别的星期上课。
  bool get isMakeup =>
      !suspended && exception?.kind == CalendarExceptionKind.makeup;
}

/// 把校历例外解析成「某天按哪天的课表上课」。
///
/// 纯 Dart、无 IO：今日视图、整周视图与（后续的）上课提醒共用同一判定，
/// 不允许各处各写一份（同 `login_url_policy` 的口径）。
class CalendarExceptionService {
  const CalendarExceptionService([this.exceptions = const []]);

  final List<CalendarException> exceptions;

  static const _weekdayNames = ['一', '二', '三', '四', '五', '六', '日'];

  /// 1=周一 … 7=周日 → 「周一」。
  static String weekdayName(int weekday) =>
      '周${_weekdayNames[(weekday - 1).clamp(0, 6)]}';

  /// 该日期是否命中例外；同一天只会有一条。
  CalendarException? forDate(DateTime date) {
    for (final exception in exceptions) {
      if (_sameDay(exception.date, date)) return exception;
    }
    return null;
  }

  DaySchedule resolve(DateTime date) {
    final natural = date.weekday;
    final exception = forDate(date);
    if (exception == null) {
      return DaySchedule(weekday: natural, suspended: false);
    }
    if (exception.kind == CalendarExceptionKind.holiday) {
      return DaySchedule(
        weekday: natural,
        suspended: true,
        exception: exception,
      );
    }
    return DaySchedule(
      weekday: (exception.makeupWeekday ?? natural).clamp(1, 7),
      suspended: false,
      exception: exception,
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
