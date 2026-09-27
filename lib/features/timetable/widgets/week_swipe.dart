import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../../core/glass/glass_motion.dart';

/// 切周手势的共享状态。
///
/// 一个值同时喂给：网格位移、周导航玻璃的高光方向、今日快捷条的避让。
/// 页面、导航、网格都只是它的读者——不存在「一个手势各自算一遍动画」。
class WeekSwipeState extends ChangeNotifier {
  double _offset = 0;

  /// 已移动的页数：0 = 停在当前周，+1 = 上一周完全就位，-1 = 下一周完全就位。
  double get offset => _offset;

  bool _dragging = false;

  bool get dragging => _dragging;

  bool get settled => _offset == 0;

  /// 手势方向：+1 = 正在拉出上一周（内容向右），-1 = 下一周。
  int get direction => _offset > 0
      ? 1
      : _offset < 0
      ? -1
      : 0;

  set offset(double value) {
    if ((value - _offset).abs() < 0.0005) return;
    _offset = value;
    notifyListeners();
  }

  set dragging(bool value) {
    if (value == _dragging) return;
    _dragging = value;
    notifyListeners();
  }

  /// 由箭头 / 回本周触发的周切换：交给 pager 去走完整个交互式过渡。
  void Function(int direction)? stepRequest;

  /// direction：+1 = 下一周，-1 = 上一周。
  void step(int direction) => stepRequest?.call(direction);

  void reset() {
    _offset = 0;
    _dragging = false;
    notifyListeners();
  }
}

/// 跟手切周容器。
///
/// - 拖动过程：三页（上一周 / 本周 / 下一周）跟着手指平移，[state] 同步广播进度；
/// - 松手：按「位置 + 速度」决定提交还是回位，两个方向都用弹簧落位；
/// - 一次手势只在松手时提交一次；落位期间开始的手势整次忽略；
/// - Reduced Motion：不位移，只按阈值提交。
/// 一次拖拽的提交判定：位置与速度一起看。
///
/// - 短距离快速 flick（速度过阈值）→ 直接按甩动方向提交；
/// - 长距离但慢速 → 按最终位置判断；
/// - 都不够 → 0，弹簧回原位。
///
/// 返回值 +1 表示拉出上一周（内容向右），-1 表示进入下一周。
int weekSwipeTarget({
  required double dragPixels,
  required double velocityPx,
  required double width,
  double distanceThreshold = 0.15,
  double flickVelocity = 380,
}) {
  if (velocityPx.abs() >= flickVelocity) return velocityPx > 0 ? 1 : -1;
  if (dragPixels.abs() >= distanceThreshold * width) {
    return dragPixels > 0 ? 1 : -1;
  }
  return 0;
}

class WeekSwipePager extends StatefulWidget {
  const WeekSwipePager({
    super.key,
    required this.state,
    required this.page,
    required this.onCommit,
    this.previous,
    this.next,
    this.distanceThreshold = 0.15,
    this.flickVelocity = 380,
  });

  final WeekSwipeState state;

  /// 本周内容。
  final Widget page;

  /// 上一周 / 下一周。为空表示到边界，不允许继续切。
  final Widget? previous;
  final Widget? next;

  /// 提交方向：+1 = 进入下一周，-1 = 回到上一周。
  final ValueChanged<int> onCommit;

  /// 位置阈值（按页宽比例）。
  final double distanceThreshold;

  /// 速度阈值（px/s）：短距离快速 flick 也算提交。
  final double flickVelocity;

  @override
  State<WeekSwipePager> createState() => _WeekSwipePagerState();
}

