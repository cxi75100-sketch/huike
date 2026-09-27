import 'package:flutter_test/flutter_test.dart';
import 'package:huike_timetable/features/timetable/services/week_agenda.dart';
import 'package:huike_timetable/models/calendar_exception.dart';
import 'package:huike_timetable/models/course.dart';
import 'package:huike_timetable/models/semester.dart';
import 'package:huike_timetable/services/calendar_exception_service.dart';
import 'package:huike_timetable/services/semester_service.dart';

/// TASK-013 的模型层：整周日期顺序、当前周锚点、例外折算与学期进度。
///
/// 日期顺序只有一个来源（[buildWeekAgenda]），所以边界（周一 / 周日 /
/// 学期前后）都在这里用注入的时间覆盖，不依赖跑测试当天是星期几。
void main() {
  final service = const SemesterService();

  // 2026-08-31 是周一：第 1 周 = 8/31..9/6，第 2 周 = 9/7..9/13，
  // 第 16 周 = 12/14..12/20，学期末日为 12/20。
  final semester = Semester(
    id: 's1',
    schoolId: 'school-1',
    firstWeekMonday: DateTime(2026, 8, 31),
    totalWeeks: 16,
  );

  WeekAgenda agenda({
    required int week,
    required DateTime today,
    List<Course> courses = const [],
    List<CalendarException> exceptions = const [],
  }) => buildWeekAgenda(
    semester: semester,
    week: week,
    courses: courses,
    calendar: CalendarExceptionService(exceptions),
    today: today,
  );

  Course course({
    required String name,
    required int weekday,
    List<int> weeks = const [
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12,
      13,
      14,
      15,
      16,
    ],
    int startSection = 1,
    int endSection = 2,
  }) => Course(
    id: name,
    schoolId: 'school-1',
    semesterId: 's1',
    name: name,
    weekday: weekday,
    startSection: startSection,
    endSection: endSection,
    weeks: weeks,
  );

  group('日期顺序', () {
    test('恒为周一 → 周日，各出现一次', () {
      final days = agenda(week: 1, today: DateTime(2026, 9, 2)).days;
      expect(days.map((day) => day.weekday).toList(), [1, 2, 3, 4, 5, 6, 7]);
      expect(days.map((day) => day.index).toList(), [0, 1, 2, 3, 4, 5, 6]);
    });

    test('七天是连续日期，且不越到下一教学周', () {
      final days = agenda(week: 1, today: DateTime(2026, 9, 2)).days;
      expect(days.first.date, DateTime(2026, 8, 31));
      expect(days.last.date, DateTime(2026, 9, 6));
      for (var i = 1; i < days.length; i++) {
        expect(days[i].date.difference(days[i - 1].date).inDays, 1);
      }
      // 第 2 周的周一（9/7）不能出现在第 1 周的议程里。
      expect(days.any((day) => day.date == DateTime(2026, 9, 7)), isFalse);
    });

    test('周日之后没有同一周的周一', () {
      // 今天是第 1 周的周日（9/6）。
      final days = agenda(week: 1, today: DateTime(2026, 9, 6)).days;
      expect(days.last.weekday, 7);
      expect(days.last.date, DateTime(2026, 9, 6));
      expect(days.where((day) => day.weekday == 1).length, 1);
      expect(days.first.date, DateTime(2026, 8, 31));
    });
  });

  group('当前周锚点', () {
    test('今天是周中：锚点就是今天', () {
      // 第 2 周的周三是 9/9。
      final result = agenda(week: 2, today: DateTime(2026, 9, 9));
      expect(result.isCurrentWeek, isTrue);
      expect(result.anchorIndex, 2);
      expect(result.days[2].isToday, isTrue);
      expect(result.days[2].date, DateTime(2026, 9, 9));
    });

    test('今天是周一：锚点为 0', () {
      final result = agenda(week: 2, today: DateTime(2026, 9, 7));
      expect(result.anchorIndex, 0);
    });

    test('今天是周日：锚点为 6', () {
      final result = agenda(week: 2, today: DateTime(2026, 9, 13));
      expect(result.anchorIndex, 6);
    });

    test('时间部分不影响锚定', () {
      final result = agenda(week: 2, today: DateTime(2026, 9, 9, 23, 59));
      expect(result.anchorIndex, 2);
    });

    test('看其它周：没有锚点，从周一开始', () {
      final result = agenda(week: 1, today: DateTime(2026, 9, 9));
      expect(result.anchorIndex, isNull);
      expect(result.isCurrentWeek, isFalse);
      expect(result.days.first.weekday, 1);
      expect(result.days.any((day) => day.isToday), isFalse);
    });

    test('学期开始前没有锚点', () {
      final result = agenda(week: 1, today: DateTime(2026, 8, 30));
      expect(result.anchorIndex, isNull);
    });

    test('学期结束后看最后一周也不算当前周', () {
      // 第 16 周是 12/14..12/20，今天是 2027-02-01（学期已结束）。
      final result = agenda(week: 16, today: DateTime(2027, 2, 1));
      expect(result.anchorIndex, isNull);
      expect(result.days.first.date, DateTime(2026, 12, 14));
    });
  });

  group('课程与例外折算', () {
    test('按星期取课并按开始节次排序', () {
      final days = agenda(
        week: 2,
        today: DateTime(2026, 9, 7),
        courses: [
          course(name: 'Course B', weekday: 1, startSection: 3, endSection: 4),
          course(name: 'Course A', weekday: 1, startSection: 1, endSection: 2),
        ],
      ).days;
      expect(days[0].courses.map((item) => item.name).toList(), [
        'Course A',
        'Course B',
      ]);
      expect(days[1].courses, isEmpty);
    });

    test('不属于本周的课程不出现', () {
      final days = agenda(
        week: 3,
        today: DateTime(2026, 9, 14),
        courses: [
          course(name: 'Course A', weekday: 1, weeks: const [1]),
        ],
      ).days;
      expect(days[0].courses, isEmpty);
    });

    test('停课日为空并标记停课', () {
      final days = agenda(
        week: 2,
        today: DateTime(2026, 9, 8),
        courses: [course(name: 'Course A', weekday: 2)],
        exceptions: [
          CalendarException(
            id: 'e1',
            schoolId: 'school-1',
            semesterId: 's1',
            date: DateTime(2026, 9, 8),
            kind: CalendarExceptionKind.holiday,
          ),
        ],
      ).days;
      expect(days[1].suspended, isTrue);
      expect(days[1].courses, isEmpty);
      expect(days[2].suspended, isFalse);
    });

    test('调休日按目标星期的课表上课，自然星期不变', () {
      // 第 2 周的周六（9/12）按周四的课表上课。
      final days = agenda(
        week: 2,
        today: DateTime(2026, 9, 12),
        courses: [course(name: 'Course D', weekday: 4)],
        exceptions: [
          CalendarException(
            id: 'e1',
            schoolId: 'school-1',
            semesterId: 's1',
            date: DateTime(2026, 9, 12),
            kind: CalendarExceptionKind.makeup,
            makeupWeekday: 4,
          ),
        ],
      ).days;
      final saturday = days[5];
      expect(saturday.weekday, 6);
      expect(saturday.schedule.weekday, 4);
      expect(saturday.isMakeup, isTrue);
      expect(saturday.makeupLabel, '按周四上课');
      expect(saturday.courses.map((item) => item.name).toList(), ['Course D']);
      // 周四本来就有这门课；周六是按周四的课表补上的，周日不受影响。
      expect(days[3].courses.map((item) => item.name).toList(), ['Course D']);
      expect(days[6].courses, isEmpty);
    });
  });

  group('日期元信息', () {
    test('今天 / 过去日期标记', () {
      final days = agenda(week: 2, today: DateTime(2026, 9, 9)).days;
      expect(days[2].isToday, isTrue);
      expect(days[1].isPast, isTrue);
      expect(days[3].isPast, isFalse);
    });

    test('周一首日与跨月第一天显示月份', () {
      final days = agenda(week: 1, today: DateTime(2026, 9, 2)).days;
      expect(days[0].showMonth, isTrue);
      expect(days[0].monthLabel, '8月');
      // 9/1 是周二，跨月第一天也要带月份。
      expect(days[1].showMonth, isTrue);
      expect(days[1].monthLabel, '9月');
      expect(days[2].showMonth, isFalse);
      expect(days[6].showMonth, isFalse);
    });

    test('星期文案', () {
      final days = agenda(week: 1, today: DateTime(2026, 9, 2)).days;
      expect(days[0].weekdayLabel, '周一');
      expect(days[6].weekdayLabel, '周日');
    });
  });

  group('学期翻页进度', () {
    test('学期中按「第几周 / 总周数」', () {
      final result = service.readingProgress(
        semester,
        4,
        DateTime(2026, 9, 20),
      );
      expect(result.mark, '阅至此处');
      expect(result.progress, closeTo(4 / 16, 0.0001));
    });

    test('开学前为 0，落款「尚未开卷」', () {
      final result = service.readingProgress(
        semester,
        1,
        DateTime(2026, 8, 30),
      );
      expect(result.mark, '尚未开卷');
      expect(result.progress, 0);
    });

    test('学期结束后为 1，落款「此卷已毕」', () {
      final result = service.readingProgress(
        semester,
        16,
        DateTime(2027, 2, 1),
      );
      expect(result.mark, '此卷已毕');
      expect(result.progress, 1);
    });

    test('进度夹取在 0..1', () {
      expect(
        service.readingProgress(semester, 0, DateTime(2026, 9, 20)).progress,
        0,
      );
      expect(
        service.readingProgress(semester, 99, DateTime(2026, 9, 20)).progress,
        1,
      );
    });
  });
}
