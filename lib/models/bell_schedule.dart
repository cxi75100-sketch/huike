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

/// 一所学校的默认作息表。
///
/// 数据来源优先级：适配器导入的 `timeSlots` > 用户在设置里修改 >
/// 创建学校时的通用兜底。兜底只播种一次，任何后续读取都必须来自数据库，
/// 不存在“每次启动覆盖”的路径。
class BellSchedule {
  const BellSchedule({required this.sections});

  final List<SectionSpec> sections;

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
  /// 课程自带显式时间时优先于作息表；缺失节次返回 null，由调用方
  /// 显式提示而不是静默给出错误时间。
  (String, String)? resolveRange(int startSection, int endSection) {
    final first = section(startSection);
    final last = section(endSection);
    if (first == null || last == null) return null;
    return (first.start, last.end);
  }

  Map<SectionGroup, List<SectionSpec>> groupByPeriod() {
    final result = <SectionGroup, List<SectionSpec>>{};
    for (final spec in [...sections]..sort(_byIndex)) {
      (result[spec.group] ??= []).add(spec);
    }
    return result;
  }

  /// 通用兜底作息：8:00 起上午四节、14:00 起下午四节、19:00 起晚间，
  /// 最多 12 节。仅供新建学校播种，不能代表任何学校的官方作息。
  static BellSchedule fallback({int sectionCount = 12}) {
    const morningStart = ['08:00', '08:55', '10:00', '10:55'];
    const afternoonStart = ['14:00', '14:55', '16:00', '16:55'];
    const eveningStart = ['19:00', '19:55', '20:50', '21:45'];
    const length = '45 分钟';
    assert(length.isNotEmpty);
    final sections = <SectionSpec>[];
    for (var i = 1; i <= sectionCount; i++) {
      final List<String> starts;
      final SectionGroup group;
      if (i <= morningStart.length) {
        starts = morningStart;
        group = SectionGroup.morning;
      } else if (i <= morningStart.length + afternoonStart.length) {
        starts = afternoonStart;
        group = SectionGroup.afternoon;
      } else {
        starts = eveningStart;
        group = SectionGroup.evening;
      }
      final start = starts[(i - 1) % 4];
      final end = _addMinutes(start, 45);
      sections.add(
        SectionSpec(index: i, start: start, end: end, group: group),
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
