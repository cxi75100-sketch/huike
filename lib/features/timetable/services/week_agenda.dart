import '../../../models/course.dart';
import '../../../models/semester.dart';
import '../../../services/calendar_exception_service.dart';
import '../../../services/semester_service.dart';

/// 整周议程里的一天。
///
/// 日期顺序、校历例外折算与课程过滤都由 [buildWeekAgenda] 一次算好，
/// Widget 只负责画。禁止在 Widget builder 里再排一次序或再判一次星期。
class WeekAgendaDay {
  const WeekAgendaDay({
    required this.index,
    required this.weekday,
    required this.date,
    required this.schedule,
    required this.courses,
    required this.isToday,
    required this.isPast,
    required this.showMonth,
  });

  /// 自然顺序下标：0=周一 … 6=周日。
  final int index;

  /// 自然星期：1=周一 … 7=周日（不是例外折算后的星期）。
  final int weekday;

  final DateTime date;

  /// 这一天实际按哪天的课表上课（停课 / 调休折算结果）。
  final DaySchedule schedule;

  /// 当天真实课程，按开始节次排序；停课日为空。
  final List<Course> courses;

  final bool isToday;

  /// 设备当天之前：日期元信息降一级对比度用。
  final bool isPast;

  /// 是否显示月份（周一或跨月第一天）。
  final bool showMonth;

  String get weekdayLabel => CalendarExceptionService.weekdayName(weekday);

  String get monthLabel => '${date.month}月';

  bool get suspended => schedule.suspended;

  bool get isMakeup => schedule.isMakeup;

  /// 「按周X上课」（调休）。
  String get makeupLabel =>
      '按${CalendarExceptionService.weekdayName(schedule.weekday)}上课';
}

/// 一周议程。[days] 恒为周一 → 周日，长度 7。
class WeekAgenda {
  const WeekAgenda({required this.days, required this.anchorIndex});

  final List<WeekAgendaDay> days;

  /// 今天在 [days] 里的下标；今天不属于这一周时为 null。
  ///
  /// 当前周用它做初始视口锚点（今天为首个可见日期，过去日期在它上方可回看），
  /// 非当前周为 null，视口停在周一。
  final int? anchorIndex;

  bool get isCurrentWeek => anchorIndex != null;

  /// 这一周里的「今天」；不属于这一周时为 null。
  WeekAgendaDay? get today {
    for (final day in days) {
      if (day.isToday) return day;
    }
    return null;
  }
}

/// 生成一周议程。
///
/// 日期永远是「第 [week] 周的周一 → 周日」自然顺序：既不循环重排，
/// 也不会跨到相邻教学周。当前周只改变初始视口（[WeekAgenda.anchorIndex]），
/// 不改变数据顺序，也不改变读屏顺序。
///
/// [today] 只用于测试注入时间，默认取设备时间。
WeekAgenda buildWeekAgenda({
  required Semester semester,
  required int week,
  required List<Course> courses,
  required CalendarExceptionService calendar,
  DateTime? today,
  SemesterService semesterService = const SemesterService(),
}) {
  final now = today ?? DateTime.now();
  final todayOnly = DateTime(now.year, now.month, now.day);
  final days = <WeekAgendaDay>[];
  int? anchorIndex;

  for (var weekday = 1; weekday <= 7; weekday++) {
    final date = semesterService.dateFor(semester, week, weekday);
    // 这天到底按哪天的课表上课由校历例外决定（停课 → 空列）。
    final schedule = calendar.resolve(date);
    final isToday = date == todayOnly;
    if (isToday) anchorIndex = weekday - 1;
    days.add(
      WeekAgendaDay(
        index: weekday - 1,
        weekday: weekday,
        date: date,
        schedule: schedule,
        courses: schedule.suspended
            ? const <Course>[]
            : _coursesOf(courses, schedule.weekday, week),
        isToday: isToday,
        isPast: date.isBefore(todayOnly),
        showMonth:
            weekday == 1 ||
            date.month !=
                semesterService.dateFor(semester, week, weekday - 1).month,
      ),
    );
  }

  return WeekAgenda(days: days, anchorIndex: anchorIndex);
}

List<Course> _coursesOf(List<Course> courses, int weekday, int week) {
  return courses
      .where(
        (course) => course.weekday == weekday && course.weeks.contains(week),
      )
      .toList()
    ..sort((a, b) => a.startSection.compareTo(b.startSection));
}
