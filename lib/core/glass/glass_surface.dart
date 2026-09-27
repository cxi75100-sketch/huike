import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_theme.dart';
import 'press_physics.dart';
import 'glass_metrics.dart';

/// 玻璃强度：决定材质底色不透明度与默认模糊半径。
enum GlassIntensity { subtle, regular, prominent }

/// 动态玻璃表面：整页唯一允许使用 BackdropFilter 的载体。
///
/// 五层结构（自下而上）：
/// 1. `BackdropFilter` —— 折射背后的真实内容（网格、环境底色）；
/// 2. 半透明材质底色 —— 左上偏亮、右下偏暗的方向性渐变，不是一块纯色；
/// 3. 方向性照明 —— 极轻的白色照明，按压时增强一点；
/// 4. 触摸高光 —— 位置跟随手指，强度跟随按压进度，最大也不到 10%；
/// 5. 发丝边缘 —— 左上亮、右下暗的一圈 1px 边线 + 向外投影（按压时减弱）。
///
/// 指针与按压物理来自 [PressPhysics]（全 App 唯一一份），
/// 因此这里不使用 InkWell / InkSplash，也不会出现 ripple。
/// 也可以完全由外部进度驱动（[pressDriver] / [touchDriver]）：
/// Sheet 拖动、切周跟手就是这种用法。
///
/// 性能约定：一条玻璃 = 一个 `RepaintBoundary` + 一次 `BackdropFilter`；
/// 触摸移动只重建这一个表面，不触发页面重绘。
class GlassSurface extends StatefulWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.radius = GlassMetrics.controlRadius,
    this.borderRadius,
    this.intensity = GlassIntensity.regular,
    this.blurSigma,
    this.tint,
    this.interactive = false,
    this.onTap,
    this.onLongPress,
    this.pressDriver,
    this.touchDriver,
    this.padding = EdgeInsets.zero,
    this.surfaceScale = GlassMetrics.pressScale,
    this.childPressScale = 1,
    this.depth = 1,
    this.showEdge = true,
    this.semanticLabel,
    this.tooltip,
  });

  final Widget child;
  final double radius;

  /// 非对称圆角（例如只让顶部两个角圆起来）；给了就优先于 [radius]。
  final BorderRadius? borderRadius;

  final GlassIntensity intensity;
  final double? blurSigma;

  /// 可选课程色 / 强调色染色，仍然保持极低不透明度。
  final Color? tint;

  final bool interactive;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// 外部按压进度（0 空闲 → 1 完全按下）。
  final ValueListenable<double>? pressDriver;

  /// 外部触摸高光位置。
  final ValueListenable<Alignment>? touchDriver;

  final EdgeInsets padding;

  /// 按下时表面整体压缩比例。
  final double surfaceScale;

  /// 按下时内容（图标/文字）压缩到该比例，1 表示内容不缩放。
  final double childPressScale;

  /// 投影强度倍率（浮得越高越大）。
  final double depth;

  final bool showEdge;
  final String? semanticLabel;
  final String? tooltip;

  /// 空闲时高光停在的位置：左上一点，像自然光。
  static const restHighlight = Alignment(-0.55, -0.75);

  /// 实际生效的圆角。
  BorderRadius get effectiveRadius =>
      borderRadius ?? BorderRadius.circular(radius);

  static double sigmaOf(GlassIntensity intensity) => switch (intensity) {
    GlassIntensity.subtle => GlassMetrics.subtleBlur,
    GlassIntensity.regular => GlassMetrics.regularBlur,
    GlassIntensity.prominent => GlassMetrics.prominentBlur,
  };

  @override
  State<GlassSurface> createState() => _GlassSurfaceState();
}

class _GlassSurfaceState extends State<GlassSurface> {
  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final sigma = widget.blurSigma ?? GlassSurface.sigmaOf(widget.intensity);
    final depth = widget.depth;
    final borderRadius = widget.effectiveRadius;

