import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huike_timetable/core/glass/glass_surface.dart';
import 'package:huike_timetable/core/theme/app_theme.dart';
import 'package:huike_timetable/features/timetable/pages/today_page.dart';
import 'package:huike_timetable/features/timetable/providers/timetable_providers.dart';
import 'package:huike_timetable/features/timetable/widgets/today_timeline.dart';
import 'package:huike_timetable/models/bell_schedule.dart';
import 'package:huike_timetable/models/course.dart';
import 'package:huike_timetable/models/school_profile.dart';
import 'package:huike_timetable/features/schools/providers/school_providers.dart';
import 'package:huike_timetable/services/calendar_exception_service.dart';

Course course(
  String id,
  String start,
  String end, {
  String note = '',
  String name = '',
}) => Course(
  id: id,
  schoolId: 'qa',
  semesterId: 'qa-semester',
  name: name.isEmpty ? '课程 $id' : name,
  startTime: start,
  endTime: end,
  weekday: 1,
  startSection: 1,
  endSection: 2,
  weeks: const [1, 2, 3, 4],
  teacher: '教师',
  classroom: 'A201',
  note: note,
);

List<Course> fourCourses() => [
  course('a', '08:20', '09:50').copyWith(colorKey: 0),
  course('b', '10:00', '11:30').copyWith(colorKey: 2),
  course('c', '14:00', '15:30').copyWith(colorKey: 3),
  course('d', '15:40', '17:10').copyWith(colorKey: 8),
];

