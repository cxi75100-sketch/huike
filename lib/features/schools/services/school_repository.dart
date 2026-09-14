import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../models/bell_schedule.dart';
import '../../../models/school_profile.dart';
import '../../../models/semester.dart';
import 'school_presets.dart';

/// 学校与学期的写路径。所有播种都只在缺失时发生，
/// 不存在“用内置值覆盖用户修改”的路径。
class SchoolRepository {
  SchoolRepository(this._db);

  final AppDatabase _db;

  Future<SchoolProfile> createSchool({
    required String displayName,
    required String adapterId,
    required String loginUrl,
    required List<String> confirmedHosts,
    String presetId = '',
  }) async {
    final id = 'school-${DateTime.now().microsecondsSinceEpoch}';
    final preset = presetById(presetId);
    final variants = preset?.bell.variants ?? const <ScheduleVariant>[];
    await _db
        .into(_db.schools)
        .insert(
          SchoolsCompanion.insert(
            id: id,
            displayName: displayName,
            adapterId: Value(adapterId),
            presetId: Value(preset?.id ?? ''),
            loginUrl: Value(loginUrl),
            acceptedHostsJson: Value(jsonEncode(confirmedHosts)),
            scheduleVariantsJson: Value(jsonEncode(
              [for (final v in variants) v.toJson()],
            )),
            createdAt: DateTime.now(),
          ),
        );
    // 有内置档案的学校直接播种官方作息；否则通用兜底。只播种一次。
    await _seedSectionTimes(id, preset?.bell ?? BellSchedule.fallback());
    return SchoolProfile(
      id: id,
      displayName: displayName,
      adapterId: adapterId,
      presetId: preset?.id ?? '',
      loginUrl: loginUrl,
      acceptedHosts: confirmedHosts,
      scheduleVariants: variants,
      createdAt: DateTime.now(),
    );
  }

  Future<void> setActiveSchool(String schoolId) =>
      _db.setSetting('active_school_id', schoolId);

  /// 用户确认新主机后追加白名单；只增不减，需要收紧时由用户重建学校。
  Future<void> appendConfirmedHost(String schoolId, String host) async {
    final row =
        await (_db.select(
          _db.schools,
        )..where((t) => t.id.equals(schoolId))).getSingleOrNull();
    if (row == null) return;
    final hosts = (jsonDecode(row.acceptedHostsJson) as List<dynamic>)
        .cast<String>();
    if (!hosts.contains(host)) {
      hosts.add(host);
      await (_db.update(
        _db.schools,
      )..where((t) => t.id.equals(schoolId))).write(
        SchoolsCompanion(acceptedHostsJson: Value(jsonEncode(hosts))),
      );
    }
  }

  /// 数据修复：给「有内置档案但变体列为空」的学校补写按教室作息变体（ISSUE-014）。
  ///
  /// v2 之前的学校 `scheduleVariantsJson` 是迁移默认的 `'[]'`，而变体只在建校那一次
  /// 播种，于是这些学校永远拿不到档案里的变体（表现：明志楼第 3、4 节没提前 10 分钟）。
  /// 只填空值、幂等；已有变体或没有档案的学校不动。`presetId` 为空时按校名精确匹配档案。
  Future<void> repairPresetVariants() async {
    final rows = await _db.select(_db.schools).get();
    for (final row in rows) {
      if (schoolVariantsFromRow(row).isNotEmpty) continue;
      final preset = row.presetId.isNotEmpty
          ? presetById(row.presetId)
          : presetByDisplayName(row.displayName);
      if (preset == null || preset.bell.variants.isEmpty) continue;
      await (_db.update(
        _db.schools,
      )..where((t) => t.id.equals(row.id))).write(
        SchoolsCompanion(
          scheduleVariantsJson: Value(
            jsonEncode([
              for (final variant in preset.bell.variants) variant.toJson(),
            ]),
          ),
        ),
      );
    }
  }

  /// 更新教务登录地址（http/https 均可）并把新主机并入白名单。
  Future<void> updateLoginUrl(String schoolId, Uri uri) async {
    await appendConfirmedHost(schoolId, uri.host);
    await (_db.update(
      _db.schools,
    )..where((t) => t.id.equals(schoolId))).write(
      SchoolsCompanion(loginUrl: Value(uri.toString())),
    );
  }

