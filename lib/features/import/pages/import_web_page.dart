import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/glass/glass_button.dart';
import '../../../core/glass/glass_dialog.dart';
import '../../../core/glass/glass_form.dart';
import '../../schools/providers/school_providers.dart';
import '../../schools/services/adapter_catalog.dart';
import '../../schools/services/school_repository.dart';
import '../models/adapter_batch.dart';
import '../models/adapter_diagnostic.dart';
import '../services/adapter_bridge.dart';
import '../services/adapter_probe.dart';
import '../services/adapter_runtime.dart';
import '../services/import_session.dart';
import '../services/import_session_cleaner.dart';
import '../services/navigation_policy.dart';
import '../services/import_web_settings.dart';
import '../services/web_load_failure.dart';
import '../services/login_session_reset.dart';
import '../services/login_recovery_policy.dart';

/// 受限 WebView：用户自行登录教务并在课表页面执行适配脚本。
///
/// - 导航经 [NavigationPolicy] 判定：host 放行范围 = 入口地址 + 学校档案里
///   已确认的主机；主框架跳到新主机时弹窗让用户确认一次并记住（只增不减），
///   因此教务登录跳统一认证/CAS 不会被拦死。scheme 只允许 http/https。
/// - 页面加载完成即注入桥；执行导入时按学校配置、URL 与无值页面特征排列
///   候选，再兼容回退到其它内置脚本；不展示逐个尝试过程。
/// - 脚本的三类 save 只写入内存会话；成功尝试完成后进入预览确认。
class ImportWebPage extends ConsumerStatefulWidget {
  const ImportWebPage({
    super.key,
    required this.host,
    required this.initialUrl,
  });

  final String host;
  final String initialUrl;

  @override
  ConsumerState<ImportWebPage> createState() => _ImportWebPageState();
}

class _ImportWebPageState extends ConsumerState<ImportWebPage> {
  InAppWebViewController? _controller;
  double _progress = 0;
  NavigationPolicy? _policy;
  Uri? _currentUrl;
  bool _pageReady = false;
  WebLoadFailure? _loadFailure;
  int _pageGeneration = 0;
  bool _resettingLogin = false;
  bool _loginViewMounted = true;
  int _loginViewGeneration = 0;
  final Set<Uri> _loginVisitedUrls = {};
  final _loginRecovery = LoginRecoveryPolicy();

  /// 放行主机（入口地址 + 学校已确认 + 会话中用户新确认），只增不减。
  late final List<String> _allowedHosts;

  /// 用户明确拒绝过的主机：同一会话不再重复弹窗。
  final Set<String> _deniedHosts = {};

  bool _hostDialogOpen = false;
  late final ImportSessionCleaner _cleaner;
  bool _running = false;
  bool _navigatedToPreview = false;
  int _attemptSequence = 0;
  String? _scriptAttemptId;
  AdapterDiagnosticCode? _attemptIssue;
  bool _attemptCompletionSeen = false;

  /// 当前尝试的完成信号：true = 脚本读到了课程。
  Completer<bool>? _attemptDone;

  /// 桥弹窗（alert/单选/输入）打开计数；打开时暂停尝试超时，
  /// 因为脚本可能在等用户选学期。
  int _bridgeDialogDepth = 0;

  static const _attemptTimeout = Duration(seconds: 25);

  /// 相邻两次适配尝试之间的间隔：同一教务站不连发请求。
  static const _probeGap = Duration(milliseconds: 800);

  @override
  void initState() {
    super.initState();
    // 清理回调持有 Notifier 实例而不是 `ref`：dispose 阶段再用 ref 会抛
    // 「Using "ref" when a widget … has been unmounted」，结果是离开导入页
    // 时内存会话根本没被清掉（TASK-018A 回归测试发现）。
    final session = ref.read(importSessionProvider.notifier);
    _cleaner = ImportSessionCleaner(session.reset);
    // 放行主机 = 入口地址主机 + 学校档案里已确认过的主机。
    // scheme 不按入口地址钉死：教务站 http↔https 互跳（登录跳 https、
    // 内容页回 http）很常见，钉死会静默失败。
    final school = ref.read(activeSchoolProvider);
    _allowedHosts = <String>{
      widget.host,
      ...?school?.acceptedHosts,
    }.where((host) => host.isNotEmpty).toList();
    _policy = NavigationPolicy(allowedHosts: _allowedHosts);
    _rememberLoginUrl(Uri.tryParse(widget.initialUrl));
  }

