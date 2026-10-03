import 'dart:convert';

import 'package:drift/drift.dart';

import 'legacy_database_import.dart';

import '../../models/bell_schedule.dart';
import '../../models/calendar_exception.dart';
import '../../models/school_profile.dart';
import '../../models/semester.dart';
import '../../models/course.dart';

part 'app_database.g.dart';

/// 一所用户显式创建的学校。
///
/// 多校设计的根：没有内置默认学校，全新安装的数据库里这张表是空的，
/// 首页据此进入引导页。loginUrl 是用户输入并显式确认的地址；
/// acceptedHostsJson 是导航白名单，只随用户确认增长。
class Schools extends Table {
  TextColumn get id => text()();
  TextColumn get displayName => text()();
  TextColumn get adapterId => text().withDefault(const Constant(''))();

  /// 内置学校档案 id（如南工）；空串表示走通用兜底作息。
  TextColumn get presetId => text().withDefault(const Constant(''))();
  TextColumn get loginUrl => text().withDefault(const Constant(''))();
  TextColumn get acceptedHostsJson =>
      text().withDefault(const Constant('[]'))();

  /// 按教室匹配的作息变体（ScheduleVariant 列表 JSON）。
  TextColumn get scheduleVariantsJson =>
      text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 一个学期属于一所学校。跨学期靠新增记录并切换激活学期。
///
/// 生成数据类名为 SemesterRow，避免与模型层 `Semester` 重名。
@DataClassName('SemesterRow')
class Semesters extends Table {
  TextColumn get id => text()();
  TextColumn get schoolId => text()();
  TextColumn get firstWeekMondayIso => text()();
  IntColumn get totalWeeks => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// source 只区分 manual / imported；学校身份在 schoolId。
/// 重新导入只替换 (schoolId, semesterId, imported) 范围。
class CourseEntries extends Table {
  TextColumn get id => text()();
  TextColumn get schoolId => text()();
  TextColumn get semesterId => text()();
  TextColumn get source => textEnum<CourseSource>()();
  TextColumn get name => text()();
  TextColumn get teacher => text().withDefault(const Constant(''))();
  TextColumn get classroom => text().withDefault(const Constant(''))();
  IntColumn get weekday => integer()();
  IntColumn get startSection => integer()();
  IntColumn get endSection => integer()();
  TextColumn get weeksJson => text()();
  TextColumn get startTime => text().nullable()();
  TextColumn get endTime => text().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();
  IntColumn get colorKey => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// 每所学校一套默认作息。只播种一次；用户修改后不再有任何覆盖路径。
class SectionTimeEntries extends Table {
  TextColumn get schoolId => text()();
  IntColumn get sectionIndex => integer()();
  TextColumn get start => text()();
  TextColumn get end => text()();
  TextColumn get periodGroup => textEnum<SectionGroup>()();

  @override
  Set<Column> get primaryKey => {schoolId, sectionIndex};
}

/// 校历例外（调休 / 停课）。挂在学期上：同一天只保留一条。
///
/// 只提供「这一天停课」或「这一天按某星期课表上课」两种语义——
/// 不表达「把某天的课移到另一天」，因为课表以周次 × 星期表达，重复一节课
/// 会同时出现在两个日期，语义反而更差。
/// 生成数据类名为 CalendarExceptionRow，避免与模型层 `CalendarException` 重名。
@DataClassName('CalendarExceptionRow')
class CalendarExceptions extends Table {
  TextColumn get id => text()();
  TextColumn get schoolId => text()();
  TextColumn get semesterId => text()();
  TextColumn get dateIso => text()();
  TextColumn get kind => textEnum<CalendarExceptionKind>()();

  /// makeup 生效：按星期几的课表上课（1=周一 … 7=周日）。
  IntColumn get makeupWeekday => integer().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

extension CourseRowMapping on CourseEntry {
  Course toModel() => Course(
    id: id,
    schoolId: schoolId,
    semesterId: semesterId,
    name: name,
    teacher: teacher,
    classroom: classroom,
    weekday: weekday,
    startSection: startSection,
    endSection: endSection,
    startTime: startTime,
    endTime: endTime,
    weeks: (jsonDecode(weeksJson) as List<dynamic>).cast<int>(),
    colorKey: colorKey,
    note: note,
    source: source,
  );
}

extension SchoolRowMapping on School {
  SchoolProfile toModel() => SchoolProfile(
    id: id,
    displayName: displayName,
    adapterId: adapterId,
    presetId: presetId,
    loginUrl: loginUrl,
    acceptedHosts: (jsonDecode(acceptedHostsJson) as List<dynamic>)
        .cast<String>(),
    scheduleVariants: schoolVariantsFromRow(this),
    createdAt: createdAt,
  );
}

List<ScheduleVariant> schoolVariantsFromRow(School row) =>
    (jsonDecode(row.scheduleVariantsJson) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(ScheduleVariant.fromJson)
        .toList();

extension SemesterRowMapping on SemesterRow {
  Semester toModel() => Semester(
    id: id,
    schoolId: schoolId,
    firstWeekMonday: DateTime.parse(firstWeekMondayIso),
    totalWeeks: totalWeeks,
  );
}

extension CalendarExceptionRowMapping on CalendarExceptionRow {
  CalendarException toModel() => CalendarException(
    id: id,
    schoolId: schoolId,
    semesterId: semesterId,
    date: DateTime.parse(dateIso),
    kind: kind,
    makeupWeekday: makeupWeekday,
    note: note,
  );
}

BellSchedule bellScheduleFromRows(List<SectionTimeEntry> rows) => BellSchedule(
  sections: rows
      .map(
        (row) => SectionSpec(
          index: row.sectionIndex,
          start: row.start,
          end: row.end,
          group: row.periodGroup,
        ),
      )
      .toList(),
);

String encodeWeeks(List<int> weeks) => jsonEncode(weeks);

String encodeHosts(List<String> hosts) => jsonEncode(hosts);

@DriftDatabase(
  tables: [
    Schools,
    Semesters,
    CourseEntries,
    SectionTimeEntries,
    CalendarExceptions,
    Settings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e, {this.legacyDatabasePath});

  /// The awaited open hook runs before any provider can observe the
  /// destination database. Tests may omit the optional source resolver.
  final Future<String?> Function()? legacyDatabasePath;

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (_) async {
      final path = await legacyDatabasePath?.call();
      if (path != null) await importLegacyDatabase(this, path);
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        // v2：学校档案新增内置预设 id 与作息变体列；老数据走通用兜底语义不变。
        await migrator.addColumn(schools, schools.presetId);
        await migrator.addColumn(schools, schools.scheduleVariantsJson);
      }
      if (from < 3) {
        // v3：新增校历例外（调休/停课）。新表对老数据是空表，
        // 语义等于「没有任何例外」，课表显示与升级前完全一致。
        await migrator.createTable(calendarExceptions);
      }
    },
  );

  /// 多校设计下没有任何“应用默认学校/学期/作息”：
  /// 全新安装只保证设置表有主题偏好读取即可，其余全部由用户创建。
  /// 该方法保留为未来 schema 演进的唯一入口，禁止在这里覆盖用户数据。
  Future<void> ensureDefaults() async {}

  Future<String> settingValue(String key, {String fallback = ''}) async {
    final row = await (select(
      settings,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value ?? fallback;
  }

  Future<void> setSetting(String key, String value) async {
    await into(
      settings,
    ).insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));
  }
}
