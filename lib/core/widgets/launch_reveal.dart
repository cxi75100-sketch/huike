import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../glass/glass_motion.dart';
import '../theme/app_palette.dart';
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
    duration: GlassMotion.slow,
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
  Widget build(BuildContext context) {
    // The launch presentation stays light even when the destination is dark.
    final palette = AppPalette.light;
    return AmbientBackdrop(
      child: Listener(
        // The first interaction completes the decorative reveal immediately.
        // The content remains mounted and receives that same pointer event.
        onPointerDown: (_) {
          if (_revealed && _controller.value < 1) _controller.value = 1;
        },
        child: AnimatedBuilder(
          animation: _curve,
          child: widget.child,
          builder: (context, child) {
            final reduced = MediaQuery.disableAnimationsOf(context);
            final progress = !_revealed
                ? 0.0
                : reduced
                ? 1.0
                : _curve.value;
            final destination = Theme.of(context).brightness == Brightness.dark
                ? AppPalette.dark.background
                : AppPalette.light.background;
            final darkIcons =
                Color.lerp(
                  palette.background,
                  destination,
                  progress,
                )!.computeLuminance() >=
                0.179;
            final systemStyle = SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: darkIcons
                  ? Brightness.dark
                  : Brightness.light,
              statusBarBrightness: darkIcons
                  ? Brightness.light
                  : Brightness.dark,
              systemNavigationBarColor: progress < 1
                  ? palette.background
                  : Colors.transparent,
              systemNavigationBarIconBrightness: progress < 1 || darkIcons
                  ? Brightness.dark
                  : Brightness.light,
              systemStatusBarContrastEnforced: false,
              systemNavigationBarContrastEnforced: false,
            );
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: systemStyle,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.ready || _revealed)
                    Transform.translate(
                      offset: Offset(0, 4 * (1 - progress)),
                      child: child,
                    ),
                  if (progress < 1)
                    Positioned.fill(
                      child: AnnotatedRegion<SystemUiOverlayStyle>(
                        key: const ValueKey('launch-system-style'),
                        value: systemStyle,
                        child: IgnorePointer(
                          child: ExcludeSemantics(
                            child: Opacity(
                              key: const ValueKey('launch-brand-overlay'),
                              opacity: 1 - progress,
                              child: ColoredBox(
                                color: palette.background,
                                child: Center(
                                  child: Transform.translate(
                                    offset: Offset(0, -12 * progress),
                                    child: Transform.scale(
                                      scale: 1 - 0.08 * progress,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const FlutterLogo(size: 96),
                                          const SizedBox(height: 24),
                                          Text(
                                            '汇课',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 4,
                                              color: palette.ink,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
