import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_preference.dart';
import 'core/theme/theme_preference_provider.dart';
import 'core/widgets/launch_readiness.dart';
import 'core/widgets/launch_reveal.dart';
import 'features/schools/services/school_repository.dart';

class HuikeApp extends ConsumerStatefulWidget {
  const HuikeApp({super.key});

  @override
  ConsumerState<HuikeApp> createState() => _HuikeAppState();
}

class _HuikeAppState extends ConsumerState<HuikeApp> {
  bool _launched = false;
  bool _themeSettled = false;
  bool _themeSettleScheduled = false;

  @override
  Widget build(BuildContext context) {
    final ready = ref.watch(launchReadinessProvider);
    _launched = _launched || ready;
    final router = ref.watch(appRouterProvider);
    final preference = ref.watch(themePreferenceProvider).value;
    if (preference != null && !_themeSettleScheduled) {
      _themeSettleScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _themeSettled = true);
      });
    }
    // 启动时补一次老学校缺失的档案变体（幂等，见 ISSUE-014），结果不参与渲染。
    ref.watch(presetVariantRepairProvider);

    return MaterialApp.router(
      title: '汇课',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeModeOf(preference ?? ThemePreference.system),
      themeAnimationDuration: _themeSettled
          ? kThemeAnimationDuration
          : Duration.zero,
      builder: (context, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
            statusBarBrightness: dark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: dark
                ? Brightness.light
                : Brightness.dark,
            systemStatusBarContrastEnforced: false,
            systemNavigationBarContrastEnforced: false,
          ),
          child: LaunchReveal(
            ready: _launched,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
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
