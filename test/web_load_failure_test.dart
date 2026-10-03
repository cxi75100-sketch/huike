import 'package:flutter_test/flutter_test.dart';
import 'package:huike_timetable/features/import/services/import_web_settings.dart';
import 'package:huike_timetable/features/import/services/navigation_policy.dart';
import 'package:huike_timetable/features/import/services/web_load_failure.dart';

void main() {
  test('各类内网地址提供校园网络提示，普通地址不臆断内网', () {
    for (final host in [
      '10.8.3.4',
      '172.16.1.2',
      '172.31.255.1',
      '192.168.7.2',
      '169.254.2.3',
      '127.0.0.1',
      '::1',
      'fd00::2',
      'fe80::1',
    ]) {
      expect(WebLoadFailure.isPrivateNetworkHost(host), isTrue, reason: host);
    }
    for (final host in [
      '172.15.1.2',
      '172.32.1.2',
      '192.169.1.2',
      '8.8.8.8',
      'jw.example.edu.cn',
      '2001:db8::1',
    ]) {
      expect(WebLoadFailure.isPrivateNetworkHost(host), isFalse, reason: host);
    }
  });
  test('提示不含原始地址、query或错误文字', () {
    final message = WebLoadFailure.connection(
      Uri.parse('http://10.2.3.4:7777/login?ticket=SECRET'),
    ).message;
    expect(message, contains('内网'));
    expect(message, isNot(contains('SECRET')));
    expect(message, isNot(contains('10.2.3.4')));
    expect(WebLoadFailure.http(403).message, contains('拒绝'));
    expect(WebLoadFailure.http(503).message, contains('暂未'));
  });
  test('平台快照复用现有导航策略并支持新增确认host', () {
    final hosts = ['jw.example.edu.cn'];
    final settings = ImportWebSettings(NavigationPolicy(allowedHosts: hosts));
    final initial = settings.toMap();
    hosts.add('cas.example.edu.cn');
    expect((initial['huikeNavigationPolicy'] as Map)['hosts'], [
      'jw.example.edu.cn',
    ]);
    expect((settings.toMap()['huikeNavigationPolicy'] as Map)['hosts'], hosts);
    expect(initial['useShouldOverrideUrlLoading'], isTrue);
    expect(initial['disableDefaultErrorPage'], isFalse);
  });
}
