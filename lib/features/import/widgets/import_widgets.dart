import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/glass/glass_form.dart';

/// 历书式小节标题：细体、全大写字距不用（中文语境），只用竖线定位。
class SectionHeaderLabel extends StatelessWidget {
  const SectionHeaderLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 10),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 12,
            color: palette.accent,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: palette.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// HTTP 风险确认门（与单校版同语义的适配版）。
class RiskConfirmTile extends StatelessWidget {
  const RiskConfirmTile({
    super.key,
    required this.confirmed,
    required this.onChanged,
  });

  final bool confirmed;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.accentSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '登录安全提示',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '请在确认地址栏属于你的学校教务系统后再输入账号密码。'
            '本应用不保存、不上传任何凭据；如遇验证码请自行输入，'
            '应用不会绕过任何认证机制。',
            style: TextStyle(fontSize: 13, height: 1.6, color: palette.inkSecondary),
          ),
          const SizedBox(height: 4),
          GlassToggleRow(
            label: '我确认以上地址是我学校自己的教务系统',
            value: confirmed,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
