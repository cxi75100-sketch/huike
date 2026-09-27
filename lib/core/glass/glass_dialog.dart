import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'glass_button.dart';
import 'glass_metrics.dart';
import 'glass_motion.dart';
import 'glass_surface.dart';
import 'glass_transition.dart';

/// Shared glass host for app dialogs. The dialog route keeps Flutter's focus,
/// keyboard, barrier and accessibility behavior; only its visible surface is
/// supplied by the Glass Design System.
Future<T?> showGlassDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
}) {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  return navigator.push<T>(
    _GlassDialogRoute<T>(
      context: context,
      builder: builder,
      barrierDismissible: barrierDismissible,
      themes: InheritedTheme.capture(from: context, to: navigator.context),
      duration: MediaQuery.disableAnimationsOf(context)
          ? GlassMotion.reduced
          : GlassMotion.dialog,
    ),
  );
}

/// DialogRoute retains Flutter's focus, barrier, safe-area and keyboard
/// contracts; only its ordinary paint transition is replaced.
class _GlassDialogRoute<T> extends DialogRoute<T> {
  _GlassDialogRoute({
    required super.context,
    required super.builder,
    required super.barrierDismissible,
    required super.themes,
    required this.duration,
  });

  final Duration duration;
  @override
  Duration get transitionDuration => duration;
  @override
  Duration get reverseTransitionDuration => duration;
  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => GlassTransition(
    animation: animation,
    travel: GlassMetrics.overlayTravel,
    child: child,
  );
}

class GlassDialog extends StatelessWidget {
  const GlassDialog({
    super.key,
    this.title,
    this.content,
    this.actions = const [],
  });

  final Widget? title;
  final Widget? content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: GlassSurface(
        radius: GlassMetrics.groupRadius,
        intensity: GlassIntensity.prominent,
        blurSigma: GlassMetrics.prominentBlur,
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 480,
            maxHeight: MediaQuery.sizeOf(context).height * 0.82,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                DefaultTextStyle(
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                  child: title!,
                ),
                if (content != null) const SizedBox(height: 12),
              ],
              if (content != null)
                Flexible(
                  fit: FlexFit.loose,
                  child: SingleChildScrollView(child: content!),
                ),
              if (actions.isNotEmpty) ...[
                if (content != null) const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: actions,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A compact dialog action. Destructive actions use a restrained danger tint
/// and keep the risk explicit in their accessibility label.
class GlassDialogAction extends StatelessWidget {
  const GlassDialogAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.destructive = false,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback onPressed;
  final bool primary;
  final bool destructive;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    final foreground = destructive
        ? palette.danger
        : primary
        ? palette.accent
        : palette.inkSecondary;
    return GlassButton(
      label: label,
      semanticLabel: semanticLabel ?? (destructive ? '$label，危险操作' : label),
      onPressed: onPressed,
      shape: GlassButtonShape.rounded,
      size: 44,
      tapTarget: GlassMetrics.minimumTarget,
      depth: 0.25,
      tint: destructive
          ? palette.danger.withValues(alpha: 0.12)
          : primary
          ? palette.accent.withValues(alpha: 0.1)
          : null,
      iconColor: foreground,
      labelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: foreground,
      ),
    );
  }
}
