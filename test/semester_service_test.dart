import 'package:flutter_test/flutter_test.dart';
import 'package:huike_timetable/models/semester.dart';
import 'package:huike_timetable/services/semester_service.dart';

void main() {
  final service = const SemesterService();
  final semester = Semester(
    id: 's1',
    schoolId: 'school-1',
    firstWeekMonday: DateTime(2026, 8, 31),
    totalWeeks: 20,
  );

  group('currentWeek', () {
    test('开学第一天是第 1 周', () {
      expect(service.currentWeek(semester, DateTime(2026, 8, 31)), 1);
    });

    test('一周后的周一是第 2 周', () {
      expect(service.currentWeek(semester, DateTime(2026, 9, 7)), 2);
    });

    test('开学前为 0', () {
      expect(service.currentWeek(semester, DateTime(2026, 8, 30)), 0);
    });

    test('超出学期封顶到 totalWeeks', () {
      expect(service.currentWeek(semester, DateTime(2027, 6, 1)), 20);
    });

    test('时间部分不影响计算', () {
      expect(service.currentWeek(semester, DateTime(2026, 9, 7, 23, 59)), 2);
    });
  });

  group('termStatus', () {
    test('before / within / after', () {
      expect(service.termStatus(semester, DateTime(2026, 8, 30)), TermStatus.before);
      expect(service.termStatus(semester, DateTime(2026, 9, 9)), TermStatus.within);
      expect(service.termStatus(semester, DateTime(2027, 1, 20)), TermStatus.after);
    });

    test('第 20 周仍在学期内', () {
      expect(service.termStatus(semester, DateTime(2027, 1, 10)), TermStatus.within);
    });
  });

  group('dateFor / weekMonday / weekdayOf', () {
    test('第 N 周星期 X 的日期', () {
      expect(service.dateFor(semester, 1, 1), DateTime(2026, 8, 31));
      expect(service.dateFor(semester, 2, 3), DateTime(2026, 9, 9));
    });

    test('dateFor 不夹取范围', () {
      expect(service.dateFor(semester, 21, 1), DateTime(2027, 1, 18));
    });

    test('weekMonday 夹取到学期范围', () {
      expect(service.weekMonday(semester, 25), DateTime(2027, 1, 11));
    });

    test('weekdayOf 返回 1..7', () {
      expect(service.weekdayOf(DateTime(2026, 9, 7)), 1);
      expect(service.weekdayOf(DateTime(2026, 9, 13)), 7);
    });
  });
}
