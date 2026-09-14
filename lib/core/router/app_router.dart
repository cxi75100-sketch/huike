import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/import/pages/import_entry_page.dart';
import '../../features/import/pages/import_preview_page.dart';
import '../../features/import/pages/import_web_page.dart';
import '../../features/onboarding/pages/onboarding_page.dart';
import '../../features/settings/pages/bell_settings_page.dart';
import '../../features/settings/pages/calendar_exception_page.dart';
import '../../features/settings/pages/school_manage_page.dart';
import '../../features/settings/pages/semester_settings_page.dart';
import '../../features/settings/pages/settings_page.dart';
import '../../features/schools/providers/school_providers.dart';
import '../../features/timetable/pages/course_detail_page.dart';
import '../../features/timetable/pages/course_edit_page.dart';
import '../../features/timetable/pages/timetable_page.dart';

/// 每个 ProviderContainer 独立的 navigator key。
/// 不能是全局变量：测试里多个容器会各自挂载 MaterialApp，
/// 复用同一个 GlobalKey 会让树状态跨用例污染。
final rootNavigatorKeyProvider = Provider<GlobalKey<NavigatorState>>(
  (ref) => GlobalKey<NavigatorState>(),
);

/// 单一 GoRouter 实例。
///
/// 学校是否存在决定 redirect；该状态通过 refreshListenable 驱动重新
/// 评估，而不是重建 Router 本身——重建会让进行中的导航与动画悬挂。
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.onDispose(refresh.dispose);
  ref.listen<AsyncValue<String?>>(activeSchoolIdProvider, (_, _) {
    refresh.value++;
  });

  return GoRouter(
    navigatorKey: ref.watch(rootNavigatorKeyProvider),
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final hasSchool = ref.read(activeSchoolIdProvider).value != null;
      final onOnboarding = state.matchedLocation == '/onboarding';
      if (!hasSchool && !onOnboarding) return '/onboarding';
      if (hasSchool && onOnboarding) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const TimetablePage(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => OnboardingPage(
          isAddingSchool: state.uri.queryParameters['add'] == '1',
        ),
      ),
      GoRoute(
        path: '/import',
        builder: (context, state) => const ImportEntryPage(),
      ),
      GoRoute(
        path: '/import/web',
        builder: (context, state) => ImportWebPage(
          host: state.uri.queryParameters['host'] ?? '',
          initialUrl: state.uri.queryParameters['url'] ?? 'about:blank',
        ),
      ),
      GoRoute(
        path: '/import/preview',
        builder: (context, state) => const ImportPreviewPage(),
      ),
      GoRoute(
        path: '/course/new',
        builder: (context, state) => const CourseEditPage(),
      ),
      GoRoute(
        path: '/course/:id',
        builder: (context, state) =>
            CourseDetailPage(courseId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/course/:id/edit',
        builder: (context, state) =>
            CourseEditPage(courseId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/settings/schools',
        builder: (context, state) => const SchoolManagePage(),
      ),
      GoRoute(
        path: '/settings/semester',
        builder: (context, state) => const SemesterSettingsPage(),
      ),
      GoRoute(
        path: '/settings/bell',
        builder: (context, state) => const BellSettingsPage(),
      ),
      GoRoute(
        path: '/settings/calendar',
        builder: (context, state) => const CalendarExceptionPage(),
      ),
    ],
  );
});
