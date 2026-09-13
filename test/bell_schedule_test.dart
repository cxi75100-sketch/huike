import 'package:flutter_test/flutter_test.dart';
import 'package:huike_timetable/models/bell_schedule.dart';

void main() {
  group('BellSchedule.fallback', () {
    test('生成 10 节通用作息，晚上最多两节', () {
      final schedule = BellSchedule.fallback();
      expect(schedule.sections.length, 10);
      expect(schedule.section(1)!.start, '08:00');
      expect(schedule.section(4)!.end, '11:40');
      expect(schedule.section(5)!.start, '14:00');
      expect(schedule.section(9)!.start, '19:00');
      expect(schedule.section(9)!.group, SectionGroup.evening);
      expect(schedule.section(11), isNull);
    });

    test('上下午分组：上午 4 / 下午 4 / 晚上 2', () {
      final schedule = BellSchedule.fallback();
      expect(schedule.section(2)!.group, SectionGroup.morning);
      expect(schedule.section(6)!.group, SectionGroup.afternoon);
      expect(schedule.section(10)!.group, SectionGroup.evening);
      final groups = schedule.groupByPeriod();
      expect(groups[SectionGroup.morning]!.length, 4);
      expect(groups[SectionGroup.afternoon]!.length, 4);
      expect(groups[SectionGroup.evening]!.length, 2);
    });
  });

  group('作息变体（按教室匹配）', () {
    final base = BellSchedule.fallback();
    final variant = ScheduleVariant(
      id: 'test.early',
      keywords: ['明志', '明德', '至善'],
      overrides: const {3: ('10:15', '10:55'), 4: ('11:05', '11:45')},
    );
    final schedule = BellSchedule(
      sections: base.sections,
      variants: [variant],
    );

    test('命中关键词的教室用变体时间', () {
      expect(
        schedule.resolveRange(3, 4, classroom: '明志楼301'),
        ('10:15', '11:45'),
      );
      expect(
        schedule.resolveRange(3, 4, classroom: '至善楼 201'),
        ('10:15', '11:45'),
      );
    });

    test('未命中的教室走基础时间', () {
      expect(
        schedule.resolveRange(3, 4, classroom: '其他楼102'),
        ('10:00', '11:40'),
      );
      expect(schedule.resolveRange(3, 4), ('10:00', '11:40'));
    });

    test('变体未覆盖的节次仍走基础时间', () {
      expect(
        schedule.resolveRange(1, 2, classroom: '明志楼301'),
        ('08:00', '09:40'),
      );
    });

    test('变体 JSON 往返', () {
      final restored = ScheduleVariant.fromJson(variant.toJson());
      expect(restored.id, variant.id);
      expect(restored.keywords, variant.keywords);
      expect(restored.overrides, variant.overrides);
    });
  });

  group('resolveRange', () {
    test('跨节次取首节开始与末节结束', () {
      final schedule = BellSchedule.fallback();
      final range = schedule.resolveRange(3, 4);
      expect(range, ('10:00', '11:40'));
    });

    test('缺失节次返回 null 而不是猜', () {
      final schedule = BellSchedule.fallback();
      expect(schedule.resolveRange(3, 13), isNull);
      expect(schedule.resolveRange(0, 2), isNull);
    });
  });

  group('groupByPeriod', () {
    test('按时段分组且节次有序', () {
      final schedule = BellSchedule.fallback();
      final groups = schedule.groupByPeriod();
      expect(groups[SectionGroup.morning]!.length, 4);
      expect(groups[SectionGroup.afternoon]!.length, 4);
      expect(groups[SectionGroup.evening]!.length, 2);
      expect(
        groups[SectionGroup.morning]!.map((s) => s.index).toList(),
        [1, 2, 3, 4],
      );
    });
  });
}
