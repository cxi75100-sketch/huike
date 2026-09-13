import 'package:flutter_test/flutter_test.dart';
import 'package:huike_timetable/features/import/services/import_diff.dart';
import 'package:huike_timetable/models/course.dart';

Course _course(String id, {String name = '数学', int section = 1}) => Course(
  id: id,
  schoolId: 'school-1',
  semesterId: 'sem-1',
  name: name,
  weekday: 1,
  startSection: section,
  endSection: section + 1,
  weeks: const [1, 2, 3],
);

void main() {
  test('新增 / 移除按 id 判定', () {
    final diff = diffImportedCourses(
      [_course('a'), _course('b')],
      [_course('b'), _course('c')],
    );
    expect(diff.added.single.id, 'c');
    expect(diff.removed.single.id, 'a');
    expect(diff.changed, isEmpty);
  });

  test('同 id 内容变化进入 changed 并列出字段', () {
    final previous = Course(
      id: 'a',
      schoolId: 's',
      semesterId: 'sem',
      name: '数学',
      teacher: '张三',
      classroom: 'A101',
      weekday: 1,
      startSection: 1,
      endSection: 2,
      weeks: const [1, 2, 3],
    );
    final current = Course(
      id: 'a',
      schoolId: 's',
      semesterId: 'sem',
      name: '数学',
      teacher: '李四',
      classroom: 'A101',
      weekday: 1,
      startSection: 1,
      endSection: 2,
      weeks: const [1, 2, 4],
    );
    final diff = diffImportedCourses([previous], [current]);
    final change = diff.changed.single;
    expect(change.fields, contains('教师'));
    expect(change.fields, contains('周次'));
    expect(change.fields, isNot(contains('教室')));
  });

  test('周次乱序但内容相同不算修改', () {
    final previous = _course('a');
    final current = Course(
      id: 'a',
      schoolId: 'school-1',
      semesterId: 'sem-1',
      name: '数学',
      weekday: 1,
      startSection: 1,
      endSection: 2,
      weeks: const [3, 2, 1],
    );
    expect(diffImportedCourses([previous], [current]).isEmpty, isTrue);
  });

  test('空对空为空', () {
    expect(diffImportedCourses([], []).isEmpty, isTrue);
  });
}
