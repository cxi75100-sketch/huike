/// 校历例外的类型。
enum CalendarExceptionKind {
  /// 停课：当天不上课（法定假日、校历放假）。
  holiday,

  /// 调休补课：当天按 [CalendarException.makeupWeekday] 那一天的课表上课。
  makeup,
}

/// 一条作用于某个具体日期的校历例外。
///
/// 挂在学期上：换学校或换学期天然隔离，不需要额外的失效逻辑。
/// 同一天只保留一条（由写路径保证），语义是「这一天到底上不上课、按谁的课表上」。
class CalendarException {
  const CalendarException({
    required this.id,
    required this.schoolId,
    required this.semesterId,
    required this.date,
    required this.kind,
    this.makeupWeekday,
    this.note = '',
  });

  final String id;
  final String schoolId;
  final String semesterId;

  /// 生效日期（只取年月日）。
  final DateTime date;

  final CalendarExceptionKind kind;

  /// [CalendarExceptionKind.makeup] 时生效：按星期几的课表上课（1=周一 … 7=周日）。
  final int? makeupWeekday;

  final String note;
}
