import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
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
          await tester.pumpWidget(app(true));
          expect(find.text('课程'), findsOneWidget);
          await tester.tap(find.text('课程'));
          expect(taps, 1);
          final opacity = tester.widget<Opacity>(find.byType(Opacity).last);
          expect(opacity.opacity, reduced ? 1 : 0.92);
          await tester.pump(const Duration(milliseconds: 180));
          expect(tester.widget<Opacity>(find.byType(Opacity).last).opacity, 1);
          // Readiness updates (or resume/rebuild) cannot replay launch.
          await tester.pumpWidget(app(false));
          await tester.pumpWidget(app(true));
          expect(tester.widget<Opacity>(find.byType(Opacity).last).opacity, 1);
        },
      );
    }
  }

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
      expect(find.text('欢迎使用汇课'), findsOneWidget);
    },
  );
}