  @override
  void dispose() {
    _cancelScript();
    _cleaner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    final viewGeneration = _loginViewGeneration;
    final school = ref.watch(activeSchoolProvider);
    ref.listen<AdapterImportSession>(importSessionProvider, (previous, next) {
      if (next.completed && !_navigatedToPreview) {
        _navigatedToPreview = true;
        context.push('/import/preview');
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(school?.displayName ?? '教务导入'),
        actions: [
          PopupMenuButton<String>(
            tooltip: '登录选项',
            enabled: _controller != null && !_running && !_resettingLogin,
            onSelected: (_) => _restartLogin(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'restart', child: Text('重新登录')),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GlassButton(
              onPressed:
                  _resettingLogin ||
                      _running ||
                      !_pageReady ||
                      _loadFailure != null
                  ? null
                  : _runAutoImport,
              icon: _running ? Icons.hourglass_top : Icons.play_arrow_outlined,
              label: _running ? '正在识别' : '执行导入',
              semanticLabel: _running ? '正在识别课表' : '执行导入',
              size: 40,
              iconColor: palette.accent,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_progress < 1)
            LinearProgressIndicator(
              value: _progress,
              minHeight: 2,
              backgroundColor: palette.hairline,
              color: palette.accent,
            ),
          Expanded(
            child: Stack(
              children: [
                if (_loginViewMounted)
                  InAppWebView(
                    key: ValueKey('login-webview-$_loginViewGeneration'),
                    initialUrlRequest: URLRequest(
                      url: WebUri(widget.initialUrl),
                    ),
                    initialSettings: ImportWebSettings(_policy!),
                    onWebViewCreated: (controller) {
                      if (!mounted || viewGeneration != _loginViewGeneration) {
                        return;
                      }
                      setState(() => _controller = controller);
                      _registerHandlers(controller);
                    },
                    onLoadStop: (controller, uri) async {
                      if (!mounted ||
                          viewGeneration != _loginViewGeneration ||
                          _resettingLogin ||
                          _loadFailure != null) {
                        return;
                      }
                      final generation = _pageGeneration;
                      _currentUrl = uri == null
                          ? null
                          : Uri.tryParse(uri.toString());
                      _rememberLoginUrl(_currentUrl);
                      try {
                        await controller.evaluateJavascript(
                          source: AdapterBridge.bootstrapJs,
                        );
                        if (mounted &&
                            _loadFailure == null &&
                            generation == _pageGeneration) {
                          setState(() => _pageReady = true);
                        }
                      } catch (_) {
                        if (mounted && generation == _pageGeneration) {
                          _setLoadFailure(
                            WebLoadFailure.connection(_currentUrl),
                          );
                        }
                      }
                    },
                    onLoadStart: (controller, uri) {
                      if (!mounted ||
                          viewGeneration != _loginViewGeneration ||
                          _resettingLogin) {
                        return;
                      }
                      _pageGeneration++;
                      _cancelScript();
                      if (_running) {
                        ref.read(importSessionProvider.notifier).reset();
                      }
                      if (_attemptDone?.isCompleted == false) {
                        _attemptDone!.complete(false);
                      }
                      setState(() {
                        _currentUrl = uri == null
                            ? null
                            : Uri.tryParse(uri.toString());
                        _rememberLoginUrl(_currentUrl);
                        _pageReady = false;
                        _loadFailure = null;
                        _progress = 0;
                      });
                    },
                    onReceivedError: (controller, request, error) {
                      if (viewGeneration != _loginViewGeneration) return;
                      if (request.isForMainFrame == true &&
                          error.type != WebResourceErrorType.CANCELLED) {
                        if (error.type ==
                                WebResourceErrorType.TOO_MANY_REDIRECTS &&
                            _tryAutoLoginRecovery(
                              Uri.tryParse(request.url.toString()),
                              redirectLoop: true,
                            )) {
                          return;
                        }
                        _setLoadFailure(
                          WebLoadFailure.connection(
                            Uri.tryParse(request.url.toString()),
                          ),
                        );
                      }
                    },
                    onReceivedHttpError: (controller, request, response) {
                      if (viewGeneration != _loginViewGeneration) return;
                      final status = response.statusCode;
                      if (request.isForMainFrame == true &&
                          status != null &&
                          status >= 400) {
                        if (_tryAutoLoginRecovery(
                          Uri.tryParse(request.url.toString()),
                          httpStatus: status,
                        )) {
                          return;
                        }
                        _setLoadFailure(WebLoadFailure.http(status));
                      }
                    },
                    shouldOverrideUrlLoading: (controller, action) =>
                        viewGeneration != _loginViewGeneration
                        ? Future.value(NavigationActionPolicy.CANCEL)
                        : _handleNavigation(action),
                    onProgressChanged: (controller, progress) {
                      if (!mounted ||
                          viewGeneration != _loginViewGeneration ||
                          _resettingLogin ||
                          _loadFailure != null) {
                        return;
                      }
                      setState(() => _progress = progress / 100);
                    },
                  ),
                if (_resettingLogin)
                  Positioned.fill(
                    child: ColoredBox(
                      color: palette.background,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('正在准备重新登录…'),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (_loadFailure case final failure?)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.wifi_off_outlined, size: 40),
                              const SizedBox(height: 16),
                              const Text('教务页面未能加载'),
                              const SizedBox(height: 12),
                              Text(
                                failure.message,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              GlassButton(
                                onPressed: _retryPage,
                                icon: Icons.refresh,
                                label: '重新加载',
                                semanticLabel: '重新加载教务页面',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _rememberLoginUrl(Uri? uri) {
    if (uri == null || !_policy!.decide(uri).allowed) return;
    // 只驻留内存；丢弃认证query/fragment，不落盘或记录URL。
    _loginVisitedUrls.add(
      Uri(
        scheme: uri.scheme,
        host: uri.host,
        port: uri.hasPort ? uri.port : null,
        path: uri.path.isEmpty ? '/' : uri.path,
      ),
    );
  }

  bool _tryAutoLoginRecovery(
    Uri? uri, {
    int? httpStatus,
    bool redirectLoop = false,
  }) {
    if (!mounted ||
        _resettingLogin ||
        _running ||
        _controller == null ||
        uri == null) {
      return false;
    }
    if (!_loginRecovery.claim(
      trusted: _policy!.decide(uri).allowed,
      httpStatus: httpStatus,
      redirectLoop: redirectLoop,
    )) {
      return false;
    }
    _rememberLoginUrl(uri);
    unawaited(_restartLogin(automatic: true));
    return true;
  }

  Future<void> _restartLogin({bool automatic = false}) async {
    final controller = _controller;
    final viewGeneration = _loginViewGeneration;
    if (controller == null || _resettingLogin || _running) return;
    final confirmed = automatic
        ? true
        : await showGlassDialog<bool>(
            context: context,
            builder: (dialogContext) => GlassDialog(
              title: const Text('重新登录'),
              content: const Text(
                '将清理本次访问过的教务及已确认登录站点的登录状态，并重新打开登录页。'
                '已导入的课表不会删除。\n\n共享同一登录站点的学校可能也需要重新登录。',
              ),
              actions: [
                GlassDialogAction(
                  label: '取消',
                  onPressed: () => Navigator.pop(dialogContext, false),
                ),
                GlassDialogAction(
                  label: '重新登录',
                  primary: true,
                  onPressed: () => Navigator.pop(dialogContext, true),
                ),
              ],
            ),
          );
    if (confirmed != true ||
        !mounted ||
        _resettingLogin ||
        _running ||
        viewGeneration != _loginViewGeneration ||
        !identical(controller, _controller)) {
      return;
    }
    _loginRecovery.markManualRecovery();
    _rememberLoginUrl(_currentUrl);
    final urls = _loginVisitedUrls.toList(growable: false);
    setState(() {
      _resettingLogin = true;
      _pageGeneration++;
      _pageReady = false;
      _loadFailure = null;
      _progress = 0;
    });
    await _cancelScript();
    if (!mounted) return;
    ref.read(importSessionProvider.notifier).reset();
    var message = '重新登录准备失败，请重试。';
    try {
      final result = await ref
          .read(loginSessionResetProvider)
          .reset(
            urls: urls,
            controller: controller,
            revokePage: () async {
              if (!mounted) return;
              setState(() {
                _loginViewMounted = false;
                _controller = null;
              });
              await WidgetsBinding.instance.endOfFrame;
            },
          );
      message = result.complete
          ? '已清理本次访问的登录状态，请重新登录。'
          : '部分登录状态未能清理；若仍无法登录，请在教务页面退出账号后重试。';
    } catch (_) {
      // 只显示固定文案；不显示原生异常、Cookie或认证URL。
    } finally {
      if (mounted) {
        setState(() {
          _loginViewGeneration++;
          _controller = null;
          _loginViewMounted = true;
          _resettingLogin = false;
          _currentUrl = Uri.tryParse(widget.initialUrl);
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  void _setLoadFailure(WebLoadFailure failure) {
    if (!mounted || _resettingLogin) return;
    _cancelScript();
    if (_running) ref.read(importSessionProvider.notifier).reset();
    setState(() {
      _loadFailure = failure;
      _pageReady = false;
      _progress = 1;
    });
    if (_attemptDone?.isCompleted == false) _attemptDone!.complete(false);
  }

  Future<void> _retryPage() async {
    if (_resettingLogin) return;
    final controller = _controller;
    if (controller == null) return;
    _cancelScript();
    setState(() {
      _pageGeneration++;
      _loadFailure = null;
      _pageReady = false;
      _progress = 0;
    });
    try {
      await controller.reload();
    } catch (_) {
      _setLoadFailure(WebLoadFailure.connection(_currentUrl));
    }
  }

  /// 导航放行判定：白名单内直接放行；主框架要跳新主机时问用户一次。
  ///
  /// 子框架（教务页面常用 iframe 承载课表）不参与白名单判定——
  /// 拦掉会更可能把页面弄坏，且框架内导航不改变用户看到的站点。
  Future<NavigationActionPolicy> _handleNavigation(
    NavigationAction action,
  ) async {
    if (_resettingLogin) return NavigationActionPolicy.CANCEL;
    final uri = action.request.url;
    if (uri == null) return NavigationActionPolicy.ALLOW;
    final decision = _policy!.decide(uri);
    if (decision.allowed) return NavigationActionPolicy.ALLOW;

    // 子框架只免「新主机确认」，不免 scheme 安全边界。否则 iframe 内的
    // file:/intent:/tel: 等导航会绕过 NavigationPolicy。
    if (!_policy!.allowsScheme(uri)) {
      _showBlocked(decision.blockedReason);
      return NavigationActionPolicy.CANCEL;
    }
    if (action.isForMainFrame == false) return NavigationActionPolicy.ALLOW;

    final host = uri.host;
    if (host.isEmpty || _deniedHosts.contains(host)) {
      _showBlocked(decision.blockedReason);
      return NavigationActionPolicy.CANCEL;
    }
    if (_hostDialogOpen) return NavigationActionPolicy.CANCEL;

    if (await _confirmNewHost(host)) {
      if (!mounted) return NavigationActionPolicy.CANCEL;
      if (!_allowedHosts.contains(host)) _allowedHosts.add(host);
      final schoolId = ref.read(activeSchoolProvider)?.id;
      if (schoolId != null) {
        await ref
            .read(schoolRepositoryProvider)
            .appendConfirmedHost(schoolId, host);
      }
      if (!mounted) return NavigationActionPolicy.CANCEL;
      await _controller?.setSettings(settings: ImportWebSettings(_policy!));
      return NavigationActionPolicy.ALLOW;
    }
    _deniedHosts.add(host);
    _showBlocked(decision.blockedReason);
    return NavigationActionPolicy.CANCEL;
  }

  Future<bool> _confirmNewHost(String host) async {
    if (!mounted) return false;
    _hostDialogOpen = true;
    try {
      final ok = await showGlassDialog<bool>(
        context: context,
        builder: (dialogContext) => GlassDialog(
          title: const Text('允许访问新域名'),
          content: Text(
            '教务页面要跳到 $host。\n\n'
            '账号与密码只在学校官方页面输入，本应用不接触登录凭据；'
            '确认后会记住这个域名，本次不再询问。',
          ),
          actions: [
            GlassDialogAction(
              label: '不允许',
              onPressed: () => Navigator.pop(dialogContext, false),
            ),
            GlassDialogAction(
              label: '允许',
              primary: true,
              onPressed: () => Navigator.pop(dialogContext, true),
            ),
          ],
        ),
      );
      return ok ?? false;
    } finally {
      _hostDialogOpen = false;
    }
  }

  void _showBlocked(String? reason) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('已拦截：${reason ?? '不在允许范围'}')));
  }

  void _registerHandlers(InAppWebViewController controller) {
    final viewGeneration = _loginViewGeneration;
    bool valid() =>
        mounted &&
        _loginViewMounted &&
        !_resettingLogin &&
        viewGeneration == _loginViewGeneration;
    Future<void> toast(List<dynamic> args) async {
      if (mounted && args.isNotEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${args.first}')));
      }
      return;
    }

    Future<bool> alert(List<dynamic> args) async {
      final title = args.isNotEmpty ? '${args[0]}' : '提示';
      final message = args.length > 1 ? '${args[1]}' : '';
      final button = args.length > 2 ? '${args[2]}' : '确定';
      if (!mounted) return false;
      _bridgeDialogDepth++;
      try {
        final result = await showGlassDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => GlassDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              GlassDialogAction(
                label: '取消',
                onPressed: () => Navigator.pop(dialogContext, false),
              ),
              GlassDialogAction(
                label: button,
                primary: true,
                onPressed: () => Navigator.pop(dialogContext, true),
              ),
            ],
          ),
        );
        return result ?? false;
      } finally {
        _bridgeDialogDepth--;
      }
    }

    Future<Object?> selection(List<dynamic> args) async {
      final title = args.isNotEmpty ? '${args[0]}' : '请选择';
      var options = const <String>[];
      if (args.length > 1) {
        try {
          final decoded = jsonDecode('${args[1]}');
          if (decoded is List) options = decoded.map((e) => '$e').toList();
        } on FormatException {
          options = const [];
        }
      }
      final defaultIndex = args.length > 2 && args[2] is int
          ? args[2] as int
          : 0;
      if (!mounted || options.isEmpty) return null;
      var selected = defaultIndex.clamp(0, options.length - 1);
      _bridgeDialogDepth++;
      try {
        return await showGlassDialog<int>(
          context: context,
          builder: (dialogContext) => StatefulBuilder(
            builder: (dialogContext, setDialogState) => GlassDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var index = 0; index < options.length; index++) ...[
                    if (index > 0) const SizedBox(height: 6),
                    GlassSelectionRow(
                      label: options[index],
                      selected: index == selected,
                      onSelected: () => setDialogState(() => selected = index),
                    ),
                  ],
                ],
              ),
              actions: [
                GlassDialogAction(
                  label: '取消',
                  onPressed: () => Navigator.pop(dialogContext),
                ),
                GlassDialogAction(
                  label: '确定',
                  primary: true,
                  onPressed: () => Navigator.pop(dialogContext, selected),
                ),
              ],
            ),
          ),
        );
      } finally {
        _bridgeDialogDepth--;
      }
    }

    Future<String?> prompt(List<dynamic> args) async {
      final title = args.isNotEmpty ? '${args[0]}' : '输入';
      final message = args.length > 1 ? '${args[1]}' : '';
      final initial = args.length > 2 ? '${args[2]}' : '';
      if (!mounted) return null;
      final controller = TextEditingController(text: initial);
      _bridgeDialogDepth++;
      try {
        final result = await showGlassDialog<String>(
          context: context,
          builder: (dialogContext) => GlassDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.isNotEmpty) Text(message),
                const SizedBox(height: 12),
                GlassTextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(),
                ),
              ],
            ),
            actions: [
              GlassDialogAction(
                label: '取消',
                onPressed: () => Navigator.pop(dialogContext),
              ),
              GlassDialogAction(
                label: '确定',
                primary: true,
                onPressed: () => Navigator.pop(dialogContext, controller.text),
              ),
            ],
          ),
        );
        controller.dispose();
        return result;
      } finally {
        _bridgeDialogDepth--;
      }
    }

    String? attemptIdFrom(List<dynamic> args) =>
        args.length > 1 && args[1] is String ? args[1] as String : null;

    bool stageCourses(List<dynamic> args) {
      if (!mounted) return false;
      final notifier = ref.read(importSessionProvider.notifier);
      final attemptId = attemptIdFrom(args);
      if (!notifier.acceptsAttempt(attemptId)) return false;
      if (args.isEmpty) {
        _attemptIssue = AdapterDiagnosticCode.malformedPayload;
        return false;
      }
      final accepted = notifier.stageCourses(
        '${args.first}',
        attemptId: attemptId,
      );
      if (!accepted) _attemptIssue = AdapterDiagnosticCode.malformedPayload;
      return accepted;
    }

    bool stageTimeSlots(List<dynamic> args) {
      if (!mounted) return false;
      final notifier = ref.read(importSessionProvider.notifier);
      final attemptId = attemptIdFrom(args);
      if (!notifier.acceptsAttempt(attemptId)) return false;
      if (args.isEmpty) {
        _attemptIssue = AdapterDiagnosticCode.malformedPayload;
        return false;
      }
      final accepted = notifier.stageTimeSlots(
        '${args.first}',
        attemptId: attemptId,
      );
      if (!accepted) _attemptIssue = AdapterDiagnosticCode.malformedPayload;
      return accepted;
    }

    bool stageConfig(List<dynamic> args) {
      if (!mounted) return false;
      final notifier = ref.read(importSessionProvider.notifier);
      final attemptId = attemptIdFrom(args);
      if (!notifier.acceptsAttempt(attemptId)) return false;
      if (args.isEmpty) {
        _attemptIssue = AdapterDiagnosticCode.malformedPayload;
        return false;
      }
      final accepted = notifier.stageConfig(
        '${args.first}',
        attemptId: attemptId,
      );
      if (!accepted) _attemptIssue = AdapterDiagnosticCode.malformedPayload;
      return accepted;
    }

    /// 脚本报告执行完毕：读到课程 → 本尝试成功；否则失败换下一个。
    Future<void> completion(List<dynamic> args) async {
      if (!mounted) return;
      final notifier = ref.read(importSessionProvider.notifier);
      final attemptId = args.isNotEmpty && args.first is String
          ? args.first as String
          : null;
      if (!notifier.acceptsAttempt(attemptId)) return;
      _attemptCompletionSeen = true;
      final session = ref.read(importSessionProvider);
      final hasCourses =
          session.normalized != null && session.normalized!.courses.isNotEmpty;
      final completer = _attemptDone;
      if (completer != null && !completer.isCompleted) {
        completer.complete(hasCourses);
      }
    }

    controller.addJavaScriptHandler(
      handlerName: AdapterBridge.toastHandler,
      callback: (args) => valid() ? toast(args) : null,
    );
    controller.addJavaScriptHandler(
      handlerName: AdapterBridge.alertHandler,
      callback: (args) => valid() ? alert(args) : null,
    );
    controller.addJavaScriptHandler(
      handlerName: AdapterBridge.selectionHandler,
      callback: (args) => valid() ? selection(args) : null,
    );
    controller.addJavaScriptHandler(
      handlerName: AdapterBridge.promptHandler,
      callback: (args) => valid() ? prompt(args) : null,
    );
    controller.addJavaScriptHandler(
      handlerName: AdapterBridge.saveCoursesHandler,
      callback: (args) => valid() ? stageCourses(args) : false,
    );
    controller.addJavaScriptHandler(
      handlerName: AdapterBridge.saveTimeSlotsHandler,
      callback: (args) => valid() ? stageTimeSlots(args) : false,
    );
    controller.addJavaScriptHandler(
      handlerName: AdapterBridge.saveConfigHandler,
      callback: (args) => valid() ? stageConfig(args) : false,
    );
    controller.addJavaScriptHandler(
      handlerName: AdapterBridge.completionHandler,
      callback: (args) => valid() ? completion(args) : null,
    );
  }

  /// 先用用户/目录配置和无值 DOM 标记排序，最后仍尝试未匹配的内置脚本。
  Future<void> _runAutoImport() async {
    if (_resettingLogin || !_pageReady || _loadFailure != null || _running) {
      return;
    }
    final generation = _pageGeneration;
    final catalog = ref.read(adapterCatalogProvider).value;
    final controller = _controller;
    if (catalog == null || controller == null) return;

    setState(() {
      _running = true;
      _navigatedToPreview = false;
    });
    final diagnostics = <AdapterAttemptDiagnostic>[];
    final pageFeatures = await _readPageFeatures(controller, generation);
    if (!mounted || generation != _pageGeneration) {
      if (mounted) setState(() => _running = false);
      return;
    }
    final school = ref.read(activeSchoolProvider);
    final candidates = const AdapterProbePlanner().plan(
      catalog: catalog,
      pageFeatures: pageFeatures,
      schoolName: school?.displayName,
      preferredAdapterId: school?.adapterId,
      currentUrl: _currentUrl ?? Uri.tryParse(widget.initialUrl),
    );
    final candidateSequence = AdapterCandidateSequence(candidates);
    var attempted = false;
    AdapterCandidate? activeCandidate;
    try {
      await controller.evaluateJavascript(source: AdapterBridge.bootstrapJs);
      while (candidateSequence.hasNext) {
        if (!mounted ||
            !_pageReady ||
            _loadFailure != null ||
            generation != _pageGeneration) {
          return;
        }
        final candidate = candidateSequence.takeNext()!;
        await _cancelScript();
        activeCandidate = candidate;
        final notifier = ref.read(importSessionProvider.notifier);
        notifier.reset();
        // 逐个尝试的过程不展示给用户（用户负责使用，机制由 App 承担）；
        // 脚本之间留间隔，避免对同一教务连续发请求。
        if (attempted) {
          await Future<void>.delayed(_probeGap);
        }
        if (!mounted ||
            !_pageReady ||
            _loadFailure != null ||
            generation != _pageGeneration) {
          return;
        }
        attempted = true;
        final attemptId =
            '${++_attemptSequence}-${DateTime.now().microsecondsSinceEpoch}';
        notifier.beginAttempt(
          attemptId: attemptId,
          adapterId: candidate.adapterId,
          familyId: candidate.familyId,
          tokenRequired: candidate.supportsAttemptToken,
          courseFieldAliases: candidate.fieldAliases,
          variant: candidate.variant,
        );
        _attemptIssue = null;
        _attemptCompletionSeen = false;
        _attemptDone = Completer<bool>();
        try {
          await controller.evaluateJavascript(
            source: candidate.contextBootstrap(attemptId),
          );
          if (!mounted ||
              !_pageReady ||
              _loadFailure != null ||
              generation != _pageGeneration) {
            if (mounted) notifier.reset();
            return;
          }
          final script = await catalog.scriptFor(candidate.entry);
          if (!mounted ||
              !_pageReady ||
              _loadFailure != null ||
              generation != _pageGeneration) {
            if (mounted) notifier.reset();
            return;
          }
          _scriptAttemptId = attemptId;
          await controller.evaluateJavascript(
            source: AdapterRuntime.execute(
              script,
              pageFeatures.framePaths[candidate.familyId] ?? const [],
            ),
          );
        } catch (_) {
          diagnostics.add(
            _attemptDiagnostic(
              candidate,
              AdapterDiagnosticStage.scriptExecution,
              AdapterDiagnosticStatus.failed,
              AdapterDiagnosticCode.scriptExecutionFailed,
            ),
          );
          notifier.reset();
          continue;
        }
        if (!mounted) return;
        final ok = await _waitAttempt();
        if (!mounted ||
            !_pageReady ||
            _loadFailure != null ||
            generation != _pageGeneration) {
          if (mounted) notifier.reset();
          return;
        }
        if (ok) {
          final batch = ref.read(importSessionProvider).normalized!;
          final code = batch.invalidCount > 0
              ? AdapterDiagnosticCode.partialCourses
              : AdapterDiagnosticCode.importReady;
          diagnostics.add(
            _attemptDiagnostic(
              candidate,
              AdapterDiagnosticStage.normalization,
              batch.invalidCount > 0
                  ? AdapterDiagnosticStatus.partial
                  : AdapterDiagnosticStatus.success,
              code,
            ),
          );
          notifier.setDiagnostics(diagnostics);
          notifier.complete(attemptId: attemptId);
          return;
        }
        diagnostics.add(
          _diagnosticForFailure(
            candidate: candidate,
            pageFeatures: pageFeatures,
            rawCourses: ref.read(importSessionProvider).rawCourses,
            normalized: ref.read(importSessionProvider).normalized,
            issue: _attemptIssue,
            completionSeen: _attemptCompletionSeen,
          ),
        );
        notifier.reset();
      }
    } catch (_) {
      final candidate = activeCandidate;
      if (candidate != null) {
        diagnostics.add(
          _attemptDiagnostic(
            candidate,
            AdapterDiagnosticStage.scriptExecution,
            AdapterDiagnosticStatus.failed,
            AdapterDiagnosticCode.scriptExecutionFailed,
          ),
        );
      }
    } finally {
      await _cancelScript();
      _attemptDone = null;
      if (mounted) setState(() => _running = false);
    }
    if (mounted) {
      final session = ref.read(importSessionProvider.notifier);
      session.reset();
      session.setDiagnostics(diagnostics);
      final showDiagnostics = await showGlassDialog<bool>(
        context: context,
        builder: (dialogContext) => GlassDialog(
          title: const Text('没有适配到你的课表'),
          content: Text(
            '支持多种主流教务系统。未收录学校也可通过教务网址尝试自动识别；'
            '请确认已登录并停留在课表查询页面后重试。',
          ),
          actions: [
            GlassDialogAction(
              label: '查看安全诊断',
              onPressed: () => Navigator.pop(dialogContext, true),
            ),
            GlassDialogAction(
              label: '知道了',
              primary: true,
              onPressed: () => Navigator.pop(dialogContext, false),
            ),
          ],
        ),
      );
      if (showDiagnostics == true && mounted) {
        await _showSafeDiagnostics(diagnostics);
      }
    }
  }

  Future<AdapterPageFeatures> _readPageFeatures(
    InAppWebViewController controller,
    int generation,
  ) => const AdapterPageReader().read(
    evaluate: (source) => controller.evaluateJavascript(source: source),
    isCurrent: () => mounted && generation == _pageGeneration && _pageReady,
  );

  Future<void> _cancelScript() async {
    final attemptId = _scriptAttemptId;
    _scriptAttemptId = null;
    if (attemptId == null) return;
    try {
      await _controller?.evaluateJavascript(
        source: AdapterRuntime.cleanupFor(attemptId),
      );
    } catch (_) {
      // A disposed or navigating native view already destroys its JS context.
    }
  }

  AdapterAttemptDiagnostic _diagnosticForFailure({
    required AdapterCandidate candidate,
    required AdapterPageFeatures pageFeatures,
    required List<dynamic>? rawCourses,
    required AdapterImportBatch? normalized,
    required AdapterDiagnosticCode? issue,
    required bool completionSeen,
  }) {
    if (issue != null) {
      return _attemptDiagnostic(
        candidate,
        AdapterDiagnosticStage.dataExtraction,
        AdapterDiagnosticStatus.failed,
        issue,
      );
    }
    if (rawCourses != null && normalized?.courses.isEmpty == true) {
      final code = rawCourses.isEmpty
          ? AdapterDiagnosticCode.noCourseData
          : AdapterDiagnosticCode.noValidCourses;
      return _attemptDiagnostic(
        candidate,
        AdapterDiagnosticStage.normalization,
        AdapterDiagnosticStatus.failed,
        code,
      );
    }
    if (completionSeen && rawCourses == null) {
      return _attemptDiagnostic(
        candidate,
        AdapterDiagnosticStage.dataExtraction,
        AdapterDiagnosticStatus.failed,
        AdapterDiagnosticCode.noCourseData,
      );
    }
    if (pageFeatures.loginFormPresent && !pageFeatures.timetableMarkerPresent) {
      return _attemptDiagnostic(
        candidate,
        AdapterDiagnosticStage.pageRecognition,
        AdapterDiagnosticStatus.failed,
        AdapterDiagnosticCode.loginRequired,
      );
    }
    if (!pageFeatures.timetableMarkerPresent &&
        candidate.basis == AdapterSelectionBasis.compatibilityFallback) {
      return _attemptDiagnostic(
        candidate,
        AdapterDiagnosticStage.pageRecognition,
        AdapterDiagnosticStatus.notMatched,
        AdapterDiagnosticCode.timetablePageRequired,
      );
    }
    if (pageFeatures.matches(candidate.entry) ||
        candidate.basis == AdapterSelectionBasis.schoolProfile ||
        candidate.basis == AdapterSelectionBasis.schoolPreference ||
        candidate.basis == AdapterSelectionBasis.knownUrl) {
      return _attemptDiagnostic(
        candidate,
        AdapterDiagnosticStage.dataExtraction,
        AdapterDiagnosticStatus.failed,
        AdapterDiagnosticCode.unsupportedPage,
      );
    }
    return _attemptDiagnostic(
      candidate,
      AdapterDiagnosticStage.pageRecognition,
      AdapterDiagnosticStatus.notMatched,
      AdapterDiagnosticCode.pageNotMatched,
    );
  }

  AdapterAttemptDiagnostic _attemptDiagnostic(
    AdapterCandidate candidate,
    AdapterDiagnosticStage stage,
    AdapterDiagnosticStatus status,
    AdapterDiagnosticCode code,
  ) => AdapterAttemptDiagnostic(
    adapterId: candidate.adapterId,
    familyId: candidate.familyId,
    variant: candidate.variant,
    stage: stage,
    status: status,
    code: code,
  );

  Future<void> _showSafeDiagnostics(
    List<AdapterAttemptDiagnostic> diagnostics,
  ) async {
    final report = const JsonEncoder.withIndent('  ')
        .convert([for (final item in diagnostics) item.toSafeMap()]);
    await showGlassDialog<void>(
      context: context,
      builder: (dialogContext) => GlassDialog(
        title: const Text('安全诊断信息'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360),
          child: SingleChildScrollView(child: SelectableText(report)),
        ),
        actions: [
          GlassDialogAction(
            label: '复制诊断',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: report));
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已复制不含教务地址和页面数据的诊断信息')),
                );
              }
            },
          ),
          GlassDialogAction(
            label: '关闭',
            primary: true,
            onPressed: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
    );
  }

  /// 等待当前尝试结束；桥弹窗打开时（脚本在等用户选择）暂停超时。
  Future<bool> _waitAttempt() async {
    var deadline = DateTime.now().add(_attemptTimeout);
    final completer = _attemptDone;
    if (completer == null) return false;
    while (true) {
      if (completer.isCompleted) return await completer.future;
      if (_bridgeDialogDepth > 0) {
        deadline = DateTime.now().add(_attemptTimeout);
      }
      if (DateTime.now().isAfter(deadline)) return false;
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
  }
}
