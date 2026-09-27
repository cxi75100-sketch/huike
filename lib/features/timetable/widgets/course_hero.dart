import 'package:flutter/material.dart';

import '../../../core/glass/glass_metrics.dart';
import '../../../core/glass/glass_surface.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/course_colors.dart';
import '../../../models/course.dart';
import '../../../services/course_time_service.dart';

enum CourseHeroSourceContext { weeklyTimetable, today }

enum CourseHeroDestination { fullDetails }

/// Stable structural tag: course identity + source route + destination.
@immutable
class CourseHeroTag {
  const CourseHeroTag({
    required this.courseId,
    required this.schoolId,
    required this.semesterId,
    required this.source,
    required this.destination,
  });

  factory CourseHeroTag.forDetails(
    Course course,
    CourseHeroSourceContext source,
  ) => CourseHeroTag(
    courseId: course.id,
    schoolId: course.schoolId,
    semesterId: course.semesterId,
    source: source,
    destination: CourseHeroDestination.fullDetails,
  );

  final String courseId;
  final String schoolId;
  final String semesterId;
  final CourseHeroSourceContext source;
  final CourseHeroDestination destination;

  @override
  bool operator ==(Object other) =>
      other is CourseHeroTag &&
      other.courseId == courseId &&
      other.schoolId == schoolId &&
      other.semesterId == semesterId &&
      other.source == source &&
      other.destination == destination;

  @override
  int get hashCode =>
      Object.hash(courseId, schoolId, semesterId, source, destination);
}

/// Uses the native Hero flight in normal mode. Reduced Motion falls back to a
/// short route cross-fade, configured by the detail route.
class CourseHero extends StatelessWidget {
  const CourseHero({super.key, required this.tag, required this.child});

  final CourseHeroTag tag;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return Hero(
      tag: tag,
      transitionOnUserGestures: true,
      flightShuttleBuilder: (flightContext, animation, direction, from, to) =>
          (to.widget as Hero).child,
      child: child,
    );
  }
}

/// Lightweight, blur-free shared course surface used on preview and detail.
class CourseHeroSurface extends StatelessWidget {
  const CourseHeroSurface({
    super.key,
    required this.course,
    required this.range,
  });

  final Course course;
  final (String, String)? range;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    final tint = courseTint(course.colorKey, Theme.of(context).brightness);
    return GlassSurface(
      radius: GlassMetrics.groupRadius,
      intensity: GlassIntensity.regular,
      blurSigma: 0,
      tint: tint.onChip.withValues(alpha: 0.3),
      depth: 0.35,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: tint.onChip,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 9),
              Text(
                sectionRangeLabel(course),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: tint.onChip,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            course.name,
            style: TextStyle(
              fontSize: 23,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            range == null ? '時間未定' : '${range!.$1} – ${range!.$2}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: palette.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
