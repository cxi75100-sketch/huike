import 'package:flutter/material.dart';

import 'glass_metrics.dart';
import 'glass_motion.dart';

/// Paint-only transition for ordinary pages/overlays. The content subtree is
/// retained; no scale, additional blur, or animated layout is introduced.
class GlassTransition extends StatefulWidget {
  const GlassTransition({
    super.key,
    required this.animation,
    required this.child,
    this.travel = GlassMetrics.pageTravel,
  });

  final Animation<double> animation;
  final Widget child;
  final double travel;

  @override
  State<GlassTransition> createState() => _GlassTransitionState();
}

class _GlassTransitionState extends State<GlassTransition> {
  late CurvedAnimation _motion;

  void _attach() {
    _motion = CurvedAnimation(
      parent: widget.animation,
      curve: GlassMotion.enter,
      reverseCurve: GlassMotion.exit,
    );
  }

  @override
  void initState() {
    super.initState();
    _attach();
  }

  @override
  void didUpdateWidget(covariant GlassTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      _motion.dispose();
      _attach();
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _motion,
      child: widget.child,
      builder: (context, child) {
        // CurvedAnimation latches its direction across an interrupted push/pop,
        // so reversing halfway cannot jump to a different curve value.
        final value = _motion.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, reduced ? 0 : widget.travel * (1 - value)),
            child: child,
          ),
        );
      },
    );
  }
}

/// Applies only to explicitly opted-in ordinary snackbar callers. Import's
/// feedback and session logic are outside the general motion audit.
AnimationStyle glassSnackBarStyle(BuildContext context) {
  final reduced = MediaQuery.disableAnimationsOf(context);
  return AnimationStyle(
    duration: reduced ? Duration.zero : GlassMotion.snackEnter,
    reverseDuration: reduced ? Duration.zero : GlassMotion.snackExit,
  );
}
