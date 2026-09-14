import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_preference.dart';
import '../../../core/theme/theme_preference_provider.dart';
import '../../../core/widgets/route_background.dart';
import '../../schools/providers/school_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppTheme.paletteOf(context);
    final school = ref.watch(activeSchoolProvider);
    final themePref =
        ref.watch(themePreferenceProvider).value ?? ThemePreference.system;

    return RouteBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('设置')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _SchoolIdentityCard(
              schoolName: school?.displayName ?? '尚未创建学校',
              hasLoginUrl: school?.loginUrl.isNotEmpty ?? false,
            ),
            const SizedBox(height: 24),
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
            _tile(
              context,
              palette,
              icon: Icons.event_busy_outlined,
              title: '调休 / 停课',
              subtitle: '放假与补课日',
              onTap: () => context.push('/settings/calendar'),
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
              // Material 必须在这里：ListTile 的背景与涟漪画在最近的 Material 上，
              // 中间隔一层带背景的 Container 会被 Flutter 断言拦下（且涟漪看不见）。
              child: Material(
                color: palette.surface,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: palette.hairline),
                  ),
                  child: Column(
                    children: [
                      for (final preference in ThemePreference.values)
                        RadioListTile<ThemePreference>(
                          value: preference,
                          title: Text(switch (preference) {
                            ThemePreference.system => '跟随系统',
                            ThemePreference.light => '日间',
                            ThemePreference.dark => '夜间',
                          }),
                          activeColor: palette.accent,
                        ),
                    ],
                  ),
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
                      style: TextStyle(
                        fontSize: 12.5,
                        color: palette.inkSecondary,
                      ),
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

class _SchoolIdentityCard extends StatelessWidget {
  const _SchoolIdentityCard({
    required this.schoolName,
    required this.hasLoginUrl,
  });

  final String schoolName;
  final bool hasLoginUrl;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    return Material(
      color: palette.surface.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.hairline),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: palette.accentSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.account_balance_outlined,
                color: palette.accent,
                size: 23,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '当前学校',
                    style: TextStyle(
                      fontSize: 11.5,
                      letterSpacing: 1.2,
                      color: palette.inkTertiary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    schoolName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: palette.ink,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    hasLoginUrl ? '本机保存 · 教务入口已配置' : '本机保存 · 可稍后配置教务入口',
                    style: TextStyle(fontSize: 12, color: palette.inkSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const SizedBox(width: 64, child: RouteMark(activeIndex: 2)),
          ],
        ),
      ),
    );
  }
}
