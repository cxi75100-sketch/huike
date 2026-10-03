import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' hide Cookie;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:huike_timetable/features/import/services/adapter_bridge.dart';
import 'package:huike_timetable/features/import/services/adapter_probe.dart';
import 'package:huike_timetable/features/import/services/adapter_runtime.dart';
import 'package:huike_timetable/features/import/services/import_web_settings.dart';
import 'package:huike_timetable/features/import/services/navigation_policy.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android WebView: POST redirects, cookie, dynamic same-origin frame and cancellation',
    (tester) async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final base = 'http://127.0.0.1:${server.port}';
      final foreign = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      foreign.listen((request) async {
        await request.drain<void>();
        request.response.headers.contentType = ContentType.html;
        request.response.write(
          '<html><body>Synthetic foreign frame</body></html>',
        );
        await request.response.close();
      });
      addTearDown(() => foreign.close(force: true));
      final requests = <String>[];
      var cookieSeen = false;
      server.listen((request) async {
        requests.add('${request.method} ${request.uri.path}');
        await request.drain<void>();
        if (request.uri.path == '/post302' || request.uri.path == '/post307') {
          request.response.statusCode = request.uri.path == '/post302'
              ? 302
              : 307;
          request.response.headers.set(
            'location',
            request.uri.path == '/post302' ? '/landing' : '/received',
          );
          request.response.cookies.add(Cookie('fixture', 'present'));
        } else if (request.uri.path == '/slow') {
          request.response.headers.contentType = ContentType.text;
          request.response.write('synthetic-start');
          await request.response.flush();
          await Future<void>.delayed(const Duration(seconds: 2));
          request.response.write('synthetic');
        } else if (request.uri.path == '/dynamic.js') {
          request.response.headers.contentType = ContentType(
            'text',
            'javascript',
            charset: 'utf-8',
          );
          request.response.add(
            utf8.encode(
              '''setTimeout(function(){document.body.innerHTML='<table><tr><th id="0_1">(08:00-08:45)</th><td id="1_1"><div class="class_div"><p>Synthetic</p><p>Teacher</p><p>1-2周</p><p>1-2节</p><p>Room</p></div></td></tr></table>';}, 700);''',
            ),
          );
        } else {
          cookieSeen |= request.cookies.any(
            (cookie) => cookie.name == 'fixture',
          );
          request.response.headers.contentType = ContentType.html;
          request.response.headers.set(
            'Content-Security-Policy',
            "script-src 'self'",
          );
          request.response.write(
            request.uri.path == '/frame'
                ? '<html><body><script src="/dynamic.js"></script></body></html>'
                : '<html><body><iframe src="/frame"></iframe><iframe src="http://127.0.0.1:${foreign.port}/foreign"></iframe></body></html>',
          );
        }
        await request.response.close();
      });
      addTearDown(() => server.close(force: true));
      final created = Completer<InAppWebViewController>();
      final loaded = <String>[];
      final bridgeEvents = <String>[];
      List<dynamic>? parsedCourses;
      final completions = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri('$base/start')),
              initialSettings: ImportWebSettings(
                NavigationPolicy(allowedHosts: ['127.0.0.1']),
              ),
              onWebViewCreated: (controller) {
                controller.addJavaScriptHandler(
                  handlerName: AdapterBridge.toastHandler,
                  callback: (args) {
                    bridgeEvents.add('${args.first}');
                    return null;
                  },
                );
                controller.addJavaScriptHandler(
                  handlerName: AdapterBridge.alertHandler,
                  callback: (args) => true,
                );
                controller.addJavaScriptHandler(
                  handlerName: AdapterBridge.saveCoursesHandler,
                  callback: (args) {
                    parsedCourses =
                        jsonDecode(args.first as String) as List<dynamic>;
                    return true;
                  },
                );
                controller.addJavaScriptHandler(
                  handlerName: AdapterBridge.saveTimeSlotsHandler,
                  callback: (args) => true,
                );
                controller.addJavaScriptHandler(
                  handlerName: AdapterBridge.completionHandler,
                  callback: (args) {
                    completions.add('${args.first}');
                    return null;
                  },
                );
                created.complete(controller);
              },
              onLoadStop: (controller, url) => loaded.add(url.toString()),
              shouldOverrideUrlLoading: (controller, action) async =>
                  NavigationActionPolicy.ALLOW,
            ),
          ),
        ),
      );
      final controller = await created.future.timeout(
        const Duration(seconds: 15),
      );
      Future<void> waitFor(bool Function() ready) async {
        for (var i = 0; i < 100; i++) {
          if (ready()) return;
          await tester.pump(const Duration(milliseconds: 100));
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
        fail('Synthetic WebView condition timed out');
      }

      await waitFor(() => loaded.isNotEmpty);
      for (final endpoint in ['post302', 'post307']) {
        await controller.evaluateJavascript(
          source:
              '''
        var form = document.createElement('form');
        form.method = 'POST'; form.action = '$base/$endpoint';
        var input = document.createElement('input'); input.name = 'fixture'; input.value = 'synthetic';
        form.appendChild(input); document.body.appendChild(form); form.submit();
      ''',
        );
        await waitFor(
          () => loaded.any(
            (url) =>
                url.endsWith(endpoint == 'post302' ? '/landing' : '/received'),
          ),
        );
      }
      expect(
        requests,
        containsAll([
          'POST /post302',
          'GET /landing',
          'POST /post307',
          'POST /received',
        ]),
      );
      expect(cookieSeen, isTrue);
      final features = await const AdapterPageReader().read(
        evaluate: (source) => controller.evaluateJavascript(source: source),
        isCurrent: () => true,
      );
      expect(features.families, contains('urp'));
      expect(features.framePaths['urp'], [0]);
      expect(features.inaccessibleFramePresent, isTrue);
      await controller.evaluateJavascript(source: AdapterBridge.bootstrapJs);
      await controller.evaluateJavascript(
        source: 'window.__huikeAdapterContext = {attemptId:"fixture"};',
      );
      await controller.evaluateJavascript(
        source: AdapterRuntime.execute(
          '''
      document.body.dataset.executed = 'frame';
      window.shiguangBridge.showToast('current');
      setTimeout(function () { window.shiguangBridge.showToast('stale-timer'); }, 1000);
      fetch('/slow').then(function (response) {
        document.body.dataset.headers = 'received';
        return response.text();
      }).then(function () {
        document.body.dataset.body = 'completed';
        window.shiguangBridge.showToast('stale-fetch');
      }).catch(function () { document.body.dataset.body = 'aborted'; });
    ''',
          [0],
        ),
      );
      await waitFor(() => bridgeEvents.contains('current'));
      expect(
        await controller.evaluateJavascript(
          source: 'window.frames[0].document.body.dataset.executed',
        ),
        'frame',
      );
      for (var i = 0; i < 20; i++) {
        if (await controller.evaluateJavascript(
              source: 'window.frames[0].document.body.dataset.headers',
            ) ==
            'received') {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
      expect(
        await controller.evaluateJavascript(
          source: 'window.frames[0].document.body.dataset.headers',
        ),
        'received',
      );
      await controller.evaluateJavascript(source: AdapterRuntime.cleanupJs);
      await Future<void>.delayed(const Duration(milliseconds: 2300));
      expect(bridgeEvents, ['current']);
      expect(
        await controller.evaluateJavascript(
          source: 'window.frames[0].document.body.dataset.body',
        ),
        'aborted',
      );
      final urp = await rootBundle.loadString('assets/adapters/urp_01.js');
      await controller.evaluateJavascript(
        source: AdapterRuntime.execute(urp, [0]),
      );
      await waitFor(() => completions.contains('fixture'));
      expect(parsedCourses, hasLength(1));
      expect((parsedCourses!.single as Map)['name'], 'Synthetic');
      expect((parsedCourses!.single as Map)['weeks'], [1, 2]);
      expect(
        await controller.evaluateJavascript(
          source: 'typeof window.runImportFlow',
        ),
        'undefined',
      );
      await tester.pumpWidget(const SizedBox());
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
