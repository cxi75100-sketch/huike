/// WebView 导航策略：scheme + host 白名单，纯 Dart 可单测。
///
/// 白名单来自用户显式确认：创建学校时的登录地址，以及会话中
/// 确认过的主机。不存在任何“猜测放行”。
class NavigationDecision {
  const NavigationDecision._(this.allowed, this.blockedReason);

  final bool allowed;
  final String? blockedReason;

  static const allow = NavigationDecision._(true, null);
  static NavigationDecision block(String reason) =>
      NavigationDecision._(false, reason);
}

class NavigationPolicy {
  const NavigationPolicy({
    required this.allowedHosts,
    this.allowedSchemes = const ['https'],
  });

  final List<String> allowedHosts;
  final List<String> allowedSchemes;

  NavigationDecision decide(Uri uri) {
    if (!allowedSchemes.contains(uri.scheme)) {
      return NavigationDecision.block('仅允许 ${allowedSchemes.join('/')} 链接');
    }
    if (!allowedHosts.contains(uri.host)) {
      return NavigationDecision.block('主机不在白名单：${uri.host}');
    }
    return NavigationDecision.allow;
  }
}
