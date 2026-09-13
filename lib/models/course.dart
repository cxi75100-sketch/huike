/// 课程来源。
///
/// 多校设计下学校身份由 `Course.schoolId` 承载，来源只区分
/// 「用户手动录入」与「教务导入」；重新导入只替换 `imported`。
enum CourseSource { manual, imported }

CourseSource courseSourceFromString(String value) =>
    value == 'imported' ? CourseSource.imported : CourseSource.manual;

class Course {
  const Course({
    required this.id,
    required this.schoolId,
    required this.semesterId,
    required this.name,
    required this.weekday,
    required this.startSection,
    required this.endSection,
    required this.weeks,
    this.colorKey = 0,
    this.teacher = '',
    this.classroom = '',
    this.startTime,
    this.endTime,
    this.note = '',
    this.source = CourseSource.manual,
  });

  final String id;
  final String schoolId;
  final String semesterId;
  final String name;
  final String teacher;
  final String classroom;
  final int weekday;
  final int startSection;
  final int endSection;
  final String? startTime;
  final String? endTime;
  final List<int> weeks;
  final int colorKey;
  final String note;
  final CourseSource source;

  Course copyWith({
    String? id,
    String? schoolId,
    String? semesterId,
    String? name,
    String? teacher,
    String? classroom,
    int? weekday,
    int? startSection,
    int? endSection,
    String? startTime,
    String? endTime,
    List<int>? weeks,
    int? colorKey,
    String? note,
    CourseSource? source,
  }) => Course(
    id: id ?? this.id,
    schoolId: schoolId ?? this.schoolId,
    semesterId: semesterId ?? this.semesterId,
    name: name ?? this.name,
    teacher: teacher ?? this.teacher,
    classroom: classroom ?? this.classroom,
    weekday: weekday ?? this.weekday,
    startSection: startSection ?? this.startSection,
    endSection: endSection ?? this.endSection,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    weeks: weeks ?? this.weeks,
    colorKey: colorKey ?? this.colorKey,
    note: note ?? this.note,
    source: source ?? this.source,
  );
}
