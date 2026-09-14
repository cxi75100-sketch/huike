import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_preference.dart';
import 'core/theme/theme_preference_provider.dart';
import 'features/schools/services/school_repository.dart';

class HuikeApp extends ConsumerWidget {
  const HuikeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final preference = ref.watch(themePreferenceProvider).value;
    // 启动时补一次老学校缺失的档案变体（幂等，见 ISSUE-014），结果不参与渲染。
    ref.watch(presetVariantRepairProvider);

    return MaterialApp.router(
      title: '汇课',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeModeOf(preference ?? ThemePreference.system),
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
    );
  }
}
