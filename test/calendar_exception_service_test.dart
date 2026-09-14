import 'package:flutter_test/flutter_test.dart';
import 'package:huike_timetable/models/calendar_exception.dart';
import 'package:huike_timetable/services/calendar_exception_service.dart';

CalendarException _exception(
  DateTime date, {
  CalendarExceptionKind kind = CalendarExceptionKind.holiday,
  int? makeupWeekday,
}) => CalendarException(
  id: 'cal-${date.month}-${date.day}',
  schoolId: 'school-1',
  semesterId: 'semester-1',
  date: date,
  kind: kind,
  makeupWeekday: makeupWeekday,
);

void main() {
  const service = CalendarExceptionService();

  group('CalendarExceptionService.resolve 无例外', () {
    test('按自然星期上课', () {
      // 2026-09-14 是周一。
      final schedule = service.resolve(DateTime(2026, 9, 14));
      expect(schedule.weekday, DateTime.monday);
      expect(schedule.suspended, isFalse);
      expect(schedule.isMakeup, isFalse);
      expect(schedule.exception, isNull);
    });

    test('周日解析为 7', () {
      expect(service.resolve(DateTime(2026, 9, 20)).weekday, DateTime.sunday);
    });
  });

  group('停课', () {
    final holiday = CalendarExceptionService([
      _exception(DateTime(2026, 10, 1)),
    ]);

    test('当天停课，其余日期不受影响', () {
      final schedule = holiday.resolve(DateTime(2026, 10, 1, 15, 30));
      expect(schedule.suspended, isTrue);
      expect(schedule.weekday, DateTime.thursday); // 仍报自然星期，供展示
      expect(schedule.isMakeup, isFalse);
      expect(holiday.resolve(DateTime(2026, 10, 2)).suspended, isFalse);
    });

    test('只比较年月日：同一天任意时刻都命中', () {
      expect(
        holiday.forDate(DateTime(2026, 10, 1, 23, 59)),
        isNotNull,
      );
      expect(
        holiday.forDate(DateTime(2026, 10, 1, 0, 0)),
        isNotNull,
      );
    });
  });

  group('调休补课', () {
    // 2026-10-10 是周六，补上周四（10-08）的课。
    final makeup = CalendarExceptionService([
      _exception(
        DateTime(2026, 10, 10),
        kind: CalendarExceptionKind.makeup,
        makeupWeekday: DateTime.thursday,
      ),
    ]);

    test('按目标星期上课，且不算停课', () {
      final schedule = makeup.resolve(DateTime(2026, 10, 10));
      expect(schedule.suspended, isFalse);
      expect(schedule.isMakeup, isTrue);
      expect(schedule.weekday, DateTime.thursday);
      expect(schedule.exception?.makeupWeekday, DateTime.thursday);
    });

    test('未指定目标星期时退回自然星期', () {
      final service = CalendarExceptionService([
        _exception(
          DateTime(2026, 10, 10),
          kind: CalendarExceptionKind.makeup,
        ),
      ]);
      final schedule = service.resolve(DateTime(2026, 10, 10));
      expect(schedule.weekday, DateTime.saturday);
      expect(schedule.isMakeup, isTrue);
    });

    test('越界的目标星期被夹到 1-7', () {
      final service = CalendarExceptionService([
        _exception(
          DateTime(2026, 10, 10),
          kind: CalendarExceptionKind.makeup,
          makeupWeekday: 99,
        ),
      ]);
      expect(service.resolve(DateTime(2026, 10, 10)).weekday, 7);
    });
  });

  test('多条例外各管各的日期', () {
    final service = CalendarExceptionService([
      _exception(DateTime(2026, 10, 1)),
      _exception(
        DateTime(2026, 10, 10),
        kind: CalendarExceptionKind.makeup,
        makeupWeekday: DateTime.thursday,
      ),
    ]);
    expect(service.resolve(DateTime(2026, 10, 1)).suspended, isTrue);
    expect(service.resolve(DateTime(2026, 10, 10)).weekday, DateTime.thursday);
    expect(service.resolve(DateTime(2026, 10, 11)).suspended, isFalse);
    expect(service.exceptions.length, 2);
  });

  test('weekdayName 输出中文星期', () {
    expect(CalendarExceptionService.weekdayName(1), '周一');
    expect(CalendarExceptionService.weekdayName(7), '周日');
  });
}
