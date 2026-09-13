import '../../models/bell_schedule.dart';
import '../../models/course.dart';

/// 课程显示时间解析：显式时间 > 学校作息表（含按教室匹配的变体）。
class CourseTimeService {
  const CourseTimeService();

  /// 返回 (开始, 结束)。课程没有显式时间且作息表缺节次时返回 null，
  /// 调用方应显示「时间未定」而不是猜一个时间。
  (String, String)? resolve(Course course, BellSchedule schedule) {
    final start = course.startTime;
    final end = course.endTime;
    if (start != null && start.isNotEmpty && end != null && end.isNotEmpty) {
      return (start, end);
    }
    return schedule.resolveRange(
      course.startSection,
      course.endSection,
      classroom: course.classroom,
    );
  }

  /// 「14:00 - 15:40」或「时间未定」。
  String formatRange(Course course, BellSchedule schedule) {
    final range = resolve(course, schedule);
    if (range == null) return '时间未定';
    return '${range.$1} - ${range.$2}';
  }
}
