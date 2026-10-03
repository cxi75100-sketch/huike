import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huike_timetable/features/import/models/adapter_batch.dart';
import 'package:huike_timetable/features/import/services/adapter_probe.dart';
import 'package:huike_timetable/features/import/services/import_session.dart';
import 'package:huike_timetable/features/schools/services/adapter_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AdapterCatalog catalog;
  const normalizer = AdapterBatchNormalizer();
  const planner = AdapterProbePlanner();

  setUpAll(() async {
    catalog = await AdapterCatalog.load();
  });

  test('动态页面有限等待4秒且失去页面归属后不再读取', () async {
    var reads = 0;
    var waitTotal = Duration.zero;
    Future<void> wait(Duration gap) async {
      waitTotal += gap;
    }

    await const AdapterPageReader().read(
      evaluate: (_) async {
        reads++;
        return {};
      },
      isCurrent: () => true,
      wait: wait,
    );
    expect(reads, 9);
    expect(waitTotal, const Duration(seconds: 4));
    reads = 0;
    var current = true;
    final stale = await const AdapterPageReader().read(
      evaluate: (_) async {
        reads++;
        current = false;
        return {
          'matches': {'urp': true},
        };
      },
      isCurrent: () => current,
      wait: wait,
    );
    expect(reads, 1);
    expect(stale.families, isEmpty);
  });

  test('动态课表出现后立刻结束检测，不继续轮询', () async {
    var reads = 0;
    final result = await const AdapterPageReader().read(
      evaluate: (_) async {
        reads++;
        return reads == 3
            ? {
                'matches': {'urp': true},
              }
            : {};
      },
      isCurrent: () => true,
      wait: (_) async {},
    );
    expect(reads, 3);
    expect(result.families, {'urp'});
  });

  test('frame路径仅保留已匹配协议和有限非负整数索引', () {
    final features = AdapterPageFeatures.fromJson({
      'matches': {'urp': true},
      'framePaths': {
        'urp': [0, 2],
        'zhengfang': [1],
        'bad': 'SECRET',
      },
      'inaccessibleFramePresent': true,
      'pageText': 'SECRET',
    });
    expect(features.framePaths, {
      'urp': [0, 2],
    });
    expect(features.inaccessibleFramePresent, isTrue);
    expect(
      AdapterPageFeatures.fromJson({
        'matches': {'urp': true},
        'framePaths': {
          'urp': [-1],
        },
      }).framePaths,
      isEmpty,
    );
  });

  test('四类脱敏页面/bridge fixture 排到对应 adapter 且规范化为课程模型', () {
    for (final family in ['zhengfang', 'qingguo', 'urp', 'chaoxing']) {
      final fixture = _fixture(family);
      final features = AdapterPageFeatures.fromJson(fixture['features']);
      final candidates = planner.plan(catalog: catalog, pageFeatures: features);
      expect(candidates.first.familyId, family);
      expect(candidates.first.basis, AdapterSelectionBasis.pageFeature);

      final batch = normalizer.normalize(
        rawCourses: fixture['courses'] as List<dynamic>,
      );
      expect(batch.courses, hasLength(1), reason: family);
      expect(batch.invalidCount, 0, reason: family);
      expect(batch.courses.single.name, startsWith('Fixture '));
    }
  });

  test('错误页面不误匹配且未知学校仍保留四个兼容候选', () {
    final candidates = planner.plan(
      catalog: catalog,
      pageFeatures: const AdapterPageFeatures(),
      schoolName: '未收录测试学校',
      currentUrl: Uri.parse('https://unknown.example.test/login'),
    );
    expect(candidates, hasLength(4));
    expect(
      candidates.map((candidate) => candidate.basis),
      everyElement(AdapterSelectionBasis.compatibilityFallback),
    );

    final sequence = AdapterCandidateSequence(candidates);
    final failed = sequence.takeNext()!;
    expect(failed.adapterId, 'zhengfang_html_generic');
    // 执行层记录当前失败后继续取候选；不会因一次失败停止未知学校回退。
    expect(sequence.takeNext()!.adapterId, 'qingguo_html_generic');
  });

  test('学校已保存的适配器优先于页面猜测，同时继续保留其它候选', () {
    final candidates = planner.plan(
      catalog: catalog,
      preferredAdapterId: 'urp_generic',
      pageFeatures: const AdapterPageFeatures(families: {'qingguo'}),
    );
    expect(candidates.first.adapterId, 'urp_generic');
    expect(candidates.first.basis, AdapterSelectionBasis.schoolPreference);
    expect(
      candidates.map((candidate) => candidate.adapterId).toSet(),
      hasLength(4),
    );
  });

  test('学校别名与精确 URL profile 优先于页面探测，host 不接受通配', () {
    final zf = catalog.byId('zhengfang_html_generic')!;
    final profile = AdapterSchoolProfile(
      id: 'fixture-school-profile',
      name: 'Fixture School',
      aliases: const ['FSU'],
      adapterId: zf.id,
      variant: 'fixture-layout',
      urlRules: const [
        AdapterUrlRule(host: 'portal.example.test', pathPrefix: '/student'),
      ],
      options: const {
        'courseFieldAliases': {'name': 'courseTitle'},
      },
    );
    final configured = AdapterCatalog(
      entries: catalog.entries,
      schoolProfiles: [profile],
    );
    final nameMatch = planner.plan(
      catalog: configured,
      schoolName: 'fsu',
      pageFeatures: const AdapterPageFeatures(families: {'urp'}),
    );
    expect(nameMatch.first.adapterId, zf.id);
    expect(nameMatch.first.basis, AdapterSelectionBasis.schoolProfile);
    expect(nameMatch.first.variant, 'fixture-layout');

    final urlMatch = planner.plan(
      catalog: configured,
      currentUrl: Uri.parse(
        'https://portal.example.test/student/schedule?ticket=x',
      ),
      pageFeatures: const AdapterPageFeatures(families: {'urp'}),
    );
    expect(urlMatch.first.adapterId, zf.id);
    expect(urlMatch.first.basis, AdapterSelectionBasis.knownUrl);
    expect(
      planner
          .plan(
            catalog: configured,
            currentUrl: Uri.parse(
              'https://sub.portal.example.test/student/schedule',
            ),
            pageFeatures: const AdapterPageFeatures(),
          )
          .first
          .basis,
      AdapterSelectionBasis.compatibilityFallback,
    );
  });

  test('同一协议两套字段选项复用规范化器并得到统一模型', () {
    final entry = catalog.byId('zhengfang_html_generic')!;
    final profiles = [
      AdapterSchoolProfile(
        id: 'fixture-a',
        name: 'Fixture A',
        aliases: const [],
        adapterId: entry.id,
        urlRules: const [],
        options: const {
          'courseFieldAliases': {
            'name': 'courseTitle',
            'day': 'weekdayIndex',
            'startSection': 'sectionStart',
            'weeks': 'weekList',
          },
        },
      ),
      AdapterSchoolProfile(
        id: 'fixture-b',
        name: 'Fixture B',
        aliases: const [],
        adapterId: entry.id,
        urlRules: const [],
        options: const {
          'courseFieldAliases': {
            'name': 'titleText',
            'day': 'dayOfWeek',
            'startSection': 'fromSection',
            'weeks': 'weekNumbers',
          },
        },
      ),
    ];
    final configured = AdapterCatalog(
      entries: [entry],
      schoolProfiles: profiles,
    );
    final candidateA = planner
        .plan(
          catalog: configured,
          schoolName: 'Fixture A',
          pageFeatures: const AdapterPageFeatures(),
        )
        .first;
    final candidateB = planner
        .plan(
          catalog: configured,
          schoolName: 'Fixture B',
          pageFeatures: const AdapterPageFeatures(),
        )
        .first;
    expect(candidateA.adapterId, candidateB.adapterId);
    expect(candidateA.options, isNot(candidateB.options));

    final batchA = normalizer.normalize(
      rawCourses: [
        {
          'courseTitle': 'Shared Family Course',
          'weekdayIndex': 2,
          'sectionStart': 3,
          'weekList': [1, 3],
        },
      ],
      courseFieldAliases: candidateA.fieldAliases,
    );
    final batchB = normalizer.normalize(
      rawCourses: [
        {
          'titleText': 'Shared Family Course',
          'dayOfWeek': 2,
          'fromSection': 3,
          'weekNumbers': [1, 3],
        },
      ],
      courseFieldAliases: candidateB.fieldAliases,
    );
    expect(batchA.courses.single.name, batchB.courses.single.name);
    expect(batchA.courses.single.weekday, batchB.courses.single.weekday);
    expect(
      batchA.courses.single.startSection,
      batchB.courses.single.startSection,
    );
    expect(candidateA.contextBootstrap('attempt-a'), contains('courseTitle'));
    expect(candidateB.contextBootstrap('attempt-b'), contains('titleText'));
  });

  test('旧尝试的迟到 bridge 回调不能污染当前 adapter 批次', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(importSessionProvider.notifier);
    notifier.beginAttempt(
      attemptId: 'attempt-current',
      adapterId: 'zhengfang_html_generic',
      familyId: 'zhengfang',
      tokenRequired: true,
    );

    expect(
      notifier.stageCourses(
        '[{"name":"stale","day":1,"startSection":1,"weeks":[1]}]',
        attemptId: 'attempt-expired',
      ),
      isFalse,
    );
    expect(container.read(importSessionProvider).rawCourses, isNull);
    expect(
      notifier.stageCourses(
        '[{"name":"current","day":1,"startSection":1,"weeks":[1]}]',
        attemptId: 'attempt-current',
      ),
      isTrue,
    );
    expect(
      container.read(importSessionProvider).normalized!.courses.single.name,
      'current',
    );
  });
}

Map<String, dynamic> _fixture(String family) =>
    jsonDecode(File('test/fixtures/adapters/$family.json').readAsStringSync())
        as Map<String, dynamic>;
