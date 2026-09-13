/// 一节课所属的时段。它是数据而不是 UI 常量：
/// 课表分组、时段标题都由它派生，节次划分不同的学校不会错位。
enum SectionGroup { morning, afternoon, evening }

SectionGroup sectionGroupFromString(String value) => switch (value) {
  'afternoon' => SectionGroup.afternoon,
  'evening' => SectionGroup.evening,
  _ => SectionGroup.morning,
};

String sectionGroupName(SectionGroup group) => switch (group) {
  SectionGroup.morning => '上午',
  SectionGroup.afternoon => '下午',
  SectionGroup.evening => '晚上',
};

class SectionSpec {
  const SectionSpec({
    required this.index,
    required this.start,
    required this.end,
    required this.group,
  });

  /// 1 起算的节次序号。
  final int index;
  final String start;
  final String end;
  final SectionGroup group;
}

/// 作息变体：同一节次在特定教室（如某几栋教学楼）使用不同时间。
///
/// 典型例子：南工第 3、4 节在明志楼/明德楼/至善楼提前 10 分钟上课。
/// 匹配规则是教室文本包含任一关键词；命中的节次用 [overrides] 里的时间。
class ScheduleVariant {
  const ScheduleVariant({
    required this.id,
    required this.keywords,
    required this.overrides,
  });

  final String id;
  final List<String> keywords;

  /// 节次 -> (开始, 结束)。
  final Map<int, (String, String)> overrides;

  bool matchesClassroom(String? classroom) {
    if (classroom == null || classroom.isEmpty) return false;
    for (final keyword in keywords) {
      if (classroom.contains(keyword)) return true;
    }
    return false;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'keywords': keywords,
    'overrides': {
      for (final entry in overrides.entries)
        entry.key.toString(): [entry.value.$1, entry.value.$2],
    },
  };

  static ScheduleVariant fromJson(Map<String, dynamic> json) {
    final rawOverrides = (json['overrides'] as Map).cast<String, dynamic>();
    return ScheduleVariant(
      id: json['id'] as String,
      keywords: (json['keywords'] as List).cast<String>(),
      overrides: {
        for (final entry in rawOverrides.entries)
          int.parse(entry.key): (
            (entry.value as List)[0] as String,
            (entry.value as List)[1] as String,
          ),
      },
    );
  }
}

/// 一所学校的默认作息表。
///
/// 数据来源优先级：内置学校档案（如南工校历作息）> 适配器导入的 `timeSlots` >
/// 用户在设置里修改 > 创建其他学校时的通用兜底。播种只发生一次，
/// 任何后续读取都必须来自数据库，不存在「每次启动覆盖」的路径。
class BellSchedule {
  const BellSchedule({required this.sections, this.variants = const []});

  final List<SectionSpec> sections;

  /// 按教室匹配的作息变体（如按教学楼区分的第 3、4 节时间）。
  final List<ScheduleVariant> variants;

  static int _byIndex(SectionSpec a, SectionSpec b) =>
      a.index.compareTo(b.index);

  SectionSpec? section(int index) {
    for (final spec in sections) {
      if (spec.index == index) return spec;
    }
    return null;
  }

  /// 课程 [startSection]..[endSection] 的显示起止时间。
  ///
  /// [classroom] 命中某个作息变体时，被覆盖的节次用变体时间。
  /// 课程自带显式时间时优先于作息表（由 CourseTimeService 处理）；
  /// 缺失节次返回 null，由调用方显式提示而不是静默给出错误时间。
  (String, String)? resolveRange(
    int startSection,
    int endSection, {
    String? classroom,
  }) {
    ScheduleVariant? variant;
    for (final candidate in variants) {
      if (candidate.matchesClassroom(classroom)) {
        variant = candidate;
        break;
      }
    }
    String? timeOf(int index) {
      final override = variant?.overrides[index];
      if (override != null) return override.$1;
      return section(index)?.start;
    }

    String? endTimeOf(int index) {
      final override = variant?.overrides[index];
      if (override != null) return override.$2;
      return section(index)?.end;
    }

    final first = timeOf(startSection);
    final last = endTimeOf(endSection);
    if (first == null || last == null) return null;
    return (first, last);
  }

  Map<SectionGroup, List<SectionSpec>> groupByPeriod() {
    final result = <SectionGroup, List<SectionSpec>>{};
    for (final spec in [...sections]..sort(_byIndex)) {
      (result[spec.group] ??= []).add(spec);
    }
    return result;
  }

  /// 通用兜底作息（给没有内置档案的学校做折中）：上午四节 8:00 起、
  /// 下午四节 14:00 起、晚上只排 9、10 两节 19:00 起，共 10 节。
  /// 仅供新建学校播种，不能代表任何学校的官方作息。
  static BellSchedule fallback() {
    const starts = [
      '08:00', '08:55', '10:00', '10:55', // 上午 1-4
      '14:00', '14:55', '16:00', '16:55', // 下午 5-8
      '19:00', '19:55', // 晚上 9-10
    ];
    final sections = <SectionSpec>[];
    for (var i = 1; i <= starts.length; i++) {
      final group = i <= 4
          ? SectionGroup.morning
          : i <= 8
          ? SectionGroup.afternoon
          : SectionGroup.evening;
      sections.add(
        SectionSpec(
          index: i,
          start: starts[i - 1],
          end: _addMinutes(starts[i - 1], 45),
          group: group,
        ),
      );
    }
    return BellSchedule(sections: sections);
  }

  static String _addMinutes(String hhmm, int minutes) {
    final parts = hhmm.split(':');
    final total = int.parse(parts[0]) * 60 + int.parse(parts[1]) + minutes;
    final h = (total ~/ 60) % 24;
    final m = total % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// 当前作息是否仍等于通用兜底（用户和导入都没动过）。
  /// 用于决定导入预览里「同时更新作息」的默认勾选。
  bool equalsFallback() {
    final fallback = BellSchedule.fallback();
    if (sections.isEmpty) return true;
    for (final spec in sections) {
      final base = fallback.section(spec.index);
      if (base == null) return false;
      if (base.start != spec.start || base.end != spec.end) return false;
    }
    return true;
  }
}
