import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../glass/glass_motion.dart';
import 'glass_page.dart';
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
import '../../features/timetable/pages/today_page.dart';
import '../../features/timetable/widgets/course_hero.dart';
import '../../features/timetable/widgets/timetable_root_shell.dart';
import '../../models/course.dart';

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
GoRoute _ordinaryRoute({
  required String path,
  required Widget Function(BuildContext, GoRouterState) builder,
}) => GoRoute(
  path: path,
  pageBuilder: (context, state) =>
      glassPage(context: context, state: state, child: builder(context, state)),
);

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
      StatefulShellRoute(
        builder: (context, state, shell) =>
            TimetableRootShell(navigationShell: shell),
        navigatorContainerBuilder: (context, shell, children) =>
            RetainedTimetablePages(
              index: shell.currentIndex,
              children: children,
            ),
        branches: [
          StatefulShellBranch(
            preload: true,
            routes: [
              GoRoute(
                path: '/today',
                builder: (context, state) => const TodayPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            preload: true,
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const TimetablePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/today/course/:id',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          opaque: false,
          barrierDismissible: false,
          transitionDuration: MediaQuery.disableAnimationsOf(context)
              ? GlassMotion.reducedHero
              : GlassMotion.standard,
          reverseTransitionDuration: MediaQuery.disableAnimationsOf(context)
              ? GlassMotion.reducedHero
              : GlassMotion.standard,
          child: TodayCoursePreviewPage(
            courseId: state.pathParameters['id']!,
            initialCourse: state.extra is Course
                ? state.extra! as Course
                : null,
          ),
          transitionsBuilder: (context, animation, secondary, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.14),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        ),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => OnboardingPage(
          isAddingSchool: state.uri.queryParameters['add'] == '1',
        ),
      ),
      _ordinaryRoute(
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
      _ordinaryRoute(
        path: '/course/new',
        builder: (context, state) => const CourseEditPage(),
      ),
      _ordinaryRoute(
        path: '/event/new',
        builder: (context, state) => const CourseEditPage(isEvent: true),
      ),
      GoRoute(
        path: '/course/:id',
        pageBuilder: (context, state) {
          final source = state.extra is CourseHeroSourceContext
              ? state.extra! as CourseHeroSourceContext
              : CourseHeroSourceContext.weeklyTimetable;
          final page = CourseDetailPage(
            courseId: state.pathParameters['id']!,
            heroSource: source,
            revealMetadata: state.extra is CourseHeroSourceContext,
          );
          // Dedicated Preview/Hero journeys keep their existing route and
          // timing. Direct detail entry follows the ordinary page language.
          if (state.extra is! CourseHeroSourceContext) {
            return glassPage(context: context, state: state, child: page);
          }
          if (MediaQuery.disableAnimationsOf(context)) {
            return CustomTransitionPage<void>(
              key: state.pageKey,
              child: page,
              transitionDuration: GlassMotion.reducedHero,
              reverseTransitionDuration: GlassMotion.reducedHero,
              transitionsBuilder: (context, animation, secondary, child) =>
                  FadeTransition(opacity: animation, child: child),
            );
          }
          // Keep the platform-adaptive route (including iOS interactive pop).
          return MaterialPage<void>(key: state.pageKey, child: page);
        },
      ),
      _ordinaryRoute(
        path: '/course/:id/edit',
        builder: (context, state) =>
            CourseEditPage(courseId: state.pathParameters['id']!),
      ),
      _ordinaryRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      _ordinaryRoute(
        path: '/settings/schools',
        builder: (context, state) => const SchoolManagePage(),
      ),
      _ordinaryRoute(
        path: '/settings/semester',
        builder: (context, state) => const SemesterSettingsPage(),
      ),
      _ordinaryRoute(
        path: '/settings/bell',
        builder: (context, state) => const BellSettingsPage(),
      ),
      _ordinaryRoute(
        path: '/settings/calendar',
        builder: (context, state) => const CalendarExceptionPage(),
      ),
    ],
  );
});
