import 'package:flutter_test/flutter_test.dart';
import 'package:huike_timetable/models/bell_schedule.dart';

void main() {
  group('BellSchedule.fallback', () {
    test('生成 12 节通用作息', () {
      final schedule = BellSchedule.fallback();
      expect(schedule.sections.length, 12);
      expect(schedule.section(1)!.start, '08:00');
      expect(schedule.section(4)!.end, '11:40');
      expect(schedule.section(5)!.start, '14:00');
      expect(schedule.section(9)!.group, SectionGroup.evening);
    });

    test('上下午分组', () {
      final schedule = BellSchedule.fallback();
      expect(schedule.section(2)!.group, SectionGroup.morning);
      expect(schedule.section(6)!.group, SectionGroup.afternoon);
      expect(schedule.section(10)!.group, SectionGroup.evening);
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
      expect(groups[SectionGroup.evening]!.length, 4);
      expect(
        groups[SectionGroup.morning]!.map((s) => s.index).toList(),
        [1, 2, 3, 4],
      );
    });
  });
}
