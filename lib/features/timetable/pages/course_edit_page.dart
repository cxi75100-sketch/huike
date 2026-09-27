import 'package:flutter/material.dart';

import '../../../core/widgets/ambient_backdrop.dart';
import '../../../core/glass/glass_button.dart';
import '../../../core/glass/glass_form.dart';
import '../../../core/glass/glass_metrics.dart';
import '../../../core/glass/glass_surface.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/glass/glass_transition.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/course_colors.dart';
import '../../../models/course.dart';
import '../../../services/week_parser.dart';
import '../../../services/section_count_resolver.dart';
import '../../../services/semester_service.dart';
import '../../import/services/course_repository.dart';
import '../../schools/providers/school_providers.dart';
import '../providers/timetable_providers.dart';

/// 手动新增 / 编辑课程。
class CourseEditPage extends ConsumerStatefulWidget {
  const CourseEditPage({super.key, this.courseId, this.isEvent = false});

  final String? courseId;
  final bool isEvent;

  @override
  ConsumerState<CourseEditPage> createState() => _CourseEditPageState();
}

class _CourseEditPageState extends ConsumerState<CourseEditPage> {
  final _nameController = TextEditingController();
  final _teacherController = TextEditingController();
  final _classroomController = TextEditingController();
  final _weeksController = TextEditingController(text: '1-16');
  final _noteController = TextEditingController();
  int _weekday = 1;
  int _startSection = 1;
  int _endSection = 1;
  bool _loadedExisting = false;
  String? _weeksError;

  @override
  void initState() {
    super.initState();
    if (widget.isEvent) {
      final semester = ref.read(activeSemesterRefProvider);
      final now = DateTime.now();
      _weekday = now.weekday;
      if (semester != null) {
        final week = const SemesterService()
            .currentWeek(semester, now)
            .clamp(1, semester.totalWeeks);
        _weeksController.text = '$week';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _teacherController.dispose();
    _classroomController.dispose();
    _weeksController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    final existing = widget.courseId == null
        ? null
        : ref.watch(courseByIdProvider(widget.courseId!)).value;
    final bell = ref.watch(bellForActiveSchoolProvider);
    final sectionCount = SectionCountResolver.resolve(
      bell,
      courses: existing == null ? const [] : [existing],
    );

    if (existing != null && !_loadedExisting) {
      _loadedExisting = true;
      _nameController.text = existing.name;
      _teacherController.text = existing.teacher;
      _classroomController.text = existing.classroom;
      _noteController.text = existing.note;
      _weeksController.text = formatWeeks(existing.weeks);
      _weekday = existing.weekday;
      _startSection = existing.startSection;
      _endSection = existing.endSection;
    }

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text(
          existing == null
              ? widget.isEvent
                    ? '添加事件'
                    : '新增课程'
              : '编辑课程',
        ),
      ),
      body: AmbientBackdrop(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            GlassTextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '课程名（必填）'),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: GlassTextField(
                    controller: _teacherController,
                    decoration: const InputDecoration(labelText: '教师'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlassTextField(
                    controller: _classroomController,
                    decoration: const InputDecoration(labelText: '教室'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _label(palette, '星期'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var day = 1; day <= 7; day++)
                  GlassChoiceChip(
                    label: '周${'一二三四五六日'[day - 1]}',
                    selected: _weekday == day,
                    onSelected: () => setState(() => _weekday = day),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            _label(palette, '节次'),
            Row(
              children: [
                Expanded(
                  child: _sectionDropdown('开始', _startSection, sectionCount, (
                    value,
                  ) {
                    setState(() {
                      _startSection = value;
                      if (_endSection < value) _endSection = value;
                    });
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '至',
                    style: TextStyle(fontSize: 13, color: palette.inkTertiary),
                  ),
                ),
                Expanded(
                  child: _sectionDropdown('结束', _endSection, sectionCount, (
                    value,
                  ) {
                    setState(() => _endSection = value);
                  }),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _label(palette, '周次'),
            GlassTextField(
              controller: _weeksController,
              decoration: InputDecoration(
                hintText: '如 1-16、1-8,11-16、1-16(单)',
                errorText: _weeksError,
              ),
            ),
            const SizedBox(height: 14),
            GlassTextField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: '备注'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: GlassSurface(
        radius: GlassMetrics.sheetRadius,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(GlassMetrics.sheetRadius),
        ),
        intensity: GlassIntensity.prominent,
        depth: 0,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: GlassButton(
                onPressed: () => _save(existing, sectionCount),
                label: existing == null ? '添加课程' : '保存修改',
                shape: GlassButtonShape.rounded,
                size: 48,
                tapTarget: GlassMetrics.minimumTarget,
                tint: palette.accent.withValues(alpha: 0.14),
                depth: 0.45,
                labelStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: palette.accent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(AppPalette palette, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 2),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        color: palette.inkSecondary,
      ),
    ),
  );

  Widget _sectionDropdown(
    String hint,
    int value,
    int max,
    ValueChanged<int> onChanged,
  ) => GlassPickerRow<int>(
    label: hint,
    value: value.clamp(1, max),
    options: [for (var i = 1; i <= max; i++) (i, '第 $i 节')],
    onChanged: onChanged,
  );

  Future<void> _save(Course? existing, int sectionCount) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('课程名不能为空')),
        snackBarAnimationStyle: glassSnackBarStyle(context),
      );
      return;
    }
    List<int> weeks;
    try {
      weeks = parseWeeks(_weeksController.text);
    } on WeekParseException catch (error) {
      setState(() => _weeksError = error.message);
      return;
    }
    setState(() => _weeksError = null);

    final school = ref.read(activeSchoolProvider);
    final semester = ref.read(activeSemesterRefProvider);
    if (school == null || semester == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('先完成学校与学期设置')),
        snackBarAnimationStyle: glassSnackBarStyle(context),
      );
      return;
    }
    final repository = ref.read(courseRepositoryProvider);
    if (existing == null) {
      final course = Course(
        id: 'manual-${DateTime.now().microsecondsSinceEpoch}',
        schoolId: school.id,
        semesterId: semester.id,
        name: name,
        teacher: _teacherController.text.trim(),
        classroom: _classroomController.text.trim(),
        weekday: _weekday,
        startSection: _startSection,
        endSection: _endSection.clamp(_startSection, sectionCount),
        weeks: weeks,
        colorKey: colorKeyForName(name),
        note: _noteController.text.trim(),
      );
      await repository.addManualCourse(
        schoolId: school.id,
        semesterId: semester.id,
        course: course,
      );
    } else {
      await repository.updateCourse(
        existing.copyWith(
          name: name,
          teacher: _teacherController.text.trim(),
          classroom: _classroomController.text.trim(),
          weekday: _weekday,
          startSection: _startSection,
          endSection: _endSection,
          weeks: weeks,
          colorKey: colorKeyForName(name),
          note: _noteController.text.trim(),
        ),
      );
    }
    if (mounted) context.go('/');
  }
}
