import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../glass/glass_motion.dart';
import '../glass/glass_transition.dart';

Page<void> glassPage({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  final reduced = MediaQuery.disableAnimationsOf(context);
  if (Theme.of(context).platform == TargetPlatform.iOS) {
    return _GlassNativePage(key: state.pageKey, child: child, reduced: reduced);
  }
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: reduced ? GlassMotion.reduced : GlassMotion.pageEnter,
    reverseTransitionDuration: reduced
        ? GlassMotion.reduced
        : GlassMotion.pageExit,
    transitionsBuilder: (context, animation, secondary, child) =>
        GlassTransition(animation: animation, child: child),
  );
}

// Keep Cupertino's interactive back gesture on iOS. The reduced variant keeps
// its gesture detector while replacing the visual translation with a fade.
class _GlassNativePage extends Page<void> {
  const _GlassNativePage({
    required super.key,
    required this.child,
    required this.reduced,
  });

  final Widget child;
  final bool reduced;

  @override
  Route<void> createRoute(BuildContext context) => _GlassNativeRoute(this);
}

class _GlassNativeRoute extends MaterialPageRoute<void> {
  _GlassNativeRoute(_GlassNativePage page)
    : super(settings: page, builder: (_) => page.child);

  _GlassNativePage get _page => settings as _GlassNativePage;

  @override
  Widget buildContent(BuildContext context) => _page.child;

  @override
  Duration get transitionDuration =>
      _page.reduced ? GlassMotion.reduced : GlassMotion.pageEnter;

  @override
  Duration get reverseTransitionDuration =>
      _page.reduced ? GlassMotion.reduced : GlassMotion.pageExit;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (!_page.reduced) {
      return super.buildTransitions(
        context,
        animation,
        secondaryAnimation,
        child,
      );
    }
    return CupertinoRouteTransitionMixin.buildPageTransitions<void>(
      this,
      context,
      const AlwaysStoppedAnimation<double>(1),
      const AlwaysStoppedAnimation<double>(0),
      GlassTransition(animation: animation, child: child),
    );
  }
}
