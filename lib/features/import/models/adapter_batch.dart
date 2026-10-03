import '../../../services/week_parser.dart';

/// 适配脚本回传数据的规范化结果。
///
/// 契约形状（社区脚本约定，证据见 knowledge/adapters.md）：
/// - courses: [{name, teacher?, position?, day, startSection, endSection, weeks}]
/// - timeSlots: [{number, startTime, endTime}]
/// - courseConfig: {semesterStartDate: 'YYYY-MM-DD', totalWeeks: int}
/// 不满足契约的条目不猜语义，直接丢弃并计数，预览页会明示。
class AdapterCourseDraft {
  const AdapterCourseDraft({
    required this.name,
    required this.weekday,
    required this.startSection,
    required this.endSection,
    required this.weeks,
    this.teacher = '',
    this.classroom = '',
  });

  final String name;
  final String teacher;
  final String classroom;
  final int weekday;
  final int startSection;
  final int endSection;
  final List<int> weeks;

  Map<String, String> toFieldMap() => {
    'name': name,
    'weekday': '$weekday',
    'sections': startSection == endSection
        ? '$startSection'
        : '$startSection-$endSection',
    'weeks': weeks.join(','),
  };
}

class AdapterTimeSlot {
  const AdapterTimeSlot({
    required this.number,
    required this.startTime,
    required this.endTime,
  });

  final int number;
  final String startTime;
  final String endTime;
}

class AdapterCourseConfig {
  const AdapterCourseConfig({this.semesterStartDate, this.totalWeeks});

  final DateTime? semesterStartDate;
  final int? totalWeeks;
}

class AdapterImportBatch {
  const AdapterImportBatch({
    required this.courses,
    required this.timeSlots,
    required this.courseConfig,
    required this.invalidCount,
    required this.invalidReasons,
  });

  final List<AdapterCourseDraft> courses;
  final List<AdapterTimeSlot> timeSlots;
  final AdapterCourseConfig courseConfig;
  final int invalidCount;
  final List<String> invalidReasons;

  bool get isEmpty => courses.isEmpty;
}

class AdapterBatchNormalizer {
  const AdapterBatchNormalizer();

  AdapterImportBatch normalize({
    required List<dynamic> rawCourses,
    List<dynamic>? rawTimeSlots,
    Map<String, dynamic>? rawConfig,
    Map<String, String> courseFieldAliases = const {},
  }) {
    final reasons = <String>[];
    final courses = <AdapterCourseDraft>[];
    for (var i = 0; i < rawCourses.length; i++) {
      final draft = _normalizeCourse(rawCourses[i], courseFieldAliases);
      if (draft == null) {
        reasons.add(_describe(rawCourses[i], i, courseFieldAliases));
      } else {
        courses.add(draft);
      }
    }

    final timeSlots = <AdapterTimeSlot>[];
    for (final raw in rawTimeSlots ?? const []) {
      final slot = _normalizeTimeSlot(raw);
      if (slot != null) timeSlots.add(slot);
    }

    final config = _normalizeConfig(rawConfig);
    return AdapterImportBatch(
      courses: courses,
      timeSlots: timeSlots,
      courseConfig: config,
      invalidCount: rawCourses.length - courses.length,
      invalidReasons: reasons.take(5).toList(),
    );
  }

  AdapterCourseDraft? _normalizeCourse(
    Object? raw,
    Map<String, String> fieldAliases,
  ) {
    if (raw is! Map) return null;
    final name = _string(_field(raw, fieldAliases, 'name', const ['name']));
    if (name.isEmpty) return null;

    final weekday = _int(
      _field(raw, fieldAliases, 'day', const ['day', 'weekday']),
    );
    if (weekday == null || weekday < 1 || weekday > 7) return null;

    final startSection = _int(
      _field(raw, fieldAliases, 'startSection', const [
        'startSection',
        'start',
      ]),
    );
    if (startSection == null || startSection < 1 || startSection > 30) {
      return null;
    }
    final endSection =
        _int(
          _field(raw, fieldAliases, 'endSection', const ['endSection', 'end']),
        ) ??
        startSection;
    if (endSection < startSection || endSection > 30) return null;

    final weeks = _normalizeWeeks(
      _field(raw, fieldAliases, 'weeks', const ['weeks']),
    );
    if (weeks == null || weeks.isEmpty) return null;

    return AdapterCourseDraft(
      name: name,
      teacher: _string(_field(raw, fieldAliases, 'teacher', const ['teacher'])),
      classroom: _string(
        _field(raw, fieldAliases, 'position', const [
          'position',
          'classroom',
          'room',
        ]),
      ),
      weekday: weekday,
      startSection: startSection,
      endSection: endSection,
      weeks: weeks,
    );
  }

  List<int>? _normalizeWeeks(Object? raw) {
    if (raw is List) {
      final weeks = <int>{};
      for (final item in raw) {
        final week = _int(item);
        if (week == null || week < 1 || week > 40) return null;
        weeks.add(week);
      }
      return weeks.toList()..sort();
    }
    if (raw is String) {
      try {
        return parseWeeks(raw);
      } on WeekParseException {
        return null;
      }
    }
    return null;
  }

  AdapterTimeSlot? _normalizeTimeSlot(Object? raw) {
    if (raw is! Map) return null;
    final number = _int(raw['number'] ?? raw['section']);
    final start = _time(raw['startTime'] ?? raw['start']);
    final end = _time(raw['endTime'] ?? raw['end']);
    if (number == null || start == null || end == null) return null;
    return AdapterTimeSlot(number: number, startTime: start, endTime: end);
  }

  AdapterCourseConfig _normalizeConfig(Map<String, dynamic>? raw) {
    if (raw == null) return const AdapterCourseConfig();
    final dateText = _string(raw['semesterStartDate'] ?? raw['startDate']);
    DateTime? startDate;
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateText)) {
      startDate = DateTime.tryParse(dateText);
    }
    final totalWeeks = _int(raw['totalWeeks']);
    return AdapterCourseConfig(
      semesterStartDate: startDate,
      totalWeeks: (totalWeeks != null && totalWeeks >= 1 && totalWeeks <= 30)
          ? totalWeeks
          : null,
    );
  }

  String? _time(Object? raw) {
    final value = _string(raw);
    return RegExp(r'^\d{1,2}:\d{2}$').hasMatch(value) ? value : null;
  }

  int? _int(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) {
      final normalized = raw.trim();
      return int.tryParse(normalized) ?? double.tryParse(normalized)?.toInt();
    }
    return null;
  }

  String _string(Object? raw) => raw?.toString().trim() ?? '';

  String _describe(Object? raw, int index, Map<String, String> fieldAliases) {
    if (raw is! Map) return '第 ${index + 1} 条：不是对象';
    final name = _string(_field(raw, fieldAliases, 'name', const ['name']));
    if (name.isEmpty) return '第 ${index + 1} 条：缺少课程名';
    final weekday = _int(
      _field(raw, fieldAliases, 'day', const ['day', 'weekday']),
    );
    if (weekday == null || weekday < 1 || weekday > 7) {
      return '第 ${index + 1} 条：星期无法识别（$name）';
    }
    return '第 ${index + 1} 条：节次或周次无法识别（$name）';
  }

  Object? _field(
    Map raw,
    Map<String, String> aliases,
    String canonical,
    List<String> existingKeys,
  ) {
    final alias = aliases[canonical];
    if (alias != null && raw.containsKey(alias)) return raw[alias];
    for (final key in existingKeys) {
      if (raw.containsKey(key)) return raw[key];
    }
    return null;
  }
}
