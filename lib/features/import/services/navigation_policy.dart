/// WebView 导航策略：scheme + host 白名单，纯 Dart 可单测。
///
/// 白名单来自用户显式确认，不存在任何「猜测放行」：
/// 入口页确认的地址、学校档案里已确认的主机（创建学校时的登录地址、
/// 学校管理改址），以及导入会话中用户对新主机确认过的域名。
/// 主框架跳到未确认主机时由页面弹窗询问，用户同意后再追加进来。
library;

class NavigationDecision {
  const NavigationDecision._(this.allowed, this.blockedReason);

  final bool allowed;
  final String? blockedReason;

  static const allow = NavigationDecision._(true, null);
  static NavigationDecision block(String reason) =>
      NavigationDecision._(false, reason);
}

class NavigationPolicy {
  /// [allowedHosts] 按引用持有：追加主机后无需重建策略即生效。
  const NavigationPolicy({
    required this.allowedHosts,
    this.allowedSchemes = const ['http', 'https'],
  });

  final List<String> allowedHosts;

  /// 明文教务已放开，故默认同时允许 http 与 https；
  /// 其余 scheme（tel:/intent:/file: 等）一律拦截。
  final List<String> allowedSchemes;

  bool allowsScheme(Uri uri) =>
      allowedSchemes.contains(uri.scheme.toLowerCase());

  NavigationDecision decide(Uri uri) {
    if (!allowsScheme(uri)) {
      return NavigationDecision.block('仅允许 ${allowedSchemes.join('/')} 链接');
    }
    if (!allowedHosts.contains(uri.host)) {
      return NavigationDecision.block('主机不在白名单：${uri.host}');
    }
    return NavigationDecision.allow;
  }
}
