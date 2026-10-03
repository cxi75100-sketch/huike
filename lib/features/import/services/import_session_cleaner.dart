import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// 离开导入页时的清理。
///
/// 正常离开只清 HTTP 缓存与导入内存暂存，保留内核管理的 Cookie 与
/// WebStorage；内核可持久保存这些登录状态，App不另行持久保存、写日志或上传。
/// 用户主动「重新登录」时另走受限的 LoginSessionReset。
class ImportSessionCleaner {
  ImportSessionCleaner(this._resetSession);

  /// 清空内存中的导入会话（原始响应与解析结果一并丢弃）。
  final void Function() _resetSession;

  bool _disposed = false;

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    // 清会话必须推迟一拍：dispose 发生在 widget 树 finalize 阶段，
    // 同步改 provider 会被 Riverpod 判为
    // 「Tried to modify a provider while the widget tree was building」，
    // 结果是内存里的原始响应与解析结果没被丢掉（TASK-018A 真机复现）。
    await Future<void>.microtask(_resetSession);
    try {
      // 静态方法：作用于全局 WebView 配置，不需要页面控制器实例。
      await InAppWebViewController.clearAllCache();
    } catch (_) {
      // 清理失败不阻断离开页面；缓存残留最多影响下一次加载。
    }
  }
}
