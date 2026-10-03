import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final loginSessionResetProvider = Provider<LoginSessionReset>(
  (ref) => LoginSessionReset(),
);

class LoginResetResult {
  const LoginResetResult({
    this.cookiesDeleted = 0,
    this.skippedCookies = 0,
    this.failedOperations = 0,
  });
  final int cookiesDeleted;
  final int skippedCookies;
  final int failedOperations;
  bool get complete => skippedCookies == 0 && failedOperations == 0;
}

/// Narrow injectable native operations; no bulk cookie/storage deletion API.
abstract class LoginResetBackend {
  Future<List<Cookie>> cookies(Uri url);
  Future<bool> deleteCookie(Uri url, Cookie cookie);
  Future<bool> clearStorage(Uri origin);
}

class LoginSessionReset {
  LoginSessionReset({
    LoginResetBackend? backend,
    Future<bool> Function(InAppWebViewController, Set<Uri>)? preparePage,
  }) : _backend = backend ?? _NativeLoginResetBackend(),
       _preparePage = preparePage ?? _prepareCurrentPage;

  final LoginResetBackend _backend;
  final Future<bool> Function(InAppWebViewController, Set<Uri>) _preparePage;

  /// Caller authorizes manual reset or bounded auth recovery for visited trusted URLs.
  /// Old page must be destroyed before cookie deletion, so it cannot rewrite them.
  Future<LoginResetResult> reset({
    required Iterable<Uri> urls,
    required InAppWebViewController controller,
    required Future<void> Function() revokePage,
  }) async {
    final scopes = <Uri>{
      for (final url in urls)
        if ((url.scheme == 'http' || url.scheme == 'https') &&
            url.host.isNotEmpty &&
            url.userInfo.isEmpty)
          Uri(
            scheme: url.scheme,
            host: url.host,
            port: url.hasPort ? url.port : null,
            path: url.path.isEmpty ? '/' : url.path,
          ),
    };
    if (scopes.isEmpty) return const LoginResetResult(failedOperations: 1);
    final origins = scopes.map((url) => Uri.parse(url.origin)).toSet();
    var failed = 0, skipped = 0, deleted = 0;
    // A failed stop cannot safely continue: a live page may keep rewriting state.
    try {
      await controller.stopLoading();
    } catch (_) {
      return const LoginResetResult(failedOperations: 1);
    }
    try {
      if (!await _preparePage(controller, origins)) failed++;
    } catch (_) {
      failed++;
    }
    try {
      await revokePage();
    } catch (_) {
      return LoginResetResult(failedOperations: failed + 1);
    }
    final hosts = scopes.map((url) => url.host.toLowerCase()).toSet();
    final cookieScopes = <Uri>{
      for (final url in scopes) ...[
        url,
        url.replace(path: '/'),
        // Cookie host/path are protocol independent; HTTPS reveals Secure cookies.
        url.replace(scheme: 'https'),
        url.replace(scheme: 'https', path: '/'),
      ],
    };
    final seen = <String>{};
    for (final url in cookieScopes) {
      List<Cookie> cookies;
      try {
        cookies = await _backend.cookies(url);
      } catch (_) {
        failed++;
        continue;
      }
      for (final cookie in cookies) {
        final domain = cookie.domain
            ?.replaceFirst(RegExp(r'^\.'), '')
            .toLowerCase();
        final path = cookie.path;
        final key = '${cookie.domain}\u0000$path\u0000${cookie.name}';
        if (!seen.add(key)) continue;
        if (domain == null ||
            !hosts.contains(domain) ||
            path == null ||
            !path.startsWith('/')) {
          skipped++;
          continue;
        }
        try {
          final target = cookie.isSecure == true
              ? url.replace(scheme: 'https')
              : url;
          if (await _backend.deleteCookie(target, cookie)) {
            deleted++;
          } else {
            failed++;
          }
        } catch (_) {
          failed++;
        }
      }
    }
    for (final origin in origins) {
      try {
        if (!await _backend.clearStorage(origin)) failed++;
      } catch (_) {
        failed++;
      }
    }
    return LoginResetResult(
      cookiesDeleted: deleted,
      skippedCookies: skipped,
      failedOperations: failed,
    );
  }

