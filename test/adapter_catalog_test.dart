import 'package:flutter_test/flutter_test.dart';
import 'package:huike_timetable/features/schools/services/adapter_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('内置目录包含四个通用教务适配器', () async {
    final catalog = await AdapterCatalog.load();
    expect(catalog.schemaVersion, 2);
    expect(catalog.entries, hasLength(4));
    expect(catalog.entries.map((e) => e.kind), everyElement('jsScript'));
    expect(catalog.byId('zhengfang_html_generic'), isNotNull);
    expect(catalog.byId('qingguo_html_generic'), isNotNull);
    expect(catalog.byId('urp_generic'), isNotNull);
    expect(catalog.byId('chaoxing_generic'), isNotNull);
    expect(catalog.schoolProfiles, isEmpty);
    expect(catalog.entries.map((e) => e.familyId), [
      'zhengfang',
      'qingguo',
      'urp',
      'chaoxing',
    ]);
    expect(
      catalog.entries.every((entry) => entry.supportsAttemptToken),
      isTrue,
    );
  });

  test('目录声明的脚本资产全部真实存在', () async {
    final catalog = await AdapterCatalog.load();
    for (final entry in catalog.entries) {
      final script = await catalog.scriptFor(entry);
      expect(script, isNotEmpty, reason: '${entry.asset} 不应为空');
      // 每个脚本都必须通过社区契约桥与宿主通信。
      expect(
        script,
        contains('shiguangBridge'),
        reason: '${entry.asset} 应使用桥契约',
      );
    }
  });

  test('schema 1 目录仍能读取，缺少 family 时用既有 adapter ID', () {
    final catalog = AdapterCatalog.fromJson({
      'schemaVersion': 1,
      'adapters': [
        {'id': 'legacy-family', 'asset': 'legacy.js'},
      ],
    });
    expect(catalog.entries.single.familyId, 'legacy-family');
    expect(catalog.schoolProfiles, isEmpty);
    expect(catalog.entries.single.supportsAttemptToken, isFalse);
  });

  test('schema 2 解析学校 profile、URL 规则、variant 与字段别名', () {
    final catalog = AdapterCatalog.fromJson({
      'schemaVersion': 2,
      'adapters': [
        {
          'id': 'fixture-adapter',
          'family': 'fixture-family',
          'asset': 'fixture.js',
        },
      ],
      'schoolProfiles': [
        {
          'id': 'fixture-profile',
          'name': 'Fixture School',
          'aliases': ['FSU'],
          'adapterId': 'fixture-adapter',
          'variant': 'fixture-layout',
          'urlRules': [
            {'host': 'portal.example.test', 'pathPrefix': '/student'},
          ],
          'options': {
            'courseFieldAliases': {'name': 'courseTitle'},
          },
        },
      ],
    });
    final profile = catalog.schoolProfiles.single;
    expect(profile.matchesSchoolName('fsu'), isTrue);
    expect(
      profile.matchesUrl(Uri.parse('https://portal.example.test/student/kb')),
      isTrue,
    );
    expect(profile.variant, 'fixture-layout');
    expect(profile.courseFieldAliases, {'name': 'courseTitle'});
  });
}
