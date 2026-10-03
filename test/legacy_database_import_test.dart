import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'package:huike_timetable/core/database/app_database.dart';
import 'package:huike_timetable/core/database/legacy_database_import.dart';
import 'package:huike_timetable/models/bell_schedule.dart';
import 'package:huike_timetable/models/course.dart';

void main() {
  late Directory directory;
  late File legacy;
  late File destination;
  final monday = DateTime(2026, 8, 31);

  setUp(() {
    directory = Directory.systemTemp.createTempSync('legacy-import-test-');
    legacy = File('${directory.path}/ncpu_timetable.sqlite');
    destination = File('${directory.path}/huike_timetable.sqlite');
    final fixture = sqlite.sqlite3.open(legacy.path);
    fixture.execute('''
      PRAGMA user_version = 1;
      CREATE TABLE semesters (
        id TEXT PRIMARY KEY, name TEXT NOT NULL,
        first_week_monday INTEGER NOT NULL, total_weeks INTEGER NOT NULL
      );
      CREATE TABLE courses (
        id TEXT PRIMARY KEY, name TEXT NOT NULL, teacher TEXT NOT NULL,
        classroom TEXT NOT NULL, weekday INTEGER NOT NULL,
        start_section INTEGER NOT NULL, end_section INTEGER NOT NULL,
        start_time TEXT, end_time TEXT, weeks_json TEXT NOT NULL,
        semester_id TEXT NOT NULL, color_key INTEGER NOT NULL,
        note TEXT NOT NULL, source TEXT NOT NULL
      );
      CREATE TABLE section_times (
        section INTEGER PRIMARY KEY, start_time TEXT NOT NULL,
        end_time TEXT NOT NULL
      );
      CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL);
    ''');
    fixture.execute('INSERT INTO semesters VALUES (?, ?, ?, ?)', [
      'older',
      '合成历史学期',
      DateTime(2026, 2, 23).millisecondsSinceEpoch ~/ 1000,
      18,
    ]);
    fixture.execute('INSERT INTO semesters VALUES (?, ?, ?, ?)', [
      'newer',
      '合成当前学期',
      monday.millisecondsSinceEpoch ~/ 1000,
      20,
    ]);
    fixture.execute(
      'INSERT INTO courses VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        'manual-id',
        '合成手工课程',
        '合成教师',
        '合成教室',
        3,
        5,
        6,
        '14:01',
        '15:31',
        '[1,3,5,7]',
        'older',
        13,
        '合成备注',
        'manual',
      ],
    );
    fixture.execute(
      'INSERT INTO courses VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        'imported-id',
        '合成导入课程',
        '',
        '',
        7,
        9,
        10,
        null,
        null,
        '[2,4]',
        'newer',
        4,
        '',
        'ncpu',
      ],
    );
    fixture.execute('''
      INSERT INTO section_times VALUES (1, '07:51', '08:33');
      INSERT INTO section_times VALUES (5, '13:51', '14:33');
      INSERT INTO section_times VALUES (10, '20:01', '20:43');
      INSERT INTO settings VALUES ('theme_mode', 'dark');
      INSERT INTO settings VALUES ('unknown_private_key', 'must-not-copy');
    ''');
    fixture.close();
  });

  tearDown(() => directory.deleteSync(recursive: true));

  AppDatabase open({bool compatibility = true}) => AppDatabase(
    NativeDatabase(destination),
    legacyDatabasePath: compatibility ? () async => legacy.path : null,
  );

  test(
    'first query sees complete migration, all course fields and custom times',
    () async {
      final original = legacy.readAsBytesSync();
      final db = open();
      addTearDown(db.close);
      final schools = await db.select(db.schools).get();
      expect(schools.single.id, 'ncpu');
      expect(schools.single.presetId, 'ncpu');
      expect(schools.single.adapterId, 'auto');
      expect(schools.single.displayName, '南昌工学院');
      expect(schools.single.toModel().acceptedHosts, ['218.204.129.252']);
      expect(schools.single.toModel().scheduleVariants, isNotEmpty);
      final terms = await db.select(db.semesters).get();
      expect(terms, hasLength(2));
      final term = terms.singleWhere((row) => row.id == 'newer').toModel();
      expect(term.firstWeekMonday, monday);
      expect(term.totalWeeks, 20);
      expect(term.schoolId, 'ncpu');
      final old = terms.singleWhere((row) => row.id == 'older').toModel();
      expect(old.firstWeekMonday, DateTime(2026, 2, 23));
      expect(old.totalWeeks, 18);
      final courses = await db.select(db.courseEntries).get();
      expect(courses, hasLength(2));
      final manual = courses
          .singleWhere((row) => row.id == 'manual-id')
          .toModel();
      expect(manual.name, '合成手工课程');
      expect(manual.teacher, '合成教师');
      expect(manual.classroom, '合成教室');
      expect(manual.weekday, 3);
      expect(manual.startSection, 5);
      expect(manual.endSection, 6);
      expect(manual.startTime, '14:01');
      expect(manual.endTime, '15:31');
      expect(manual.weeks, [1, 3, 5, 7]);
      expect(manual.semesterId, 'older');
      expect(manual.schoolId, 'ncpu');
      expect(manual.colorKey, 13);
      expect(manual.note, '合成备注');
      expect(manual.source, CourseSource.manual);
      final imported = courses.singleWhere((row) => row.id == 'imported-id');
      expect(imported.source, CourseSource.imported);
      expect(imported.startTime, isNull);
      expect(imported.endTime, isNull);
      final sections = await (db.select(
        db.sectionTimeEntries,
      )..orderBy([(t) => OrderingTerm.asc(t.sectionIndex)])).get();
      expect(sections.map((row) => row.start), ['07:51', '13:51', '20:01']);
      expect(sections.map((row) => row.end), ['08:33', '14:33', '20:43']);
      expect(sections.map((row) => row.periodGroup), [
        SectionGroup.morning,
        SectionGroup.afternoon,
        SectionGroup.evening,
      ]);
      expect(await db.settingValue('theme_mode'), 'dark');
      expect(await db.settingValue('legacy_semester_name:older'), '合成历史学期');
      expect(await db.settingValue('legacy_semester_name:newer'), '合成当前学期');
      expect(await db.settingValue('active_school_id'), 'ncpu');
      expect(await db.settingValue('active_semester:ncpu'), 'newer');
      expect(await db.settingValue('unknown_private_key'), '');
      expect(await db.settingValue(legacyImportMarker), 'complete');
      expect(legacy.readAsBytesSync(), orderedEquals(original));
    },
  );

  test(
    'completed migration is idempotent and deleted data is not resurrected',
    () async {
      final db = open();
      await db.select(db.schools).get();
      await db.delete(db.courseEntries).go();
      await db.delete(db.schools).go();
      await db.close();
      final reopened = open();
      addTearDown(reopened.close);
      expect(await reopened.select(reopened.schools).get(), isEmpty);
      expect(await reopened.select(reopened.courseEntries).get(), isEmpty);
      expect(await reopened.settingValue(legacyImportMarker), 'complete');
    },
  );

  test(
    'existing destination school and settings are never overwritten',
    () async {
      final db = open(compatibility: false);
      await db
          .into(db.schools)
          .insert(
            SchoolsCompanion.insert(
              id: 'existing',
              displayName: '已有学校',
              createdAt: DateTime(2025),
            ),
          );
      await db.setSetting('active_school_id', 'existing');
      await db.setSetting('theme_mode', 'light');
      await db.close();
      final reopened = open();
      addTearDown(reopened.close);
      expect(
        (await reopened.select(reopened.schools).get()).single.id,
        'existing',
      );
      expect(await reopened.settingValue('theme_mode'), 'light');
      expect(await reopened.settingValue('active_school_id'), 'existing');
      expect(await reopened.settingValue(legacyImportMarker), '');
    },
  );

  test('error rolls back all writes and later startup can retry', () async {
    final fixture = sqlite.sqlite3.open(legacy.path);
    fixture.execute(
      "UPDATE courses SET source = 'unknown' WHERE id = 'imported-id'",
    );
    fixture.close();
    final original = legacy.readAsBytesSync();
    final failed = open();
    await expectLater(
      failed.select(failed.schools).get(),
      throwsFormatException,
    );
    await failed.close();
    expect(legacy.readAsBytesSync(), orderedEquals(original));
    final inspect = open(compatibility: false);
    expect(await inspect.select(inspect.schools).get(), isEmpty);
    expect(await inspect.select(inspect.semesters).get(), isEmpty);
    expect(await inspect.select(inspect.courseEntries).get(), isEmpty);
    expect(await inspect.settingValue(legacyImportMarker), '');
    await inspect.close();
    final repairedFixture = sqlite.sqlite3.open(legacy.path);
    repairedFixture.execute(
      "UPDATE courses SET source = 'ncpu' WHERE id = 'imported-id'",
    );
    repairedFixture.close();
    final retry = open();
    addTearDown(retry.close);
    expect(await retry.select(retry.courseEntries).get(), hasLength(2));
    expect(await retry.settingValue(legacyImportMarker), 'complete');
  });

  test(
    'absent source keeps new installation empty without creating legacy file',
    () async {
      legacy.deleteSync();
      final db = open();
      addTearDown(db.close);
      expect(await db.select(db.schools).get(), isEmpty);
      expect(await db.settingValue(legacyImportMarker), '');
      expect(legacy.existsSync(), isFalse);
    },
  );

  test(
    'unsupported schema is rejected without touching source or target',
    () async {
      final fixture = sqlite.sqlite3.open(legacy.path);
      fixture.userVersion = 2;
      fixture.close();
      final original = legacy.readAsBytesSync();
      final db = open();
      await expectLater(db.select(db.schools).get(), throwsFormatException);
      await db.close();
      expect(legacy.readAsBytesSync(), orderedEquals(original));
      final inspect = open(compatibility: false);
      addTearDown(inspect.close);
      expect(await inspect.select(inspect.schools).get(), isEmpty);
      expect(await inspect.settingValue(legacyImportMarker), '');
    },
  );

  test('orphan courses prevent incomplete migration', () async {
    final fixture = sqlite.sqlite3.open(legacy.path);
    fixture.execute(
      "UPDATE courses SET semester_id = 'missing' WHERE id = 'imported-id'",
    );
    fixture.close();
    final db = open();
    await expectLater(db.select(db.schools).get(), throwsFormatException);
    await db.close();
    final inspect = open(compatibility: false);
    addTearDown(inspect.close);
    expect(await inspect.select(inspect.schools).get(), isEmpty);
    expect(await inspect.select(inspect.semesters).get(), isEmpty);
    expect(await inspect.select(inspect.courseEntries).get(), isEmpty);
  });

  test('ordinary app never imports an existing legacy database', () async {
    final db = open(compatibility: false);
    addTearDown(db.close);
    expect(await db.select(db.schools).get(), isEmpty);
  });
}