class _WeekSwipePagerState extends State<WeekSwipePager>
    with SingleTickerProviderStateMixin {
  late final AnimationController _offset = AnimationController(
    vsync: this,
    lowerBound: -1.05,
    upperBound: 1.05,
    // 必须显式给 0：AnimationController 默认停在 lowerBound。
    value: 0,
  );

  double _viewportWidth = 1;
  double _dragPixels = 0;
  double? _target;
  bool _gestureAccepted = false;
  bool _dragActive = false;
  int? _pointer;

  @override
  void initState() {
    super.initState();
    _offset.addStatusListener(_handleStatus);
    _offset.addListener(_syncOffset);
    widget.state.stepRequest = _step;
  }

  @override
  void didUpdateWidget(covariant WeekSwipePager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state &&
        oldWidget.state.stepRequest == _step) {
      oldWidget.state.stepRequest = null;
    }
    widget.state.stepRequest = _step;
  }

  @override
  void dispose() {
    if (widget.state.stepRequest == _step) widget.state.stepRequest = null;
    _offset.removeStatusListener(_handleStatus);
    _offset.removeListener(_syncOffset);
    _offset.dispose();
    super.dispose();
  }

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  void _syncOffset() => widget.state.offset = _offset.value;

  void _handleStatus(AnimationStatus status) {
    final target = _target;
    if (target == null) return;
    final finished =
        status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed;
    if (!finished) return;
    _target = null;
    if (target == 0) {
      // 弹簧收敛不会精确落在 0：显式归零，否则相邻周会一直挂在树上。
      _offset.value = 0;
      widget.state.reset();
      return;
    }
    _finish(target);
  }

  void _finish(double target) {
    // 先把偏移归零再换周：两件事发生在同一帧，画面完全等价，不会闪。
    _offset.value = 0;
    widget.state.reset();
    widget.onCommit(target > 0 ? -1 : 1);
  }

  bool get _canGoPrevious => widget.previous != null;
  bool get _canGoNext => widget.next != null;

  /// 箭头 / 回本周请求：+1 下一周，-1 上一周。
  void _step(int direction) {
    if (direction > 0 ? !_canGoNext : !_canGoPrevious) return;
    // 按钮仍走既有切周路径，但已经接管的拖动不能再于松手时提交。
    _gestureAccepted = false;
    _dragActive = false;
    widget.state.dragging = false;
    _settle(-direction.toDouble(), velocity: 0);
  }

  void _settle(double target, {double velocity = 0}) {
    _offset.stop();
    if (_reduceMotion) {
      if (target != 0) {
        _finish(target);
      } else {
        _offset.value = 0;
        widget.state.reset();
      }
      return;
    }
    _target = target;
    final spring = target == 0
        ? GlassMotion.returnSpring
        : GlassMotion.weekSpring;
    _offset.animateWith(
      SpringSimulation(spring, _offset.value, target, velocity),
    );
  }

  void _handleDragDown(DragDownDetails details) {
    // 在 pointer down 锁定资格，而非等 drag start：动画期间按下，
    // 即使等到动画结束再移动，也不能接管下一周。
    _gestureAccepted = _target == null && !_offset.isAnimating;
  }

  void _handleDragStart(DragStartDetails details) {
    if (!_gestureAccepted) return;
    _dragActive = true;
    _dragPixels = 0;
    widget.state.dragging = true;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_dragActive) return;
    final delta = details.primaryDelta ?? 0;
    _dragPixels += delta;
    if (_reduceMotion) return;
    // 内容跟手 1:1：手指走多远，课表就走多远；到边界就停住不橡皮筋。
    final next = (_offset.value + delta / _viewportWidth).clamp(-1.0, 1.0);
    if (next > 0 && !_canGoPrevious) return;
    if (next < 0 && !_canGoNext) return;
    _offset.value = next;
    widget.state.offset = next;
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_dragActive) return;
    // 在启动动画前 consume，后续事件和动画完成均不能再次消费 velocity。
    _dragActive = false;
    _gestureAccepted = false;
    widget.state.dragging = false;
    final velocityPx = details.primaryVelocity ?? 0;
    var direction = weekSwipeTarget(
      dragPixels: _reduceMotion ? _dragPixels : _offset.value * _viewportWidth,
      velocityPx: velocityPx,
      width: _viewportWidth,
      distanceThreshold: widget.distanceThreshold,
      flickVelocity: widget.flickVelocity,
    );
    if (direction > 0 && !_canGoPrevious) direction = 0;
    if (direction < 0 && !_canGoNext) direction = 0;

    if (direction == 0) {
      _settle(0, velocity: velocityPx / _viewportWidth);
      return;
    }
    _settle(direction.toDouble(), velocity: velocityPx / _viewportWidth);
  }

  void _handleDragCancel() {
    _gestureAccepted = false;
    if (!_dragActive) return;
    _dragActive = false;
    widget.state.dragging = false;
    _settle(0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportWidth = constraints.maxWidth;
        return Listener(
          // Flutter 的 drag recognizer 在 pointer cancel 时也可能发出 end；
          // 先消费取消，避免将取消后的位移当作翻页条件。
          onPointerDown: (event) => _pointer ??= event.pointer,
          onPointerUp: (event) {
            if (_pointer == event.pointer) _pointer = null;
          },
          onPointerCancel: (event) {
            if (_pointer != event.pointer) return;
            _pointer = null;
            _handleDragCancel();
          },
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragDown: _handleDragDown,
            onHorizontalDragStart: _handleDragStart,
            onHorizontalDragUpdate: _handleDragUpdate,
            onHorizontalDragEnd: _handleDragEnd,
            onHorizontalDragCancel: _handleDragCancel,
            child: AnimatedBuilder(
              animation: _offset,
              builder: (context, _) {
                final offset = _offset.value;
                final pages = <Widget>[
                  // 静止时不额外渲染相邻周：省一层网格，也让语义树保持单一。
                  if (offset != 0 && widget.previous != null)
                    _page(widget.previous!, -1, offset),
                  _page(widget.page, 0, offset),
                  if (offset != 0 && widget.next != null)
                    _page(widget.next!, 1, offset),
                ];
                return Stack(fit: StackFit.expand, children: pages);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _page(Widget child, int slot, double offset) {
    return Positioned.fill(
      child: Transform.translate(
        offset: Offset((slot + offset) * _viewportWidth, 0),
        child: child,
      ),
    );
  }
}
