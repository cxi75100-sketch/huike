import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import 'glass_motion.dart';

/// 统一的按压物理。
///
/// 全 App 只有这一处指针代码：按下 → 快速压缩（[GlassMotion.fast]）、
/// 指针移动 → 高光位置平滑跟随、抬起 → 弹簧回位。玻璃表面、课程块、
/// 加课按钮、Sheet 关闭按钮全部复用它，谁也不许再写一份 `AnimatedScale`。
///
/// 也可以完全由外部进度驱动（[pressDriver] / [touchDriver]）：
/// 用于 Sheet 拖动、切周跟手这类「进度来自手势而不是按压」的场景。
class PressPhysics extends StatefulWidget {
  const PressPhysics({
    super.key,
    required this.builder,
    this.child,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.pressDriver,
    this.touchDriver,
    this.trackTouch = false,
    this.restTouch = const Alignment(-0.55, -0.75),
    this.hoverProgress = 0.3,
    this.hitTestBehavior = HitTestBehavior.opaque,
  });

  /// press: 0（空闲）→ 1（完全按下）；touch: 高光中心（-1…1）。
  final Widget Function(
    BuildContext context,
    double press,
    Alignment touch,
    Widget? child,
  )
  builder;

  /// 传给 builder 的不透明子树：每帧只重排外壳，不重建它。
  final Widget? child;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;

  /// 外部按压进度（非空时不接管指针）。
  final ValueListenable<double>? pressDriver;

  /// 外部高光位置（非空时不接管指针）。
  final ValueListenable<Alignment>? touchDriver;

  /// 是否把指针位置映射为高光位置。
  final bool trackTouch;

  /// 空闲时高光停留位置。
  final Alignment restTouch;

  /// 指针悬停（桌面）贡献的进度；0 表示忽略悬停。
  final double hoverProgress;

  final HitTestBehavior hitTestBehavior;

  @override
  State<PressPhysics> createState() => _PressPhysicsState();
}

class _PressPhysicsState extends State<PressPhysics>
    with TickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: GlassMotion.fast,
  );
  late final AnimationController _follow = AnimationController(
    vsync: this,
    duration: GlassMotion.touchFollow,
    value: 1,
  );

  Alignment _from = const Alignment(-0.55, -0.75);
  Alignment _to = const Alignment(-0.55, -0.75);
  var _hovering = false;

  @override
  void initState() {
    super.initState();
    _from = widget.restTouch;
    _to = widget.restTouch;
  }

  @override
  void dispose() {
    _press.dispose();
    _follow.dispose();
    super.dispose();
  }

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  double get _pressValue {
    final driver = widget.pressDriver;
    if (driver != null) return driver.value.clamp(0.0, 1.0);
    final hover = _hovering ? widget.hoverProgress : 0.0;
    return (_press.value >= hover ? _press.value : hover).clamp(0.0, 1.0);
  }

  Alignment get _touchValue {
    final driver = widget.touchDriver;
    if (driver != null) return driver.value;
    if (!widget.trackTouch) return widget.restTouch;
    final t = GlassMotion.enter.transform(_follow.value.clamp(0.0, 1.0));
    return Alignment.lerp(_from, _to, t) ?? _to;
  }

  void _moveTouchTo(Alignment target) {
    if (!widget.trackTouch || widget.touchDriver != null) return;
    _from = _touchValue;
    _to = target;
    if (_reduceMotion) {
      _follow.value = 1;
    } else {
      _follow.forward(from: 0);
    }
  }

  Alignment _alignmentFor(Offset local) {
    final bounds = context.size;
    if (bounds == null || bounds.isEmpty) return Alignment.center;
    final x = (local.dx / bounds.width) * 2 - 1;
    final y = (local.dy / bounds.height) * 2 - 1;
    return Alignment(x.clamp(-1.0, 1.0), y.clamp(-1.0, 1.0));
  }

  void _handleDown(PointerDownEvent event) {
    if (!widget.enabled) return;
    _moveTouchTo(_alignmentFor(event.localPosition));
    if (_reduceMotion) {
      _press.value = 1;
    } else {
      _press.animateTo(1, duration: GlassMotion.fast, curve: GlassMotion.enter);
    }
  }

  void _handleMove(PointerMoveEvent event) {
    if (!widget.enabled) return;
    _moveTouchTo(_alignmentFor(event.localPosition));
  }

  void _handleUp() {
    if (!widget.enabled) return;
    if (_reduceMotion) {
      _press.value = 0;
      return;
    }
    _press.animateWith(
      SpringSimulation(
        GlassMotion.releaseSpring,
        _press.value,
        0,
        _press.velocity,
      ),
    );
    _moveTouchTo(widget.restTouch);
  }

  @override
  Widget build(BuildContext context) {
    final inner = AnimatedBuilder(
      animation: Listenable.merge([
        _press,
        _follow,
        widget.pressDriver,
        widget.touchDriver,
      ]),
      child: widget.child,
      builder: (context, child) =>
          widget.builder(context, _pressValue, _touchValue, child),
    );

    // 进度由外部驱动时不接管指针（Sheet 拖动、切周跟手）。
    if (widget.pressDriver != null ||
        widget.touchDriver != null ||
        !widget.enabled) {
      return inner;
    }

    return Listener(
      onPointerDown: _handleDown,
      onPointerMove: _handleMove,
      onPointerUp: (_) => _handleUp(),
      onPointerCancel: (_) => _handleUp(),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          behavior: widget.hitTestBehavior,
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          child: inner,
        ),
      ),
    );
  }
}
