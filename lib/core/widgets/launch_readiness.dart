import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/theme_preference_provider.dart';
import '../../features/schools/providers/school_providers.dart';
import '../../features/schools/providers/calendar_exception_providers.dart';
import '../../features/timetable/providers/timetable_providers.dart';

/// Resolve real initial state, rather than painting transient empty defaults.
/// No timer and no dependency on animation completion. Errors settle too.
final launchReadinessProvider = Provider<bool>((ref) {
  final theme = ref.watch(themePreferenceProvider);
  final activeId = ref.watch(activeSchoolIdProvider);
  final schools = ref.watch(schoolsProvider);
  var ready = !theme.isLoading && !activeId.isLoading && !schools.isLoading;
  final school = ref.watch(activeSchoolProvider);
  if (school == null) return ready;
  final semesters = ref.watch(semestersForSchoolProvider(school.id));
  final selected = ref.watch(
    settingValueProvider(activeSemesterKey(school.id)),
  );
  final bell = ref.watch(sectionTimesProvider(school.id));
  ready =
      ready && !semesters.isLoading && !selected.isLoading && !bell.isLoading;
  // Do not query a fallback semester until the saved selection is known.
  if (semesters.isLoading || selected.isLoading) return false;
  final semester = ref.watch(activeSemesterProvider(school.id));
  if (semester == null) return ready;
  final ids = (school.id, semester.id);
  final courses = ref.watch(coursesForProvider(ids));
  final calendar = ref.watch(calendarExceptionsProvider(ids));
  return ready && !courses.isLoading && !calendar.isLoading;
});
