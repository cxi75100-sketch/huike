import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_preference.dart';
import '../../../core/theme/theme_preference_provider.dart';
import '../../schools/providers/school_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppTheme.paletteOf(context);
    final school = ref.watch(activeSchoolProvider);
    final themePref = ref.watch(themePreferenceProvider).value
        ?? ThemePreference.system;

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _groupTitle(palette, '学校'),
          _tile(
            context,
            palette,
            icon: Icons.school_outlined,
            title: school?.displayName ?? '未创建学校',
            subtitle: '学校管理、切换与导入配置',
            onTap: () => context.push('/settings/schools'),
          ),
          _tile(
            context,
            palette,
            icon: Icons.event_outlined,
            title: '学期设置',
            subtitle: '开学周一与教学周数',
            onTap: () => context.push('/settings/semester'),
          ),
          _tile(
            context,
            palette,
            icon: Icons.schedule_outlined,
            title: '默认作息',
            subtitle: '每节课的起止时间',
            onTap: () => context.push('/settings/bell'),
          ),
          const SizedBox(height: 20),
          _groupTitle(palette, '外观'),
          RadioGroup<ThemePreference>(
            groupValue: themePref,
            onChanged: (value) {
              if (value != null) {
                ref.read(themePreferenceProvider.notifier).set(value);
              }
            },
            child: Container(
              decoration: _groupDecoration(palette),
              child: Column(
                children: [
                  for (final preference in ThemePreference.values)
                    RadioListTile<ThemePreference>(
                      value: preference,
                      title: Text(
                        switch (preference) {
                          ThemePreference.system => '跟随系统',
                          ThemePreference.light => '日间',
                          ThemePreference.dark => '夜间',
                        },
                      ),
                      activeColor: palette.accent,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _groupTitle(palette, '关于'),
          _tile(
            context,
            palette,
            icon: Icons.info_outline,
            title: '关于汇课',
            subtitle: '版本与开源说明',
            onTap: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('汇课'),
                content: const Text(
                  '多校通用本地课表。\n\n'
                  '课程数据全部保存在设备本地；教务导入在你的学校官方页面完成，'
                  '本应用不接触登录凭据。\n\n'
                  '内置教务适配脚本来自社区开源项目（MIT），'
                  '署名见应用仓库的 THIRD_PARTY_NOTICES 文件。',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('知道了'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _groupTitle(AppPalette palette, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 2),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        color: palette.inkTertiary,
      ),
    ),
  );

  BoxDecoration _groupDecoration(AppPalette palette) => BoxDecoration(
    color: palette.surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: palette.hairline),
  );

  Widget _tile(
    BuildContext context,
    AppPalette palette, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.hairline),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: palette.inkSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
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
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12.5, color: palette.inkSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: palette.inkTertiary),
            ],
          ),
        ),
      ),
    ),
  );
}
