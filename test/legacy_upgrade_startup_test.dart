import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huike_timetable/app.dart';
import 'package:huike_timetable/core/database/app_database.dart';
import 'package:huike_timetable/core/database/database_provider.dart';
import 'package:huike_timetable/features/onboarding/pages/onboarding_page.dart';
import 'package:huike_timetable/features/schools/services/adapter_catalog.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  testWidgets('迁移失败阻断建校；重试重新开库并显示保留的课表', (tester) async {
    final directory = Directory.systemTemp.createTempSync('upgrade-startup-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final source = File('${directory.path}/ncpu_timetable.sqlite');
    final fixture = sqlite.sqlite3.open(source.path);
    fixture.execute('''
      PRAGMA user_version = 2;
      CREATE TABLE semesters(id TEXT, name TEXT, first_week_monday INTEGER,
                             total_weeks INTEGER);
      CREATE TABLE courses(id TEXT);
      CREATE TABLE section_times(section INTEGER, start_time TEXT, end_time TEXT);
      CREATE TABLE settings(key TEXT, value TEXT);
    ''');
    fixture.execute('INSERT INTO semesters VALUES (?, ?, ?, ?)', [
      'semester',
      '合成学期',
      DateTime(2026, 8, 31).millisecondsSinceEpoch ~/ 1000,
      20,
    ]);
    fixture.close();
    var opens = 0;
    final retiredDatabases = <AppDatabase>[];
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWith((ref) {
          opens++;
          final db = AppDatabase(
            NativeDatabase(File('${directory.path}/huike_timetable.sqlite')),
            legacyDatabasePath: () async => source.path,
          );
          // Collect instances rather than starting close() in the fake test
          // zone: Drift's stream teardown must start in runAsync below.
          ref.onDispose(() => retiredDatabases.add(db));
          return db;
        }),
        adapterCatalogProvider.overrideWith(
          (ref) async => const AdapterCatalog(entries: []),
        ),
      ],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await tester.pump();
      await tester.runAsync(() async {
        expect(retiredDatabases, hasLength(opens));
        for (final db in retiredDatabases) {
          await db.close();
        }
        retiredDatabases.clear();
      });
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const HuikeApp()),
    );
    await tester.pumpAndSettle();
    expect(find.text('读取原课表失败'), findsOneWidget);
    expect(find.byType(OnboardingPage), findsNothing);
    expect(tester.takeException(), isNull);

    final repair = sqlite.sqlite3.open(source.path);
    repair.userVersion = 1;
    repair.close();
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(opens, 2);
    expect(find.text('读取原课表失败'), findsNothing);
    expect(find.byType(OnboardingPage), findsNothing);
    final db = container.read(databaseProvider);
    expect((await db.select(db.semesters).get()).single.id, 'semester');
    expect(await db.settingValue('active_school_id'), 'ncpu');
    expect(tester.takeException(), isNull);
  });
}
