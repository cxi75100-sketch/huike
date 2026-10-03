import 'package:flutter_test/flutter_test.dart';
import 'package:huike_timetable/features/import/models/adapter_batch.dart';

void main() {
  const normalizer = AdapterBatchNormalizer();

  group('courses', () {
    test('契约形状完整解析', () {
      final batch = normalizer.normalize(
        rawCourses: [
          {
            'name': '高等数学',
            'teacher': '张三',
            'position': '明理楼 301',
            'day': 1,
            'startSection': 3,
            'endSection': 4,
            'weeks': [1, 2, 3, 4, 5],
          },
        ],
      );
      expect(batch.courses, hasLength(1));
      final course = batch.courses.single;
      expect(course.name, '高等数学');
      expect(course.teacher, '张三');
      expect(course.classroom, '明理楼 301');
      expect(course.weekday, 1);
      expect(course.startSection, 3);
      expect(course.endSection, 4);
      expect(course.weeks, [1, 2, 3, 4, 5]);
      expect(batch.invalidCount, 0);
    });

    test('缺 endSection 时退化为单节', () {
      final batch = normalizer.normalize(
        rawCourses: [
          {
            'name': '体育',
            'day': 5,
            'startSection': 9,
            'weeks': [1],
          },
        ],
      );
      expect(batch.courses.single.endSection, 9);
    });

    test('weeks 支持周次文本', () {
      final batch = normalizer.normalize(
        rawCourses: [
          {'name': '英语', 'day': 2, 'startSection': 1, 'weeks': '1-16(单)'},
        ],
      );
      expect(batch.courses.single.weeks, [1, 3, 5, 7, 9, 11, 13, 15]);
    });

    test('day 为 0（无法定位星期）被丢弃并计数', () {
      final batch = normalizer.normalize(
        rawCourses: [
          {
            'name': '未知课',
            'day': 0,
            'startSection': 1,
            'weeks': [1],
          },
        ],
      );
      expect(batch.courses, isEmpty);
      expect(batch.invalidCount, 1);
      expect(batch.invalidReasons.single, contains('星期'));
    });

    test('缺课程名被丢弃', () {
      final batch = normalizer.normalize(
        rawCourses: [
          {
            'day': 1,
            'startSection': 1,
            'weeks': [1],
          },
        ],
      );
      expect(batch.invalidCount, 1);
    });

    test('weeks 为空被丢弃', () {
      final batch = normalizer.normalize(
        rawCourses: [
          {'name': '空周次', 'day': 1, 'startSection': 1, 'weeks': []},
        ],
      );
      expect(batch.invalidCount, 1);
    });

    test('非对象条目被丢弃', () {
      final batch = normalizer.normalize(rawCourses: ['oops', 42]);
      expect(batch.invalidCount, 2);
    });

    test('学校配置字段别名可映射到相同的统一课程模型', () {
      final batch = normalizer.normalize(
        rawCourses: [
          {
            'courseTitle': '配置化课程',
            'weekdayIndex': 4,
            'sectionStart': 7,
            'weekList': [2, 4],
          },
        ],
        courseFieldAliases: const {
          'name': 'courseTitle',
          'day': 'weekdayIndex',
          'startSection': 'sectionStart',
          'weeks': 'weekList',
        },
      );
      expect(batch.courses.single.name, '配置化课程');
      expect(batch.courses.single.weekday, 4);
      expect(batch.courses.single.startSection, 7);
      expect(batch.courses.single.weeks, [2, 4]);
    });
  });

  group('timeSlots', () {
    test('解析节次时间', () {
      final batch = normalizer.normalize(
        rawCourses: const [],
        rawTimeSlots: [
          {'number': 1, 'startTime': '08:00', 'endTime': '08:45'},
        ],
      );
      expect(batch.timeSlots.single.startTime, '08:00');
    });

    test('格式非法的节次被忽略', () {
      final batch = normalizer.normalize(
        rawCourses: const [],
        rawTimeSlots: [
          {'number': 1, 'startTime': '8点', 'endTime': '08:45'},
        ],
      );
      expect(batch.timeSlots, isEmpty);
    });
  });

  group('courseConfig', () {
    test('解析开学日期与总周数', () {
      final batch = normalizer.normalize(
        rawCourses: const [],
        rawConfig: {'semesterStartDate': '2026-09-07', 'totalWeeks': 18},
      );
      expect(batch.courseConfig.semesterStartDate, DateTime(2026, 9, 7));
      expect(batch.courseConfig.totalWeeks, 18);
    });

    test('非法日期与超界周数忽略', () {
      final batch = normalizer.normalize(
        rawCourses: const [],
        rawConfig: {'semesterStartDate': '2026/09/07', 'totalWeeks': 99},
      );
      expect(batch.courseConfig.semesterStartDate, isNull);
      expect(batch.courseConfig.totalWeeks, isNull);
    });
  });
}
