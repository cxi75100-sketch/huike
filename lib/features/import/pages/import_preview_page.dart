import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/course_colors.dart';
import '../../../models/bell_schedule.dart';
import '../../../models/course.dart';
import '../../../models/semester.dart';
import '../../../services/course_time_service.dart';
import '../../schools/providers/school_providers.dart';
import '../../schools/services/school_repository.dart';
import '../models/adapter_batch.dart';
import '../services/course_repository.dart';
import '../services/import_diff.dart';
import '../services/import_session.dart';
import '../widgets/import_widgets.dart';

/// 写库前的最后确认：差异三类、无效条目、附加选项，全部明示。
class ImportPreviewPage extends ConsumerStatefulWidget {
  const ImportPreviewPage({super.key});

  @override
  ConsumerState<ImportPreviewPage> createState() => _ImportPreviewPageState();
}

class _ImportPreviewPageState extends ConsumerState<ImportPreviewPage> {
  bool _replaceSchedule = false;
  bool _applyConfig = false;
  bool _applying = false;
  bool _initializedDefaults = false;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    final school = ref.watch(activeSchoolProvider);
    final session = ref.watch(importSessionProvider);
    final semester = school == null
        ? null
        : ref.watch(activeSemesterProvider(school.id));

    if (school == null || session.normalized == null || semester == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('导入预览')),
        body: const Center(child: Text('没有可预览的导入数据')),
      );
    }

    final batch = session.normalized!;
    final existing = ref.watch(
      importedCoursesProvider((school.id, semester.id)),
    ).value;
    if (existing == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('导入预览')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final bell = ref.watch(sectionTimesProvider(school.id)).value;
    final schedule = bell ?? BellSchedule.fallback();
    if (!_initializedDefaults && batch.timeSlots.isNotEmpty) {
      // 默认值只在“作息仍是通用兜底”时替用户勾上；自定义过则默认不动。
      // 只初始化一次，避免重建覆盖用户选择。
      _initializedDefaults = true;
      _replaceSchedule = (bell ?? schedule).equalsFallback();
    }

    final nextCourses = _draftsToCourses(batch.courses, school.id, semester.id, schedule);
    final diff = diffImportedCourses(existing, nextCourses);

    final config = batch.courseConfig;
    final showConfigOption = config.semesterStartDate != null ||
        config.totalWeeks != null;

    return Scaffold(
      appBar: AppBar(title: const Text('导入预览')),
      body: _applying
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                _summary(context, diff, batch),
                if (batch.invalidCount > 0) ...[
                  const SizedBox(height: 12),
                  _invalidBlock(context, batch),
                ],
                if (batch.timeSlots.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _scheduleOption(context, batch),
                ],
                if (showConfigOption) ...[
                  const SizedBox(height: 12),
                  _configOption(context, config, semester),
                ],
                if (!diff.isEmpty) ...[
                  const SizedBox(height: 20),
                  _diffLists(context, diff),
                ] else ...[
                  const SizedBox(height: 16),
                  Text(
                    '与上次导入一致，没有新增、移除或修改。',
                    style: TextStyle(fontSize: 14, color: palette.inkSecondary),
                  ),
                ],
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton(
            onPressed: _applying ? null : () => _apply(school.id, semester.id, batch),
            child: Text(_applying ? '正在写入' : '确认写入 ${batch.courses.length} 门课程'),
          ),
        ),
      ),
    );
  }

  Widget _summary(BuildContext context, ImportDiff diff, AdapterImportBatch batch) {
    final palette = AppTheme.paletteOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.hairline),
      ),
      child: Row(
        children: [
          _count(context, '新增', diff.added.length),
          _divider(palette),
          _count(context, '移除', diff.removed.length),
          _divider(palette),
          _count(context, '修改', diff.changed.length),
          if (batch.invalidCount > 0) ...[
            _divider(palette),
            _count(context, '无效', batch.invalidCount, warn: true),
          ],
        ],
      ),
    );
  }

  Widget _count(BuildContext context, String label, int count, {bool warn = false}) {
    final palette = AppTheme.paletteOf(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: warn ? palette.accent : palette.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: palette.inkSecondary),
          ),
        ],
      ),
    );
  }

  Widget _divider(AppPalette palette) => Container(
    width: 1,
    height: 28,
    color: palette.hairline,
  );

  Widget _invalidBlock(BuildContext context, AdapterImportBatch batch) {
    final palette = AppTheme.paletteOf(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.accentSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${batch.invalidCount} 条数据无法识别，已跳过（不会写入）',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: palette.ink,
            ),
          ),
          for (final reason in batch.invalidReasons)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                reason,
                style: TextStyle(fontSize: 12.5, color: palette.inkSecondary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _scheduleOption(BuildContext context, AdapterImportBatch batch) {
    final palette = AppTheme.paletteOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.hairline),
      ),
      child: CheckboxListTile(
        value: _replaceSchedule,
        onChanged: (value) => setState(() => _replaceSchedule = value ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: palette.accent,
        contentPadding: EdgeInsets.zero,
        title: Text(
          '同时更新默认作息时间',
          style: TextStyle(fontSize: 14, color: palette.ink),
        ),
        subtitle: Text(
          '读到 ${batch.timeSlots.length} 节的起止时间，会整体替换当前作息表',
          style: TextStyle(fontSize: 12.5, color: palette.inkSecondary),
        ),
      ),
    );
  }

  Widget _configOption(
    BuildContext context,
    AdapterCourseConfig config,
    Semester semester,
  ) {
    final palette = AppTheme.paletteOf(context);
    final parts = <String>[
      if (config.semesterStartDate != null)
        '开学周一 ${_iso(config.semesterStartDate!)}',
      if (config.totalWeeks != null) '共 ${config.totalWeeks} 周',
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.hairline),
      ),
      child: CheckboxListTile(
        value: _applyConfig,
        onChanged: (value) => setState(() => _applyConfig = value ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: palette.accent,
        contentPadding: EdgeInsets.zero,
        title: Text(
          '更新学期设置（脚本提供：${parts.join('，')}）',
          style: TextStyle(fontSize: 14, color: palette.ink),
        ),
        subtitle: Text(
          '当前：开学周一 ${_iso(semester.firstWeekMonday)}，共 ${semester.totalWeeks} 周',
          style: TextStyle(fontSize: 12.5, color: palette.inkSecondary),
        ),
      ),
    );
  }

  Widget _diffLists(BuildContext context, ImportDiff diff) {
    final palette = AppTheme.paletteOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeaderLabel('明细'),
        for (final course in diff.added)
          _courseLine(context, course, palette.accent, '新增'),
        for (final course in diff.removed)
          _courseLine(context, course, palette.inkTertiary, '移除'),
        for (final change in diff.changed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _tag(context, '修改', palette.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        change.current.name,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: palette.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(left: 34),
                  child: Text(
                    change.fields.join('、'),
                    style: TextStyle(fontSize: 12.5, color: palette.inkSecondary),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _courseLine(BuildContext context, Course course, Color tagColor, String tag) {
    final palette = AppTheme.paletteOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _tag(context, tag, tagColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              course.name,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: palette.ink,
              ),
            ),
          ),
          Text(
            '周${'一二三四五六日'[course.weekday - 1]} ${course.startSection}-${course.endSection}节',
            style: TextStyle(fontSize: 12.5, color: palette.inkSecondary),
          ),
        ],
      ),
    );
  }

  Widget _tag(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  List<Course> _draftsToCourses(
    List<AdapterCourseDraft> drafts,
    String schoolId,
    String semesterId,
    BellSchedule schedule,
  ) {
    final service = const CourseTimeService();
    return List.generate(drafts.length, (index) {
      final draft = drafts[index];
      final range = service.resolve(
        Course(
          id: '',
          schoolId: schoolId,
          semesterId: semesterId,
          name: draft.name,
          weekday: draft.weekday,
          startSection: draft.startSection,
          endSection: draft.endSection,
          weeks: draft.weeks,
          colorKey: 0,
          startTime: schedule.section(draft.startSection)?.start,
          endTime: schedule.section(draft.endSection)?.end,
        ),
        schedule,
      );
      return Course(
        id: CourseRepository.importedCourseId(schoolId, draft),
        schoolId: schoolId,
        semesterId: semesterId,
        name: draft.name,
        teacher: draft.teacher,
        classroom: draft.classroom,
        weekday: draft.weekday,
        startSection: draft.startSection,
        endSection: draft.endSection,
        weeks: draft.weeks,
        colorKey: colorKeyForName(draft.name),
        startTime: range?.$1,
        endTime: range?.$2,
        source: CourseSource.imported,
      );
    });
  }

  Future<void> _apply(
    String schoolId,
    String semesterId,
    AdapterImportBatch batch,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _applying = true);

    final bell = ref.read(sectionTimesProvider(schoolId)).value;
    final schedule = bell ?? BellSchedule.fallback();

    final courseRepo = ref.read(courseRepositoryProvider);
    final schoolRepo = ref.read(schoolRepositoryProvider);

    try {
      if (_replaceSchedule && batch.timeSlots.isNotEmpty) {
        await courseRepo.replaceSectionTimes(schoolId, batch.timeSlots);
      }
      final effectiveBell =
          (_replaceSchedule && batch.timeSlots.isNotEmpty)
          ? _scheduleFromSlots(batch.timeSlots)
          : schedule;
      await courseRepo.replaceImportedCourses(
        schoolId: schoolId,
        semesterId: semesterId,
        drafts: batch.courses,
        schedule: effectiveBell,
      );
      if (_applyConfig) {
        final config = batch.courseConfig;
        await schoolRepo.updateSemester(
          semesterId,
          firstWeekMonday: config.semesterStartDate,
          totalWeeks: config.totalWeeks,
        );
      }
      ref.read(importSessionProvider.notifier).reset();
      messenger.showSnackBar(
        SnackBar(content: Text('已写入 ${batch.courses.length} 门课程')),
      );
      router.go('/');
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('写入失败：$error')));
      if (mounted) setState(() => _applying = false);
    }
  }

  BellSchedule _scheduleFromSlots(List<AdapterTimeSlot> slots) => BellSchedule(
    sections: slots
        .map(
          (slot) => SectionSpec(
            index: slot.number,
            start: slot.startTime,
            end: slot.endTime,
            group: slot.number <= 4
                ? SectionGroup.morning
                : slot.number <= 8
                ? SectionGroup.afternoon
                : SectionGroup.evening,
          ),
        )
        .toList(),
  );

  String _iso(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }
}

/// 与当前 (schoolId, semesterId) 的教务来源课程流。
final importedCoursesProvider = StreamProvider.family
    .autoDispose<List<Course>, (String, String)>((ref, ids) {
      final (schoolId, semesterId) = ids;
      final db = ref.watch(databaseProvider);
      final query = db.select(db.courseEntries)
        ..where(
          (t) =>
              t.schoolId.equals(schoolId) &
              t.semesterId.equals(semesterId) &
              t.source.equals('imported'),
        );
      return query
          .watch()
          .map((rows) => rows.map((row) => row.toModel()).toList());
    });
