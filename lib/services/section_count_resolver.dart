import 'dart:math' as math;

import '../models/bell_schedule.dart';
import '../models/course.dart';

/// Shared section extent for the grid, editor, and detail page.
class SectionCountResolver {
  const SectionCountResolver._();

  static int resolve(
    BellSchedule? schedule, {
    Iterable<Course> courses = const [],
  }) {
    var count =
        10; // Legacy schedules without section entries use ten sections.
    for (final section in schedule?.sections ?? const <SectionSpec>[]) {
      count = math.max(count, section.index);
    }
    for (final course in courses) {
      count = math.max(count, course.endSection);
    }
    return count.clamp(1, 20);
  }
}
