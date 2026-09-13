import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../schools/providers/school_providers.dart';
import '../../schools/services/school_repository.dart';
import '../widgets/import_widgets.dart';

/// 导入入口：确认教务地址与风险，之后才创建 WebView。
///
/// 学生不需要知道教务系统类型：执行导入时 App 会依次尝试全部内置
/// 适配器，能识别当前页面的脚本自己会成功。安全准则不变：
/// 候选地址必须显式确认；本构建只支持 HTTPS 教务。
class ImportEntryPage extends ConsumerStatefulWidget {
  const ImportEntryPage({super.key});

  @override
  ConsumerState<ImportEntryPage> createState() => _ImportEntryPageState();
}

class _ImportEntryPageState extends ConsumerState<ImportEntryPage> {
  late final TextEditingController _urlController;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    final school = ref.read(activeSchoolProvider);
    _urlController = TextEditingController(text: school?.loginUrl ?? '');
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    final school = ref.watch(activeSchoolProvider);

    if (school == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('导入教务课表')),
        body: const Center(child: Text('先创建学校再导入')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('导入教务课表')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          SectionHeaderLabel('学校'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: palette.hairlineStrong),
            ),
            child: Text(
              school.displayName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: palette.ink,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SectionHeaderLabel('导入步骤'),
          Text(
            '1. 在下面填入学校教务网址（HTTPS）。\n'
            '2. 登录教务系统（账号密码只在贵校官方页面输入）。\n'
            '3. 打开「学生课表」之类的页面并完成一次课表查询。\n'
            '4. 点右上角「执行导入」，App 会自动逐个尝试内置适配器。',
            style: TextStyle(fontSize: 14, height: 1.9, color: palette.ink),
          ),
          const SizedBox(height: 20),
          SectionHeaderLabel('教务网址'),
          TextField(
            controller: _urlController,
            keyboardType: TextInputType.url,
            autofillHints: const [AutofillHints.url],
            decoration:
                const InputDecoration(hintText: 'https://jw.example.edu.cn'),
          ),
          const SizedBox(height: 8),
          Text(
            '脚本只在上面这个站点内运行。换域名需要重新确认。',
            style: TextStyle(fontSize: 12.5, color: palette.inkTertiary),
          ),
          const SizedBox(height: 20),
          RiskConfirmTile(
            confirmed: _confirmed,
            onChanged: (value) => setState(() => _confirmed = value),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton(
            onPressed: _confirmed ? () => _start(school.id) : null,
            child: const Text('确认并进入教务登录'),
          ),
        ),
      ),
    );
  }

  Future<void> _start(String schoolId) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.tryParse(_urlController.text.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('网址格式不正确')));
      return;
    }
    if (uri.scheme != 'https') {
      messenger.showSnackBar(
        const SnackBar(content: Text('当前构建只支持 HTTPS 教务地址')),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('进入教务登录页'),
        content: Text(
          '即将打开 ${uri.host}。账号与密码只在该学校的官方页面输入，'
          '本应用不接触登录凭据；导入结果会先预览、经确认后才写入。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('继续'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final repository = ref.read(schoolRepositoryProvider);
    await repository.appendConfirmedHost(schoolId, uri.host);
    if (!mounted) return;
    context.push(
      '/import/web?host=${Uri.encodeComponent(uri.host)}'
      '&url=${Uri.encodeComponent(uri.toString())}',
    );
  }
}
