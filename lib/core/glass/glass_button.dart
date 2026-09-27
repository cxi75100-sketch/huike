import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'glass_surface.dart';

/// 玻璃控制：GlassSurface + 指针反馈 + 语义 + 提示。
///
/// 全 App 的按钮类交互都走这里：周导航箭头、顶部图标、今日快捷、加课、
/// Sheet 关闭……统一按压物理（压缩 → 高光跟随 → 弹簧回位），不使用
/// InkWell / InkSplash / InkSparkle。
enum GlassButtonShape { circle, rounded, square }

class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.onPressed,
    this.icon,
    this.label,
    this.tooltip,
    this.semanticLabel,
    this.onLongPress,
    this.shape = GlassButtonShape.rounded,
    this.size = 40,
    this.intensity = GlassIntensity.regular,
    this.radius,
    this.iconSize = 20,
    this.padding,
    this.depth = 1,
    this.iconColor,
    this.labelStyle,
    this.tint,
    this.tapTarget = 44,
  });

  /// 圆形图标控制。
  const GlassButton.icon({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.semanticLabel,
    this.onLongPress,
    this.size = 36,
    this.intensity = GlassIntensity.regular,
    this.iconSize = 19,
    this.depth = 1,
    this.iconColor,
    this.tint,
    this.tapTarget = 44,
    this.radius,
    this.padding,
    this.label,
    this.labelStyle,
  }) : shape = GlassButtonShape.circle;

  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final IconData? icon;
  final String? label;
  final String? tooltip;
  final String? semanticLabel;
  final GlassButtonShape shape;
  final double size;
  final GlassIntensity intensity;
  final double? radius;
  final double iconSize;
  final EdgeInsets? padding;
  final double depth;
  final Color? iconColor;
  final TextStyle? labelStyle;
  final Color? tint;
  final double tapTarget;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    final enabled = onPressed != null || onLongPress != null;
    final foreground = enabled
        ? (iconColor ?? palette.inkSecondary)
        : palette.inkTertiary.withValues(alpha: 0.45);
    final effectiveRadius = radius ?? _defaultRadius;
    final effectivePadding =
        padding ??
        switch (shape) {
          GlassButtonShape.circle => EdgeInsets.zero,
          GlassButtonShape.rounded => const EdgeInsets.symmetric(
            horizontal: 14,
          ),
          GlassButtonShape.square => const EdgeInsets.symmetric(horizontal: 12),
        };

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) Icon(icon, size: iconSize, color: foreground),
        if (icon != null && label != null) const SizedBox(width: 7),
        if (label != null)
          Text(
            label!,
            style:
                labelStyle ??
                TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: enabled ? palette.ink : foreground,
                ),
          ),
      ],
    );

    Widget visual = GlassSurface(
      radius: effectiveRadius,
      intensity: enabled ? intensity : GlassIntensity.subtle,
      tint: tint,
      interactive: enabled,
      onTap: onPressed,
      onLongPress: onLongPress,
      padding: effectivePadding,
      depth: enabled ? depth : depth * 0.35,
      childPressScale: 0.9,
      child: SizedBox(
        width: shape == GlassButtonShape.circle ? size : null,
        height: size,
        child: Center(child: content),
      ),
    );

    Widget result = ConstrainedBox(
      constraints: BoxConstraints(minWidth: tapTarget, minHeight: tapTarget),
      // heightFactor 固定为 1：`Scaffold.bottomNavigationBar` 用松约束布局，
      // 未收缩的 Center 会纵向撑满整屏，把 body 挤成 0 高（见 TASK-018A）。
      child: Center(heightFactor: 1, child: visual),
    );

    final tip = tooltip;
    if (tip != null) {
      result = Tooltip(message: tip, excludeFromSemantics: true, child: result);
    }

    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: semanticLabel ?? tip ?? label,
      onTap: enabled ? onPressed : null,
      child: result,
    );
  }

  double get _defaultRadius => switch (shape) {
    GlassButtonShape.circle => size / 2,
    GlassButtonShape.rounded => 14,
    GlassButtonShape.square => 16,
  };
}
