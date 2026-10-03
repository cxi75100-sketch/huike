import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../../features/schools/services/school_presets.dart';
import '../../models/bell_schedule.dart';
import '../../models/course.dart';
import 'app_database.dart';

const legacyImportMarker = 'legacy_ncpu_import_v1';

/// One-way compatibility import. The source is opened read-only, never renamed
/// or removed. Errors propagate so startup cannot show an empty, usable app
/// after a partial import; the transaction rolls back and a later open retries.
Future<void> importLegacyDatabase(AppDatabase target, String path) async {
  if (!File(path).existsSync()) return;
  await target.transaction(() async {
    if (await target.settingValue(legacyImportMarker) == 'complete') return;
    if (await (target.select(target.schools)..limit(1)).getSingleOrNull() !=
        null) {
      return;
    }
    final source = sqlite.sqlite3.open(path, mode: sqlite.OpenMode.readOnly);
    try {
      if (source.userVersion != 1) {
        throw const FormatException('Unsupported legacy database schema');
      }
      // A read transaction keeps all tables at the same source snapshot.
      source.execute('BEGIN');
      final semesters = source.select(
        'SELECT id, name, first_week_monday, total_weeks FROM semesters '
        'ORDER BY first_week_monday DESC, id',
      );
      final courses = source.select('SELECT * FROM courses');
      final sections = source.select(
        'SELECT section, start_time, end_time FROM section_times ORDER BY section',
      );
      final theme = source.select(
        "SELECT value FROM settings WHERE key = 'theme_mode'",
      );
      if (semesters.isEmpty) {
        throw const FormatException('Legacy database has no semesters');
      }
      final semesterIds = semesters.map((row) => row['id'] as String).toSet();
      final preset = ncpuPreset;
      await target
          .into(target.schools)
          .insert(
            SchoolsCompanion.insert(
              id: preset.id,
              displayName: preset.displayName,
              adapterId: const Value('auto'),
              presetId: Value(preset.id),
              loginUrl: Value(preset.defaultLoginUrl),
              acceptedHostsJson: Value(
                jsonEncode([Uri.parse(preset.defaultLoginUrl).host]),
              ),
              scheduleVariantsJson: Value(
                jsonEncode([
                  for (final variant in preset.bell.variants) variant.toJson(),
                ]),
              ),
              createdAt: DateTime.now(),
            ),
          );
      for (final row in semesters) {
        // Drift's default SQLite dateTime storage is Unix seconds, not ms.
        final monday = DateTime.fromMillisecondsSinceEpoch(
          (row['first_week_monday'] as int) * 1000,
        );
        await target
            .into(target.semesters)
            .insert(
              SemestersCompanion.insert(
                id: row['id'] as String,
                schoolId: preset.id,
                firstWeekMondayIso: monday.toIso8601String(),
                totalWeeks: row['total_weeks'] as int,
              ),
            );
        // The current UI has no semester-name column. Retain the explicit
        // legacy metadata so a user's custom name is not discarded.
        await target.setSetting(
          'legacy_semester_name:${row['id'] as String}',
          row['name'] as String,
        );
      }
      for (final row in courses) {
        final semesterId = row['semester_id'] as String;
        if (!semesterIds.contains(semesterId)) {
          throw const FormatException('Legacy course has no matching semester');
        }
        final sourceName = row['source'] as String;
        final courseSource = switch (sourceName) {
          'manual' => CourseSource.manual,
          'ncpu' => CourseSource.imported,
          _ => throw const FormatException('Unsupported legacy course source'),
        };
        final weeks = (jsonDecode(row['weeks_json'] as String) as List)
            .cast<int>();
        await target
            .into(target.courseEntries)
            .insert(
              CourseEntriesCompanion.insert(
                id: row['id'] as String,
                schoolId: preset.id,
                semesterId: semesterId,
                source: courseSource,
                name: row['name'] as String,
                teacher: Value(row['teacher'] as String),
                classroom: Value(row['classroom'] as String),
                weekday: row['weekday'] as int,
                startSection: row['start_section'] as int,
                endSection: row['end_section'] as int,
                weeksJson: jsonEncode(weeks),
                startTime: Value(row['start_time'] as String?),
                endTime: Value(row['end_time'] as String?),
                note: Value(row['note'] as String),
                colorKey: Value(row['color_key'] as int),
              ),
            );
      }
      for (final row in sections) {
        final index = row['section'] as int;
        await target
            .into(target.sectionTimeEntries)
            .insert(
              SectionTimeEntriesCompanion.insert(
                schoolId: preset.id,
                sectionIndex: index,
                start: row['start_time'] as String,
                end: row['end_time'] as String,
                periodGroup: index <= 4
                    ? SectionGroup.morning
                    : index <= 8
                    ? SectionGroup.afternoon
                    : SectionGroup.evening,
              ),
            );
      }
      if (theme.isNotEmpty &&
          const ['system', 'light', 'dark'].contains(theme.first['value']) &&
          await target.settingValue('theme_mode') == '') {
        await target.setSetting('theme_mode', theme.first['value'] as String);
      }
      // The old app selected the latest first-week Monday, without a stored
      // active-semester setting. Preserve that rule explicitly in the new app.
      await target.setSetting('active_school_id', preset.id);
      await target.setSetting(
        'active_semester:${preset.id}',
        semesters.first['id'] as String,
      );
      await target.setSetting(legacyImportMarker, 'complete');
      source.execute('ROLLBACK');
    } finally {
      source.close();
    }
  });
}
