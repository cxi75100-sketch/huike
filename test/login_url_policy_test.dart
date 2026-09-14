import 'package:flutter_test/flutter_test.dart';
import 'package:huike_timetable/features/schools/services/login_url_policy.dart';

void main() {
  group('checkLoginUrl', () {
    test('空输入：非必填算通过且无地址', () {
      final check = checkLoginUrl('   ');
      expect(check.ok, isTrue);
      expect(check.uri, isNull);
    });

    test('空输入：必填时报错', () {
      final check = checkLoginUrl('', required: true);
      expect(check.ok, isFalse);
      expect(check.error, isNotNull);
    });

    test('https 通过且不标明文', () {
      final check = checkLoginUrl('https://jw.example.edu.cn/login');
      expect(check.ok, isTrue);
      expect(check.uri!.host, 'jw.example.edu.cn');
      expect(check.isCleartext, isFalse);
    });

    test('http 通过且标为明文（学校管理页与引导页同一判定）', () {
      final check = checkLoginUrl('http://jwxt.ncpu.edu.cn');
      expect(check.ok, isTrue);
      expect(check.uri!.host, 'jwxt.ncpu.edu.cn');
      expect(check.isCleartext, isTrue);
    });

    test('前后空白被裁剪', () {
      final check = checkLoginUrl('  https://jw.example.edu.cn  ');
      expect(check.ok, isTrue);
      expect(check.uri!.host, 'jw.example.edu.cn');
    });

    test('缺 scheme 报格式错误', () {
      final check = checkLoginUrl('jw.example.edu.cn');
      expect(check.ok, isFalse);
    });

    test('非 http/https scheme 被拒', () {
      for (final raw in ['ftp://jw.example.edu.cn', 'file:///tmp/a.html']) {
        final check = checkLoginUrl(raw);
        expect(check.ok, isFalse, reason: raw);
      }
    });

    test('有 scheme 但无主机被拒', () {
      final check = checkLoginUrl('https://');
      expect(check.ok, isFalse);
    });
  });
}
