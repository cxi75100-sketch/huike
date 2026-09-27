import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/glass/glass_metrics.dart';
import '../../../core/glass/glass_motion.dart';
import '../../../core/glass/glass_surface.dart';
import '../../../core/theme/app_theme.dart';

/// Root-only geometry; this overlay does not resize the Weekly viewport.
abstract final class RootSwitcherLayout {
  static const height = 64.0;
  static const gap = GlassMetrics.controlRadius;
  static const fabLift = height + gap;
}

/// Share one motion timeline and hide root chrome behind inline previews.
class RootSwitcherScope extends InheritedWidget {
  const RootSwitcherScope({
    super.key,
    required this.progress,
    required this.previewVisible,
    required super.child,
  });

  final Animation<double> progress;
  final ValueNotifier<bool> previewVisible;

  static RootSwitcherScope? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<RootSwitcherScope>();

  @override
  bool updateShouldNotify(RootSwitcherScope oldWidget) =>
      progress != oldWidget.progress ||
      previewVisible != oldWidget.previewVisible;
}

class TimetableRootShell extends StatefulWidget {
  const TimetableRootShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  State<TimetableRootShell> createState() => _TimetableRootShellState();
}

class _TimetableRootShellState extends State<TimetableRootShell>
    with SingleTickerProviderStateMixin {
  late final _progress = AnimationController(
    vsync: this,
    value: widget.navigationShell.currentIndex.toDouble(),
    duration: GlassMotion.slow,
  );
  final _previewVisible = ValueNotifier(false);

  @override
  void didUpdateWidget(covariant TimetableRootShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    _move();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _move();
  }

  void _move() {
    final target = widget.navigationShell.currentIndex.toDouble();
    if (MediaQuery.disableAnimationsOf(context)) {
      _progress.value = target;
    } else if (_progress.value != target) {
      _progress.animateTo(
        target,
        duration: GlassMotion.slow,
        curve: GlassMotion.enter,
      );
    }
  }

  void _select(int index) {
    if (index == widget.navigationShell.currentIndex) return;
    unawaited(HapticFeedback.selectionClick());
    widget.navigationShell.goBranch(index);
  }

  @override
  void dispose() {
    _previewVisible.dispose();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RootSwitcherScope(
    progress: _progress,
    previewVisible: _previewVisible,
    child: Stack(
      fit: StackFit.expand,
      children: [
        widget.navigationShell,
        AnimatedBuilder(
          animation: Listenable.merge([
            _previewVisible,
            GoRouter.of(context).routerDelegate,
          ]),
          child: _FloatingSwitcher(progress: _progress, onSelect: _select),
          builder: (context, child) {
            final path = GoRouter.of(context).routerDelegate.state.uri.path;
            return Positioned(
              left: GlassMetrics.controlRadius,
              right: GlassMetrics.controlRadius,
              bottom:
                  MediaQuery.viewPaddingOf(context).bottom +
                  RootSwitcherLayout.gap,
              child: Offstage(
                offstage:
                    _previewVisible.value || (path != '/' && path != '/today'),
                child: Center(child: child),
              ),
            );
          },
        ),
      ],
    ),
  );
}

/// Both branch navigators remain mounted; only their paint and input change.
class RetainedTimetablePages extends StatelessWidget {
  const RetainedTimetablePages({
    super.key,
    required this.children,
    required this.index,
  });
  final List<Widget> children;
  final int index;

  @override
  Widget build(BuildContext context) {
    final progress = RootSwitcherScope.maybeOf(context)!.progress;
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < children.length; i++)
          AnimatedBuilder(
            animation: progress,
            child: HeroMode(
              enabled: i == index,
              child: RepaintBoundary(child: children[i]),
            ),
            builder: (context, child) {
              final opacity = i == 0 ? 1 - progress.value : progress.value;
              final reduced = MediaQuery.disableAnimationsOf(context);
              return Offstage(
                offstage: opacity == 0,
                child: TickerMode(
                  enabled: i == index,
                  child: ExcludeFocus(
                    excluding: i != index,
                    child: ExcludeSemantics(
                      excluding: i != index,
                      child: IgnorePointer(
                        ignoring: i != index,
                        child: Opacity(
                          opacity: opacity,
                          child: Transform.translate(
                            offset: Offset(
                              reduced
                                  ? 0
                                  : GlassMetrics.pageTravel *
                                        (i == 0
                                            ? progress.value
                                            : progress.value - 1),
                              0,
                            ),
                            child: child,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _FloatingSwitcher extends StatelessWidget {
  const _FloatingSwitcher({required this.progress, required this.onSelect});
  final Animation<double> progress;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final shell = context.findAncestorWidgetOfExactType<TimetableRootShell>()!;
    final selected = shell.navigationShell.currentIndex;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(272.0, constraints.maxWidth);
        final cell = (width - 12) / 2;
        return SizedBox(
          key: const ValueKey('root-switcher'),
          width: width,
          height: RootSwitcherLayout.height,
          child: GlassSurface(
            radius: RootSwitcherLayout.height / 2,
            intensity: GlassIntensity.subtle,
            depth: 0.35,
            padding: const EdgeInsets.all(6),
            child: AnimatedBuilder(
              animation: progress,
              child: RepaintBoundary(
                child: SizedBox(
                  key: const ValueKey('root-active-capsule'),
                  width: cell,
                  height: RootSwitcherLayout.height - 12,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: dark ? 0.16 : 0.78),
                          Colors.white.withValues(alpha: dark ? 0.07 : 0.38),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: dark ? 0.10 : 0.035,
                          ),
                          blurRadius: 7,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              builder: (context, capsule) => Stack(
                children: [
                  Transform.translate(
                    offset: Offset(cell * progress.value, 0),
                    child: capsule,
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < 2; i++)
                        Expanded(
                          child: Semantics(
                            selected: i == selected,
                            button: true,
                            label: i == 0 ? '今日' : '周课表',
                            child: Tooltip(
                              message: i == 0 ? '今日课程' : '周课表',
                              child: GestureDetector(
                                key: ValueKey(
                                  i == 0 ? 'root-tab-today' : 'root-tab-weekly',
                                ),
                                behavior: HitTestBehavior.opaque,
                                onTap: () => onSelect(i),
                                child: ExcludeSemantics(
                                  child: SizedBox(
                                    height: RootSwitcherLayout.height - 12,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          i == 0
                                              ? Icons.today_outlined
                                              : Icons
                                                    .calendar_view_week_rounded,
                                          size: 20,
                                          color: Color.lerp(
                                            palette.inkSecondary,
                                            palette.ink,
                                            i == 0
                                                ? 1 - progress.value
                                                : progress.value,
                                          ),
                                        ),
                                        const SizedBox(width: 7),
                                        Text(
                                          i == 0 ? '今日' : '周课表',
                                          style: TextStyle(
                                            inherit: false,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color.lerp(
                                              palette.inkSecondary,
                                              palette.ink,
                                              i == 0
                                                  ? 1 - progress.value
                                                  : progress.value,
                                            ),
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
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
