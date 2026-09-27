import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/glass/glass_button.dart';
import '../../../core/glass/glass_dialog.dart';
import '../../../core/glass/glass_surface.dart';
import '../../../core/widgets/ambient_backdrop.dart';
import '../../../models/bell_schedule.dart';
import '../../schools/providers/school_providers.dart';
import '../../schools/services/school_repository.dart';

class BellSettingsPage extends ConsumerWidget {
  const BellSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppTheme.paletteOf(context);
    final school = ref.watch(activeSchoolProvider);
    final bell = school == null
        ? null
        : ref.watch(sectionTimesProvider(school.id)).value;

    if (school == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('默认作息')),
        body: const Center(child: Text('先创建学校')),
      );
    }
    final sections = [...(bell?.sections ?? const <SectionSpec>[])]
      ..sort((a, b) => a.index.compareTo(b.index));

    return Scaffold(
      appBar: AppBar(
        title: const Text('默认作息'),
        actions: [
          GlassButton(
            onPressed: () => _confirmReset(context, ref, school.id),
            label: '恢复通用默认',
            semanticLabel: '恢复通用默认作息',
            iconColor: palette.accent,
            labelStyle: TextStyle(fontSize: 13.5, color: palette.accent),
            size: 40,
          ),
        ],
      ),
      body: AmbientBackdrop(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              '按学校官方作息修改每节课的起止时间；教务导入也可能整体替换这里的值（会先征得确认）。',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.6,
                color: palette.inkTertiary,
              ),
            ),
            const SizedBox(height: 12),
            for (final spec in sections)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassSurface(
                  interactive: true,
                  onTap: () => _editTime(context, ref, school.id, spec),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 64,
                        child: Text(
                          '第 ${spec.index} 节',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: palette.ink,
                          ),
                        ),
                      ),
                      Text(
                        sectionGroupName(spec.group),
                        style: TextStyle(
                          fontSize: 12,
                          color: palette.inkTertiary,
                        ),
                      ),
                      const Spacer(),
                      Semantics(
                        label: '修改第 ${spec.index} 节时间',
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${spec.start} - ${spec.end}',
                            style: TextStyle(
                              fontSize: 15,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                              color: palette.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _editTime(
    BuildContext context,
    WidgetRef ref,
    String schoolId,
    SectionSpec spec,
  ) async {
    final start = await showTimePicker(
      context: context,
      initialTime: _parse(spec.start),
      helpText: '第 ${spec.index} 节开始',
    );
    if (start == null || !context.mounted) return;
    final end = await showTimePicker(
      context: context,
      initialTime: _parse(spec.end),
      helpText: '第 ${spec.index} 节结束',
    );
    if (end == null) return;
    await ref
        .read(schoolRepositoryProvider)
        .updateSectionTime(
          schoolId,
          spec.index,
          start: _format(start),
          end: _format(end),
        );
  }

  String _format(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';

  TimeOfDay _parse(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
  }

  Future<void> _confirmReset(
    BuildContext context,
    WidgetRef ref,
    String schoolId,
  ) async {
    final ok = await showGlassDialog<bool>(
      context: context,
      builder: (dialogContext) => GlassDialog(
        title: const Text('恢复通用默认作息'),
        content: const Text('当前所有节次时间会被替换为 8:00 起的通用作息，需要重新手动修改。'),
        actions: [
          GlassDialogAction(
            label: '取消',
            onPressed: () => Navigator.pop(dialogContext, false),
          ),
          GlassDialogAction(
            label: '恢复',
            destructive: true,
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(schoolRepositoryProvider).resetSectionTimes(schoolId);
    }
  }
}
