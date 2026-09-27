import '../models/semester.dart';

/// 某个日期相对学期区间的位置。
///
/// [SemesterService.currentWeek] 会把超出学期的周次封顶到 `totalWeeks`，
/// 因此“正在最后一周”和“学期早已结束”无法区分。需要判断学期日期是否
/// 已经过期时用 [SemesterService.termStatus]。
enum TermStatus { before, within, after }

class SemesterService {
  const SemesterService();

  int currentWeek(Semester semester, DateTime date) {
    final difference = _dateOnly(date)
        .difference(_dateOnly(semester.firstWeekMonday))
        .inDays;
    if (difference < 0) return 0;
    final week = difference ~/ 7 + 1;
    return week > semester.totalWeeks ? semester.totalWeeks : week;
  }

  DateTime weekMonday(Semester semester, int week) {
    final safeWeek = week.clamp(1, semester.totalWeeks);
    return _dateOnly(semester.firstWeekMonday)
        .add(Duration(days: (safeWeek - 1) * 7));
  }

  TermStatus termStatus(Semester semester, DateTime date) {
    final today = _dateOnly(date);
    final start = _dateOnly(semester.firstWeekMonday);
    if (today.isBefore(start)) return TermStatus.before;
    final endExclusive = start.add(Duration(days: semester.totalWeeks * 7));
    return today.isBefore(endExclusive) ? TermStatus.within : TermStatus.after;
  }

  /// 学期「翻页」进度与落款：翻到第 [week] 周时这一卷读到哪了。
  ///
  /// 只有这一处算进度，整周页的学期进度弹层与后续任何入口都读它，
  /// 不允许各自再算一遍。进度夹取在 0..1；[date] 用于判学期前 / 学期后。
  ({double progress, String mark}) readingProgress(
    Semester semester,
    int week,
    DateTime date,
  ) {
    switch (termStatus(semester, date)) {
      case TermStatus.before:
        return (progress: 0, mark: '尚未开卷');
      case TermStatus.after:
        return (progress: 1, mark: '此卷已毕');
      case TermStatus.within:
        return (
          progress: (week / semester.totalWeeks).clamp(0.0, 1.0),
          mark: '阅至此处',
        );
    }
  }

  /// 第 [week] 周星期 [weekday]（1=周一）的日期。
  ///
  /// 不把 [week] 夹到学期范围内：周历需要如实显示用户翻到的那一周。
  DateTime dateFor(Semester semester, int week, int weekday) =>
      _dateOnly(semester.firstWeekMonday)
          .add(Duration(days: (week - 1) * 7 + weekday - 1));

  /// 设备当天是星期几，1=周一 … 7=周日。
  int weekdayOf(DateTime date) {
    final value = _dateOnly(date).weekday; // DateTime: 1=Mon..7=Sun
    return value;
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
