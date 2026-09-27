import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/glass/glass_motion.dart';
import '../../../core/glass/glass_surface.dart';
import '../../../core/theme/app_theme.dart';

/// Floating plus control that opens a compact, anchored glass action menu.
class LiquidAddButton extends StatefulWidget {
  const LiquidAddButton({
    super.key,
    required this.onPressed,
    required this.scrolling,
    this.onImport,
    this.onAddEvent,
  });

  final VoidCallback onPressed;
  final VoidCallback? onImport;
  final VoidCallback? onAddEvent;
  final ValueListenable<bool> scrolling;

  @override
  State<LiquidAddButton> createState() => _LiquidAddButtonState();
}

class _LiquidAddButtonState extends State<LiquidAddButton>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: GlassMotion.menu,
    reverseDuration: GlassMotion.standard,
  );
  late final CurvedAnimation _motion = CurvedAnimation(
    parent: _progress,
    curve: GlassMotion.enter,
    reverseCurve: GlassMotion.exit,
  );

  @override
  void dispose() {
    _motion.dispose();
    _progress.dispose();
    super.dispose();
  }

  void _setExpanded(bool value) {
    setState(() => _expanded = value);
    if (MediaQuery.disableAnimationsOf(context)) {
      _progress.value = value ? 1 : 0;
    } else if (value) {
      _progress.forward();
    } else {
      _progress.reverse();
    }
  }

  void _select(VoidCallback? action) {
    _setExpanded(false);
    action?.call();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    final reduced = MediaQuery.disableAnimationsOf(context);
    return ValueListenableBuilder<bool>(
      valueListenable: widget.scrolling,
      builder: (context, scrolling, child) => AnimatedOpacity(
        duration: reduced ? Duration.zero : GlassMotion.fast,
        curve: GlassMotion.enter,
        opacity: scrolling && !_expanded ? 0.82 : 1,
        child: child,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AnimatedBuilder(
            animation: _progress,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassSurface(
                radius: 20,
                intensity: GlassIntensity.prominent,
                blurSigma: 20,
                padding: const EdgeInsets.all(6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _entry(
                      '添加课程',
                      Icons.add_circle_outline_rounded,
                      () => _select(widget.onPressed),
                    ),
                    _entry(
                      '导入课表',
                      Icons.download_rounded,
                      () => _select(widget.onImport),
                    ),
                    _entry(
                      '添加事件',
                      Icons.event_available_outlined,
                      () => _select(widget.onAddEvent),
                    ),
                  ],
                ),
              ),
            ),
            builder: (context, child) => Offstage(
              offstage: _progress.isDismissed,
              child: IgnorePointer(
                ignoring: !_expanded,
                child: SizeTransition(
                  sizeFactor: _motion,
                  alignment: Alignment.bottomRight,
                  child: FadeTransition(opacity: _motion, child: child),
                ),
              ),
            ),
          ),
          GlassSurface(
            interactive: true,
            onTap: () {
              _setExpanded(!_expanded);
              if (_expanded) HapticFeedback.selectionClick();
            },
            radius: 19,
            intensity: GlassIntensity.prominent,
            blurSigma: 20,
            depth: 1.8,
            semanticLabel: _expanded ? '关闭添加菜单' : '打开添加菜单',
            child: SizedBox(
              width: 58,
              height: 56,
              child: Center(
                child: Icon(
                  _expanded ? Icons.close_rounded : Icons.add_rounded,
                  size: 27,
                  color: palette.accent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _entry(String label, IconData icon, VoidCallback onTap) {
    final palette = AppTheme.paletteOf(context);
    return GlassSurface(
      interactive: true,
      onTap: onTap,
      blurSigma: 0,
      radius: 13,
      semanticLabel: label,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: SizedBox(
        width: 158,
        height: 48,
        child: Row(
          children: [
            Icon(icon, size: 19, color: palette.accent),
            const SizedBox(width: 11),
            Text(label, style: TextStyle(fontSize: 14, color: palette.ink)),
          ],
        ),
      ),
    );
  }
}
