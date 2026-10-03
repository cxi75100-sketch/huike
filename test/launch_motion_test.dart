import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huike_timetable/app.dart';
import 'package:huike_timetable/core/database/app_database.dart';
import 'package:huike_timetable/core/database/database_provider.dart';
import 'package:huike_timetable/core/widgets/launch_reveal.dart';
import 'package:huike_timetable/core/theme/theme_preference.dart';
import 'package:huike_timetable/core/theme/theme_preference_provider.dart';
import 'package:huike_timetable/features/schools/providers/school_providers.dart';

void main() {
  testWidgets('saved theme resolves without a default theme tween', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.setSetting(
      'theme_mode',
      themePreferenceToString(ThemePreference.dark),
    );
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const HuikeApp()),
    );
    await tester.runAsync(() => container.read(themePreferenceProvider.future));
    await tester.pump();
    expect(
      tester
          .widget<MaterialApp>(find.byType(MaterialApp))
          .themeAnimationDuration,
      Duration.zero,
    );
    final reveal = tester.element(find.byType(LaunchReveal));
    expect(Theme.of(reveal).brightness, Brightness.dark);
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(LaunchReveal))).brightness,
      Brightness.dark,
    );
  });
  for (final dark in [false, true]) {
    for (final reduced in [false, true]) {
      testWidgets(
        'launch interactive immediately dark=$dark reduced=$reduced',
        (tester) async {
          var taps = 0;
          Widget app(bool ready) => MaterialApp(
            theme: ThemeData(
              brightness: dark ? Brightness.dark : Brightness.light,
            ),
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduced),
              child: LaunchReveal(
                ready: ready,
                child: Center(
                  child: TextButton(
                    onPressed: () => taps++,
                    child: const Text('课程'),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpWidget(app(false));
          expect(find.text('课程'), findsNothing);
          expect(find.byType(FlutterLogo), findsOneWidget);
          final fill = find.descendant(
            of: find.byKey(const ValueKey('launch-brand-overlay')),
            matching: find.byType(ColoredBox),
          );
          expect(
            tester.widget<ColoredBox>(fill).color,
            const Color(0xFFF5F6F9),
          );
          await tester.pumpWidget(app(true));
          expect(find.text('课程'), findsOneWidget);
          if (reduced) {
            expect(
              find.byKey(const ValueKey('launch-brand-overlay')),
              findsNothing,
            );
          } else {
            expect(
              find.byKey(const ValueKey('launch-brand-overlay')),
              findsOneWidget,
            );
          }
          await tester.tap(find.text('课程'));
          await tester.pump();
          expect(taps, 1);
          expect(
            find.byKey(const ValueKey('launch-brand-overlay')),
            findsNothing,
          );
          // Startup content stays opaque even while it translates into place.
          expect(
            find.ancestor(of: find.text('课程'), matching: find.byType(Opacity)),
            findsNothing,
          );
          await tester.pump(const Duration(milliseconds: 180));
          expect(find.text('课程'), findsOneWidget);
          // Readiness updates (or resume/rebuild) cannot replay launch.
          await tester.pumpWidget(app(false));
          await tester.pumpWidget(app(true));
          expect(find.text('课程'), findsOneWidget);
        },
      );
    }
  }

  testWidgets('品牌退场自然完成且重建不重播', (tester) async {
    Widget app(bool ready) => MaterialApp(
      home: LaunchReveal(ready: ready, child: const Text('首页')),
    );
    await tester.pumpWidget(app(false));
    await tester.pumpWidget(app(true));
    await tester.pump(const Duration(milliseconds: 100));
    final overlay = tester.widget<Opacity>(
      find.byKey(const ValueKey('launch-brand-overlay')),
    );
    expect(overlay.opacity, inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('launch-brand-overlay')), findsNothing);
    await tester.pumpWidget(app(false));
    await tester.pumpWidget(app(true));
    expect(find.byKey(const ValueKey('launch-brand-overlay')), findsNothing);
    expect(find.text('首页'), findsOneWidget);
  });

  testWidgets('浅色品牌层接管深色AppBar系统栏，淡出后段切换图标', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: LaunchReveal(
          ready: true,
          child: Scaffold(appBar: AppBar(title: const Text('首页'))),
        ),
      ),
    );
    final styleFinder = find.byKey(const ValueKey('launch-system-style'));
    expect(
      tester
          .widget<AnnotatedRegion<SystemUiOverlayStyle>>(styleFinder)
          .value
          .statusBarIconBrightness,
      Brightness.dark,
    );
    await tester.pump(const Duration(milliseconds: 170));
    expect(
      tester
          .widget<AnnotatedRegion<SystemUiOverlayStyle>>(styleFinder)
          .value
          .statusBarIconBrightness,
      Brightness.light,
    );
    await tester.pumpAndSettle();
    expect(styleFinder, findsNothing);
  });

  testWidgets(
    'unresolved school never paints onboarding as a loading default',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final schoolId = StreamController<String?>();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          activeSchoolIdProvider.overrideWith((ref) => schoolId.stream),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await schoolId.close();
        await db.close();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const HuikeApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('欢迎使用汇课'), findsNothing);
      schoolId.add(null);
      await tester.pumpAndSettle();
      expect(find.text('你的课表，从这里开始'), findsOneWidget);
    },
  );
}
