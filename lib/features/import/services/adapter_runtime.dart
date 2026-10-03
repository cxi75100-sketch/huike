import 'dart:convert';

/// Each attempt owns its bridge, fetches and timers; host page globals stay intact.
class AdapterRuntime {
  const AdapterRuntime._();

  static const cleanupJs = '''
(function () {
  var runtime = window.__huikeAttemptRuntime;
  if (runtime) runtime.cancel();
  window.__huikeAttemptRuntime = null;
})();
''';

  static String cleanupFor(String attemptId) =>
      '''
(function () {
  var runtime = window.__huikeAttemptRuntime;
  if (runtime && runtime.attemptId === ${jsonEncode(attemptId)}) {
    runtime.cancel(); window.__huikeAttemptRuntime = null;
  }
})();
''';

  static String execute(String script, List<int> framePath) =>
      '''
(function () {
  $cleanupJs
  var root = window, target = root;
  var path = ${jsonEncode(framePath)};
  path.forEach(function (index) { target = target.frames[index]; });
  if (!target || !target.document) throw new Error('frame_unavailable');
  var context = root.__huikeAdapterContext;
  var alive = true, requests = [], timers = [], listeners = [];
  var runtime = {attemptId: context && context.attemptId, cancel: function () {
    alive = false;
    requests.forEach(function (request) { request.abort(); });
    listeners.forEach(function (remove) { remove(); });
    timers.forEach(function (timer) { target.clearTimeout(timer); target.clearInterval(timer); });
    requests = []; timers = []; listeners = [];
  }};
  root.__huikeAttemptRuntime = runtime;
  function bridge(original) {
    var copy = {};
    Object.keys(original).forEach(function (key) {
      copy[key] = function () {
        if (!alive) return Promise.resolve(null);
        return original[key].apply(original, arguments);
      };
    });
    return copy;
  }
  var syncBridge = bridge(root.shiguangBridge);
  var asyncBridge = bridge(root.shiguangBridgePromise);
  function request(input, options) {
    if (!alive) return Promise.reject(new Error('attempt_cancelled'));
    var controller = new target.AbortController();
    var supplied = options && options.signal;
    function abort() { controller.abort(); }
    if (supplied) {
      if (supplied.aborted) abort();
      else supplied.addEventListener('abort', abort, {once: true});
      listeners.push(function () { supplied.removeEventListener('abort', abort); });
    }
    requests.push(controller);
    // Keep ownership through response.text/json and streaming body consumption.
    return target.fetch(input, Object.assign({}, options, {signal: controller.signal}));
  }
  function timer(repeating) {
    return function (callback, delay) {
      if (!alive) return 0;
      var args = Array.prototype.slice.call(arguments, 2);
      var id = target[repeating ? 'setInterval' : 'setTimeout'](function () {
        if (alive && typeof callback === 'function') callback.apply(target, args);
      }, delay);
      timers.push(id);
      return id;
    };
  }
  var scopedTimeout = timer(false), scopedInterval = timer(true);
  var scope = new Proxy(target, {get: function (object, key) {
    if (key === '__huikeAdapterContext') return context;
    if (key === 'shiguangBridge') return syncBridge;
    if (key === 'shiguangBridgePromise') return asyncBridge;
    if (key === 'fetch') return request;
    if (key === 'setTimeout') return scopedTimeout;
    if (key === 'setInterval') return scopedInterval;
    var value = Reflect.get(object, key, object);
    if (key === 'jQuery' || key === '\$') return value;
    return typeof value === 'function' ? value.bind(object) : value;
  }});
  (function (window, document, location, self, fetch, setTimeout, setInterval,
    shiguangBridge, shiguangBridgePromise, jQuery, \$, DOMParser) {
    $script
  }).call(scope, scope, target.document, target.location, scope,
    request, scopedTimeout, scopedInterval, syncBridge, asyncBridge,
    target.jQuery, target.\$, target.DOMParser);
  return true;
})();
''';
}
