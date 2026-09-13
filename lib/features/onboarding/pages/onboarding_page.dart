import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../schools/services/school_repository.dart';
import '../../import/widgets/import_widgets.dart';

/// 创建学校 + 第一学期。
///
/// 学生不需要知道学校用什么教务系统：教务网址选填，适配器在导入时
/// 由 App 依次自动尝试。没有「默认学校」：全新安装必经此页。
/// 开学周一必须由用户按校历给出，App 不猜测日期。
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key, this.isAddingSchool = false});

  final bool isAddingSchool;

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  DateTime _firstWeekMonday = _defaultMonday();
  int _totalWeeks = 20;
  bool _creating = false;

  static DateTime _defaultMonday() {
    final now = DateTime.now();
    final weekday = now.weekday;
    final monday = now.subtract(Duration(days: weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAddingSchool ? '添加学校' : '欢迎使用汇课'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          if (!widget.isAddingSchool) ...[
            Text(
              '一所学校的课表，从建立它的档案开始。',
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: palette.inkSecondary,
              ),
            ),
            const SizedBox(height: 20),
          ],
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '学校名称（必填）',
              hintText: '如：某某大学',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _urlController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: '教务网址（选填，HTTPS）',
              hintText: 'https://jw.example.edu.cn',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '教务系统类型不用选：导入时 App 会自动逐个尝试内置适配器。'
            '不知道网址可以先留空，之后在导入页或学校管理里补。',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.6,
              color: palette.inkTertiary,
            ),
          ),
          const SizedBox(height: 20),
          SectionHeaderLabel('第一学期'),
          _dateTile(palette),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '教学周数',
                style: TextStyle(fontSize: 14.5, color: palette.ink),
              ),
              const Spacer(),
              IconButton(
                onPressed: _totalWeeks > 1
                    ? () => setState(() => _totalWeeks -= 1)
                    : null,
                icon: const Icon(Icons.remove),
              ),
              Text(
                '$_totalWeeks',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: palette.ink,
                ),
              ),
              IconButton(
                onPressed: _totalWeeks < 30
                    ? () => setState(() => _totalWeeks += 1)
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '开学周一是一切周次与单双周的锚点，按校历填写；'
            '填错会让整学期周次偏移，之后也能在设置里修改。',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.6,
              color: palette.inkTertiary,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton(
            onPressed: _creating ? null : _create,
            child: Text(_creating ? '正在创建' : '创建学校'),
          ),
        ),
      ),
    );
  }

  Widget _dateTile(AppPalette palette) => InkWell(
    onTap: _pickDate,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.hairlineStrong),
      ),
      child: Row(
        children: [
          Text(
            '开学第一周周一',
            style: TextStyle(fontSize: 14.5, color: palette.inkSecondary),
          ),
          const Spacer(),
          Text(
            DateFormat('yyyy-MM-dd').format(_firstWeekMonday),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: palette.accent,
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right, size: 20, color: palette.inkTertiary),
        ],
      ),
    ),
  );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _firstWeekMonday,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      setState(
        () => _firstWeekMonday = DateTime(picked.year, picked.month, picked.day),
      );
    }
  }

  Future<void> _create() async {
    final messenger = ScaffoldMessenger.of(context);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('学校名称不能为空')));
      return;
    }
    var loginUrl = '';
    var hosts = <String>[];
    final urlText = _urlController.text.trim();
    if (urlText.isNotEmpty) {
      final uri = Uri.tryParse(urlText);
      if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('教务网址需要是合法的 HTTPS 地址，或留空')),
        );
        return;
      }
      loginUrl = uri.toString();
      hosts = [uri.host];
    }

    setState(() => _creating = true);
    try {
      final repository = ref.read(schoolRepositoryProvider);
      final school = await repository.createSchool(
        displayName: name,
        adapterId: loginUrl.isEmpty ? '' : 'auto',
        loginUrl: loginUrl,
        confirmedHosts: hosts,
      );
      await repository.createSemester(
        schoolId: school.id,
        firstWeekMonday: _firstWeekMonday,
        totalWeeks: _totalWeeks,
      );
      await repository.setActiveSchool(school.id);
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('「$name」已就绪')));
        context.go('/');
      }
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('创建失败：$error')));
      if (mounted) setState(() => _creating = false);
    }
  }
}
