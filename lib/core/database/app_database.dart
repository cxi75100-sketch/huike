import 'dart:convert';

import 'package:drift/drift.dart';

import '../../models/bell_schedule.dart';
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
  TextColumn get acceptedHostsJson => text().withDefault(const Constant('[]'))();

  /// 按教室匹配的作息变体（ScheduleVariant 列表 JSON）。
  TextColumn get scheduleVariantsJson => text().withDefault(const Constant('[]'))();
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
    acceptedHosts:
        (jsonDecode(acceptedHostsJson) as List<dynamic>).cast<String>(),
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

BellSchedule bellScheduleFromRows(List<SectionTimeEntry> rows) =>
    BellSchedule(
      sections:
          rows
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

@DriftDatabase(tables: [
  Schools,
  Semesters,
  CourseEntries,
  SectionTimeEntries,
  Settings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        // v2：学校档案新增内置预设 id 与作息变体列；老数据走通用兜底语义不变。
        await migrator.addColumn(schools, schools.presetId);
        await migrator.addColumn(schools, schools.scheduleVariantsJson);
      }
    },
  );

  /// 多校设计下没有任何“应用默认学校/学期/作息”：
  /// 全新安装只保证设置表有主题偏好读取即可，其余全部由用户创建。
  /// 该方法保留为未来 schema 演进的唯一入口，禁止在这里覆盖用户数据。
  Future<void> ensureDefaults() async {}

  Future<String> settingValue(String key, {String fallback = ''}) async {
    final row =
        await (select(settings)..where((t) => t.key.equals(key)))
            .getSingleOrNull();
    return row?.value ?? fallback;
  }

  Future<void> setSetting(String key, String value) async {
    await into(settings).insertOnConflictUpdate(
      SettingsCompanion.insert(key: key, value: value),
    );
  }
}
