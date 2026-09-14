import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/course_colors.dart';
import '../../../core/widgets/route_background.dart';
import '../../../models/bell_schedule.dart';
import '../../../models/course.dart';
import '../../../services/course_time_service.dart';
import '../../import/services/course_repository.dart';
import '../providers/timetable_providers.dart';

class CourseDetailPage extends ConsumerWidget {
  const CourseDetailPage({super.key, required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppTheme.paletteOf(context);
    final course = ref.watch(courseByIdProvider(courseId)).value;
    final bell = ref.watch(bellForActiveSchoolProvider);

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

    return RouteBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          actions: [
            IconButton(
              tooltip: '编辑',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/course/${course.id}/edit'),
            ),
            IconButton(
              tooltip: '删除',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, ref, course),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _CourseHero(course: course, range: range),
            const SizedBox(height: 18),
            _metaRow(context, '星期', '周${'一二三四五六日'[course.weekday - 1]}'),
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
    );
  }

  String _weeksText(List<int> weeks) {
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除课程'),
        content: Text('「${course.name}」将被删除，此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(courseRepositoryProvider).deleteCourse(course.id);
    if (context.mounted) context.go('/');
  }
}

class _CourseHero extends StatelessWidget {
  const _CourseHero({required this.course, required this.range});

  final Course course;
  final (String, String)? range;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    final tint = courseTint(course.colorKey, Theme.of(context).brightness);
    final sectionText = course.startSection == course.endSection
        ? '第 ${course.startSection} 节'
        : '第 ${course.startSection}-${course.endSection} 节';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: tint.chip,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tint.onChip.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  course.name,
                  style: TextStyle(
                    fontSize: 25,
                    height: 1.22,
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: palette.surface.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  sectionText,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: tint.onChip,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            range == null ? '时间未定' : '${range!.$1} - ${range!.$2}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: palette.inkSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _SectionRoute(
            startSection: course.startSection,
            endSection: course.endSection,
            activeColor: tint.onChip,
          ),
        ],
      ),
    );
  }
}

class _SectionRoute extends StatelessWidget {
  const _SectionRoute({
    required this.startSection,
    required this.endSection,
    required this.activeColor,
  });

  final int startSection;
  final int endSection;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    return Semantics(
      label: '一天十站，课程占用第 $startSection 至第 $endSection 节',
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
                for (var section = 1; section <= 10; section++)
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
