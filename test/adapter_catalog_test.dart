import 'package:flutter_test/flutter_test.dart';
import 'package:huike_timetable/features/schools/services/adapter_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('内置目录包含四个通用教务适配器', () async {
    final catalog = await AdapterCatalog.load();
    expect(catalog.entries, hasLength(4));
    expect(
      catalog.entries.map((e) => e.kind),
      everyElement('jsScript'),
    );
    expect(catalog.byId('zhengfang_html_generic'), isNotNull);
    expect(catalog.byId('qingguo_html_generic'), isNotNull);
    expect(catalog.byId('urp_generic'), isNotNull);
    expect(catalog.byId('chaoxing_generic'), isNotNull);
  });

  test('目录声明的脚本资产全部真实存在', () async {
    final catalog = await AdapterCatalog.load();
    for (final entry in catalog.entries) {
      final script = await catalog.scriptFor(entry);
      expect(script, isNotEmpty, reason: '${entry.asset} 不应为空');
      // 每个脚本都必须通过社区契约桥与宿主通信。
      expect(script, contains('shiguangBridge'),
          reason: '${entry.asset} 应使用桥契约');
    }
  });
}
