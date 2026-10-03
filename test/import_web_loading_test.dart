import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huike_timetable/core/glass/glass_button.dart';
import 'package:huike_timetable/features/import/pages/import_web_page.dart';
import 'package:huike_timetable/features/import/services/adapter_bridge.dart';
import 'package:huike_timetable/features/import/services/login_session_reset.dart';
import 'package:huike_timetable/features/schools/providers/school_providers.dart';

class _Controller extends PlatformInAppWebViewController {
  _Controller()
    : super.implementation(
        const PlatformInAppWebViewControllerCreationParams(id: 99),
      );
  int reloads = 0;
  int evaluations = 0;
  int bootstraps = 0;
  Completer<void>? pendingEvaluation;
  final handlers = <String, JavaScriptHandlerCallback>{};
  @override
  void addJavaScriptHandler({
    required String handlerName,
    required JavaScriptHandlerCallback callback,
  }) {
    handlers[handlerName] = callback;
  }

  @override
  Future<dynamic> evaluateJavascript({
    required String source,
    ContentWorld? contentWorld,
  }) async {
    evaluations++;
    if (source == AdapterBridge.bootstrapJs) bootstraps++;
    final pending = pendingEvaluation;
    if (pending != null) await pending.future;
    return null;
  }

  @override
  Future<void> reload() async {
    reloads++;
  }

  @override
  void dispose({bool isKeepAlive = false}) {}
}

class _WebWidget extends PlatformInAppWebViewWidget {
  _WebWidget(super.params) : super.implementation();
  @override
  Widget build(BuildContext context) => const SizedBox.expand();
  @override
  T controllerFromPlatform<T>(PlatformInAppWebViewController controller) =>
      params.controllerFromPlatform!(controller) as T;
  @override
  void dispose() {}
}

class _Platform extends InAppWebViewPlatform {
  late PlatformInAppWebViewWidgetCreationParams latest;
  @override
  PlatformInAppWebViewWidget createPlatformInAppWebViewWidget(
    PlatformInAppWebViewWidgetCreationParams params,
  ) {
    latest = params;
    return _WebWidget(params);
  }
}

class _LoginReset extends LoginSessionReset {
  int calls = 0;
  List<Uri> visited = [];
  Completer<void>? pending;
  bool complete = true;
  @override
  Future<LoginResetResult> reset({
    required Iterable<Uri> urls,
    required InAppWebViewController controller,
    required Future<void> Function() revokePage,
  }) async {
    calls++;
    visited = urls.toList();
    await revokePage();
    final wait = pending;
    if (wait != null) await wait.future;
    return LoginResetResult(skippedCookies: complete ? 0 : 1);
  }
}

