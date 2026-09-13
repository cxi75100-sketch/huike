import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/semester.dart';
import '../../schools/providers/school_providers.dart';
import '../../schools/services/school_repository.dart';

class SemesterSettingsPage extends ConsumerWidget {
  const SemesterSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppTheme.paletteOf(context);
    final school = ref.watch(activeSchoolProvider);
    final semester = school == null
        ? null
        : ref.watch(activeSemesterProvider(school.id));
    final semesters = school == null
        ? null
        : ref.watch(semestersForSchoolProvider(school.id)).value;

    if (school == null || semester == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('学期设置')),
        body: const Center(child: Text('先创建学校')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('学期设置')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          InkWell(
            onTap: () => _editMonday(context, ref, semester),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: palette.hairlineStrong),
              ),
              child: Row(
                children: [
                  Text(
                    '开学第一周周一',
                    style: TextStyle(fontSize: 14.5, color: palette.inkSecondary),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('yyyy-MM-dd').format(semester.firstWeekMonday),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: palette.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '选择任意日期后会自动对齐到该日期所在周的周一。',
            style: TextStyle(fontSize: 12.5, color: palette.inkTertiary),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: palette.hairlineStrong),
            ),
            child: Row(
              children: [
                Text(
                  '教学周数',
                  style: TextStyle(fontSize: 14.5, color: palette.ink),
                ),
                const Spacer(),
                IconButton(
                  onPressed: semester.totalWeeks > 1
                      ? () => ref
                            .read(schoolRepositoryProvider)
                            .updateSemester(semester.id, totalWeeks: semester.totalWeeks - 1)
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                Text(
                  '${semester.totalWeeks}',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: palette.ink,
                  ),
                ),
                IconButton(
                  onPressed: semester.totalWeeks < 30
                      ? () => ref
                            .read(schoolRepositoryProvider)
                            .updateSemester(semester.id, totalWeeks: semester.totalWeeks + 1)
                      : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '周次、单双周与教学周历全部以开学周一为锚点；修改后课表立即按新锚点重算。',
            style: TextStyle(fontSize: 12.5, height: 1.6, color: palette.inkTertiary),
          ),
          if (semesters != null && semesters.length > 1) ...[
            const SizedBox(height: 24),
            Text(
              '历史学期',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: palette.inkTertiary,
              ),
            ),
            const SizedBox(height: 8),
            for (final other in semesters)
              if (other.id != semester.id)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    '${DateFormat('yyyy-MM-dd').format(other.firstWeekMonday)} 开始 · ${other.totalWeeks} 周',
                  ),
                  trailing: TextButton(
                    onPressed: () => ref
                        .read(schoolRepositoryProvider)
                        .setActiveSemester(school.id, other.id),
                    child: const Text('切换'),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Future<void> _editMonday(
    BuildContext context,
    WidgetRef ref,
    Semester semester,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: semester.firstWeekMonday,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (picked == null) return;
    final monday = picked.subtract(Duration(days: picked.weekday - 1));
    await ref
        .read(schoolRepositoryProvider)
        .updateSemester(
          semester.id,
          firstWeekMonday: DateTime(monday.year, monday.month, monday.day),
        );
  }
}
