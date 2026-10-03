import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'core/router/app_router.dart';
import 'core/database/database_provider.dart';
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
    // Theme's existing startup read awaits the same beforeOpen migration.
    // Keep the app-level subscription narrow so school edits do not rebuild
    // unrelated routes such as the platform WebView.
    final databaseFailed = ref.watch(themePreferenceProvider).hasError;
    if (databaseFailed) {
      return MaterialApp(
        title: '汇课',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('读取原课表失败', style: TextStyle(fontSize: 20)),
                    const SizedBox(height: 12),
                    const Text('原有数据未删除。请重试；若仍无法打开，请保留应用并反馈此问题。'),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        setState(() => _launched = false);
                        ref.invalidate(databaseProvider);
                      },
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
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