void main() {
  testWidgets('旧手动确认不能在自动恢复后再次清理新页面', (tester) async {
    final previous = InAppWebViewPlatform.instance;
    final platform = _Platform();
    InAppWebViewPlatform.instance = platform;
    addTearDown(() => InAppWebViewPlatform.instance = previous ?? _Platform());
    final reset = _LoginReset();
    final container = ProviderContainer(
      overrides: [
        activeSchoolProvider.overrideWith((ref) => null),
        loginSessionResetProvider.overrideWithValue(reset),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ImportWebPage(
            host: 'portal.example.test',
            initialUrl: 'https://portal.example.test/login',
          ),
        ),
      ),
    );
    final controller = _Controller();
    final facade = InAppWebViewController.fromPlatform(platform: controller);
    final callbacks = platform.latest;
    callbacks.onWebViewCreated!(facade);
    await tester.pump();
    await tester.tap(find.byTooltip('登录选项'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('重新登录'));
    await tester.pumpAndSettle();
    callbacks.onReceivedHttpError!(
      facade,
      WebResourceRequest(
        url: WebUri('https://portal.example.test/login'),
        isForMainFrame: true,
      ),
      WebResourceResponse(statusCode: 401),
    );
    await tester.pumpAndSettle();
    expect(reset.calls, 1);
    final freshCallbacks = platform.latest;
    final freshViewKey = tester
        .widget<InAppWebView>(find.byType(InAppWebView))
        .key;
    freshCallbacks.onWebViewCreated!(
      InAppWebViewController.fromPlatform(platform: _Controller()),
    );
    await tester.tap(find.widgetWithText(GlassButton, '重新登录'));
    await tester.pumpAndSettle();
    expect(reset.calls, 1);
    expect(
      tester.widget<InAppWebView>(find.byType(InAppWebView)).key,
      freshViewKey,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
  for (final redirectLoop in [false, true]) {
    testWidgets('明确登录失效自动恢复一次，不清未确认域/子资源 redirectLoop=$redirectLoop', (
      tester,
    ) async {
      final previous = InAppWebViewPlatform.instance;
      final platform = _Platform();
      InAppWebViewPlatform.instance = platform;
      addTearDown(
        () => InAppWebViewPlatform.instance = previous ?? _Platform(),
      );
      final reset = _LoginReset();
      final container = ProviderContainer(
        overrides: [
          activeSchoolProvider.overrideWith((ref) => null),
          loginSessionResetProvider.overrideWithValue(reset),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ImportWebPage(
              host: 'portal.example.test',
              initialUrl: 'https://portal.example.test/login',
            ),
          ),
        ),
      );
      final facade = InAppWebViewController.fromPlatform(
        platform: _Controller(),
      );
      platform.latest.onWebViewCreated!(facade);
      void fail(
        PlatformInAppWebViewWidgetCreationParams callbacks,
        String url, {
        bool mainFrame = true,
      }) {
        final request = WebResourceRequest(
          url: WebUri(url),
          isForMainFrame: mainFrame,
        );
        if (redirectLoop) {
          callbacks.onReceivedError!(
            facade,
            request,
            WebResourceError(
              type: WebResourceErrorType.TOO_MANY_REDIRECTS,
              description: 'synthetic',
            ),
          );
        } else {
          callbacks.onReceivedHttpError!(
            facade,
            request,
            WebResourceResponse(statusCode: 401),
          );
        }
      }

      fail(platform.latest, 'https://other.example.test/login');
      await tester.pump();
      fail(
        platform.latest,
        'https://portal.example.test/login',
        mainFrame: false,
      );
      await tester.pump();
      expect(reset.calls, 0);
      fail(platform.latest, 'https://portal.example.test/login');
      await tester.pumpAndSettle();
      expect(reset.calls, 1);
      expect(find.text('正在准备重新登录…'), findsNothing);
      expect(find.text('取消'), findsNothing);
      platform.latest.onWebViewCreated!(
        InAppWebViewController.fromPlatform(platform: _Controller()),
      );
      fail(platform.latest, 'https://portal.example.test/login');
      await tester.pumpAndSettle();
      expect(reset.calls, 1);
      expect(find.text('教务页面未能加载'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  }
  testWidgets('重新登录仅确认后清理，取消/网络失败不清；重建并阻断旧桥', (tester) async {
    final previous = InAppWebViewPlatform.instance;
    final platform = _Platform();
    InAppWebViewPlatform.instance = platform;
    addTearDown(() => InAppWebViewPlatform.instance = previous ?? _Platform());
    final reset = _LoginReset();
    final container = ProviderContainer(
      overrides: [
        activeSchoolProvider.overrideWith((ref) => null),
        loginSessionResetProvider.overrideWithValue(reset),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ImportWebPage(
            host: 'portal.example.test',
            initialUrl: 'https://portal.example.test/login?token=synthetic',
          ),
        ),
      ),
    );
    final controller = _Controller();
    final facade = InAppWebViewController.fromPlatform(platform: controller);
    final oldCallbacks = platform.latest;
    oldCallbacks.onWebViewCreated!(facade);
    oldCallbacks.onReceivedHttpError!(
      facade,
      WebResourceRequest(
        url: WebUri('https://portal.example.test/login'),
        isForMainFrame: true,
      ),
      WebResourceResponse(statusCode: 403),
    );
    await tester.pump();
    expect(reset.calls, 0);
    Future<void> menu() async {
      await tester.tap(find.byTooltip('登录选项'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('重新登录'));
      await tester.pumpAndSettle();
    }

    await menu();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(reset.calls, 0);
    await menu();
    reset.pending = Completer<void>();
    await tester.tap(find.widgetWithText(GlassButton, '重新登录'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(reset.calls, 1);
    expect(find.text('正在准备重新登录…'), findsOneWidget);
    expect(reset.visited.single.query, isEmpty);
    expect(reset.visited.single.path, '/login');
    expect(
      await controller.handlers[AdapterBridge.toastHandler]!(['stale']),
      isNull,
    );
    reset.pending!.complete();
    await tester.pumpAndSettle();
    expect(
      platform.latest.initialUrlRequest!.url.toString(),
      'https://portal.example.test/login?token=synthetic',
    );
    final freshController = _Controller();
    final freshFacade = InAppWebViewController.fromPlatform(
      platform: freshController,
    );
    platform.latest.onWebViewCreated!(freshFacade);
    oldCallbacks.onReceivedHttpError!(
      facade,
      WebResourceRequest(
        url: WebUri('https://portal.example.test/login'),
        isForMainFrame: true,
      ),
      WebResourceResponse(statusCode: 403),
    );
    await tester.pump();
    expect(find.text('教务页面未能加载'), findsNothing);
    expect(
      await controller.handlers[AdapterBridge.toastHandler]!(['stale']),
      isNull,
    );
    expect(find.text('stale'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
  testWidgets('加载失败禁用导入；子资源失败不盖住页面；重试后恢复', (tester) async {
    final previous = InAppWebViewPlatform.instance;
    final platform = _Platform();
    InAppWebViewPlatform.instance = platform;
    addTearDown(() => InAppWebViewPlatform.instance = previous ?? _Platform());
    final container = ProviderContainer(
      overrides: [activeSchoolProvider.overrideWith((ref) => null)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ImportWebPage(
            host: '10.8.2.3',
            initialUrl: 'http://10.8.2.3:7777/login',
          ),
        ),
      ),
    );
    final controller = _Controller();
    final facade = InAppWebViewController.fromPlatform(platform: controller);
    final callbacks = platform.latest;
    callbacks.onWebViewCreated!(facade);
    GlassButton importButton() =>
        tester.widget<GlassButton>(find.widgetWithText(GlassButton, '执行导入'));
    expect(importButton().onPressed, isNull);
    callbacks.onLoadStop!(facade, WebUri('http://10.8.2.3:7777/login'));
    await tester.pump();
    expect(importButton().onPressed, isNotNull);
    callbacks.onReceivedError!(
      facade,
      WebResourceRequest(
        url: WebUri('http://10.8.2.3:7777/login'),
        isForMainFrame: true,
      ),
      WebResourceError(
        description: 'cancelled redirect',
        type: WebResourceErrorType.CANCELLED,
      ),
    );
    await tester.pump();
    expect(importButton().onPressed, isNotNull);
    callbacks.onLoadStart!(facade, WebUri('http://10.8.2.3/old'));
    final pending = controller.pendingEvaluation = Completer<void>();
    callbacks.onLoadStop!(facade, WebUri('http://10.8.2.3/old'));
    callbacks.onLoadStart!(facade, WebUri('http://10.8.2.3/new'));
    pending.complete();
    controller.pendingEvaluation = null;
    await tester.pump();
    expect(importButton().onPressed, isNull);
    callbacks.onLoadStop!(facade, WebUri('http://10.8.2.3/new'));
    await tester.pumpAndSettle();
    expect(importButton().onPressed, isNotNull);
    final error = WebResourceError(
      description: 'secret URL should not appear',
      type: WebResourceErrorType.HOST_LOOKUP,
    );
    callbacks.onReceivedError!(
      facade,
      WebResourceRequest(
        url: WebUri('http://10.8.2.3/image'),
        isForMainFrame: false,
      ),
      error,
    );
    await tester.pump();
    expect(find.text('教务页面未能加载'), findsNothing);
    callbacks.onLoadStart!(facade, WebUri('http://10.8.2.3:7777/login'));
    callbacks.onReceivedError!(
      facade,
      WebResourceRequest(
        url: WebUri('http://10.8.2.3:7777/login?ticket=SECRET'),
        isForMainFrame: true,
      ),
      error,
    );
    callbacks.onLoadStop!(facade, WebUri('http://10.8.2.3:7777/login'));
    await tester.pump();
    expect(find.text('教务页面未能加载'), findsOneWidget);
    expect(find.textContaining('内网'), findsOneWidget);
    expect(find.textContaining('SECRET'), findsNothing);
    expect(importButton().onPressed, isNull);
    expect(controller.bootstraps, 3);
    await tester.tap(find.text('重新加载'));
    await tester.pump();
    expect(controller.reloads, 1);
    expect(importButton().onPressed, isNull);
    callbacks.onLoadStart!(facade, WebUri('http://10.8.2.3:7777/login'));
    callbacks.onLoadStop!(facade, WebUri('http://10.8.2.3:7777/login'));
    await tester.pump();
    expect(importButton().onPressed, isNotNull);
    callbacks.onReceivedHttpError!(
      facade,
      WebResourceRequest(
        url: WebUri('http://10.8.2.3:7777/login'),
        isForMainFrame: true,
      ),
      WebResourceResponse(statusCode: 403),
    );
    await tester.pump();
    expect(find.textContaining('拒绝'), findsOneWidget);
    expect(importButton().onPressed, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
