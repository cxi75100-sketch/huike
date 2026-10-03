import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/glass/glass_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ambient_backdrop.dart';
import '../../../models/bell_schedule.dart';
import '../../../models/course.dart';
import '../providers/timetable_providers.dart';
import '../widgets/course_preview_sheet.dart';
import '../widgets/course_hero.dart';
import '../widgets/today_timeline.dart';
import '../widgets/timetable_root_shell.dart';
import '../../schools/providers/school_providers.dart';
import '../../../core/glass/glass_button.dart';

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
        child: ref.watch(activeSchoolProvider) == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '还没有课程',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: palette.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '导入课表后，在这里查看每天的课程。',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: palette.inkSecondary),
                      ),
                      const SizedBox(height: 20),
                      GlassButton(
                        label: '导入课表',
                        icon: Icons.download_outlined,
                        size: 48,
                        onPressed: () => context.push('/import'),
                      ),
                    ],
                  ),
                ),
              )
            : SafeArea(
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
                        onCourseTap: (course) => context.push(
                          '/today/course/${course.id}',
                          extra: course,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Page-backed preview retains the Today route/scroll position. Only the
/// fixed-size panel slides; the dim layer stays fixed across the viewport.
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
    final animation =
        ModalRoute.of(context)?.animation ?? const AlwaysStoppedAnimation(1.0);
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: animation,
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
        builder: (context, panel) {
          // Use the same position function both ways so a Back during entry
          // reverses from the current position without a curve-switch jump.
          final value = reduced
              ? 1.0
              : GlassMotion.enter.transform(animation.value);
          return Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(),
                child: ColoredBox(
                  key: const ValueKey('today-preview-dim'),
                  color: Colors.black.withValues(alpha: 0.18 * value),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: FractionalTranslation(
                  key: const ValueKey('today-preview-slide'),
                  translation: Offset(0, 1 - value),
                  child: panel,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
