import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../schools/providers/school_providers.dart';
import '../../schools/services/adapter_catalog.dart';
import '../services/adapter_bridge.dart';
import '../services/import_session.dart';
import '../services/import_session_cleaner.dart';
import '../services/navigation_policy.dart';

/// 受限 WebView：用户自行登录教务并在课表页面执行适配脚本。
///
/// - 导航经 [NavigationPolicy] 白名单拦截（scheme=https、host=确认过的主机）。
/// - 页面加载完成即注入桥；用户点「执行导入」后，App 依次尝试全部内置
///   适配器：每个脚本自己校验当前页面，读不到课表就换下一个。用户
///   不需要知道学校用什么教务系统。
/// - 脚本的三类 save 只写入内存会话；成功尝试完成后进入预览确认。
class ImportWebPage extends ConsumerStatefulWidget {
  const ImportWebPage({super.key, required this.host, required this.initialUrl});

  final String host;
  final String initialUrl;

  @override
  ConsumerState<ImportWebPage> createState() => _ImportWebPageState();
}

class _ImportWebPageState extends ConsumerState<ImportWebPage> {
  InAppWebViewController? _controller;
  double _progress = 0;
  NavigationPolicy? _policy;
  late final ImportSessionCleaner _cleaner;
  bool _running = false;
  bool _navigatedToPreview = false;

  /// 当前尝试的完成信号：true = 脚本读到了课程。
  Completer<bool>? _attemptDone;

  /// 桥弹窗（alert/单选/输入）打开计数；打开时暂停尝试超时，
  /// 因为脚本可能在等用户选学期。
  int _bridgeDialogDepth = 0;

  static const _attemptTimeout = Duration(seconds: 25);

  @override
  void initState() {
    super.initState();
    _cleaner = ImportSessionCleaner(
      () => ref.read(importSessionProvider.notifier).reset(),
    );
    // 用户在入口页确认过的地址决定 scheme：明文白名单域名为 http，
    // 其余一律 https。
    final uri = Uri.tryParse(widget.initialUrl);
    final schemes = (uri?.scheme == 'http') ? ['http'] : ['https'];
    _policy = NavigationPolicy(
      allowedHosts: [widget.host],
      allowedSchemes: schemes,
    );
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
            child: TextButton.icon(
              onPressed: _running ? null : _runAutoImport,
              icon: _running
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow_outlined, size: 18),
              label: const Text('执行导入'),
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
              shouldOverrideUrlLoading: (controller, action) async {
                final uri = action.request.url;
                final decision = uri == null
                    ? NavigationDecision.allow
                    : _policy!.decide(uri);
                if (decision.allowed) return NavigationActionPolicy.ALLOW;
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('已拦截：${decision.blockedReason}')),
                  );
                }
                return NavigationActionPolicy.CANCEL;
              },
              onProgressChanged: (controller, progress) {
                setState(() => _progress = progress / 100);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _registerHandlers(InAppWebViewController controller) {
    Future<void> toast(List<dynamic> args) async {
      if (mounted && args.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${args.first}')));
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
        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(button),
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
        return await showDialog<int>(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: Text(title),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              content: SizedBox(
                width: 320,
                child: RadioGroup<int>(
                  groupValue: selected,
                  onChanged: (value) => Navigator.pop(context, value),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) => RadioListTile<int>(
                      value: index,
                      title: Text(options[index]),
                      dense: true,
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, selected),
                  child: const Text('确定'),
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
        return await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.isNotEmpty) Text(message),
                const SizedBox(height: 12),
                TextField(controller: controller, autofocus: true),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('确定'),
              ),
            ],
          ),
        );
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
    try {
      await controller.evaluateJavascript(source: AdapterBridge.bootstrapJs);
      for (final entry in catalog.entries) {
        ref.read(importSessionProvider.notifier).reset();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('正在尝试 ${entry.name}…'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
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
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('没有适配器识别出课表'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('请确认已登录并打开了课表查询页面，然后重试。'),
              const SizedBox(height: 12),
              for (final line in results)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    line,
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('知道了'),
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
