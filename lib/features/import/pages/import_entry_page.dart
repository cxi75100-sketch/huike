import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/glass/glass_button.dart';
import '../../../core/glass/glass_dialog.dart';
import '../../../core/glass/glass_surface.dart';
import '../../../core/glass/glass_form.dart';
import '../../../core/widgets/ambient_backdrop.dart';
import '../../schools/providers/school_providers.dart';
import '../../schools/services/login_url_policy.dart';
import '../../schools/services/school_repository.dart';
import '../widgets/import_widgets.dart';

/// 导入入口：确认教务地址与风险，之后才创建 WebView。
///
/// 学生不需要知道教务系统类型：执行导入时 App 会依次尝试全部内置
/// 适配器，能识别当前页面的脚本自己会成功。安全准则不变：
/// 候选地址必须显式确认（明文 HTTP 额外警示）；判定与建校/改址共用
/// `checkLoginUrl`（见 knowledge/decisions.md DEC-006）。
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
      // 读取中 / 读取失败 / 确实还没建校必须区分：三者都渲染成空白页会让
      // 用户以为导入功能坏了，也永远等不到可操作的控件（见 TASK-018A）。
      return Scaffold(
        appBar: AppBar(title: const Text('导入教务课表')),
        body: AmbientBackdrop(
          child: Center(child: _placeholder(palette)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('导入教务课表')),
      body: AmbientBackdrop(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            SectionHeaderLabel('学校'),
            GlassSurface(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              '1. 在下面填入学校教务网址。\n'
              '2. 登录教务系统（账号密码只在贵校官方页面输入）。\n'
              '3. 打开「学生课表」之类的页面并完成一次课表查询。\n'
              '4. 点右上角「执行导入」，App 会自动适配并导入。',
              style: TextStyle(fontSize: 14, height: 1.9, color: palette.ink),
            ),
            const SizedBox(height: 20),
            SectionHeaderLabel('教务网址'),
            GlassTextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              autofillHints: const [AutofillHints.url],
              decoration: const InputDecoration(
                hintText: 'https://jw.example.edu.cn',
              ),
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
      ),
      bottomNavigationBar: SafeArea(
        // Scaffold 只让 body 避开键盘，底部栏本身不移动；补上键盘高度，
        // 否则输入网址时 CTA 被键盘盖住（TASK-018A）。
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            16 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: GlassButton(
            onPressed: _confirmed ? () => _start(school.id) : null,
            label: '确认并进入教务登录',
            icon: Icons.login_rounded,
            size: 48,
            iconColor: palette.accent,
          ),
        ),
      ),
    );
  }

  /// 没有可导入的学校时的占位：加载中、读取失败、未建校各有各的说法。
  Widget _placeholder(AppPalette palette) {
    final schools = ref.watch(schoolsProvider);
    final activeId = ref.watch(activeSchoolIdProvider);

    if ((schools.isLoading && !schools.hasValue) ||
        (activeId.isLoading && !activeId.hasValue)) {
      return Column(
        key: const ValueKey('import-loading'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          const SizedBox(height: 14),
          Text(
            '正在读取学校信息…',
            style: TextStyle(fontSize: 14, color: palette.inkSecondary),
          ),
        ],
      );
    }

    if (schools.hasError || activeId.hasError) {
      return Column(
        key: const ValueKey('import-error'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 26, color: palette.danger),
          const SizedBox(height: 12),
          Text(
            '读不到学校信息，请重试。',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: palette.inkSecondary),
          ),
          const SizedBox(height: 16),
          GlassButton(
            onPressed: () {
              ref.invalidate(schoolsProvider);
              ref.invalidate(activeSchoolIdProvider);
            },
            label: '重试',
            icon: Icons.refresh_rounded,
            size: 44,
            iconColor: palette.accent,
          ),
        ],
      );
    }

    return Column(
      key: const ValueKey('import-empty'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '先创建学校再导入',
          style: TextStyle(fontSize: 15, color: palette.inkSecondary),
        ),
        const SizedBox(height: 16),
        GlassButton(
          onPressed: () => context.push('/onboarding'),
          label: '去创建学校',
          icon: Icons.add_rounded,
          size: 44,
          iconColor: palette.accent,
        ),
      ],
    );
  }

  Future<void> _start(String schoolId) async {
    final messenger = ScaffoldMessenger.of(context);
    // 明文 HTTP 不按学校名单拦截（站点协议由学校决定），判定与建校/改址共用同一函数。
    final check = checkLoginUrl(_urlController.text, required: true);
    if (!check.ok) {
      messenger.showSnackBar(SnackBar(content: Text(check.error!)));
      return;
    }
    final uri = check.uri!;

    final ok = await showGlassDialog<bool>(
      context: context,
      builder: (dialogContext) => GlassDialog(
        title: const Text('进入教务登录页'),
        content: Text(
          '即将打开 ${uri.host}。账号与密码只在该学校的官方页面输入，'
          '本应用不接触登录凭据；导入结果会先预览、经确认后才写入。'
          '${uri.scheme == 'http' ? '\n\n注意：该站点为明文 HTTP，'
                    '请确认地址属于你学校。' : ''}',
        ),
        actions: [
          GlassDialogAction(
            label: '取消',
            onPressed: () => Navigator.pop(dialogContext, false),
          ),
          GlassDialogAction(
            label: '继续',
            primary: true,
            onPressed: () => Navigator.pop(dialogContext, true),
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
