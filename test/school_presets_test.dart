import 'package:flutter_test/flutter_test.dart';
import 'package:huike_timetable/features/schools/services/school_presets.dart';
import 'package:huike_timetable/services/course_time_service.dart';
import 'package:huike_timetable/models/course.dart';

void main() {
  final preset = presetById('ncpu')!;

  test('南工档案存在且为 10 节', () {
    expect(preset, isNotNull);
    expect(preset.bell.sections, hasLength(10));
    expect(preset.defaultFirstWeekMonday, DateTime(2026, 8, 31));
    expect(preset.defaultTotalWeeks, 20);
  });

  test('校历作息时间逐节正确', () {
    final bell = preset.bell;
    expect(bell.resolveRange(1, 1), ('08:20', '09:00'));
    expect(bell.resolveRange(2, 2), ('09:10', '09:50'));
    expect(bell.resolveRange(5, 5), ('14:00', '14:40'));
    expect(bell.resolveRange(8, 8), ('16:45', '17:25'));
    expect(bell.resolveRange(9, 10), ('19:00', '20:30'));
  });

  test('第 3、4 节按教学楼变体：明志/明德/至善提前', () {
    final bell = preset.bell;
    expect(
      bell.resolveRange(3, 3, classroom: '明志楼302'),
      ('10:15', '10:55'),
    );
    expect(
      bell.resolveRange(4, 4, classroom: '明德楼105'),
      ('11:05', '11:45'),
    );
    expect(
      bell.resolveRange(3, 4, classroom: '至善楼101'),
      ('10:15', '11:45'),
    );
    // 其他教学场所走基础时间
    expect(
      bell.resolveRange(3, 4, classroom: '实验楼A202'),
      ('10:25', '11:55'),
    );
  });

  test('CourseTimeService 组合：显式时间 > 变体 > 基础', () {
    final bell = preset.bell;
    const service = CourseTimeService();

    Course course(String classroom, {String? start, String? end}) => Course(
      id: 'c',
      schoolId: 's',
      semesterId: 'sem',
      name: '课',
      weekday: 1,
      startSection: 3,
      endSection: 4,
      weeks: const [1],
      classroom: classroom,
      startTime: start,
      endTime: end,
    );

    expect(service.resolve(course('明志楼301'), bell), ('10:15', '11:45'));
    expect(service.resolve(course('其他楼'), bell), ('10:25', '11:55'));
    expect(
      service.resolve(course('明志楼301', start: '09:00', end: '10:00'), bell),
      ('09:00', '10:00'),
    );
  });

  test('未知预设返回 null（走通用兜底）', () {
    expect(presetById('nope'), isNull);
  });

  test('南工教务默认地址为明文 HTTP（导入门会额外警示）', () {
    expect(preset.defaultLoginUrl, 'http://jwxt.ncpu.edu.cn');
    expect(Uri.parse(preset.defaultLoginUrl).scheme, 'http');
  });
}