  Future<Semester> createSemester({
    required String schoolId,
    required DateTime firstWeekMonday,
    required int totalWeeks,
  }) async {
    final id = 'semester-${DateTime.now().microsecondsSinceEpoch}';
    await _db
        .into(_db.semesters)
        .insert(
          SemestersCompanion.insert(
            id: id,
            schoolId: schoolId,
            firstWeekMondayIso: _isoDate(firstWeekMonday),
            totalWeeks: totalWeeks,
          ),
        );
    await setActiveSemester(schoolId, id);
    return Semester(
      id: id,
      schoolId: schoolId,
      firstWeekMonday: DateTime(
        firstWeekMonday.year,
        firstWeekMonday.month,
        firstWeekMonday.day,
      ),
      totalWeeks: totalWeeks,
    );
  }

  Future<void> setActiveSemester(String schoolId, String semesterId) =>
      _db.setSetting('active_semester:$schoolId', semesterId);

  Future<void> updateSemester(
    String semesterId, {
    DateTime? firstWeekMonday,
    int? totalWeeks,
  }) async {
    await (_db.update(
      _db.semesters,
    )..where((t) => t.id.equals(semesterId))).write(
      SemestersCompanion(
        firstWeekMondayIso: firstWeekMonday == null
            ? const Value.absent()
            : Value(_isoDate(firstWeekMonday)),
        totalWeeks: totalWeeks == null
            ? const Value.absent()
            : Value(totalWeeks),
      ),
    );
  }

  Future<void> updateSectionTime(
    String schoolId,
    int sectionIndex, {
    required String start,
    required String end,
  }) async {
    await (_db.update(_db.sectionTimeEntries)
          ..where(
            (t) =>
                t.schoolId.equals(schoolId) &
                t.sectionIndex.equals(sectionIndex),
          ))
        .write(SectionTimeEntriesCompanion(start: Value(start), end: Value(end)));
  }

  /// 把作息恢复为该校的默认值（内置档案学校回到官方作息，其他走通用兜底）；
  /// 这是用户显式操作，不是启动行为。
  Future<void> resetSectionTimes(String schoolId) async {
    final row =
        await (_db.select(
          _db.schools,
        )..where((t) => t.id.equals(schoolId))).getSingleOrNull();
    final preset = presetById(row?.presetId ?? '');
    await (_db.delete(
      _db.sectionTimeEntries,
    )..where((t) => t.schoolId.equals(schoolId))).go();
    await _seedSectionTimes(schoolId, preset?.bell ?? BellSchedule.fallback());
  }

  Future<void> _seedSectionTimes(String schoolId, BellSchedule schedule) async {
    final existing =
        await (_db.select(
          _db.sectionTimeEntries,
        )..where((t) => t.schoolId.equals(schoolId))).get();
    if (existing.isNotEmpty) return; // 只播种，不覆盖。
    for (final spec in schedule.sections) {
      await _db
          .into(_db.sectionTimeEntries)
          .insert(
            SectionTimeEntriesCompanion.insert(
              schoolId: schoolId,
              sectionIndex: spec.index,
              start: spec.start,
              end: spec.end,
              periodGroup: spec.group,
            ),
          );
    }
  }

  Future<void> deleteSchool(String schoolId) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.courseEntries,
      )..where((t) => t.schoolId.equals(schoolId))).go();
      await (_db.delete(
        _db.sectionTimeEntries,
      )..where((t) => t.schoolId.equals(schoolId))).go();
      await (_db.delete(
        _db.calendarExceptions,
      )..where((t) => t.schoolId.equals(schoolId))).go();
      await (_db.delete(
        _db.semesters,
      )..where((t) => t.schoolId.equals(schoolId))).go();
      await (_db.delete(_db.schools)..where((t) => t.id.equals(schoolId))).go();
      await (_db.delete(
        _db.settings,
      )..where((t) => t.key.equals('active_semester:$schoolId'))).go();
    });
    final activeId = await _db.settingValue('active_school_id');
    if (activeId == schoolId) {
      await (_db.delete(
        _db.settings,
      )..where((t) => t.key.equals('active_school_id'))).go();
    }
  }

  String _isoDate(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }
}

final schoolRepositoryProvider = Provider<SchoolRepository>(
  (ref) => SchoolRepository(ref.watch(databaseProvider)),
);

/// 启动时跑一次的数据修复：补齐老学校缺失的档案变体（ISSUE-014）。
///
/// 不放进 Drift 迁移，是因为 `core/database` 不应反向依赖 `features/schools`
/// 的档案数据（分层约束）；这里由 App 外壳 watch 一次触发，方法本身幂等。
final presetVariantRepairProvider = FutureProvider<void>(
  (ref) => ref.watch(schoolRepositoryProvider).repairPresetVariants(),
);
