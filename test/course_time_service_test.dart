import 'package:flutter_test/flutter_test.dart';
import 'package:huike_timetable/models/bell_schedule.dart';
import 'package:huike_timetable/models/course.dart';
import 'package:huike_timetable/services/course_time_service.dart';

Course _course(int start, int end) => Course(
  id: 'c',
  schoolId: 's',
  semesterId: 'sem',
  name: '课',
  weekday: 1,
  startSection: start,
  endSection: end,
  weeks: const [1],
);

void main() {
  const service = CourseTimeService();
  final fallback = BellSchedule.fallback();

  test('无显式时间时按作息表解析', () {
    expect(service.resolve(_course(3, 4), fallback), ('10:00', '11:40'));
  });

  test('显式时间优先于作息表', () {
    final course = Course(
      id: 'c',
      schoolId: 's',
      semesterId: 'sem',
      name: '课',
      weekday: 1,
      startSection: 3,
      endSection: 4,
      weeks: const [1],
      startTime: '09:00',
      endTime: '10:30',
    );
    expect(service.resolve(course, fallback), ('09:00', '10:30'));
  });

  test('节次缺失显示时间未定', () {
    expect(service.resolve(_course(11, 14), fallback), isNull);
    expect(service.formatRange(_course(11, 14), fallback), '时间未定');
  });

  test('equalsFallback 判定未被修改的作息', () {
    expect(BellSchedule.fallback().equalsFallback(), isTrue);
    expect(const BellSchedule(sections: []).equalsFallback(), isTrue);
    final modified = BellSchedule(
      sections: [
        for (final spec in fallback.sections)
          spec.index == 1
              ? SectionSpec(
                  index: 1,
                  start: '08:30',
                  end: spec.end,
                  group: spec.group,
                )
              : spec,
      ],
    );
    expect(modified.equalsFallback(), isFalse);
  });
}
