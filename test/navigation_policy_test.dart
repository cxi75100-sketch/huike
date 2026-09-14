import 'package:flutter_test/flutter_test.dart';
import 'package:huike_timetable/features/import/services/navigation_policy.dart';

void main() {
  group('NavigationPolicy', () {
    test('白名单内的主机直接放行', () {
      const policy = NavigationPolicy(allowedHosts: ['jw.example.edu.cn']);
      expect(
        policy.decide(Uri.parse('https://jw.example.edu.cn/login')).allowed,
        isTrue,
      );
      expect(
        policy.decide(Uri.parse('http://jw.example.edu.cn/kb')).allowed,
        isTrue,
      );
    });

    test('默认同时允许 http 与 https（明文教务已放开）', () {
      const policy = NavigationPolicy(allowedHosts: ['jw.example.edu.cn']);
      expect(policy.allowedSchemes, containsAll(<String>['http', 'https']));
    });

    test('未确认主机被拦截并给出主机名', () {
      const policy = NavigationPolicy(allowedHosts: ['jw.example.edu.cn']);
      final decision = policy.decide(Uri.parse('https://cas.example.edu.cn/'));
      expect(decision.allowed, isFalse);
      expect(decision.blockedReason, contains('cas.example.edu.cn'));
    });

    test('子域名不算白名单内（精确匹配）', () {
      const policy = NavigationPolicy(allowedHosts: ['example.edu.cn']);
      expect(
        policy.decide(Uri.parse('https://jw.example.edu.cn/')).allowed,
        isFalse,
      );
    });

    test('非 http/https scheme 一律拦截', () {
      const policy = NavigationPolicy(allowedHosts: ['jw.example.edu.cn']);
      for (final url in ['tel:10086', 'intent://x', 'file:///etc/passwd']) {
        final uri = Uri.parse(url);
        final decision = policy.decide(uri);
        expect(policy.allowsScheme(uri), isFalse, reason: url);
        expect(decision.allowed, isFalse, reason: url);
      }
    });

    test('白名单按引用持有：追加主机后原策略立即生效', () {
      final hosts = <String>['jw.example.edu.cn'];
      final policy = NavigationPolicy(allowedHosts: hosts);
      expect(
        policy.decide(Uri.parse('https://cas.example.edu.cn/')).allowed,
        isFalse,
      );
      hosts.add('cas.example.edu.cn');
      expect(
        policy.decide(Uri.parse('https://cas.example.edu.cn/')).allowed,
        isTrue,
      );
    });

    test('白名单以主机为单位：同主机的其它端口与路径仍放行', () {
      // 南工教务是 http://218.204.129.252:8088/jwglxt/... 这种 IP + 端口形态，
      // 档案里存的是主机名，所以端口不参与判定（这是刻意的主机粒度）。
      const policy = NavigationPolicy(allowedHosts: ['218.204.129.252']);
      expect(
        policy
            .decide(
              Uri.parse(
                'http://218.204.129.252:8088/jwglxt/xtgl/login_slogin.html',
              ),
            )
            .allowed,
        isTrue,
      );
      expect(
        policy.decide(Uri.parse('http://218.204.129.253:8088/')).allowed,
        isFalse,
      );
    });
  });
}
