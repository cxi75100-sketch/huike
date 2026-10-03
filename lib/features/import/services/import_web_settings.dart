import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'navigation_policy.dart';

/// 将唯一导航策略的快照交给 vendored Android 内核同步判定。
/// 已确认请求直接继续，避免插件取消后用 loadUrl 重建登录跳转。
class ImportWebSettings extends InAppWebViewSettings {
  ImportWebSettings(this.policy)
    : super(
        useShouldOverrideUrlLoading: true,
        javaScriptEnabled: true,
        domStorageEnabled: true,
        thirdPartyCookiesEnabled: true,
        transparentBackground: false,
        disableContextMenu: false,
        // 禁用原生错误页会被插件导航到 about:blank，破坏失败URL与重试。
        // 保留内核页面，由 Flutter 不透明失败层覆盖。
        disableDefaultErrorPage: false,
      );

  final NavigationPolicy policy;

  @override
  Map<String, dynamic> toMap() => {
    ...super.toMap(),
    'huikeNavigationPolicy': {
      'hosts': List<String>.of(policy.allowedHosts),
      'schemes': List<String>.of(policy.allowedSchemes),
    },
  };
}
