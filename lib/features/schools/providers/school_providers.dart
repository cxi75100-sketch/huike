import 'package:drift/drift.dart' hide Column;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../models/bell_schedule.dart';
import '../../../models/school_profile.dart';
import '../../../models/semester.dart';

const _activeSchoolKey = 'active_school_id';

String activeSemesterKey(String schoolId) => 'active_semester:$schoolId';

/// 读取单个设置键的实时流；键不存在时发 null。
final settingValueProvider = StreamProvider.family
    .autoDispose<String?, String>((ref, key) {
      final db = ref.watch(databaseProvider);
      final query = db.select(db.settings)..where((t) => t.key.equals(key));
      return query.watchSingleOrNull().map((row) => row?.value);
    });

final schoolsProvider = StreamProvider<List<SchoolProfile>>((ref) {
  final db = ref.watch(databaseProvider);
  final query = db.select(db.schools)
    ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
  return query.watch().map(
    (rows) => rows.map((row) => row.toModel()).toList(),
  );
});

final activeSchoolIdProvider = StreamProvider<String?>((ref) {
  final db = ref.watch(databaseProvider);
  final query = db.select(db.settings)
    ..where((t) => t.key.equals(_activeSchoolKey));
  return query.watchSingleOrNull().map((row) => row?.value);
});

/// 当前激活的学校；一台设备同一时间只服务一所学校。
/// 没有任何学校或未选择时为 null，首页据此进入引导。
final activeSchoolProvider = Provider<SchoolProfile?>((ref) {
  final schools = ref.watch(schoolsProvider).value ?? const [];
  final activeId = ref.watch(activeSchoolIdProvider).value;
  if (activeId == null) return null;
  for (final school in schools) {
    if (school.id == activeId) return school;
  }
  return null;
});

final semestersForSchoolProvider = StreamProvider.family
    .autoDispose<List<Semester>, String>((ref, schoolId) {
      final db = ref.watch(databaseProvider);
      final query = db.select(db.semesters)
        ..where((t) => t.schoolId.equals(schoolId))
        ..orderBy([(t) => OrderingTerm.desc(t.firstWeekMondayIso)]);
      return query.watch().map((rows) => rows.map((r) => r.toModel()).toList());
    });

/// 一所学校的激活学期：无记录时回退到“最近开始”的那一个。
final activeSemesterProvider = Provider.family<Semester?, String>((
  ref,
  schoolId,
) {
  final semesters = ref.watch(semestersForSchoolProvider(schoolId)).value;
  if (semesters == null || semesters.isEmpty) return null;
  final stored = ref
      .watch(settingValueProvider(activeSemesterKey(schoolId)))
      .value;
  for (final semester in semesters) {
    if (semester.id == stored) return semester;
  }
  return semesters.first;
});

final sectionTimesProvider = StreamProvider.family
    .autoDispose<BellSchedule, String>((ref, schoolId) {
      final db = ref.watch(databaseProvider);
      final query = db.select(db.sectionTimeEntries)
        ..where((t) => t.schoolId.equals(schoolId))
        ..orderBy([(t) => OrderingTerm.asc(t.sectionIndex)]);
      return query.watch().map(bellScheduleFromRows);
    });

/// 一所学校的完整作息：节次表 + 按教室匹配的作息变体。
/// 需要解析课程显示时间的一律用这个，不要用 [sectionTimesProvider]。
final schoolBellProvider = Provider.family.autoDispose<BellSchedule, String>((
  ref,
  schoolId,
) {
  final base = ref.watch(sectionTimesProvider(schoolId)).value;
  if (base == null) return BellSchedule.fallback();
  final schools = ref.watch(schoolsProvider).value ?? const [];
  for (final school in schools) {
    if (school.id == schoolId) {
      return BellSchedule(sections: base.sections, variants: school.scheduleVariants);
    }
  }
  return base;
});
