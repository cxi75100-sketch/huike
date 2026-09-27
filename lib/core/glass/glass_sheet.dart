import 'dart:ui' show FontFeature, ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../theme/app_theme.dart';
import 'glass_button.dart';
import 'glass_motion.dart';
import 'glass_surface.dart';

/// 玻璃 Sheet 宿主。
///
/// 一个 [AnimationController]（0 关闭 → 1 完全展开）同时驱动：
/// - Sheet 位移（`FractionalTranslation`，跟手且不需要预先知道高度）；
/// - 背景缩放（1 → 0.982）；
/// - 背景模糊（0 → [maxBlur]）；
/// - 背景压暗（0 → [maxDim]）；
/// - Sheet 圆角与边缘高光（[GlassSheetScope]）。
///
/// 没有 Material `BottomSheet` 的默认动画，也没有四个互不相关的动画：
/// 骨架列表在 Sheet 升起时留在原位、退到后面，Sheet 是在课表「上面升起来」。
class GlassSheetHost extends StatefulWidget {
  const GlassSheetHost({
    super.key,
    required this.background,
    required this.sheet,
    required this.onDismissed,
    this.sourceRect,
    this.backgroundScale = 0.018,
    this.maxBlur = 14,
    this.maxDim = 0.16,
    this.closeThreshold = 0.72,
    this.flickVelocity = 900,
  });

  /// 页面内容（LEVEL 1–3）。
  final Widget background;

  /// Sheet 内容（LEVEL 5）；为空表示关闭。
  final Widget? sheet;

  /// Source course block in global coordinates for a shared-element-like flight.
  final Rect? sourceRect;

  /// 关闭动画结束后回调，调用方应把 [sheet] 置空。
  final VoidCallback onDismissed;

  final double backgroundScale;
  final double maxBlur;
  final double maxDim;

  /// 拖过该比例即关闭（按位置判定）。
  final double closeThreshold;

  /// 向下甩过的速度（px/s）即关闭，不看位置。
  final double flickVelocity;

  @override
  State<GlassSheetHost> createState() => GlassSheetHostState();
}

