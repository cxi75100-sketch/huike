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
    this.onDismissStarted,
    this.sourceRect,
    this.sourceRectProvider,
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

  /// Reads the live source geometry at dismiss time; return null when detached.
  final Rect? Function()? sourceRectProvider;

  /// 关闭动画结束后回调，调用方应把 [sheet] 置空。
  final VoidCallback onDismissed;

  /// 本次展示第一次进入关闭流程时通知调用方。
  final VoidCallback? onDismissStarted;

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
  final _hostStackKey = GlobalKey();
  var _dragging = false;
  var _dismissing = false;
  var _dismissed = false;
  var _geometryPending = false;
  var _geometryReady = false;
  var _geometryMeasurementQueued = false;
  var _geometryMeasurementAttempts = 0;
  Rect? _sourceInHost;
  Rect? _destinationInHost;
  Size? _geometryHostSize;
  Size? _geometryMediaSize;
  EdgeInsets? _geometryViewPadding;
  EdgeInsets? _geometryViewInsets;
  TextScaler? _geometryTextScaler;

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  double get _sheetHeight {
    final size = _sheetKey.currentContext?.size;
    if (size != null && size.height > 0) return size.height;
    final host = _hostStackKey.currentContext?.size;
    return host?.height ?? MediaQuery.sizeOf(context).height;
  }

  @override
  void didUpdateWidget(covariant GlassSheetHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sheet != null &&
        (oldWidget.sheet == null ||
            (_dismissing && widget.sheet!.key != oldWidget.sheet!.key))) {
      _dismissing = false;
      _dismissed = false;
      _dragging = false;
      _geometryMeasurementAttempts = 0;
      _geometryReady = false;
      _sourceInHost = null;
      _destinationInHost = null;
      if (widget.sourceRect != null) {
        _geometryPending = true;
        progress.value = 0;
      } else {
        _geometryPending = false;
        _open();
      }
    } else if (widget.sheet == null && oldWidget.sheet != null) {
      _geometryPending = false;
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
      ..animateWith(SpringSimulation(GlassMotion.sheetSpring, from, 1, 0))
          .then((_) {
            progress.value = 1;
          });
  }

  void _queueGeometryMeasurement() {
    if (!_geometryPending || _geometryMeasurementQueued) return;
    _geometryMeasurementQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _geometryMeasurementQueued = false;
      if (!mounted || !_geometryPending) return;
      final hostRender = _hostStackKey.currentContext?.findRenderObject();
      final sheetRender = _sheetKey.currentContext?.findRenderObject();
      if (hostRender is! RenderBox ||
          sheetRender is! RenderBox ||
          !hostRender.hasSize ||
          !sheetRender.hasSize ||
          sheetRender.size.isEmpty) {
        _retryOrFallbackGeometry();
        return;
      }

      final source = widget.sourceRect;
      final sourceInHost = source == null
          ? null
          : Rect.fromPoints(
              hostRender.globalToLocal(source.topLeft),
              hostRender.globalToLocal(source.bottomRight),
            );
      final destinationInHost = MatrixUtils.transformRect(
        sheetRender.getTransformTo(hostRender),
        Offset.zero & sheetRender.size,
      );
      final media = MediaQuery.of(context);
      if (sourceInHost == null ||
          sourceInHost.isEmpty ||
          destinationInHost.isEmpty) {
        _retryOrFallbackGeometry();
        return;
      }

      setState(() {
        _geometryPending = false;
        _geometryReady = true;
        _sourceInHost = sourceInHost;
        _destinationInHost = destinationInHost;
        _geometryHostSize = hostRender.size;
        _geometryMediaSize = media.size;
        _geometryViewPadding = media.viewPadding;
        _geometryViewInsets = media.viewInsets;
        _geometryTextScaler = media.textScaler;
      });
      _open();
    });
  }

  void _retryOrFallbackGeometry() {
    _geometryMeasurementAttempts++;
    if (_geometryMeasurementAttempts < 2) {
      _queueGeometryMeasurement();
      WidgetsBinding.instance.ensureVisualUpdate();
      return;
    }
    _geometryPending = false;
    _geometryReady = false;
    _open();
    if (mounted) setState(() {});
  }

  /// 所有关闭入口共用此状态转换；本次展示只完成一次。
  void close() => _dismiss();

  void _dismiss({double velocity = 0}) {
    if (widget.sheet == null || _dismissing || _dismissed) return;
    _refreshSourceGeometryForDismiss();
    _dismissing = true;
    _dragging = false;
    widget.onDismissStarted?.call();
    _settle(0, velocity: velocity);
  }

  void _refreshSourceGeometryForDismiss() {
    final provider = widget.sourceRectProvider;
    if (!_geometryReady || provider == null) return;
    final liveSource = provider();
    final host = _hostStackKey.currentContext?.findRenderObject();
    if (liveSource == null || host is! RenderBox || !host.hasSize) {
      _geometryReady = false;
      return;
    }
    final source = Rect.fromPoints(
      host.globalToLocal(liveSource.topLeft),
      host.globalToLocal(liveSource.bottomRight),
    );
    if (source.isEmpty || !source.overlaps(Offset.zero & host.size)) {
      _geometryReady = false;
      return;
    }
    final backgroundScale = 1 - widget.backgroundScale * progress.value;
    final center = host.size.center(Offset.zero);
    _sourceInHost = Rect.fromPoints(
      center + (source.topLeft - center) / backgroundScale,
      center + (source.bottomRight - center) / backgroundScale,
    );
  }

  void _finishDismiss() {
    if (!mounted || !_dismissing || _dismissed) return;
    _dismissed = true;
    widget.onDismissed();
  }

  void _handleDragStart(DragStartDetails details) {
    if (_dismissing) return;
    _dragging = true;
    progress.stop();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_dragging || _dismissing) return;
    final delta = details.primaryDelta ?? 0;
    progress.value = (progress.value - delta / _sheetHeight).clamp(0.0, 1.0);
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_dragging || _dismissing) return;
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
    if (target == 0) {
      _dismiss(velocity: velocity / _sheetHeight);
    } else {
      _settle(1, velocity: velocity / _sheetHeight);
    }
  }

  void _settle(double target, {double velocity = 0}) {
    if (_reduceMotion) {
      progress.value = target;
      if (target == 0) _finishDismiss();
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
      ).then((_) {
        progress.value = target;
        if (target == 0) _finishDismiss();
      });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = _reduceMotion;
    _queueGeometryMeasurement();
    return AnimatedBuilder(
      animation: progress,
      child: widget.background,
      builder: (context, background) {
        final value = progress.value.clamp(0.0, 1.0);
        final media = MediaQuery.of(context);
        final open = widget.sheet != null;
        final visible =
            open &&
            (_geometryPending ||
                _geometryReady ||
                _dismissing ||
                value > 0.001);
        return LayoutBuilder(
          builder: (context, constraints) {
            final hostSize = constraints.biggest;
            return Stack(
              key: _hostStackKey,
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
                        child: widget.maxBlur == 0
                            ? ColoredBox(
                                color: Colors.black.withValues(
                                  alpha: widget.maxDim * value,
                                ),
                              )
                            : BackdropFilter(
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
                    child: IgnorePointer(
                      ignoring: _dismissing,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: close,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                  Builder(
                    builder: (context) {
                      final sheet = IgnorePointer(
                        ignoring: _dismissing,
                        child: GestureDetector(
                          behavior: HitTestBehavior.deferToChild,
                          onVerticalDragStart: reduceMotion
                              ? null
                              : _handleDragStart,
                          onVerticalDragUpdate: reduceMotion
                              ? null
                              : _handleDragUpdate,
                          onVerticalDragEnd: reduceMotion
                              ? null
                              : _handleDragEnd,
                          child: GlassSheetScope(
                            progress: progress,
                            revealContent:
                                _geometryReady && widget.sourceRect != null,
                            child: KeyedSubtree(
                              key: _sheetKey,
                              child: KeyedSubtree(
                                key: const ValueKey(
                                  'glass-sheet-measured-content',
                                ),
                                child: widget.sheet ?? const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ),
                      );
                      final source = _sourceInHost;
                      final destination = _destinationInHost;
                      final canUseGeometry =
                          !reduceMotion &&
                          _geometryReady &&
                          source != null &&
                          destination != null &&
                          hostSize == _geometryHostSize &&
                          media.size == _geometryMediaSize &&
                          media.viewPadding == _geometryViewPadding &&
                          media.viewInsets == _geometryViewInsets &&
                          media.textScaler == _geometryTextScaler;
                      final geometryProgress = value;
                      final box = KeyedSubtree(
                        key: const ValueKey('glass-sheet-geometry-container'),
                        child: _geometryPending
                            ? Opacity(opacity: 0, child: sheet)
                            : sheet,
                      );
                      if (canUseGeometry) {
                        return Positioned.fromRect(
                          rect: Rect.lerp(
                            source,
                            destination,
                            geometryProgress,
                          )!,
                          child: box,
                        );
                      }
                      if (_geometryPending) {
                        return Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: box,
                        );
                      }
                      return Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: FractionalTranslation(
                          translation: Offset(0, 1 - value),
                          child: box,
                        ),
                      );
                    },
                  ),
                ],
              ],
            );
          },
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
    this.revealContent = false,
    required super.child,
  }) : super(notifier: progress);

  final bool revealContent;

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
    this.blurSigma = 22,
    this.maxHeightFactor = 0.72,
    this.closeLabel = '关闭',
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final VoidCallback? onClose;
  final Color? tint;
  final double blurSigma;
  final double maxHeightFactor;
  final String closeLabel;

  @override
  Widget build(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<GlassSheetScope>();
    final progress = scope?.notifier;
    final revealContent = scope?.revealContent ?? false;
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
      blurSigma: blurSigma,
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
        child: Opacity(
          opacity: revealContent && progress != null
              ? ((progress.value - 0.65) / 0.35).clamp(0.0, 1.0)
              : 1,
          child: content,
        ),
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
