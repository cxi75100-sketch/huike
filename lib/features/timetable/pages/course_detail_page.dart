import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/glass/glass_button.dart';
import '../../../core/glass/glass_dialog.dart';
import '../../../core/glass/glass_surface.dart';
import '../../../core/widgets/ambient_backdrop.dart';
import '../../../models/bell_schedule.dart';
import '../../../models/course.dart';
import '../../../services/course_time_service.dart';
import '../../../services/section_count_resolver.dart';
import '../../import/services/course_repository.dart';
import '../providers/timetable_providers.dart';
import '../widgets/course_hero.dart';

class CourseDetailPage extends ConsumerWidget {
  const CourseDetailPage({
    super.key,
    required this.courseId,
    this.heroSource = CourseHeroSourceContext.weeklyTimetable,
    this.revealMetadata = true,
  });

  final String courseId;
  final CourseHeroSourceContext heroSource;
  final bool revealMetadata;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppTheme.paletteOf(context);
    final courseAsync = ref.watch(courseByIdProvider(courseId));
    final course = courseAsync.value;
    final bell = ref.watch(bellForActiveSchoolProvider);
    final blur = heroSource == CourseHeroSourceContext.today ? 0.0 : null;

    if (courseAsync.isLoading && !courseAsync.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (courseAsync.hasError) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('课程加载失败，请稍后重试')),
      );
    }

    if (course == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('课程不存在或已删除')),
      );
    }

    final range = const CourseTimeService().resolve(
      course,
      bell ?? BellSchedule.fallback(),
    );

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        actions: [
          GlassButton.icon(
            blurSigma: blur,
            icon: Icons.edit_outlined,
            tooltip: '编辑',
            semanticLabel: '编辑课程',
            iconColor: palette.accent,
            onPressed: () => context.push('/course/${course.id}/edit'),
            size: 36,
          ),
          GlassButton.icon(
            blurSigma: blur,
            icon: Icons.delete_outline,
            tooltip: '删除',
            semanticLabel: '删除课程',
            iconColor: palette.danger,
            tint: palette.danger.withValues(alpha: 0.1),
            onPressed: () => _confirmDelete(context, ref, course),
            size: 36,
          ),
        ],
      ),
      body: AmbientBackdrop(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            CourseHero(
              tag: CourseHeroTag.forDetails(course, heroSource),
              child: CourseHeroSurface(course: course, range: range),
            ),
            const SizedBox(height: 12),
            _revealBody(
              context,
              GlassSurface(
                blurSigma: blur,
                padding: const EdgeInsets.all(16),
                child: _SectionRoute(
                  startSection: course.startSection,
                  endSection: course.endSection,
                  sectionCount: SectionCountResolver.resolve(
                    bell,
                    courses: [course],
                  ),
                  activeColor: palette.accent,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _revealBody(
              context,
              GlassSurface(
                blurSigma: blur,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _metaRow(
                      context,
                      '星期',
                      '周${'一二三四五六日'[course.weekday - 1]}',
                    ),
                    _hairline(palette),
                    _metaRow(context, '周次', _weeksText(course.weeks)),
                    _hairline(palette),
                    _metaRow(
                      context,
                      '教师',
                      course.teacher.isEmpty ? '未填' : course.teacher,
                    ),
                    _hairline(palette),
                    _metaRow(
                      context,
                      '教室',
                      course.classroom.isEmpty ? '未填' : course.classroom,
                    ),
                    _hairline(palette),
                    _metaRow(
                      context,
                      '来源',
                      course.source == CourseSource.imported ? '教务导入' : '手动录入',
                    ),
                    if (course.note.isNotEmpty) ...[
                      _hairline(palette),
                      _metaRow(context, '备注', course.note),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _revealBody(BuildContext context, Widget child) {
    if (!revealMetadata) return child;
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final routeAnimation = ModalRoute.of(context)?.animation;
    if (routeAnimation == null) return child;
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: routeAnimation,
        curve: const Interval(0.25, 1, curve: Curves.easeOut),
      ),
      child: child,
    );
  }

  String _weeksText(List<int> weeks) {
    if (weeks.isEmpty) return '未设置周次';
    final sorted = [...weeks]..sort();
    final parts = <String>[];
    var start = sorted.first;
    var previous = start;
    for (final week in sorted.skip(1)) {
      if (week == previous + 1) {
        previous = week;
        continue;
      }
      parts.add(start == previous ? '$start' : '$start-$previous');
      start = previous = week;
    }
    parts.add(start == previous ? '$start' : '$start-$previous');
    return '第 ${parts.join(',')} 周';
  }

  Widget _hairline(AppPalette palette) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Container(height: 1, color: palette.hairline),
  );

  Widget _metaRow(BuildContext context, String label, String value) {
    final palette = AppTheme.paletteOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: TextStyle(fontSize: 13.5, color: palette.inkTertiary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: palette.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Course course,
  ) async {
    final ok = await showGlassDialog<bool>(
      context: context,
      builder: (dialogContext) => GlassDialog(
        title: const Text('删除课程'),
        content: Text('「${course.name}」将被删除，此操作不可撤销。'),
        actions: [
          GlassDialogAction(
            label: '取消',
            onPressed: () => Navigator.pop(dialogContext, false),
          ),
          GlassDialogAction(
            label: '删除',
            destructive: true,
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(courseRepositoryProvider).deleteCourse(course.id);
    if (context.mounted) context.go('/');
  }
}

class _SectionRoute extends StatelessWidget {
  const _SectionRoute({
    required this.startSection,
    required this.endSection,
    required this.sectionCount,
    required this.activeColor,
  });

  final int startSection;
  final int endSection;
  final int sectionCount;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    return Semantics(
      label: '一天 $sectionCount 节，课程占用第 $startSection 至第 $endSection 节',
      child: SizedBox(
        height: 34,
        child: Stack(
          children: [
            Positioned(
              left: 12,
              right: 12,
              top: 18,
              child: Container(height: 1.5, color: palette.hairlineStrong),
            ),
            Row(
              children: [
                for (var section = 1; section <= sectionCount; section++)
                  Expanded(
                    child: ExcludeSemantics(
                      child: Column(
                        children: [
                          Text(
                            '$section',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                              color: palette.inkTertiary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width:
                                section >= startSection && section <= endSection
                                ? 10
                                : 7,
                            height:
                                section >= startSection && section <= endSection
                                ? 10
                                : 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  section >= startSection &&
                                      section <= endSection
                                  ? activeColor
                                  : palette.surface,
                              border: Border.all(
                                color:
                                    section >= startSection &&
                                        section <= endSection
                                    ? activeColor
                                    : palette.hairlineStrong,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