class GlassSheetHostState extends State<GlassSheetHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController progress = AnimationController(
    vsync: this,
    duration: GlassMotion.slow,
  );

  final _sheetKey = GlobalKey();
  var _dragging = false;

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  double get _sheetHeight {
    final size = _sheetKey.currentContext?.size;
    if (size != null && size.height > 0) return size.height;
    return MediaQuery.sizeOf(context).height * 0.5;
  }

  @override
  void didUpdateWidget(covariant GlassSheetHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sheet != null && oldWidget.sheet == null) {
      _open();
    } else if (widget.sheet == null && oldWidget.sheet != null) {
      progress.value = 0;
    }
  }

  @override
  void dispose() {
    progress.dispose();
    super.dispose();
  }

  void _open() {
    final from = progress.value;
    if (_reduceMotion) {
      progress.value = 1;
      return;
    }
    progress
      ..stop()
      ..animateWith(SpringSimulation(GlassMotion.sheetSpring, from, 1, 0));
  }

  /// 外部（例如点按背景）请求关闭。
  void close() => _settle(0);

  void _handleDragStart(DragStartDetails details) {
    _dragging = true;
    progress.stop();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_dragging) return;
    final delta = details.primaryDelta ?? 0;
    progress.value = (progress.value - delta / _sheetHeight).clamp(0.0, 1.0);
  }

  void _handleDragEnd(DragEndDetails details) {
    _dragging = false;
    final velocity = details.primaryVelocity ?? 0;
    final double target;
    if (velocity > widget.flickVelocity) {
      target = 0;
    } else if (velocity < -widget.flickVelocity) {
      target = 1;
    } else {
      target = progress.value < widget.closeThreshold ? 0 : 1;
    }
    _settle(target, velocity: velocity / _sheetHeight);
  }

  void _settle(double target, {double velocity = 0}) {
    if (_reduceMotion) {
      progress.value = target;
      if (target == 0) widget.onDismissed();
      return;
    }
    progress
      ..stop()
      ..animateWith(
        SpringSimulation(
          GlassMotion.sheetSpring,
          progress.value,
          target,
          velocity,
        ),
      ).whenCompleteOrCancel(() {
        if (target == 0 && mounted) widget.onDismissed();
      });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = _reduceMotion;
    return AnimatedBuilder(
      animation: progress,
      child: widget.background,
      builder: (context, background) {
        final value = progress.value.clamp(0.0, 1.0);
        final open = widget.sheet != null;
        final visible = open && value > 0.001;
        return Stack(
          fit: StackFit.expand,
          children: [
            Transform.scale(
              scale: open ? 1 - widget.backgroundScale * value : 1,
              child: background,
            ),
            if (visible) ...[
              Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: widget.maxBlur * value,
                        sigmaY: widget.maxBlur * value,
                      ),
                      child: ColoredBox(
                        color: Colors.black.withValues(
                          alpha: widget.maxDim * value,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: close,
                  child: const SizedBox.expand(),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Builder(
                  builder: (context) {
                    final sheet = GestureDetector(
                      behavior: HitTestBehavior.deferToChild,
                      onVerticalDragStart: reduceMotion
                          ? null
                          : _handleDragStart,
                      onVerticalDragUpdate: reduceMotion
                          ? null
                          : _handleDragUpdate,
                      onVerticalDragEnd: reduceMotion ? null : _handleDragEnd,
                      child: GlassSheetScope(
                        progress: progress,
                        child: KeyedSubtree(
                          key: _sheetKey,
                          child: widget.sheet ?? const SizedBox.shrink(),
                        ),
                      ),
                    );
                    final source = reduceMotion ? null : widget.sourceRect;
                    if (source == null) {
                      return FractionalTranslation(
                        translation: Offset(0, 1 - value),
                        child: sheet,
                      );
                    }
                    final size = MediaQuery.sizeOf(context);
                    // The sheet's RenderBox is not safe to query during build.
                    // Drag callbacks use its measured height after layout.
                    final height = size.height * 0.5;
                    final progressValue = Curves.easeOutCubic.transform(value);
                    final scaleX =
                        source.width / size.width * (1 - progressValue) +
                        progressValue;
                    final scaleY =
                        source.height / height * (1 - progressValue) +
                        progressValue;
                    return Transform.translate(
                      offset: Offset(
                        source.left * (1 - progressValue),
                        (source.top - (size.height - height)) *
                            (1 - progressValue),
                      ),
                      child: Transform.scale(
                        alignment: Alignment.topLeft,
                        scaleX: scaleX.clamp(0.05, 1),
                        scaleY: scaleY.clamp(0.05, 1),
                        child: sheet,
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// 让 Sheet 内容读到拖动进度（圆角、边缘高光随拖动变化）。
class GlassSheetScope extends InheritedNotifier<AnimationController> {
  const GlassSheetScope({
    super.key,
    required AnimationController progress,
    required super.child,
  }) : super(notifier: progress);

  static AnimationController? progressOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GlassSheetScope>()?.notifier;
}

/// 玻璃 Sheet 面板：拖动手柄 + 标题 + 内容。
///
/// 位置由 [GlassSheetHost] 用同一个进度驱动；这里只提供视觉与拖动区。
class GlassSheetPanel extends StatelessWidget {
  const GlassSheetPanel({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.onClose,
    this.tint,
    this.maxHeightFactor = 0.72,
    this.closeLabel = '关闭',
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final VoidCallback? onClose;
  final Color? tint;
  final double maxHeightFactor;
  final String closeLabel;

  @override
  Widget build(BuildContext context) {
    final progress = GlassSheetScope.progressOf(context);
    final size = MediaQuery.sizeOf(context);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SheetGrabber(),
        if (title != null) ...[
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SheetTitle(title: title!, subtitle: subtitle),
              ),
              if (onClose != null)
                GlassButton.icon(
                  icon: Icons.close_rounded,
                  tooltip: closeLabel,
                  semanticLabel: closeLabel,
                  onPressed: onClose,
                  size: 32,
                  iconSize: 18,
                  depth: 0.2,
                ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Flexible(child: child),
      ],
    );

    Widget panel(double value) => GlassSurface(
      radius: 26 - 6 * value,
      intensity: GlassIntensity.prominent,
      blurSigma: 22,
      tint: tint,
      depth: 2.2,
      // 让开系统手势条：面板自己贴底，没有路由来帮它做 SafeArea。
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        18 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: size.height * maxHeightFactor,
          minHeight: 0,
        ),
        child: content,
      ),
    );

    if (progress == null) return panel(1);
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) => panel(progress.value.clamp(0.0, 1.0)),
    );
  }
}

class _SheetGrabber extends StatelessWidget {
  const _SheetGrabber();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppTheme.paletteOf(context).hairlineStrong,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 21,
            height: 1.2,
            fontWeight: FontWeight.w700,
            color: palette.ink,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 12.5,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: palette.inkSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
