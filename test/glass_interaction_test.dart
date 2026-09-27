import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huike_timetable/core/glass/glass_button.dart';
import 'package:huike_timetable/core/glass/glass_motion.dart';
import 'package:huike_timetable/core/glass/glass_surface.dart';
import 'package:huike_timetable/core/glass/press_physics.dart';

/// 动态玻璃的物理与响应：按压压缩、触摸位置驱动高光、松手弹簧回位，
/// 以及「不使用 InkWell / 没有 ripple」的硬约束。
void main() {
  /// 玻璃表面的压缩是绘制变换（`Transform.scale`），布局尺寸不变，
  /// 所以这里读变换矩阵的 x 轴尺度（不能用 getMaxScaleOnAxis：z 轴恒为 1）。
  double surfaceScale(WidgetTester tester) {
    final transforms = tester.widgetList<Transform>(
      find.descendant(
        of: find.byType(GlassSurface),
        matching: find.byType(Transform),
      ),
    );
    return transforms.first.transform.entry(0, 0);
  }

  testWidgets('按下压缩：松手后弹簧回到原尺寸', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: GlassButton(label: '测试', onPressed: () {}, size: 48),
        ),
      ),
    );

    expect(surfaceScale(tester), closeTo(1, 0.001));

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('测试')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 140));
    final pressed = surfaceScale(tester);
    expect(pressed, lessThan(0.995));
    expect(pressed, greaterThan(0.94));

    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    // 回弹途中仍在恢复，且没有夸张的弹跳。
    expect(surfaceScale(tester), lessThan(1.02));
    await tester.pumpAndSettle();
    expect(surfaceScale(tester), closeTo(1, 0.001));
  });

  testWidgets('触摸位置驱动高光：手指从左移到右，高光跟着走，抬手回到左上', (tester) async {
    var press = 0.0;
    var touch = GlassSurface.restHighlight;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 160,
            height: 64,
            child: PressPhysics(
              trackTouch: true,
              onTap: () {},
              builder: (context, value, alignment, child) {
                press = value;
                touch = alignment;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      ),
    );

    final box = tester.getRect(find.byType(PressPhysics));
    final gesture = await tester.startGesture(
      Offset(box.left + 12, box.top + 12),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 140));
    expect(press, closeTo(1, 0.02));
    expect(touch.x, lessThan(-0.5));
    expect(touch.y, lessThan(-0.5));

    await gesture.moveTo(Offset(box.right - 12, box.bottom - 8));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 140));
    expect(touch.x, greaterThan(0.5));
    expect(touch.y, greaterThan(0.3));

    await gesture.up();
    await tester.pumpAndSettle();
    // 抬手：按压进度归零，高光缓慢回到默认位置。
    expect(press, closeTo(0, 0.01));
    expect(touch.x, closeTo(GlassSurface.restHighlight.x, 0.05));
    expect(touch.y, closeTo(GlassSurface.restHighlight.y, 0.05));
  });

  testWidgets('按压进度可以被外部驱动（Sheet / 切周共用一套进度）', (tester) async {
    final driver = ValueNotifier<double>(0);
    addTearDown(driver.dispose);
    var press = 0.0;
    await tester.pumpWidget(
      MaterialApp(
        home: PressPhysics(
          pressDriver: driver,
          builder: (context, value, alignment, child) {
            press = value;
            return const SizedBox(width: 10, height: 10);
          },
        ),
      ),
    );

    expect(press, 0);
    driver.value = 0.6;
    await tester.pump();
    expect(press, closeTo(0.6, 0.001));
    driver.value = 1;
    await tester.pump();
    expect(press, closeTo(1, 0.001));

    final touchDriver = ValueNotifier<Alignment>(Alignment.center);
    addTearDown(touchDriver.dispose);
    var touch = Alignment.center;
    await tester.pumpWidget(
      MaterialApp(
        home: PressPhysics(
          touchDriver: touchDriver,
          builder: (context, value, alignment, child) {
            touch = alignment;
            return const SizedBox(width: 10, height: 10);
          },
        ),
      ),
    );
    touchDriver.value = const Alignment(0.8, 0.4);
    await tester.pump();
    expect(touch, const Alignment(0.8, 0.4));
  });

  testWidgets('玻璃表面不使用 InkWell / 涟漪：按压反馈来自材质本身', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassSurface(
              interactive: true,
              onTap: () => taps++,
              child: const SizedBox(width: 80, height: 40),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(InkWell), findsNothing);
    expect(find.byType(InkResponse), findsNothing);

    final rest = surfaceScale(tester);
    await tester.tap(find.byType(GlassSurface));
    expect(taps, 1);
    await tester.pumpAndSettle();
    expect(surfaceScale(tester), closeTo(rest, 0.001));
  });

  testWidgets('玻璃五层里确实有模糊层，且每块玻璃都有独立重绘边界', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassSurface(
              blurSigma: 16,
              child: const SizedBox(width: 80, height: 40),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.byType(RepaintBoundary), findsWidgets);

    // blurSigma 为 0 时不再建立滤镜层（模糊只花在真正需要折射的地方）。
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassSurface(
              blurSigma: 0,
              child: const SizedBox(width: 80, height: 40),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(BackdropFilter), findsNothing);
  });

  test('动效令牌是唯一来源：按压与回弹各有弹簧，且不是卡通弹跳', () {
    // 阻尼比 = damping / (2*sqrt(stiffness*mass))；0.6~1.1 之间才是克制区间。
    double ratio(SpringDescription spring) =>
        spring.damping / (2 * math.sqrt(spring.stiffness * spring.mass));

    expect(ratio(GlassMotion.releaseSpring), greaterThan(0.6));
    expect(ratio(GlassMotion.releaseSpring), lessThan(1.05));
    expect(ratio(GlassMotion.sheetSpring), greaterThan(0.85));
    expect(ratio(GlassMotion.sheetSpring), lessThan(1.1));
    expect(ratio(GlassMotion.weekSpring), greaterThan(0.85));
    expect(ratio(GlassMotion.weekSpring), lessThan(1.1));

    expect(GlassMotion.fast.inMilliseconds, inInclusiveRange(90, 120));
    expect(GlassMotion.standard.inMilliseconds, inInclusiveRange(160, 200));
    expect(GlassMotion.slow.inMilliseconds, inInclusiveRange(220, 280));
  });
}
