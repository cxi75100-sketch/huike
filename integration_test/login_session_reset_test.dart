import 'dart:async';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:huike_timetable/features/import/services/login_session_reset.dart';

Future<({HeadlessInAppWebView view, InAppWebViewController controller})> _page(
  String url,
) async {
  final loaded = Completer<InAppWebViewController>();
  final view = HeadlessInAppWebView(
    initialData: InAppWebViewInitialData(
      data: '<html><body>Synthetic</body></html>',
      baseUrl: WebUri(url),
    ),
    onLoadStop: (controller, _) {
      if (!loaded.isCompleted) loaded.complete(controller);
    },
  );
  await view.run();
  return (
    view: view,
    controller: await loaded.future.timeout(const Duration(seconds: 15)),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('精确重新登录保留另一host Cookie/localStorage，处理HttpOnly Secure和Path', (
    tester,
  ) async {
    const selected = 'https://127.0.0.1:19071/auth/login';
    const other = 'https://localhost:19071/auth/login';
    final cookies = CookieManager.instance();
    // Synthetic state only; there is no server, credential or real site.
    await cookies.setCookie(
      url: WebUri(selected),
      name: 'fixture_http_only',
      value: 'synthetic',
      path: '/auth',
      isHttpOnly: true,
    );
    await cookies.setCookie(
      url: WebUri(selected),
      name: 'fixture_secure',
      value: 'synthetic',
      path: '/auth',
      isSecure: true,
      isHttpOnly: true,
    );
    await cookies.setCookie(
      url: WebUri(selected),
      name: 'fixture_domain',
      value: 'synthetic',
      domain: '127.0.0.1',
      path: '/',
    );
    await cookies.setCookie(
      url: WebUri(other),
      name: 'fixture_other',
      value: 'synthetic',
      path: '/auth',
      isHttpOnly: true,
    );
    await cookies.setCookie(
      url: WebUri(selected),
      name: '__Secure-fixture',
      value: 'synthetic',
      path: '/auth',
      isSecure: true,
      isHttpOnly: true,
    );
    await cookies.setCookie(
      url: WebUri(selected),
      name: '__Host-fixture',
      value: 'synthetic',
      path: '/',
      isSecure: true,
      isHttpOnly: true,
    );
    final current = await _page(selected);
    final secondary = await _page(other);
    await secondary.controller.evaluateJavascript(
      source: "localStorage.setItem('fixture','other');",
    );
    // Simulate a current document outside the trusted visited-origin scope.
    // Its localStorage must survive; only the explicitly selected origin changes.
    final outside = await LoginSessionReset().reset(
      urls: [Uri.parse('https://127.0.0.2:19071/auth/login')],
      controller: secondary.controller,
      revokePage: () => secondary.view.dispose(),
    );
    expect(outside.complete, isFalse);
    await current.controller.evaluateJavascript(
      source: "localStorage.setItem('fixture','selected');sessionStorage.setItem('fixture','selected');",
    );
    final before = await cookies.getCookies(url: WebUri(selected));
    expect(
      before.map((cookie) => cookie.name),
      containsAll([
        'fixture_http_only',
        'fixture_secure',
        'fixture_domain',
        '__Secure-fixture',
        '__Host-fixture',
      ]),
    );
    expect(
      before.every((cookie) => cookie.domain != null && cookie.path != null),
      isTrue,
    );
    for (final prefix in ['__Secure-fixture', '__Host-fixture']) {
      expect(
        before.firstWhere((cookie) => cookie.name == prefix).isSecure,
        isTrue,
        reason: 'Secure metadata',
      );
    }
    final result = await LoginSessionReset().reset(
      urls: [Uri.parse(selected)],
      controller: current.controller,
      revokePage: () => current.view.dispose(),
    );
    expect(
      result.failedOperations,
      0,
      reason:
          'deleted=${result.cookiesDeleted}; skipped=${result.skippedCookies}',
    );
    expect(result.complete, isTrue);
    final after = await cookies.getCookies(url: WebUri(selected));
    expect(
      after
          .map((cookie) => cookie.name)
          .where(
            (name) => name.startsWith('fixture_') || name.endsWith('-fixture'),
          ),
      isEmpty,
    );
    final otherCookies = await cookies.getCookies(url: WebUri(other));
    expect(
      otherCookies.map((cookie) => cookie.name),
      contains('fixture_other'),
    );
    final selectedCheck = await _page(selected);
    expect(
      await selectedCheck.controller.evaluateJavascript(
        source: "localStorage.getItem('fixture')",
      ),
      isNull,
    );
    expect(
      await selectedCheck.controller.evaluateJavascript(
        source: "sessionStorage.getItem('fixture')",
      ),
      isNull,
    );
    await selectedCheck.view.dispose();
    final otherCheck = await _page(other);
    expect(
      await otherCheck.controller.evaluateJavascript(
        source: "localStorage.getItem('fixture')",
      ),
      'other',
    );
    // Exact cleanup of synthetic fixture state; never bulk-delete the store.
    await otherCheck.controller.evaluateJavascript(
      source: "localStorage.removeItem('fixture');",
    );
    await otherCheck.view.dispose();
    for (final cookie in otherCookies.where(
      (cookie) => cookie.name == 'fixture_other',
    )) {
      await cookies.deleteCookie(
        url: WebUri(other),
        name: cookie.name,
        domain: cookie.domain,
        path: cookie.path!,
      );
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}
