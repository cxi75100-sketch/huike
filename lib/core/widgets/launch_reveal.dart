import 'package:flutter/material.dart';

import '../glass/glass_motion.dart';
import 'ambient_backdrop.dart';

/// One reveal per app tree, never per route or lifecycle resume.
class LaunchReveal extends StatefulWidget {
  const LaunchReveal({super.key, required this.ready, required this.child});

  final bool ready;
  final Widget child;

  @override
  State<LaunchReveal> createState() => _LaunchRevealState();
}

class _LaunchRevealState extends State<LaunchReveal>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: GlassMotion.standard,
  );
  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: GlassMotion.enter,
  );
  bool _revealed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _start();
  }

  @override
  void didUpdateWidget(covariant LaunchReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    _start();
  }

  void _start() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    }
    if (!widget.ready || _revealed) return;
    _revealed = true;
    if (!MediaQuery.disableAnimationsOf(context)) _controller.forward();
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AmbientBackdrop(
    child: widget.ready || _revealed
        ? AnimatedBuilder(
            animation: _curve,
            child: widget.child,
            builder: (context, child) {
              final reduced = MediaQuery.disableAnimationsOf(context);
              final progress = reduced ? 1.0 : _curve.value;
              return Transform.translate(
                offset: Offset(0, 4 * (1 - progress)),
                child: Opacity(opacity: 0.92 + 0.08 * progress, child: child),
              );
            },
          )
        : const SizedBox.expand(),
  );
}
