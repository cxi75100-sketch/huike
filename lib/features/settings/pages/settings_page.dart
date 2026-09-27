import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/glass/glass_dialog.dart';
import '../../../core/glass/glass_form.dart';
import '../../../core/glass/glass_surface.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_preference.dart';
import '../../../core/theme/theme_preference_provider.dart';
import '../../../core/widgets/ambient_backdrop.dart';
import '../../schools/providers/school_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppTheme.paletteOf(context);
    final school = ref.watch(activeSchoolProvider);
    final preference =
        ref.watch(themePreferenceProvider).value ?? ThemePreference.system;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: const Text('设置')),
      body: AmbientBackdrop(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
          children: [
            GlassSurface(
              radius: 22,
              intensity: GlassIntensity.prominent,
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(Icons.school_rounded, size: 24, color: palette.accent),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '当前学校',
                          style: TextStyle(
                            fontSize: 12,
                            color: palette.inkSecondary,
                          ),
                        ),
                        Text(
                          school?.displayName ?? '尚未创建学校',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: palette.ink,
                          ),
                        ),
                        Text(
                          school?.loginUrl.isNotEmpty == true
                              ? '本机保存 · 教务入口已配置'
                              : '本机保存',
                          style: TextStyle(
                            fontSize: 12,
                            color: palette.inkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _title(context, '学校'),
            _group(context, [
              _row(
                context,
                Icons.school_outlined,
                school?.displayName ?? '学校管理',
                '学校管理、切换与导入配置',
                () => context.push('/settings/schools'),
              ),
              _row(
                context,
                Icons.event_outlined,
                '学期设置',
                '开学周一与教学周数',
                () => context.push('/settings/semester'),
              ),
              _row(
                context,
                Icons.schedule_outlined,
                '默认作息',
                '每节课的起止时间',
                () => context.push('/settings/bell'),
              ),
              _row(
                context,
                Icons.event_busy_outlined,
                '调休 / 停课',
                '放假与补课日',
                () => context.push('/settings/calendar'),
              ),
            ]),
            const SizedBox(height: 22),
            _title(context, '外观'),
            _group(context, [
              for (final choice in ThemePreference.values)
                _choice(
                  context,
                  choice,
                  preference,
                  () => ref.read(themePreferenceProvider.notifier).set(choice),
                ),
            ]),
            const SizedBox(height: 22),
            _title(context, '关于'),
            _group(context, [
              _row(
                context,
                Icons.info_outline_rounded,
                '关于汇课',
                '版本与开源说明',
                () => _about(context),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _title(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 0, 0, 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppTheme.paletteOf(context).inkSecondary,
      ),
    ),
  );

  Widget _group(BuildContext context, List<Widget> rows) {
    final palette = AppTheme.paletteOf(context);
    return GlassSurface(
      radius: 20,
      blurSigma: 16,
      intensity: GlassIntensity.regular,
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            if (index > 0)
              Padding(
                padding: const EdgeInsets.only(left: 54),
                child: Divider(height: 1, color: palette.hairline),
              ),
            rows[index],
          ],
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    final palette = AppTheme.paletteOf(context);
    return GlassSurface(
      interactive: true,
      onTap: onTap,
      blurSigma: 0,
      radius: 18,
      semanticLabel: '$title，$subtitle',
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Row(
          children: [
            Icon(icon, size: 21, color: palette.accent),
            const SizedBox(width: 17),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: palette.ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: palette.inkSecondary),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: palette.inkTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _choice(
    BuildContext context,
    ThemePreference choice,
    ThemePreference current,
    VoidCallback onTap,
  ) {
    final label = switch (choice) {
      ThemePreference.system => '跟随系统',
      ThemePreference.light => '日间',
      ThemePreference.dark => '夜间',
    };
    return GlassSelectionRow(
      label: label,
      selected: choice == current,
      onSelected: onTap,
      leading: Icon(
        switch (choice) {
          ThemePreference.system => Icons.brightness_auto_rounded,
          ThemePreference.light => Icons.wb_sunny_outlined,
          ThemePreference.dark => Icons.nightlight_outlined,
        },
        size: 20,
        color: AppTheme.paletteOf(context).accent,
      ),
    );
  }

  Future<void> _about(BuildContext context) => showGlassDialog<void>(
    context: context,
    builder: (dialogContext) => GlassDialog(
      title: const Text('汇课'),
      content: const Text(
        '多校通用本地课表。课程数据保存在设备本地；教务导入在学校官方页面完成。\n\n内置教务适配脚本的署名见 THIRD_PARTY_NOTICES。',
      ),
      actions: [
        GlassDialogAction(
          label: '知道了',
          primary: true,
          onPressed: () => Navigator.of(dialogContext).pop(),
        ),
      ],
    ),
  );
}