  static Future<bool> _prepareCurrentPage(
    InAppWebViewController controller,
    Set<Uri> origins,
  ) async {
    final result = await controller.evaluateJavascript(
      source:
          '''
(function () {
  var allowed = ${jsonEncode(origins.map((origin) => origin.toString()).toList())};
  if (allowed.indexOf(window.location.origin) < 0) return false;
  var ok = true, visited = 0;
  function clear(win) {
    if (++visited > 32) { ok = false; return; }
    try {
      if (win.location.origin !== window.location.origin) return;
      win.sessionStorage.clear(); win.localStorage.clear();
      for (var i = 0; i < win.frames.length; i++) clear(win.frames[i]);
    } catch (_) { ok = false; }
  }
  clear(window); return ok;
})();
''',
    );
    return result == true;
  }
}

class _NativeLoginResetBackend implements LoginResetBackend {
  @override
  Future<List<Cookie>> cookies(Uri url) =>
      CookieManager.instance().getCookies(url: WebUri(url.toString()));
  @override
  Future<bool> deleteCookie(Uri url, Cookie cookie) async {
    // Native deleteCookie lacks attributes required for prefixed cookies.
    final prefixed =
        cookie.name.startsWith('__Secure-') ||
        cookie.name.startsWith('__Host-');
    if (prefixed && cookie.isSecure != true) return false;
    final deleted = prefixed
        ? await CookieManager.instance().setCookie(
            url: WebUri(url.toString()),
            name: cookie.name,
            // Android Dart wrapper asserts nonempty values, even for expiry.
            value: 'expired',
            maxAge: -1,
            domain: cookie.name.startsWith('__Host-') ? null : cookie.domain,
            path: cookie.path!,
            isSecure: cookie.isSecure,
            isHttpOnly: cookie.isHttpOnly,
          )
        : await CookieManager.instance().deleteCookie(
            url: WebUri(url.toString()),
            name: cookie.name,
            domain: cookie.domain,
            path: cookie.path!,
          );
    if (!deleted) return false;
    final remaining = await cookies(url);
    String? domain(String? raw) =>
        raw?.replaceFirst(RegExp(r'^\.'), '').toLowerCase();
    return !remaining.any(
      (item) =>
          item.name == cookie.name &&
          item.path == cookie.path &&
          domain(item.domain) == domain(cookie.domain),
    );
  }

  @override
  Future<bool> clearStorage(Uri origin) async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return false;
    }
    // A blank same-origin context clears exact localStorage without a network load.
    final done = Completer<bool>();
    final headless = HeadlessInAppWebView(
      initialData: InAppWebViewInitialData(
        data: '<html><body></body></html>',
        baseUrl: WebUri(origin.toString()),
      ),
      onLoadStop: (controller, _) async {
        try {
          final result = await controller.evaluateJavascript(
            source: '(function(){try{localStorage.clear();return true;}catch(_){return false;}})();',
          );
          if (!done.isCompleted) done.complete(result == true);
        } catch (_) {
          if (!done.isCompleted) done.complete(false);
        }
      },
    );
    try {
      await headless.run();
      final cleared = await done.future.timeout(
        const Duration(seconds: 8),
        onTimeout: () => false,
      );
      if (defaultTargetPlatform == TargetPlatform.android) {
        // Native deleteOrigin covers legacy Application Cache/WebSQL only;
        // it is not a general HTTP-cache or IndexedDB clear.
        await WebStorageManager.instance().deleteOrigin(
          origin: origin.toString(),
        );
      }
      // iOS broader site data deletion has no verified exact-origin API here.
      return cleared && defaultTargetPlatform == TargetPlatform.android;
    } finally {
      await headless.dispose();
    }
  }
}
