import 'package:flutter_test/flutter_test.dart';
import 'package:huike_timetable/models/bell_schedule.dart';
import 'package:huike_timetable/models/course.dart';
import 'package:huike_timetable/services/section_count_resolver.dart';

void main() {
  Course course(int end) => Course(
    id: '$end',
    schoolId: 'school',
    semesterId: 'semester',
    name: 'Section test',
    weekday: 1,
    startSection: end - 1,
    endSection: end,
    weeks: const [1],
  );

  test('作息与课程上限统一用于 10、12、14 节', () {
    final fallback = BellSchedule.fallback();
    expect(SectionCountResolver.resolve(fallback), 10);
    expect(SectionCountResolver.resolve(fallback, courses: [course(12)]), 12);
    expect(SectionCountResolver.resolve(fallback, courses: [course(14)]), 14);
  });
}
