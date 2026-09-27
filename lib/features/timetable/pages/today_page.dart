import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ambient_backdrop.dart';
import '../../../models/bell_schedule.dart';
import '../../../models/course.dart';
import '../providers/timetable_providers.dart';
import '../widgets/course_preview_sheet.dart';
import '../widgets/course_hero.dart';
import '../widgets/today_timeline.dart';
import '../widgets/timetable_root_shell.dart';

/// Dedicated day view with content-sized nodes and a semantic time rail.
class TodayPage extends ConsumerStatefulWidget {
  const TodayPage({super.key});

  @override
  ConsumerState<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends ConsumerState<TodayPage> {
  late DateTime _now = DateTime.now();
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      final now = DateTime.now();
      if (now.minute == _now.minute &&
          now.hour == _now.hour &&
          now.day == _now.day) {
        return;
      }
      if (now.day != _now.day ||
          now.month != _now.month ||
          now.year != _now.year) {
        ref.invalidate(todayDayScheduleProvider);
        ref.invalidate(todayCoursesProvider);
      }
      setState(() => _now = now);
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    final schedule =
        ref.watch(bellForActiveSchoolProvider) ?? BellSchedule.fallback();
    final courses = ref.watch(todayCoursesProvider);
    final day = ref.watch(todayDayScheduleProvider);
    final date = '${_now.month}月${_now.day}日 星期${'一二三四五六日'[_now.weekday - 1]}';
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: const Text('今日课程'),
        automaticallyImplyLeading: false,
      ),
      body: AmbientBackdrop(
        child: SafeArea(
          top: false,
          minimum: EdgeInsets.only(
            bottom: RootSwitcherScope.maybeOf(context) == null
                ? 0
                : MediaQuery.viewPaddingOf(context).bottom +
                      RootSwitcherLayout.fabLift,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: palette.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        day == null
                            ? '当前不在学期内'
                            : day.suspended
                            ? '今天停课'
                            : day.isMakeup
                            ? '调休 · 按周${day.weekday}上课'
                            : courses.isEmpty
                            ? '今天没有课程'
                            : '今天有 ${courses.length} 门课程',
                        style: TextStyle(
                          fontSize: 12,
                          color: palette.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TodayTimeline(
                  courses: courses,
                  schedule: schedule,
                  now: _now,
                  showCurrentTime: day != null && !day.suspended,
                  onCourseTap: (course) =>
                      context.push('/today/course/${course.id}', extra: course),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Page-backed overlay keeps the Today route available as a Hero source while
/// retaining the sheet presentation. A PopupRoute cannot participate in the
/// framework's PageRoute-to-PageRoute Hero flights.
class TodayCoursePreviewPage extends ConsumerWidget {
  const TodayCoursePreviewPage({
    super.key,
    required this.courseId,
    this.initialCourse,
  });

  final String courseId;
  final Course? initialCourse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course =
        ref.watch(courseByIdProvider(courseId)).value ?? initialCourse;
    final schedule =
        ref.watch(bellForActiveSchoolProvider) ?? BellSchedule.fallback();
    if (course == null) {
      return const Material(
        color: Colors.transparent,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.18)),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: CoursePreviewSheet(
              course: course,
              schedule: schedule,
              heroSource: CourseHeroSourceContext.today,
              onClose: () => Navigator.of(context).pop(),
              onEdit: () {
                final router = GoRouter.of(context);
                router.pop();
                router.push('/course/${course.id}/edit');
              },
              onDetails: () => context.push(
                '/course/${course.id}',
                extra: CourseHeroSourceContext.today,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
