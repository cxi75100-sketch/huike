import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/calendar_exception.dart';
import '../../../models/semester.dart';
import '../../../services/calendar_exception_service.dart';
import '../../../services/semester_service.dart';
import '../../schools/providers/calendar_exception_providers.dart';
import '../../schools/providers/school_providers.dart';
import '../../schools/services/calendar_exception_repository.dart';
import '../../timetable/widgets/course_listing_row.dart';

/// 调休 / 停课：按日期维护校历例外。
///
/// 只表达两种语义——这天停课，或这天按某个星期的课表上课。用户不需要理解
/// 优先级规则：同一天只有一条记录，再填一次就是覆盖。
class CalendarExceptionPage extends ConsumerWidget {
  const CalendarExceptionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppTheme.paletteOf(context);
    final school = ref.watch(activeSchoolProvider);
    final semester = school == null
        ? null
        : ref.watch(activeSemesterProvider(school.id));

    if (school == null || semester == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('调休 / 停课')),
        body: const Center(child: Text('先创建学校并设置学期')),
      );
    }

    final exceptions =
        ref.watch(calendarExceptionsProvider((school.id, semester.id))).value ??
        const <CalendarException>[];

    return Scaffold(
      appBar: AppBar(title: const Text('调休 / 停课')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            _edit(context, ref, schoolId: school.id, semester: semester),
        backgroundColor: palette.accent,
        foregroundColor: palette.onAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        icon: const Icon(Icons.add),
        label: const Text('添加'),
      ),
      body: exceptions.isEmpty
          ? const EmptyDayPlate(
              title: '还没有例外',
              subtitle: '放假日标为停课，补课日标为按某天的课表上课',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
              children: [
                for (final exception in exceptions)
                  _ExceptionTile(
                    exception: exception,
                    semester: semester,
                    onEdit: () => _edit(
                      context,
                      ref,
                      schoolId: school.id,
                      semester: semester,
                      existing: exception,
                    ),
                    onDelete: () => ref
                        .read(calendarExceptionRepositoryProvider)
                        .deleteById(exception.id),
                  ),
                const SizedBox(height: 16),
                Text(
                  '例外只作用于课表显示，不改动课程本身；同一天再填一次即覆盖旧设置。',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.6,
                    color: palette.inkTertiary,
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, {
    required String schoolId,
    required Semester semester,
    CalendarException? existing,
  }) async {
    final today = DateTime.now();
    final initial = existing?.date ?? today;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: semester.firstWeekMonday.subtract(const Duration(days: 30)),
      lastDate: semester.firstWeekMonday.add(
        Duration(days: semester.totalWeeks * 7 + 30),
      ),
    );
    if (picked == null || !context.mounted) return;

    var kind = existing?.kind ?? CalendarExceptionKind.holiday;
    var makeupWeekday =
        existing?.makeupWeekday ?? const SemesterService().weekdayOf(picked);
    final noteController = TextEditingController(text: existing?.note ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(DateFormat('M月d日').format(picked)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RadioGroup<CalendarExceptionKind>(
                groupValue: kind,
                onChanged: (value) {
                  if (value == null) return;
                  setDialogState(() => kind = value);
                },
                child: Column(
                  children: [
                    RadioListTile<CalendarExceptionKind>(
                      value: CalendarExceptionKind.holiday,
                      title: const Text('停课'),
                      dense: true,
                    ),
                    RadioListTile<CalendarExceptionKind>(
                      value: CalendarExceptionKind.makeup,
                      title: const Text('调休：按某天的课表上课'),
                      dense: true,
                    ),
                  ],
                ),
              ),
              if (kind == CalendarExceptionKind.makeup) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    for (var day = 1; day <= 7; day++)
                      ChoiceChip(
                        label: Text(CalendarExceptionService.weekdayName(day)),
                        selected: makeupWeekday == day,
                        onSelected: (_) =>
                            setDialogState(() => makeupWeekday = day),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: '备注（可选）',
                  hintText: '如：国庆、校运会',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;

    await ref
        .read(calendarExceptionRepositoryProvider)
        .save(
          id: existing?.id,
          schoolId: schoolId,
          semesterId: semester.id,
          date: picked,
          kind: kind,
          makeupWeekday: makeupWeekday,
          note: noteController.text.trim(),
        );
  }
}

class _ExceptionTile extends StatelessWidget {
  const _ExceptionTile({
    required this.exception,
    required this.semester,
    required this.onEdit,
    required this.onDelete,
  });

  final CalendarException exception;
  final Semester semester;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    final isMakeup = exception.kind == CalendarExceptionKind.makeup;
    final label = isMakeup
        ? '调休 · 按${CalendarExceptionService.weekdayName(exception.makeupWeekday ?? exception.date.weekday)}的课表'
        : '停课';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.hairline),
        ),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 34,
              decoration: BoxDecoration(
                color: isMakeup ? palette.accent : palette.inkTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        DateFormat('M月d日').format(exception.date),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: palette.ink,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        CalendarExceptionService.weekdayName(
                          exception.date.weekday,
                        ),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: palette.inkTertiary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '第 ${const SemesterService().currentWeek(semester, exception.date)} 周',
                        style: TextStyle(
                          fontSize: 12,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: palette.inkTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    exception.note.isEmpty
                        ? label
                        : '$label · ${exception.note}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isMakeup ? palette.accent : palette.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: '更多',
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('修改')),
                PopupMenuItem(value: 'delete', child: Text('删除')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
