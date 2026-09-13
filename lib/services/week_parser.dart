class WeekParseException implements FormatException {
  const WeekParseException(this.message, [this.source]);

  @override
  final String message;
  @override
  final Object? source;
  @override
  int? get offset => null;

  @override
  String toString() => 'WeekParseException: $message';
}

/// 解析“1-16周(单)”风格的周次文本：范围、离散、单双周、中英文括号。
List<int> parseWeeks(String input) {
  var normalized = input.trim().replaceAll('（', '(').replaceAll('）', ')');
  if (normalized.isEmpty) throw const WeekParseException('周次不能为空');
  final odd = normalized.contains('(单)');
  final even = normalized.contains('(双)');
  if (odd && even) {
    throw WeekParseException('不能同时指定单双周', input);
  }
  normalized = normalized
      .replaceAll('(单)', '')
      .replaceAll('(双)', '')
      .replaceAll('周', '')
      .replaceAll(RegExp(r'\s+'), '');
  if (normalized.isEmpty ||
      !RegExp(r'^\d+(?:-\d+)?(?:,\d+(?:-\d+)?)*$').hasMatch(normalized)) {
    throw WeekParseException('无法识别周次格式', input);
  }
  final values = <int>{};
  for (final segment in normalized.split(',')) {
    if (segment.contains('-')) {
      final bounds = segment.split('-').map(int.parse).toList();
      if (bounds[0] < 1 || bounds[1] < bounds[0]) {
        throw WeekParseException('周次范围无效', input);
      }
      values.addAll(
        List<int>.generate(bounds[1] - bounds[0] + 1, (i) => bounds[0] + i),
      );
    } else {
      final value = int.parse(segment);
      if (value < 1) {
        throw WeekParseException('周次必须大于 0', input);
      }
      values.add(value);
    }
  }
  final result =
      values
          .where(
            (week) =>
                (!odd && !even) || (odd && week.isOdd) || (even && week.isEven),
          )
          .toList()
        ..sort();
  if (result.isEmpty) {
    throw WeekParseException('筛选后没有有效周次', input);
  }
  return result;
}

String formatWeeks(List<int> weeks) {
  if (weeks.isEmpty) return '无';
  final sorted = weeks.toSet().toList()..sort();
  final parts = <String>[];
  var start = sorted.first;
  var previous = start;
  for (final week in sorted.skip(1)) {
    if (week == previous + 1) {
      previous = week;
      continue;
    }
    parts.add(start == previous ? '$start' : '$start-$previous');
    start = previous = week;
  }
  parts.add(start == previous ? '$start' : '$start-$previous');
  return '${parts.join(',')}周';
}