void main() {
  setUpAll(() async {
    if (Platform.environment['HUIKE_TODAY_QA_DIR'] == null) return;
    TestWidgetsFlutterBinding.ensureInitialized();
    final font = FontLoader('TodayQA')
      ..addFont(
        File('C:/Windows/Fonts/msyh.ttc')
            .readAsBytes()
            .then((bytes) => ByteData.sublistView(bytes)),
      );
    await font.load();
  });
  Future<void> pumpTimeline(
    WidgetTester tester,
    List<Course> courses, {
    int hour = 9,
    int minute = 0,
    double width = 390,
    double scale = 1,
    bool dark = false,
    bool showCurrentTime = true,
    ValueChanged<Course>? onTap,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: (dark ? AppTheme.dark() : AppTheme.light()).copyWith(
          textTheme: Platform.environment['HUIKE_TODAY_QA_DIR'] == null
              ? null
              : (dark ? AppTheme.dark() : AppTheme.light()).textTheme.apply(
                  fontFamily: 'TodayQA',
                ),
        ),
        home: RepaintBoundary(
          key: const ValueKey('today-status-qa'),
          child: Scaffold(
            body: TodayTimeline(
              courses: courses,
              schedule: BellSchedule.fallback(),
              now: DateTime(2026, 9, 27, hour, minute),
              onCourseTap: onTap ?? (_) {},
              showCurrentTime: showCurrentTime,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Rect card(WidgetTester tester, String id) =>
      tester.getRect(find.byKey(ValueKey('today-course-$id')));

  for (final dark in [false, true]) {
    testWidgets('三种今日状态有明确文字且不重复当前时间 dark=$dark', (tester) async {
      for (final (hour, label, state) in [
        (9, '进行中 · 09:50结束', 'active'),
        (12, '下一节还有2小时', 'between'),
        (20, '今日课程已结束', 'after'),
      ]) {
        await pumpTimeline(tester, fourCourses(), hour: hour, dark: dark);
        expect(find.text(label), findsOneWidget);
        expect(find.text('$hour:00'), findsNothing);
        final qaDirectory = Platform.environment['HUIKE_TODAY_QA_DIR'];
        if (qaDirectory != null) {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('today-status-qa')),
          );
          await tester.runAsync(() async {
            final capture = await boundary.toImage();
            final data = await capture.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await Directory(qaDirectory).create(recursive: true);
            await File(
              '$qaDirectory/status-$state-${dark ? 'dark' : 'light'}.png',
            ).writeAsBytes(data!.buffer.asUint8List());
            capture.dispose();
          });
        }
      }
    });
  }

  testWidgets('90分钟与六小时课程内容定高，duration不撑高卡片', (tester) async {
    await pumpTimeline(tester, [
      course('a', '08:20', '09:50'),
      course('b', '10:00', '16:00'),
    ]);
    expect(card(tester, 'a').height, inInclusiveRange(100.5, 150));
    expect(card(tester, 'b').height, closeTo(134 * 0.75, 0.1));
    expect(find.textContaining('10:00 - 16:00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('内容增加自然增高，长时长和长文本仍有有限高度且字段保留', (tester) async {
    await pumpTimeline(
      tester,
      [
        course('a', '08:20', '09:50'),
        course(
          'b',
          '10:00',
          '23:50',
          name: '很长的课程名称需要两行表达完整的主题',
          note: '请携带实验记录本与教材，课前完成准备练习',
        ),
      ],
      width: 360,
      scale: 1.3,
    );
    expect(card(tester, 'b').height, greaterThan(card(tester, 'a').height));
    expect(card(tester, 'b').height, lessThanOrEqualTo(290));
    expect(find.text('教师'), findsNWidgets(2));
    expect(find.text('A201'), findsNWidgets(2));
    expect(find.textContaining('请携带'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('按实际开始时间排序，三小时空档被压缩但大于短课间', (tester) async {
    final items = fourCourses();
    await pumpTimeline(tester, [
      items[3],
      items[1],
      items[2],
      items[0],
    ], hour: 7);
    expect(card(tester, 'a').top, lessThan(card(tester, 'b').top));
    expect(card(tester, 'b').top, lessThan(card(tester, 'c').top));
    expect(card(tester, 'c').top, lessThan(card(tester, 'd').top));
    final shortGap = card(tester, 'b').top - card(tester, 'a').bottom;
    final longGap = card(tester, 'c').top - card(tester, 'b').bottom;
    expect(longGap, greaterThan(shortGap));
    expect(longGap, lessThanOrEqualTo(40));
  });

  testWidgets('当前时间在课程内关联课程，松散时间轴不按分钟定位', (tester) async {
    await pumpTimeline(tester, fourCourses(), hour: 8, minute: 40);
    final marker = tester.getRect(
      find.byKey(const ValueKey('today-now-course-a')),
    );
    expect(marker.top, greaterThanOrEqualTo(card(tester, 'a').top));
    expect(marker.bottom, lessThanOrEqualTo(card(tester, 'a').bottom));
    expect(find.text('进行中 · 09:50结束'), findsOneWidget);
    expect(find.byKey(const ValueKey('today-now-between')), findsNothing);
    final firstY = marker.top;
    await pumpTimeline(tester, fourCourses(), hour: 9, minute: 40);
    expect(
      tester.getRect(find.byKey(const ValueKey('today-now-course-a'))).top,
      firstY,
    );
  });

  testWidgets('当前时间在两课之间与精确结束时，indicator位于间隔带', (tester) async {
    for (final minute in [50, 55]) {
      await pumpTimeline(tester, fourCourses(), hour: 9, minute: minute);
      final marker = tester.getRect(
        find.byKey(const ValueKey('today-now-between')),
      );
      expect(marker.top, greaterThanOrEqualTo(card(tester, 'a').bottom));
      expect(marker.bottom, lessThanOrEqualTo(card(tester, 'b').top));
      expect(find.text('进行中'), findsNothing);
      expect(find.text('下一节还有${60 - minute}分钟'), findsOneWidget);
    }
  });

  testWidgets('课前与课后indicator位于首尾，空Today无伪造时间节点', (tester) async {
    await pumpTimeline(tester, fourCourses(), hour: 7);
    expect(find.text('下一节还有1小时20分钟'), findsOneWidget);
    expect(
      tester.getRect(find.byKey(const ValueKey('today-now-before'))).bottom,
      lessThanOrEqualTo(card(tester, 'a').top),
    );
    await pumpTimeline(tester, fourCourses(), hour: 20);
    expect(find.text('今日课程已结束'), findsOneWidget);
    expect(find.text('20:00'), findsNothing);
    expect(
      tester.getRect(find.byKey(const ValueKey('today-now-after'))).top,
      greaterThanOrEqualTo(card(tester, 'd').bottom),
    );
    await pumpTimeline(tester, []);
    expect(find.text('今天没有课程'), findsOneWidget);
    expect(find.byType(GlassSurface), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('未知作息混入时不宣称全部结束，隐藏当前状态仍保留课程', (tester) async {
    await pumpTimeline(tester, [
      course('a', '08:20', '09:50'),
      course('u', 'bad', 'bad'),
    ], hour: 20);
    expect(find.text('今日课程已结束'), findsNothing);
    await pumpTimeline(tester, fourCourses(), showCurrentTime: false);
    expect(find.text('课程 a'), findsOneWidget);
    expect(find.byKey(const ValueKey('today-now-course-a')), findsNothing);
    expect(find.byKey(const ValueKey('today-now-after')), findsNothing);
    expect(find.textContaining('下一节还有'), findsNothing);
  });

  testWidgets('单课程保留所有信息、Glass/tint与点击；未知时间不假造indicator', (tester) async {
    Course? selected;
    final item = course('a', '08:20', '09:50', note: '带教材');
    await pumpTimeline(tester, [item], onTap: (value) => selected = value);
    expect(find.text('A201'), findsOneWidget);
    expect(find.text('教师'), findsOneWidget);
    expect(find.text('第 1、2、3、4 周'), findsOneWidget);
    expect(find.text('带教材'), findsOneWidget);
    expect(
      tester.widget<GlassSurface>(find.byType(GlassSurface)).tint,
      isNotNull,
    );
    await tester.tap(find.text('课程 a'));
    await tester.pumpAndSettle();
    expect(selected, same(item));
    await pumpTimeline(tester, [course('u', 'bad', 'bad')]);
    expect(find.text('待定'), findsOneWidget);
    expect(find.text('时间未定'), findsOneWidget);
    expect(find.byKey(const ValueKey('today-now-course-u')), findsNothing);
    expect(find.byKey(const ValueKey('today-now-after')), findsNothing);
  });

  testWidgets('嵌套重叠保留进行中关联，以最大结束时间压缩下一段空档', (tester) async {
    await pumpTimeline(tester, [
      course('a', '08:00', '12:00'),
      course('b', '09:00', '10:00'),
      course('c', '13:00', '14:00'),
    ], hour: 11);
    expect(find.byKey(const ValueKey('today-now-course-a')), findsOneWidget);
    expect(find.byKey(const ValueKey('today-now-course-b')), findsNothing);
    expect(find.text('进行中 · 12:00结束'), findsOneWidget);
    expect(find.text('已结束'), findsOneWidget);
    expect(card(tester, 'c').top - card(tester, 'b').bottom, 24);
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    testWidgets('窄屏大字号完整显示长课程字段，无省略 dark=$dark', (tester) async {
      final item =
          course(
            'long',
            '08:20',
            '09:50',
            name: '复杂工程系统建模与跨学科实验研究方法导论',
            note: '请携带实验记录本与教材，完成课前准备练习并记录每一步实验结果，课后提交完整报告。',
          ).copyWith(
            classroom: '九龙湖校区西区实训中心三号楼A010实验室',
            teacher: '联合授课教师与实验指导教师',
            weeks: List.generate(20, (i) => i + 1),
          );
      await pumpTimeline(tester, [item], width: 360, scale: 2, dark: dark);
      final courseFinder = find.byKey(const ValueKey('today-course-long'));
      for (final value in [
        item.name,
        item.classroom,
        item.teacher,
        item.note,
      ]) {
        expect(find.text(value), findsOneWidget);
        expect(
          tester.getRect(find.text(value)).bottom,
          lessThanOrEqualTo(card(tester, 'long').bottom),
        );
      }
      for (final paragraph
          in find
              .descendant(of: courseFinder, matching: find.byType(RichText))
              .evaluate()) {
        expect(
          (paragraph.renderObject! as RenderParagraph).didExceedMaxLines,
          isFalse,
        );
      }
      expect(card(tester, 'long').height, greaterThan(134 * 0.75));
      expect(
        tester.widget<GlassSurface>(find.byType(GlassSurface)).solidColor,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [360.0, 390.0, 430.0]) {
    for (final scale in [1.0, 1.3]) {
      for (final dark in [false, true]) {
        testWidgets('Today四课 $width dp / $scale / dark=$dark 首屏密度与无overflow', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                activeSchoolProvider.overrideWith(
                  (ref) => SchoolProfile(
                    id: 'qa',
                    displayName: '合成学校',
                    adapterId: '',
                    loginUrl: '',
                    acceptedHosts: const [],
                    createdAt: DateTime(2026, 1, 1),
                  ),
                ),
                todayCoursesProvider.overrideWith((ref) => fourCourses()),
                todayDayScheduleProvider.overrideWith(
                  (ref) => const DaySchedule(weekday: 1, suspended: false),
                ),
                bellForActiveSchoolProvider.overrideWith(
                  (ref) => BellSchedule.fallback(),
                ),
              ],
              child: RepaintBoundary(
                key: const ValueKey('today-qa-screen'),
                child: MaterialApp(
                  theme: (dark ? AppTheme.dark() : AppTheme.light()).copyWith(
                    textTheme:
                        Platform.environment['HUIKE_TODAY_QA_DIR'] == null
                        ? null
                        : (dark ? AppTheme.dark() : AppTheme.light()).textTheme
                              .apply(fontFamily: 'TodayQA'),
                  ),
                  home: const TodayPage(),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final viewport = tester.getRect(
            find.byKey(const ValueKey('today-timeline-scroll')),
          );
          expect(card(tester, 'a').top, greaterThanOrEqualTo(viewport.top));
          expect(card(tester, 'a').bottom, lessThanOrEqualTo(viewport.bottom));
          expect(card(tester, 'b').bottom, lessThanOrEqualTo(viewport.bottom));
          expect(card(tester, 'c').top + 50, lessThan(viewport.bottom));
          for (final id in ['a', 'b', 'c', 'd']) {
            expect(card(tester, id).height, inInclusiveRange(100.5, 200));
            expect(card(tester, id).right, lessThanOrEqualTo(width));
          }
          expect(
            find.byType(GlassSurface),
            findsNWidgets(4),
          ); // Four courses; Today is a root with no back button.
          expect(tester.takeException(), isNull);
          final qaDirectory = Platform.environment['HUIKE_TODAY_QA_DIR'];
          if (qaDirectory != null && width == 390 && scale == 1) {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('today-qa-screen')),
            );
            await tester.runAsync(() async {
              final capture = await boundary.toImage();
              final data = await capture.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await Directory(qaDirectory).create(recursive: true);
              await File('$qaDirectory/today-${dark ? 'dark' : 'light'}.png')
                  .writeAsBytes(data!.buffer.asUint8List());
              capture.dispose();
            });
          }
          await tester.pumpWidget(const SizedBox()); // disposes live clock
        });
      }
    }
  }
}
