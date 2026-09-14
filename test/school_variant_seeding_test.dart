import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huike_timetable/core/database/app_database.dart';
import 'package:huike_timetable/core/database/database_provider.dart';
import 'package:huike_timetable/features/schools/services/school_repository.dart';
import 'package:huike_timetable/features/timetable/providers/timetable_providers.dart';
import 'package:huike_timetable/models/bell_schedule.dart';
import 'package:huike_timetable/services/course_time_service.dart';
import 'package:huike_timetable/models/course.dart';

/// 锁定「按教学楼的作息变体」从建校到显示时间的整条链路。
///
/// 用户 2026-09-14 反馈：导入回来的「九龙湖校区明志楼223」第 3-4 节显示 10:25，
/// 而档案里明志楼应为 10:15。这里用真实教室文本复现该路径。
void main() {
  late AppDatabase db;
  late SchoolRepository schools;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    schools = SchoolRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<BellSchedule> bellOf(String schoolId) async {
    final rows =
        await (db.select(db.sectionTimeEntries)
              ..where((t) => t.schoolId.equals(schoolId)))
            .get();
    final row =
        await (db.select(db.schools)..where((t) => t.id.equals(schoolId)))
            .getSingle();
    return BellSchedule(
      sections: bellScheduleFromRows(rows).sections,
      variants: schoolVariantsFromRow(row),
    );
  }

  test('按档案建校时写入按教室变体，明志楼盘在九龙湖校区下仍命中', () async {
    final school = await schools.createSchool(
      displayName: '南昌工学院',
      adapterId: 'auto',
      loginUrl: 'http://218.204.129.252:8088/jwglxt/xtgl/login_slogin.html',
      confirmedHosts: const ['218.204.129.252'],
      presetId: 'ncpu',
    );

    // 建校返回值与数据库读回都必须带变体（重启后走的是读回路径）。
    expect(school.scheduleVariants, hasLength(1));
    final bell = await bellOf(school.id);
    expect(bell.variants, hasLength(1));

    const service = CourseTimeService();
    Course course(String classroom) => Course(
      id: 'c',
      schoolId: school.id,
      semesterId: 'sem',
      name: '工程力学',
      weekday: 1,
      startSection: 3,
      endSection: 4,
      weeks: const [1],
      classroom: classroom,
    );

    // 教务回传的教室文本带校区前缀，变体仍要命中。
    expect(service.resolve(course('九龙湖校区明志楼223'), bell), (
      '10:15',
      '11:45',
    ));
    // 未列入变体的教学楼走基础作息。
    expect(service.resolve(course('九龙湖校区致远楼B406'), bell), (
      '10:25',
      '11:55',
    ));
  });

  test('无档案的学校不写入变体，全部走基础作息', () async {
    final school = await schools.createSchool(
      displayName: '某大学',
      adapterId: '',
      loginUrl: '',
      confirmedHosts: const [],
    );
    expect(school.scheduleVariants, isEmpty);
    final bell = await bellOf(school.id);
    expect(bell.variants, isEmpty);
    // 通用兜底第 3、4 节是 10:00-11:40，与南工档案不同，便于分辨走的是哪套作息。
    expect(bell.resolveRange(3, 4, classroom: '明志楼223'), ('10:00', '11:40'));
  });

  test('数据修复：老学校（变体列为空）按 presetId 补写档案变体', () async {
    // 模拟 v2 之前建的学校：迁移只加了列，值是默认的 '[]'。
    await db.into(db.schools).insert(
      SchoolsCompanion.insert(
        id: 'legacy-ncpu',
        displayName: '南昌工学院',
        adapterId: const Value('auto'),
        presetId: const Value('ncpu'),
        loginUrl: const Value(''),
        acceptedHostsJson: const Value('[]'),
        scheduleVariantsJson: const Value('[]'),
        createdAt: DateTime(2026, 9, 13),
      ),
    );

    expect((await bellOf('legacy-ncpu')).variants, isEmpty);
    await schools.repairPresetVariants();
    final bell = await bellOf('legacy-ncpu');

    expect(bell.variants, hasLength(1));
    const service = CourseTimeService();
    expect(
      service.resolve(
        Course(
          id: 'c',
          schoolId: 'legacy-ncpu',
          semesterId: 'sem',
          name: '工程力学',
          weekday: 1,
          startSection: 3,
          endSection: 4,
          weeks: const [1],
          classroom: '九龙湖校区明志楼223',
        ),
        bell,
      ),
      ('10:15', '11:45'),
    );
  });

  test('数据修复：presetId 为空但校名与档案一致时也补齐', () async {
    await db.into(db.schools).insert(
      SchoolsCompanion.insert(
        id: 'legacy-by-name',
        displayName: '南昌工学院',
        adapterId: const Value(''),
        presetId: const Value(''),
        loginUrl: const Value(''),
        acceptedHostsJson: const Value('[]'),
        scheduleVariantsJson: const Value('[]'),
        createdAt: DateTime(2026, 9, 13),
      ),
    );
    await schools.repairPresetVariants();
    expect((await bellOf('legacy-by-name')).variants, hasLength(1));
  });

  test('数据修复：不动没有档案的学校，也不覆盖已有变体', () async {
    await db.into(db.schools).insert(
      SchoolsCompanion.insert(
        id: 'other-school',
        displayName: '某大学',
        adapterId: const Value(''),
        presetId: const Value(''),
        loginUrl: const Value(''),
        acceptedHostsJson: const Value('[]'),
        scheduleVariantsJson: const Value('[]'),
        createdAt: DateTime(2026, 9, 13),
      ),
    );
    await db.into(db.schools).insert(
      SchoolsCompanion.insert(
        id: 'custom-variant',
        displayName: '南昌工学院',
        adapterId: const Value(''),
        presetId: const Value('ncpu'),
        loginUrl: const Value(''),
        acceptedHostsJson: const Value('[]'),
        // 用户自己维护过的变体（关键词不同），不能被档案覆盖。
        scheduleVariantsJson: const Value(
          '[{"id":"mine","keywords":["实验楼"],'
          '"overrides":{"3":["09:00","09:40"]}}]',
        ),
        createdAt: DateTime(2026, 9, 13),
      ),
    );

    await schools.repairPresetVariants();

    expect((await bellOf('other-school')).variants, isEmpty);
    final kept = await bellOf('custom-variant');
    expect(kept.variants, hasLength(1));
    expect(kept.variants.single.id, 'mine');
  });

  test('档案变体已存在时不重复写入（建校只播种一次）', () async {
    final school = await schools.createSchool(
      displayName: '南昌工学院',
      adapterId: 'auto',
      loginUrl: '',
      confirmedHosts: const [],
      presetId: 'ncpu',
    );
    final first = await (db.select(db.schools)
          ..where((t) => t.id.equals(school.id)))
        .getSingle();
    await schools.setActiveSchool(school.id);
    final again = await (db.select(db.schools)
          ..where((t) => t.id.equals(school.id)))
        .getSingle();
    expect(again.scheduleVariantsJson, first.scheduleVariantsJson);
  });

  test('接线：修复后的学校档案经 provider 组装后，作息带变体且解析出 10:15', () async {
    // 先用档案正常建校（会播种作息与变体），再把变体列清空，模拟 v2 之前的老学校。
    final school = await schools.createSchool(
      displayName: '南昌工学院',
      adapterId: 'auto',
      loginUrl: '',
      confirmedHosts: const [],
      presetId: 'ncpu',
    );
    await (db.update(db.schools)..where((t) => t.id.equals(school.id))).write(
      const SchoolsCompanion(scheduleVariantsJson: Value('[]')),
    );
    await schools.setActiveSchool(school.id);
    expect((await bellOf(school.id)).variants, isEmpty);

    // App 外壳启动时跑的就是这个（见 lib/app.dart）。
    await schools.repairPresetVariants();

    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    try {
      // 变体要经「作息流 + 学校档案」两条异步流汇合才出现在 bell 上。
      // 这些 provider 是 autoDispose：必须挂一个常驻订阅，否则每轮读取都会
      // 重建整条链、流永远来不及发出首帧。
      final sub = container.listen(
        bellForActiveSchoolProvider,
        (_, _) {},
        fireImmediately: true,
      );
      BellSchedule? bell;
      for (var i = 0; i < 100; i++) {
        bell = sub.read();
        if (bell != null && bell.variants.isNotEmpty) break;
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      sub.close();
      expect(bell, isNotNull);
      expect(bell!.variants, hasLength(1));
      expect(
        const CourseTimeService().resolve(
          Course(
            id: 'c',
            schoolId: school.id,
            semesterId: 'sem',
            name: '工程力学',
            weekday: 1,
            startSection: 3,
            endSection: 4,
            weeks: const [1],
            classroom: '九龙湖校区明志楼223',
          ),
          bell,
        ),
        ('10:15', '11:45'),
      );
    } finally {
      // 必须在 db.close() 之前释放，否则流 provider 会在已关闭的库上抛错。
      container.dispose();
    }
  });
}
