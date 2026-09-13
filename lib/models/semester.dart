class Semester {
  const Semester({
    required this.id,
    required this.schoolId,
    required this.firstWeekMonday,
    required this.totalWeeks,
  });

  final String id;
  final String schoolId;

  /// 第 1 教学周的周一。它是全部周次、单双周与提醒的唯一锚点。
  final DateTime firstWeekMonday;
  final int totalWeeks;

  Semester copyWith({DateTime? firstWeekMonday, int? totalWeeks}) => Semester(
    id: id,
    schoolId: schoolId,
    firstWeekMonday: firstWeekMonday ?? this.firstWeekMonday,
    totalWeeks: totalWeeks ?? this.totalWeeks,
  );
}
