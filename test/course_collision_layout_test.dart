import 'package:flutter_test/flutter_test.dart';
import 'package:huike_timetable/features/timetable/services/course_collision_layout.dart';
import 'package:huike_timetable/models/course.dart';

void main() {
  Course course(String id, int start, int end) => Course(
    id: id,
    schoolId: 'school',
    semesterId: 'semester',
    name: 'Course $id',
    weekday: 1,
    startSection: start,
    endSection: end,
    weeks: const [1],
  );

  test('不重叠课程复用同一 lane', () {
    final result = layoutCourseCollisions([
      course('a', 1, 2),
      course('b', 3, 4),
    ]);

    expect(result.clusters, hasLength(2));
    expect(result.placements.map((item) => item.lane), everyElement(0));
    expect(result.placements.map((item) => item.laneCount), everyElement(1));
  });

  test('相同节次的两门课程稳定地并排', () {
    final result = layoutCourseCollisions([
      course('b', 1, 2),
      course('a', 1, 2),
    ]);

    expect(result.clusters, hasLength(1));
    expect(result.clusters.single.laneCount, 2);
    expect(result.placements.map((item) => (item.course.id, item.lane)), [
      ('a', 0),
      ('b', 1),
    ]);
  });

  test('链式相交属于同一冲突簇并使用所需 lane 数', () {
    final result = layoutCourseCollisions([
      course('a', 1, 3),
      course('b', 2, 4),
      course('c', 4, 5),
    ]);

    expect(result.clusters, hasLength(1));
    expect(result.clusters.single.startSection, 1);
    expect(result.clusters.single.endSection, 5);
    expect(result.clusters.single.laneCount, 2);
    expect(result.placements.map((item) => item.clusterId), everyElement(0));
  });

  test('三路同时冲突会报告三条 lane 供 UI 折叠', () {
    final result = layoutCourseCollisions([
      course('a', 2, 3),
      course('b', 2, 3),
      course('c', 2, 3),
    ]);

    expect(result.clusters.single.laneCount, 3);
    expect(result.clusters.single.courses, hasLength(3));
    expect(result.placements.map((item) => item.lane).toSet(), {0, 1, 2});
  });

  test('链式冲突只返回与当前课程真正重叠的对象', () {
    final a = course('a', 3, 4);
    final b = course('b', 4, 5);
    final c = course('c', 5, 6);
    final result = layoutCourseCollisions([a, b, c]);
    expect(result.clusters, hasLength(1));
    expect(result.overlapping(a).map((item) => item.id), ['b']);
    expect(result.overlapping(b).map((item) => item.id), ['a', 'c']);
    expect(result.overlapping(c).map((item) => item.id), ['b']);
  });
}
