/// 适配脚本桥。
///
/// 社区适配脚本运行在学校教务页面里，通过 `window.shiguangBridge`（同步）
/// 与 `window.shiguangBridgePromise`（异步）与本 App 通信。契约的完整
/// 证据（函数清单与调用签名）见 knowledge/adapters.md：
///
/// - shiguangBridge.showToast(msg)               // 同步提示
/// - shiguangBridge.notifyTaskCompletion()       // 同步：脚本执行完毕
/// - await showSingleSelection(title, jsonList, defaultIndex) -> index|null
/// - await showAlert(title, message, buttonText) -> bool|null
/// - await showPrompt(title, message, defaultText, validator?) -> string|null
/// - await saveImportedCourses(json) / savePresetTimeSlots(json) /
///          saveCourseConfig(json)
///
/// 安全约束：三类 save 只把数据**暂存到内存会话**，不直接写库；
/// 落库必须经过导入预览页的用户确认。原始 JSON 不落盘、不写日志。
class AdapterBridge {
  const AdapterBridge._();

  /// flutter_inappwebview JavaScriptHandler 名称。桥的 JS 侧通过
  /// `window.flutter_inappwebview.callHandler(name, ...)` 转发调用。
  static const toastHandler = 'huike_showToast';
  static const completionHandler = 'huike_notifyTaskCompletion';
  static const alertHandler = 'huike_showAlert';
  static const selectionHandler = 'huike_showSingleSelection';
  static const promptHandler = 'huike_showPrompt';
  static const saveCoursesHandler = 'huike_saveImportedCourses';
  static const saveTimeSlotsHandler = 'huike_savePresetTimeSlots';
  static const saveConfigHandler = 'huike_saveCourseConfig';

  static const handlerNames = [
    toastHandler,
    completionHandler,
    alertHandler,
    selectionHandler,
    promptHandler,
    saveCoursesHandler,
    saveTimeSlotsHandler,
    saveConfigHandler,
  ];

  /// 注入到页面的桥实现。幂等：重复注入只安装一次，脚本可在任意
  /// 页面加载后执行。契约名保持 `shiguangBridge*`，让社区脚本无需修改。
  static String get bootstrapJs => '''
(function () {
  if (window.__huikeBridgeInstalled) return;
  window.__huikeBridgeInstalled = true;
  var native = function (name) {
    return function () {
      var args = Array.prototype.slice.call(arguments);
      try {
        return window.flutter_inappwebview.callHandler.apply(
          window.flutter_inappwebview, [name].concat(args));
      } catch (e) {
        return Promise.resolve(null);
      }
    };
  };
  window.shiguangBridge = {
    showToast: function (msg) { native('$toastHandler')(String(msg)); },
    notifyTaskCompletion: function () { native('$completionHandler')(); }
  };
  var promised = function (name) {
    return function () {
      return native(name).apply(null, arguments);
    };
  };
  window.shiguangBridgePromise = {
    showAlert: promised('$alertHandler'),
    showSingleSelection: promised('$selectionHandler'),
    showPrompt: promised('$promptHandler'),
    saveImportedCourses: promised('$saveCoursesHandler'),
    savePresetTimeSlots: promised('$saveTimeSlotsHandler'),
    saveCourseConfig: promised('$saveConfigHandler')
  };
})();
''';
}
