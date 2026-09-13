import 'package:flutter_test/flutter_test.dart';
import 'package:huike_timetable/services/week_parser.dart';

void main() {
  group('parseWeeks', () {
    test('解析连续范围', () {
      expect(parseWeeks('1-16周'), List.generate(16, (i) => i + 1));
    });

    test('解析离散周次', () {
      expect(parseWeeks('1,3,5'), [1, 3, 5]);
    });

    test('解析混合范围与离散', () {
      expect(parseWeeks('1-3,5,7-8'), [1, 2, 3, 5, 7, 8]);
    });

    test('单双周筛选', () {
      expect(parseWeeks('1-16(单)'), [1, 3, 5, 7, 9, 11, 13, 15]);
      expect(parseWeeks('1-16(双)'), [2, 4, 6, 8, 10, 12, 14, 16]);
    });

    test('中文括号', () {
      expect(parseWeeks('1-2（单）'), [1]);
    });

    test('空输入抛异常', () {
      expect(() => parseWeeks('  '), throwsA(isA<WeekParseException>()));
    });

    test('无法识别的格式抛异常', () {
      expect(() => parseWeeks('第1周到第5周'), throwsA(isA<WeekParseException>()));
    });

    test('同时单双周抛异常', () {
      expect(() => parseWeeks('1-16(单)(双)'), throwsA(isA<WeekParseException>()));
    });

    test('范围起止倒置抛异常', () {
      expect(() => parseWeeks('8-3'), throwsA(isA<WeekParseException>()));
    });
  });

  group('formatWeeks', () {
    test('空列表', () {
      expect(formatWeeks(const []), '无');
    });

    test('连续区间压缩', () {
      expect(formatWeeks([1, 2, 3, 7, 9, 10]), '1-3,7,9-10周');
    });

    test('输入乱序输出去重后的连续段', () {
      expect(formatWeeks([5, 4, 4, 1]), '1,4-5周');
    });
  });
}