    Widget surface = PressPhysics(
      enabled: widget.interactive,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      pressDriver: widget.pressDriver,
      touchDriver: widget.touchDriver,
      trackTouch: true,
      restTouch: GlassSurface.restHighlight,
      child: widget.child,
      builder: (context, press, touch, child) {
        return Transform.scale(
          scale: 1 - widget.surfaceScale * (_reduceMotion ? 0 : press),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: (dark ? 0.42 : 0.09) * depth * (1 - 0.45 * press),
                  ),
                  blurRadius: 18 * depth * (1 - 0.35 * press),
                  spreadRadius: -2,
                  offset: Offset(0, 7 * depth * (1 - 0.4 * press)),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: borderRadius,
              child: _maybeBlur(
                sigma: sigma,
                child: CustomPaint(
                  painter: _GlassSurfacePainter(
                    palette: palette,
                    dark: dark,
                    borderRadius: borderRadius,
                    intensity: widget.intensity,
                    tint: widget.tint,
                    press: press,
                    highlight: touch,
                    showEdge: widget.showEdge,
                  ),
                  child: Transform.scale(
                    scale:
                        1 -
                        (1 - widget.childPressScale) *
                            (_reduceMotion ? 0 : press),
                    child: RepaintBoundary(
                      child: Padding(padding: widget.padding, child: child),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    surface = RepaintBoundary(child: surface);

    final label = widget.semanticLabel;
    if (label != null) {
      surface = Semantics(
        container: true,
        label: label,
        button: widget.onTap != null,
        child: surface,
      );
    }
    final tooltip = widget.tooltip;
    if (tooltip != null) {
      surface = Tooltip(message: tooltip, child: surface);
    }
    return surface;
  }

  /// 模糊为 0 时干脆不建滤镜层：模糊只花在真正需要折射的地方。
  Widget _maybeBlur({required double sigma, required Widget child}) {
    if (sigma <= 0) return child;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: child,
    );
  }
}

class _GlassSurfacePainter extends CustomPainter {
  const _GlassSurfacePainter({
    required this.palette,
    required this.dark,
    required this.borderRadius,
    required this.intensity,
    required this.tint,
    required this.press,
    required this.highlight,
    required this.showEdge,
  });

  final AppPalette palette;
  final bool dark;
  final BorderRadius borderRadius;
  final GlassIntensity intensity;
  final Color? tint;
  final double press;
  final Alignment highlight;
  final bool showEdge;

  double get _fillAlpha => switch (intensity) {
    GlassIntensity.subtle => dark ? 0.52 : 0.62,
    GlassIntensity.regular => dark ? 0.62 : 0.72,
    GlassIntensity.prominent => dark ? 0.74 : 0.84,
  };

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndCorners(
      rect,
      topLeft: borderRadius.topLeft,
      topRight: borderRadius.topRight,
      bottomLeft: borderRadius.bottomLeft,
      bottomRight: borderRadius.bottomRight,
    );
    final base = tint == null
        ? palette.surface
        : Color.alphaBlend(
            tint!.withValues(alpha: dark ? 0.3 : 0.16),
            palette.surface,
          );

    canvas.save();
    canvas.clipRRect(rrect);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            base.withValues(
              alpha: (_fillAlpha + (dark ? 0.02 : 0.08)).clamp(0.0, 1.0),
            ),
            base.withValues(
              alpha: (_fillAlpha - (dark ? 0.08 : 0.16)).clamp(0.0, 1.0),
            ),
          ],
        ).createShader(rect),
    );

    // 方向性照明：左上极轻提亮，按压时略强（材质被点亮而不是变白）。
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: const Alignment(0.5, 0.95),
          colors: dark
              ? [
                  Colors.white.withValues(alpha: 0.04 + 0.05 * press),
                  Colors.white.withValues(alpha: 0),
                ]
              : [
                  Colors.white.withValues(alpha: 0.3 + 0.16 * press),
                  Colors.white.withValues(alpha: 0.01),
                ],
        ).createShader(rect),
    );

    // 触摸高光：跟随手指，强度克制。
    if (press > 0.002) {
      final center = Alignment(
        highlight.x.clamp(-1.0, 1.0),
        highlight.y.clamp(-1.0, 1.0),
      );
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            center: center,
            radius: 0.9,
            colors: dark
                ? [
                    Colors.white.withValues(alpha: 0.12 * press),
                    Colors.white.withValues(alpha: 0),
                  ]
                : [
                    palette.accent.withValues(alpha: 0.08 * press),
                    palette.accent.withValues(alpha: 0),
                  ],
          ).createShader(rect),
      );
    }

    canvas.restore();

    if (!showEdge) return;
    canvas.drawRRect(
      rrect.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? [
                  Colors.white.withValues(alpha: 0.18 + 0.1 * press),
                  Colors.white.withValues(alpha: 0.02),
                  Colors.black.withValues(alpha: 0.45),
                ]
              : [
                  Colors.white.withValues(alpha: 0.85),
                  palette.hairline.withValues(alpha: 0.6),
                  Colors.black.withValues(alpha: 0.05),
                ],
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _GlassSurfacePainter old) =>
      old.palette != palette ||
      old.dark != dark ||
      old.borderRadius != borderRadius ||
      old.intensity != intensity ||
      old.tint != tint ||
      old.press != press ||
      old.highlight != highlight ||
      old.showEdge != showEdge;
}
