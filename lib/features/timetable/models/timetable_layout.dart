import '../../../models/course.dart';

enum TimetableDensity { compact, medium, expanded }

class TimetableLayoutMetrics {
  const TimetableLayoutMetrics({
    required this.density,
    required this.axisWidth,
    required this.dayHeaderHeight,
    required this.sectionHeight,
    required this.courseGap,
    required this.contentPadding,
  });

  final TimetableDensity density;
  final double axisWidth;
  final double dayHeaderHeight;

  /// 单节的行高。
  ///
  /// 超过 12 节时的下限；10/12 节由可用视口均分，不测量课程内容。
  final double sectionHeight;

  final double courseGap;
  final double contentPadding;

  bool get isCompact => density == TimetableDensity.compact;

  TimetableLayoutMetrics withSectionHeight(double value) {
    return TimetableLayoutMetrics(
      density: density,
      axisWidth: axisWidth,
      dayHeaderHeight: dayHeaderHeight,
      sectionHeight: value,
      courseGap: courseGap,
      contentPadding: contentPadding,
    );
  }

  static TimetableLayoutMetrics of(double width) {
    if (width < 600) {
      return const TimetableLayoutMetrics(
        density: TimetableDensity.compact,
        axisWidth: 28,
        dayHeaderHeight: 48,
        // Sections stay as the positioning unit. Two adjacent sections form
        // one compact visual period, so a normal class does not consume two
        // oversized cells on a phone. Grid geometry stays viewport-driven.
        sectionHeight: 44,
        courseGap: 1.5,
        contentPadding: 4,
      );
    }
    if (width <= 900) {
      return const TimetableLayoutMetrics(
        density: TimetableDensity.medium,
        axisWidth: 56,
        dayHeaderHeight: 60,
        sectionHeight: 64,
        courseGap: 2,
        contentPadding: 8,
      );
    }
    return const TimetableLayoutMetrics(
      density: TimetableDensity.expanded,
      axisWidth: 72,
      dayHeaderHeight: 64,
      sectionHeight: 72,
      courseGap: 3,
      contentPadding: 12,
    );
  }
}

class TimetableCoursePlacement {
  const TimetableCoursePlacement({
    required this.course,
    required this.lane,
    required this.laneCount,
    required this.clusterId,
  });

  final Course course;
  final int lane;
  final int laneCount;
  final int clusterId;

  int get sectionSpan => course.endSection - course.startSection + 1;
}

class TimetableCollisionCluster {
  const TimetableCollisionCluster({
    required this.id,
    required this.startSection,
    required this.endSection,
    required this.laneCount,
    required this.courses,
  });

  final int id;
  final int startSection;
  final int endSection;
  final int laneCount;
  final List<Course> courses;
}

class CourseCollisionLayoutResult {
  const CourseCollisionLayoutResult({
    required this.placements,
    required this.clusters,
  });

  final List<TimetableCoursePlacement> placements;
  final List<TimetableCollisionCluster> clusters;

  /// Only courses that share at least one section with [course].
  List<Course> overlapping(Course course) {
    final clusterId = placements
        .where((placement) => placement.course.id == course.id)
        .firstOrNull
        ?.clusterId;
    if (clusterId == null) return const [];
    final cluster = clusters.firstWhere((item) => item.id == clusterId);
    return cluster.courses
        .where(
          (peer) =>
              peer.id != course.id &&
              peer.startSection <= course.endSection &&
              course.startSection <= peer.endSection,
        )
        .toList(growable: false);
  }
}
