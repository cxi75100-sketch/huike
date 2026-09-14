import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../schools/providers/school_providers.dart';
import '../../schools/services/adapter_catalog.dart';
import '../../schools/services/login_url_policy.dart';
import '../../schools/services/school_repository.dart';

class SchoolManagePage extends ConsumerWidget {
  const SchoolManagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppTheme.paletteOf(context);
    final schools = ref.watch(schoolsProvider).value ?? const [];
    final activeId = ref.watch(activeSchoolIdProvider).value;
    final catalog = ref.watch(adapterCatalogProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('学校管理')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          for (final school in schools)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: school.id == activeId
                        ? palette.accent
                        : palette.hairline,
                    width: school.id == activeId ? 1.4 : 1,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  onTap: () async {
                    await ref
                        .read(schoolRepositoryProvider)
                        .setActiveSchool(school.id);
                  },
                  title: Text(
                    school.displayName,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: palette.ink,
                    ),
                  ),
                  subtitle: Text(
                    school.adapterId == 'auto'
                        ? '教务适配：自动识别'
                        : catalog?.byId(school.adapterId)?.name ??
                              (school.adapterId.isEmpty ? '未配置教务' : school.adapterId),
                    style: TextStyle(fontSize: 12.5, color: palette.inkSecondary),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (school.id == activeId)
                        Text(
                          '使用中',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: palette.accent,
                          ),
                        ),
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: palette.inkSecondary,
                        ),
                        onSelected: (value) async {
                          if (value == 'delete') {
                            await _confirmDelete(context, ref, school.id, school.displayName);
                          } else if (value == 'url') {
                            await _editLoginUrl(context, ref, school.id);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'url', child: Text('修改教务网址')),
                          const PopupMenuItem(value: 'delete', child: Text('删除学校')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.push('/onboarding?add=1'),
            icon: const Icon(Icons.add),
            label: const Text('添加学校'),
          ),
          const SizedBox(height: 8),
          Text(
            '切换学校后，另一所学校的课表数据仍保留在本机，只是不再显示。',
            style: TextStyle(fontSize: 12.5, height: 1.6, color: palette.inkTertiary),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String schoolId,
    String name,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除学校'),
        content: Text('将删除「$name」的全部课程、学期与作息设置，此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(schoolRepositoryProvider).deleteSchool(schoolId);
    }
  }

  Future<void> _editLoginUrl(
    BuildContext context,
    WidgetRef ref,
    String schoolId,
  ) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改教务网址'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'https:// 或 http://jw.example.edu.cn',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final check = checkLoginUrl(controller.text, required: true);
    if (!check.ok) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(check.error!)));
      }
      return;
    }
    final repository = ref.read(schoolRepositoryProvider);
    await repository.updateLoginUrl(schoolId, check.uri!);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('教务网址已更新')));
    }
  }
}
