import 'package:flutter/material.dart';

import '../../../core/glass/glass_button.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/semester.dart';
import 'week_navigation.dart';
import 'week_swipe.dart';

/// 顶部控制区（LEVEL 4，浮动玻璃）。
///
/// 结构：学校行（名称 + 导入/设置）→ 周导航 island。
/// 今日由底部一级切换器负责，不展示今日摘要。
///
/// 刻意不用 AppBar，也不把每块做成独立的白色大卡：
/// 层级由浮动与材质表达，而不是由卡片边框表达。
class TimetableHeader extends StatelessWidget {
  const TimetableHeader({
    super.key,
    required this.schoolName,
    required this.semester,
    required this.week,
    required this.currentWeek,
    required this.onPrevious,
    required this.onNext,
    required this.onCurrent,
    required this.onImport,
    required this.onSettings,
    required this.onSemesterProgress,
    this.swipe,
  });

  final String schoolName;
  final Semester semester;
  final int week;
  final int currentWeek;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onCurrent;
  final VoidCallback onImport;
  final VoidCallback onSettings;
  final VoidCallback onSemesterProgress;
  final WeekSwipeState? swipe;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    final compact = MediaQuery.sizeOf(context).width < 600;

    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 10 : 16, 2, compact ? 10 : 16, 5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 每一行都给下限而不是固定高度：字体放大时整体长高，不裁切。
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 38),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    schoolName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 16 : 17.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      color: palette.ink,
                    ),
                  ),
                ),
                GlassButton.icon(
                  icon: Icons.download_outlined,
                  tooltip: '导入教务课表',
                  onPressed: onImport,
                  size: 30,
                  iconSize: 16,
                  tapTarget: 38,
                  depth: 0.7,
                ),
                const SizedBox(width: 4),
                GlassButton.icon(
                  icon: Icons.settings_outlined,
                  tooltip: '设置',
                  onPressed: onSettings,
                  size: 30,
                  iconSize: 16,
                  tapTarget: 38,
                  depth: 0.7,
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          WeekNavigation(
            semester: semester,
            week: week,
            currentWeek: currentWeek,
            onPrevious: onPrevious,
            onNext: onNext,
            onCurrent: onCurrent,
            onSemesterProgress: onSemesterProgress,
            swipe: swipe,
          ),
        ],
      ),
    );
  }
}
