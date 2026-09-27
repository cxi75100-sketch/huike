import 'package:flutter/animation.dart' show Curves;
import 'package:flutter/physics.dart';

/// 全 App 统一的动态材质动效令牌。
///
/// 禁止在 Widget 里各写 `Duration(milliseconds: xxx)`：时长、曲线与弹簧
/// 参数只在这里定义一次，玻璃、切周、Sheet 共用同一套节奏。
abstract final class GlassMotion {
  const GlassMotion._();

  /// 按压进入：快到几乎与手指同步。
  static const fast = Duration(milliseconds: 110);
  static const reducedHero = Duration(milliseconds: 90);

  /// 小尺度状态变化（标签、图标、指示线）。
  static const standard = Duration(milliseconds: 180);

  /// 大面积位移（页面、Sheet 展开）。
  static const slow = Duration(milliseconds: 280);
  static const menu = Duration(milliseconds: 220);
  static const weekLabel = Duration(milliseconds: 260);
  static const todayPulse = Duration(milliseconds: 460);

  /// 触摸高光跟随：短到几乎贴身，但仍有轻微滞后，避免「光斑跳动」。
  static const touchFollow = Duration(milliseconds: 90);

  /// Ordinary routes and overlays share the same cadence. Hero/week springs
  /// remain independent contracts and must not be retuned by a general audit.
  static const pageEnter = slow;
  static const pageExit = standard;
  static const dialog = standard;
  static const reduced = reducedHero;
  static const snackEnter = standard;
  static const snackExit = fast;

  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
  static const emphasized = Curves.easeOutQuart;

  /// 松手回弹：阻尼比约 0.75，有极轻的过冲后立刻安定。
  static const releaseSpring = SpringDescription(
    mass: 1,
    stiffness: 520,
    damping: 34,
  );

  /// Sheet 开合：临界阻尼，不弹跳（Apple-like：快、可控、安静）。
  static const sheetSpring = SpringDescription(
    mass: 1,
    stiffness: 300,
    damping: 35,
  );

  /// 切周提交：略快于 Sheet，落在 220–280ms 区间。
  static const weekSpring = SpringDescription(
    mass: 1,
    stiffness: 340,
    damping: 37,
  );

  /// 松手后停在原位的回弹。
  static const returnSpring = SpringDescription(
    mass: 1,
    stiffness: 420,
    damping: 36,
  );

  static SpringSimulation simulation(
    SpringDescription spring, {
    required double from,
    required double to,
    double velocity = 0,
  }) => SpringSimulation(spring, from, to, velocity);

  /// 速度是否足以让一次拖拽直接提交（短距离快速 flick 也算数）。
  static bool flicksPast(double velocity, double threshold) =>
      velocity.abs() >= threshold;
}
