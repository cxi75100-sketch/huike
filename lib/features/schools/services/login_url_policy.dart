/// 教务登录地址校验：三处入口共用（引导页建校、学校管理改址、导入入口确认）。
///
/// 抽成一个函数是硬性要求（见 knowledge/decisions.md DEC-006）：此前明文放开时
/// 只改了引导页与导入入口，学校管理页漏改，导致同一所学校两处判定不一致。
///
/// 策略：明文 HTTP 与 HTTPS 都接受——站点协议由学校决定，不按学校名单拦截；
/// 明文风险在入口确认时额外警示。
library;

class LoginUrlCheck {
  const LoginUrlCheck._({this.uri, this.error});

  /// 解析成功时的地址；空输入且非必填时为 null。
  final Uri? uri;

  /// 不可用原因；null 表示通过。
  final String? error;

  bool get ok => error == null;

  /// 明文 HTTP：入口需要额外警示。
  bool get isCleartext => uri?.scheme == 'http';
}

/// [raw] 为空时：`required` 为真报错，否则视为「不填网址」。
LoginUrlCheck checkLoginUrl(String raw, {bool required = false}) {
  final text = raw.trim();
  if (text.isEmpty) {
    return required
        ? const LoginUrlCheck._(error: '请填写教务网址')
        : const LoginUrlCheck._();
  }
  final uri = Uri.tryParse(text);
  if (uri == null || uri.host.isEmpty) {
    return const LoginUrlCheck._(
      error: '网址格式不正确，例：https://jw.example.edu.cn',
    );
  }
  if (uri.scheme != 'http' && uri.scheme != 'https') {
    return const LoginUrlCheck._(error: '只支持 http:// 或 https:// 开头的网址');
  }
  return LoginUrlCheck._(uri: uri);
}
