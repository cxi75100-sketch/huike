import '../../../models/course.dart';
import '../models/timetable_layout.dart';

/// 纯展示层的节次冲突布局，不修改课程或数据库语义。
///
/// 先把互相重叠的闭区间 `[startSection, endSection]` 分簇，再在每簇内以
/// 稳定贪心分配 lane。相邻但不重叠的课程会复用 lane；同一节次相交的课程
/// 永远不会得到同一 lane。
CourseCollisionLayoutResult layoutCourseCollisions(List<Course> courses) {
  if (courses.isEmpty) {
    return const CourseCollisionLayoutResult(placements: [], clusters: []);
  }

  final sorted = [...courses]
    ..sort((a, b) {
      final byStart = a.startSection.compareTo(b.startSection);
      if (byStart != 0) return byStart;
      final byEnd = a.endSection.compareTo(b.endSection);
      if (byEnd != 0) return byEnd;
      return a.id.compareTo(b.id);
    });

  final grouped = <List<Course>>[];
  var cluster = <Course>[];
  var clusterEnd = -1;
  for (final course in sorted) {
    if (cluster.isEmpty || course.startSection <= clusterEnd) {
      cluster.add(course);
      if (course.endSection > clusterEnd) clusterEnd = course.endSection;
    } else {
      grouped.add(cluster);
      cluster = [course];
      clusterEnd = course.endSection;
    }
  }
  grouped.add(cluster);

  final placements = <TimetableCoursePlacement>[];
  final clusters = <TimetableCollisionCluster>[];
  for (var clusterId = 0; clusterId < grouped.length; clusterId++) {
    final group = grouped[clusterId];
    final laneEnds = <int>[];
    final lanes = <Course, int>{};
    for (final course in group) {
      var lane = 0;
      while (lane < laneEnds.length && course.startSection <= laneEnds[lane]) {
        lane++;
      }
      if (lane == laneEnds.length) {
        laneEnds.add(course.endSection);
      } else {
        laneEnds[lane] = course.endSection;
      }
      lanes[course] = lane;
    }

    final laneCount = laneEnds.length;
    placements.addAll(
      group.map(
        (course) => TimetableCoursePlacement(
          course: course,
          lane: lanes[course]!,
          laneCount: laneCount,
          clusterId: clusterId,
        ),
      ),
    );
    clusters.add(
      TimetableCollisionCluster(
        id: clusterId,
        startSection: group
            .map((course) => course.startSection)
            .reduce((a, b) => a < b ? a : b),
        endSection: group
            .map((course) => course.endSection)
            .reduce((a, b) => a > b ? a : b),
        laneCount: laneCount,
        courses: List.unmodifiable(group),
      ),
    );
  }

  return CourseCollisionLayoutResult(
    placements: List.unmodifiable(placements),
    clusters: List.unmodifiable(clusters),
  );
}
