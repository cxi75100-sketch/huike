import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
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
import '../services/adapter_bridge.dart';
import '../services/import_session.dart';
import '../services/import_session_cleaner.dart';
import '../services/navigation_policy.dart';

/// 受限 WebView：用户自行登录教务并在课表页面执行适配脚本。
///
/// - 导航经 [NavigationPolicy] 判定：host 放行范围 = 入口地址 + 学校档案里
///   已确认的主机；主框架跳到新主机时弹窗让用户确认一次并记住（只增不减），
///   因此教务登录跳统一认证/CAS 不会被拦死。scheme 只允许 http/https。
/// - 页面加载完成即注入桥；用户点「执行导入」后，App 自动依次尝试全部内置
///   适配器：每个脚本自己校验当前页面，读不到课表就换下一个。用户不需要
///   知道学校用什么教务系统，也看不到逐个尝试的过程。
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

  /// 放行主机（入口地址 + 学校已确认 + 会话中用户新确认），只增不减。
  late final List<String> _allowedHosts;

  /// 用户明确拒绝过的主机：同一会话不再重复弹窗。
  final Set<String> _deniedHosts = {};

  bool _hostDialogOpen = false;
  late final ImportSessionCleaner _cleaner;
  bool _running = false;
  bool _navigatedToPreview = false;

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
  }

  @override
  void dispose() {
    _cleaner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
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
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GlassButton(
              onPressed: _running ? null : _runAutoImport,
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
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                transparentBackground: false,
                disableContextMenu: false,
              ),
              onWebViewCreated: (controller) {
                _controller = controller;
                _registerHandlers(controller);
              },
              onLoadStop: (controller, uri) async {
                await controller.evaluateJavascript(
                  source: AdapterBridge.bootstrapJs,
                );
              },
              shouldOverrideUrlLoading: (controller, action) =>
                  _handleNavigation(action),
              onProgressChanged: (controller, progress) {
                setState(() => _progress = progress / 100);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 导航放行判定：白名单内直接放行；主框架要跳新主机时问用户一次。
  ///
  /// 子框架（教务页面常用 iframe 承载课表）不参与白名单判定——
  /// 拦掉会更可能把页面弄坏，且框架内导航不改变用户看到的站点。
  Future<NavigationActionPolicy> _handleNavigation(
    NavigationAction action,
  ) async {
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
      if (!_allowedHosts.contains(host)) _allowedHosts.add(host);
      final schoolId = ref.read(activeSchoolProvider)?.id;
      if (schoolId != null) {
        await ref
            .read(schoolRepositoryProvider)
            .appendConfirmedHost(schoolId, host);
      }
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

    bool stageCourses(List<dynamic> args) {
      if (args.isEmpty) return false;
      return ref
          .read(importSessionProvider.notifier)
          .stageCourses('${args.first}');
    }

    bool stageTimeSlots(List<dynamic> args) {
      if (args.isEmpty) return false;
      return ref
          .read(importSessionProvider.notifier)
          .stageTimeSlots('${args.first}');
    }

    bool stageConfig(List<dynamic> args) {
      if (args.isEmpty) return false;
      return ref
          .read(importSessionProvider.notifier)
          .stageConfig('${args.first}');
    }

    /// 脚本报告执行完毕：读到课程 → 本尝试成功；否则失败换下一个。
    Future<void> completion(List<dynamic> args) async {
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
      callback: (args) => toast(args),
    );
    controller.addJavaScriptHandler(
      handlerName: AdapterBridge.alertHandler,
      callback: (args) => alert(args),
    );
    controller.addJavaScriptHandler(
      handlerName: AdapterBridge.selectionHandler,
      callback: (args) => selection(args),
    );
    controller.addJavaScriptHandler(
      handlerName: AdapterBridge.promptHandler,
      callback: (args) => prompt(args),
    );
    controller.addJavaScriptHandler(
      handlerName: AdapterBridge.saveCoursesHandler,
      callback: (args) => stageCourses(args),
    );
    controller.addJavaScriptHandler(
      handlerName: AdapterBridge.saveTimeSlotsHandler,
      callback: (args) => stageTimeSlots(args),
    );
    controller.addJavaScriptHandler(
      handlerName: AdapterBridge.saveConfigHandler,
      callback: (args) => stageConfig(args),
    );
    controller.addJavaScriptHandler(
      handlerName: AdapterBridge.completionHandler,
      callback: (args) => completion(args),
    );
  }

  /// 依次尝试全部内置适配器；每个脚本自己校验当前页面。
  /// 第一个读到课程的尝试完成后进入预览；全部失败给出逐项汇总。
  Future<void> _runAutoImport() async {
    final catalog = ref.read(adapterCatalogProvider).value;
    final controller = _controller;
    if (catalog == null || controller == null) return;

    setState(() {
      _running = true;
      _navigatedToPreview = false;
    });
    final results = <String>[];
    var attempted = false;
    try {
      await controller.evaluateJavascript(source: AdapterBridge.bootstrapJs);
      for (final entry in catalog.entries) {
        ref.read(importSessionProvider.notifier).reset();
        // 逐个尝试的过程不展示给用户（用户负责使用，机制由 App 承担）；
        // 脚本之间留间隔，避免对同一教务连续发请求。
        if (attempted) {
          await Future<void>.delayed(_probeGap);
        }
        attempted = true;
        final script = await catalog.scriptFor(entry);
        _attemptDone = Completer<bool>();
        try {
          await controller.evaluateJavascript(source: script);
        } catch (error) {
          results.add('${entry.name}：脚本无法在此页面执行');
          continue;
        }
        final ok = await _waitAttempt();
        if (ok) {
          ref.read(importSessionProvider.notifier).complete();
          return;
        }
        results.add('${entry.name}：在这个页面没找到可识别的课表');
      }
    } catch (error) {
      results.add('执行中断：$error');
    } finally {
      _attemptDone = null;
      if (mounted) setState(() => _running = false);
    }
    if (mounted && results.isNotEmpty) {
      // 常规失败（脚本没读到课表）不逐条罗列：对用户没有可操作价值。
      // 只把「执行中断」这类异常报出来，便于排查。
      String? error;
      for (final line in results) {
        if (line.startsWith('执行中断')) {
          error = line;
          break;
        }
      }
      await showGlassDialog<void>(
        context: context,
        builder: (dialogContext) => GlassDialog(
          title: const Text('没有适配到你的课表'),
          content: Text(
            '请确认已经登录教务、并停留在课表查询页面（学生个人课表），然后重试。'
            '${error == null ? '' : '\n\n$error'}',
          ),
          actions: [
            GlassDialogAction(
              label: '知道了',
              primary: true,
              onPressed: () => Navigator.pop(dialogContext),
            ),
          ],
        ),
      );
    }
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
