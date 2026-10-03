import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:huike_timetable/core/glass/glass_button.dart';
import 'package:huike_timetable/features/import/pages/import_web_page.dart';
import 'package:huike_timetable/features/schools/providers/school_providers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('实际导入页遇旧Cookie的401自动清理并重新打开登录页', (tester) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final url = 'http://127.0.0.1:${server.port}/login';
    var rejected = 0, ready = 0;
    server.listen((request) async {
      await request.drain<void>();
      final stale = request.cookies.any(
        (cookie) => cookie.name == 'huike_recovery_fixture',
      );
      request.response.headers.contentType = ContentType.html;
      if (stale) {
        rejected++;
        request.response.statusCode = 401;
        request.response.write(
          '<html><body>Expired synthetic session</body></html>',
        );
      } else {
        ready++;
        request.response.write(
          '<html><body>Fresh synthetic login page</body></html>',
        );
      }
      await request.response.close();
    });
    final cookies = CookieManager.instance();
    expect(
      await cookies.setCookie(
        url: WebUri(url),
        name: 'huike_recovery_fixture',
        value: 'synthetic',
        path: '/',
        domain: '127.0.0.1',
        isHttpOnly: true,
        maxAge: 3600,
      ),
      isTrue,
    );
    final container = ProviderContainer(
      overrides: [activeSchoolProvider.overrideWith((ref) => null)],
    );
    try {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: ImportWebPage(host: '127.0.0.1', initialUrl: url),
          ),
        ),
      );
      bool importReady() {
        final finder = find.widgetWithText(GlassButton, '执行导入');
        return finder.evaluate().isNotEmpty &&
            tester.widget<GlassButton>(finder).onPressed != null;
      }

      for (var i = 0; i < 200 && (ready == 0 || !importReady()); i++) {
        await tester.pump(const Duration(milliseconds: 100));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      // Chromium may retry an HTTP authentication challenge before cancellation.
      expect(rejected, greaterThanOrEqualTo(1));
      expect(ready, greaterThanOrEqualTo(1));
      expect(importReady(), isTrue);
      expect(
        tester.widget<InAppWebView>(find.byType(InAppWebView)).key,
        const ValueKey('login-webview-1'),
      );
      expect(
        (await cookies.getCookies(url: WebUri(url)))
            .any((cookie) => cookie.name == 'huike_recovery_fixture'),
        isFalse,
      );
      expect(find.text('取消'), findsNothing);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      container.dispose();
      await cookies.deleteCookie(
        url: WebUri(url),
        name: 'huike_recovery_fixture',
        domain: '127.0.0.1',
      );
      await server.close(force: true);
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
