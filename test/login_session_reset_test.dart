import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huike_timetable/features/import/services/login_session_reset.dart';

class _Controller extends PlatformInAppWebViewController {
  _Controller(this.events, {this.failStop = false})
    : super.implementation(
        const PlatformInAppWebViewControllerCreationParams(id: 98),
      );
  final List<String> events;
  final bool failStop;
  @override
  Future<void> stopLoading() async {
    events.add('stop');
    if (failStop) throw StateError('synthetic');
  }
}

class _Backend implements LoginResetBackend {
  _Backend(this.events, this.fixture);
  final List<String> events;
  final List<Cookie> fixture;
  final queries = <Uri>[], origins = <Uri>[];
  final deleted = <Cookie>[];
  @override
  Future<List<Cookie>> cookies(Uri url) async {
    events.add('cookies');
    queries.add(url);
    return fixture;
  }

  @override
  Future<bool> deleteCookie(Uri url, Cookie cookie) async {
    events.add('delete');
    deleted.add(cookie);
    if (cookie.isSecure == true) expect(url.scheme, 'https');
    return true;
  }

  @override
  Future<bool> clearStorage(Uri origin) async {
    events.add('storage');
    origins.add(origin);
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('清理先停止、清当前页、撤销旧上下文；精确cookie属性和真实origin', () async {
    final events = <String>[];
    final backend = _Backend(events, [
      Cookie(
        name: 'session',
        domain: 'portal.example.test',
        path: '/auth',
        isHttpOnly: true,
        isSecure: true,
      ),
    ]);
    final service = LoginSessionReset(
      backend: backend,
      preparePage: (_, origins) async {
        events.add('prepare');
        return true;
      },
    );
    final result = await service.reset(
      urls: [
        Uri.parse(
          'http://portal.example.test:8080/auth/login?ticket=SECRET#SECRET',
        ),
      ],
      controller: InAppWebViewController.fromPlatform(
        platform: _Controller(events),
      ),
      revokePage: () async {
        events.add('revoke');
      },
    );
    expect(events.take(3), ['stop', 'prepare', 'revoke']);
    expect(result.complete, isTrue);
    expect(result.cookiesDeleted, 1);
    expect(backend.deleted.single.path, '/auth');
    expect(
      backend.queries.every((url) => url.query.isEmpty && url.fragment.isEmpty),
      isTrue,
    );
    expect(backend.origins.map((url) => url.toString()), [
      'http://portal.example.test:8080',
    ]);
  });
  test('缺Domain/Path和范围之外的共享父域cookie跳过并partial', () async {
    final events = <String>[];
    final backend = _Backend(events, [
      Cookie(name: 'unknown'),
      Cookie(name: 'shared', domain: '.example.test', path: '/'),
      Cookie(name: 'own', domain: 'portal.example.test', path: '/'),
    ]);
    final result =
        await LoginSessionReset(
          backend: backend,
          preparePage: (_, origins) async => true,
        ).reset(
          urls: [Uri.parse('https://portal.example.test/')],
          controller: InAppWebViewController.fromPlatform(
            platform: _Controller(events),
          ),
          revokePage: () async {},
        );
    expect(result.complete, isFalse);
    expect(result.skippedCookies, 2);
    expect(backend.deleted.map((cookie) => cookie.name), ['own']);
  });
  test('旧页面未能stop或撤销时不能删除cookie/storage', () async {
    for (final failStop in [true, false]) {
      final events = <String>[];
      final backend = _Backend(events, []);
      final result =
          await LoginSessionReset(
            backend: backend,
            preparePage: (_, origins) async => true,
          ).reset(
            urls: [Uri.parse('https://portal.example.test/')],
            controller: InAppWebViewController.fromPlatform(
              platform: _Controller(events, failStop: failStop),
            ),
            revokePage: () async {
              throw StateError('synthetic');
            },
          );
      expect(result.complete, isFalse);
      expect(backend.queries, isEmpty);
      expect(backend.origins, isEmpty);
    }
  });
}
