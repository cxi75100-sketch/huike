import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
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

    return Scaffold(
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
          Text(
            course.name,
            style: TextStyle(
              fontSize: 28,
              height: 1.25,
              fontWeight: FontWeight.w700,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 16),
          _metaRow(context, '时间', range == null ? '时间未定' : '${range.$1} - ${range.$2}'),
          _hairline(palette),
          _metaRow(context, '节次', _sectionText(course)),
          _hairline(palette),
          _metaRow(context, '星期', '周${'一二三四五六日'[course.weekday - 1]}'),
          _hairline(palette),
          _metaRow(context, '周次', _weeksText(course.weeks)),
          _hairline(palette),
          _metaRow(context, '教师', course.teacher.isEmpty ? '未填' : course.teacher),
          _hairline(palette),
          _metaRow(context, '教室', course.classroom.isEmpty ? '未填' : course.classroom),
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
    );
  }

  String _sectionText(Course course) => course.startSection == course.endSection
      ? '第 ${course.startSection} 节'
      : '第 ${course.startSection}-${course.endSection} 节';

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
