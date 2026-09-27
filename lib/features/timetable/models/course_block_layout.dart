import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';

/// 课程块的排印与内容测量。
///
/// 网格由 viewport 决定高度；这些样式只用于卡片内部排印和测量。
class CourseBlockTypography {
  const CourseBlockTypography({
    required this.nameStyle,
    required this.secondaryStyle,
    required this.timeStyle,
    required this.padding,
    required this.gap,
  });

  final TextStyle nameStyle;
  final TextStyle secondaryStyle;
  final TextStyle timeStyle;
  final EdgeInsets padding;

  /// 行间距。
  final double gap;

  /// 冲突徽标（`+N`）条的高度：含它与文字之间的空隙。
  ///
  /// 同一时段有多门课时，块里仍然是**一门课的完整信息**（全宽排印），
  /// 其余课程用这枚小签进入列表。徽标占**顶部一条**而不是右上角一块：
  /// 七列手机宽度下把 38dp 的文字列再让出 21dp，等于把文字挤成每行一个字。
  static const conflictBadgeHeight = 15.0;

  static const compact = CourseBlockTypography(
    nameStyle: TextStyle(
      fontSize: 11.5,
      height: 1.06,
      fontWeight: FontWeight.w700,
    ),
    secondaryStyle: TextStyle(fontSize: 10, height: 1.12),
    timeStyle: TextStyle(fontSize: 9.6, height: 1.05),
    padding: EdgeInsets.fromLTRB(4, 5, 4, 5),
    gap: 1,
  );

  static const medium = CourseBlockTypography(
    nameStyle: TextStyle(
      fontSize: 13.5,
      height: 1.1,
      fontWeight: FontWeight.w700,
    ),
    secondaryStyle: TextStyle(fontSize: 11.4, height: 1.16),
    timeStyle: TextStyle(fontSize: 11, height: 1.08),
    padding: EdgeInsets.fromLTRB(8, 7, 6, 7),
    gap: 3.5,
  );

  static const expanded = CourseBlockTypography(
    nameStyle: TextStyle(
      fontSize: 15,
      height: 1.12,
      fontWeight: FontWeight.w700,
    ),
    secondaryStyle: TextStyle(fontSize: 12.6, height: 1.18),
    timeStyle: TextStyle(fontSize: 12.4, height: 1.1),
    padding: EdgeInsets.fromLTRB(10, 8, 8, 8),
    gap: 4,
  );

  /// 按网格密度取排印，并把调色板颜色注入样式。
  CourseBlockTypography colored({
    required Color ink,
    required Color secondary,
    required Color tertiary,
  }) => CourseBlockTypography(
    nameStyle: nameStyle.copyWith(color: ink),
    secondaryStyle: secondaryStyle.copyWith(color: secondary),
    timeStyle: timeStyle.copyWith(
      color: tertiary,
      fontFeatures: const [FontFeature.tabularFigures()],
    ),
    padding: padding,
    gap: gap,
  );

  /// 与 `+N` 小签同处一块时，顶部让出一条小签的位置。
  ///
  /// 测量与实际绘制都用这一份调整后的排印，两者不会脱节。
  CourseBlockTypography withConflictBadge() => CourseBlockTypography(
    nameStyle: nameStyle,
    secondaryStyle: secondaryStyle,
    timeStyle: timeStyle,
    padding: padding.copyWith(top: padding.top + conflictBadgeHeight),
    gap: gap,
  );

  /// 拆出课程块要画的所有内容。
  ///
  /// 名称、地点、教师、时间只要在数据库里有值就一定会被画出来：
  /// 名称永远第一行，时间固定在块底。
  CourseBlockContent contentOf({
    required String name,
    required String classroom,
    required String teacher,
    required (String, String)? range,
    required bool stackedTime,
  }) {
    final lines = <CourseBlockLine>[
      if (name.trim().isNotEmpty) CourseBlockLine(name, nameStyle),
      if (classroom.trim().isNotEmpty)
        CourseBlockLine(classroom, secondaryStyle),
      if (teacher.trim().isNotEmpty && teacher != classroom)
        CourseBlockLine(teacher, secondaryStyle),
    ];
    final timeText = range == null
        ? '时间未定'
        : stackedTime
        ? '${range.$1}\n${range.$2}'
        : '${range.$1}–${range.$2}';
    return CourseBlockContent(
      lines: lines,
      timeText: timeText,
      timeStyle: timeStyle,
      padding: padding,
      gap: gap,
    );
  }
}

/// 课程块里的一行：文字 + 它自己的样式。
class CourseBlockLine {
  const CourseBlockLine(this.text, this.style);

  final String text;
  final TextStyle style;
}

/// 课程块的完整内容与高度预算。
class CourseBlockContent {
  const CourseBlockContent({
    required this.lines,
    required this.timeText,
    required this.timeStyle,
    required this.padding,
    required this.gap,
  });

  /// 顶部信息：名称、地点、教师（按优先级）。
  final List<CourseBlockLine> lines;

  /// 固定在块底的时间（含「时间未定」），永不为 null。
  final String timeText;
  final TextStyle timeStyle;

  final EdgeInsets padding;
  final double gap;

  /// 在 [width] 宽的块里画完这些内容需要的高度。
  ///
  /// 用与渲染完全相同的 [TextScaler] 与样式测量，因此结果就是实际高度；
  /// 调用方在此基础上再留一点余量即可保证不裁切。
  double requiredHeight(double width, TextScaler scaler) {
    final inner = math.max(1.0, width - padding.horizontal);
    var height = padding.vertical;
    for (var index = 0; index < lines.length; index++) {
      if (index > 0) height += gap;
      height += measureTextHeight(
        lines[index].text,
        lines[index].style,
        inner,
        scaler,
      );
    }
    height += gap + measureTextHeight(timeText, timeStyle, inner, scaler);
    return height;
  }
}

/// 一行文字在给定宽度下实际占用的高度（多行自动折行，不截断）。
double measureTextHeight(
  String text,
  TextStyle style,
  double width,
  TextScaler scaler,
) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textScaler: scaler,
  )..layout(maxWidth: math.max(1, width));
  final height = painter.height;
  painter.dispose();
  return height;
}

/// 一行文字在单行排列下需要的宽度。
double measureTextWidth(String text, TextStyle style, TextScaler scaler) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textScaler: scaler,
    maxLines: 1,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

/// 给课程块用的一致性颜色读取（避免 Widget 里各写一份 alpha）。
extension CourseBlockPalette on AppPalette {
  Color courseSurface(Color tint, Brightness brightness) => Color.alphaBlend(
    tint.withValues(alpha: brightness == Brightness.dark ? 0.18 : 0.08),
    brightness == Brightness.dark ? surface : background,
  );
}
