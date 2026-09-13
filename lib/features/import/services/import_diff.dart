import '../../../models/course.dart';

enum ImportChangeKind { added, removed, changed }

class CourseChange {
  const CourseChange({required this.previous, required this.current});

  final Course previous;
  final Course current;

  List<String> get fields {
    final result = <String>[];
    if (previous.name != current.name) result.add('名称');
    if (previous.teacher != current.teacher) result.add('教师');
    if (previous.classroom != current.classroom) result.add('教室');
    if (previous.weekday != current.weekday) result.add('星期');
    if (previous.startSection != current.startSection ||
        previous.endSection != current.endSection) {
      result.add('节次');
    }
    if (!_sameWeeks(previous.weeks, current.weeks)) result.add('周次');
    if (previous.startTime != current.startTime ||
        previous.endTime != current.endTime) {
      result.add('起止时间');
    }
    if (previous.note != current.note) result.add('备注');
    return result;
  }

  static bool _sameWeeks(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    final sortedA = [...a]..sort();
    final sortedB = [...b]..sort();
    for (var i = 0; i < sortedA.length; i++) {
      if (sortedA[i] != sortedB[i]) return false;
    }
    return true;
  }
}

class ImportDiff {
  const ImportDiff({
    required this.added,
    required this.removed,
    required this.changed,
  });

  final List<Course> added;
  final List<Course> removed;
  final List<CourseChange> changed;

  bool get isEmpty => added.isEmpty && removed.isEmpty && changed.isEmpty;
}

/// 与上次导入的差异。按稳定 id 比对，只比较教务来源；
/// 手动课程混入时不算新增、也不会被计为修改。
ImportDiff diffImportedCourses(
  List<Course> currentImported,
  List<Course> nextImported,
) {
  final currentById = {for (final course in currentImported) course.id: course};
  final nextById = {for (final course in nextImported) course.id: course};

  final added = nextImported
      .where((course) => !currentById.containsKey(course.id))
      .toList();
  final removed = currentImported
      .where((course) => !nextById.containsKey(course.id))
      .toList();
  final changed = <CourseChange>[];
  for (final entry in nextById.entries) {
    final previous = currentById[entry.key];
    if (previous == null) continue;
    final change = CourseChange(previous: previous, current: entry.value);
    if (change.fields.isNotEmpty) changed.add(change);
  }
  return ImportDiff(added: added, removed: removed, changed: changed);
}
