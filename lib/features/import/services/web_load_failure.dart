import 'dart:io';

/// 不保留 URL、内核错误文字、query 或登录数据，只显示固定分类提示。
class WebLoadFailure {
  const WebLoadFailure(this.message);

  factory WebLoadFailure.connection(Uri? uri) => WebLoadFailure(
    isPrivateNetworkHost(uri?.host ?? '')
        ? '当前教务地址位于内网。请连接学校校园网或学校提供的 VPN 后重试；连接中止也可能由服务器或设备代理造成。'
        : '连接未完成。请检查网络、学校服务是否可访问以及设备 VPN 或代理设置，然后重试。',
  );

  factory WebLoadFailure.http(int status) => WebLoadFailure(
    status == 401 || status == 403
        ? '学校服务器拒绝访问。请确认访问权限和所需网络后重试。'
        : '学校服务器暂未返回可用页面，请稍后重试。',
  );

  final String message;

  static bool isPrivateNetworkHost(String host) {
    final address = InternetAddress.tryParse(host);
    if (address == null) return host.toLowerCase() == 'localhost';
    final bytes = address.rawAddress;
    if (bytes.length == 4) {
      return bytes[0] == 10 ||
          bytes[0] == 127 ||
          (bytes[0] == 172 && bytes[1] >= 16 && bytes[1] <= 31) ||
          (bytes[0] == 192 && bytes[1] == 168) ||
          (bytes[0] == 169 && bytes[1] == 254);
    }
    return address.isLoopback ||
        (bytes[0] & 0xfe) == 0xfc ||
        (bytes[0] == 0xfe && (bytes[1] & 0xc0) == 0x80);
  }
}
