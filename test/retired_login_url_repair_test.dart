import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huike_timetable/core/database/app_database.dart';
import 'package:huike_timetable/core/database/database_provider.dart';
import 'package:huike_timetable/features/schools/providers/school_providers.dart';
import 'package:huike_timetable/features/schools/services/school_presets.dart';
import 'package:huike_timetable/features/schools/services/school_repository.dart';
import 'package:huike_timetable/models/course.dart';

void main() {
  test(
    'known default roots only; custom hosts/paths/ports remain unchanged',
    () {
      for (final url in [
        'http://jwxt.ncpu.edu.cn',
        'https://JWXT.NCPU.EDU.CN/',
      ]) {
        expect(
          ncpuPreset.replacementForRetiredLoginUrl(url),
          ncpuPreset.defaultLoginUrl,
        );
      }
      for (final url in [
        ncpuPreset.defaultLoginUrl,
        'https://custom.example.edu.cn/',
        'http://jwxt.ncpu.edu.cn:8080/',
        'http://jwxt.ncpu.edu.cn/custom',
        'http://jwxt.ncpu.edu.cn/?custom=1',
        'http://jwxt.ncpu.edu.cn/#custom',
        'http://user@jwxt.ncpu.edu.cn/',
        'http://jwxt.ncpu.edu.cn.evil.example/',
        '',
      ]) {
        expect(
          ncpuPreset.replacementForRetiredLoginUrl(url),
          isNull,
          reason: url,
        );
      }
    },
  );

  test('provider first read repairs persisted legacy URL once, preserving data and hosts', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final repository = SchoolRepository(db);
    final school = await repository.createSchool(
      displayName: ncpuPreset.displayName,
      adapterId: 'auto',
      loginUrl: 'http://jwxt.ncpu.edu.cn/',
      confirmedHosts: ['jwxt.ncpu.edu.cn', 'sso.example.edu.cn'],
    );
    final semester = await repository.createSemester(
      schoolId: school.id,
      firstWeekMonday: DateTime(2026, 8, 31),
      totalWeeks: 20,
    );
    await db
        .into(db.courseEntries)
        .insert(
          CourseEntriesCompanion.insert(
            id: 'synthetic-course',
            schoolId: school.id,
            semesterId: semester.id,
            name: '示例课程',
            weekday: 1,
            startSection: 1,
            endSection: 2,
            weeksJson: '[1,2]',
            source: CourseSource.manual,
          ),
        );
    final before = await db.select(db.schools).getSingle();
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    final subscription = container.listen(schoolsProvider, (_, _) {});
    try {
      final first = await container.read(schoolsProvider.future);
      expect(first.single.loginUrl, ncpuPreset.defaultLoginUrl);
      final after = await db.select(db.schools).getSingle();
      expect(
        after.toJson()..remove('loginUrl'),
        before.toJson()..remove('loginUrl'),
      );
      expect((await db.select(db.courseEntries).get()).single.name, '示例课程');
      expect((await db.select(db.semesters).get()).single.id, semester.id);
      await repository.repairRetiredLoginUrls();
      expect(
        (await db.select(db.schools).getSingle()).toJson(),
        after.toJson(),
      );
      await repository.updateLoginUrl(
        school.id,
        Uri.parse('https://custom.example.edu.cn/'),
      );
      await repository.repairRetiredLoginUrls();
      expect(
        (await db.select(db.schools).getSingle()).loginUrl,
        'https://custom.example.edu.cn/',
      );
    } finally {
      subscription.close();
      container.dispose();
      await Future<void>.delayed(Duration.zero);
      await db.close();
    }
  });

  test(
    'preset identity repairs renamed school but unrelated school is untouched',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repository = SchoolRepository(db);
      try {
        for (final (name, presetId) in [('自定义显示名', 'ncpu'), ('其他学校', '')]) {
          await repository.createSchool(
            displayName: name,
            presetId: presetId,
            adapterId: '',
            loginUrl: 'http://jwxt.ncpu.edu.cn/',
            confirmedHosts: [],
          );
        }
        await repository.repairRetiredLoginUrls();
        final rows = await db.select(db.schools).get();
        expect(rows.first.loginUrl, ncpuPreset.defaultLoginUrl);
        expect(rows.last.loginUrl, 'http://jwxt.ncpu.edu.cn/');
      } finally {
        await db.close();
      }
    },
  );
}
