import '../../../models/bell_schedule.dart';

/// 内置学校档案：为个别学校把官方作息（含按教学楼的变体）写进代码。
///
/// 目前只有南昌工学院（依据其校历公布作息：第 3、4 节在明志楼/明德楼/
/// 至善楼提前 10 分钟）。其他学校一律走通用兜底作息 + 用户可改 +
/// 导入适配器可整体替换，不做猜测。
class SchoolPreset {
  const SchoolPreset({
    required this.id,
    required this.displayName,
    required this.bell,
    required this.defaultFirstWeekMonday,
    required this.defaultTotalWeeks,
    this.defaultLoginUrl = '',
    this.retiredLoginHosts = const [],
  });

  final String id;
  final String displayName;
  final BellSchedule bell;
  final DateTime defaultFirstWeekMonday;
  final int defaultTotalWeeks;

  /// 教务登录地址（预填用；可为空）。
  final String defaultLoginUrl;

  /// Exact obsolete preset hosts whose default root URLs can be repaired.
  final List<String> retiredLoginHosts;

  String? replacementForRetiredLoginUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        !retiredLoginHosts.contains(uri.host) ||
        uri.userInfo.isNotEmpty ||
        uri.port != (uri.scheme == 'https' ? 443 : 80) ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        uri.hasQuery ||
        uri.hasFragment ||
        defaultLoginUrl.isEmpty) {
      return null;
    }
    return defaultLoginUrl;
  }
}

final ncpuPreset = SchoolPreset(
  id: 'ncpu',
  displayName: '南昌工学院',
  bell: _ncpuBell,
  defaultFirstWeekMonday: DateTime(2026, 8, 31),
  defaultTotalWeeks: 20,
  // 学校实际入口：正方教务（jwglxt）、明文 HTTP、IP + 8088 端口。
  // 不要改回 http://jwxt.ncpu.edu.cn——该域名只剩 IPv6 解析且请求超时，
  // 用它会导致导入 WebView 打不开登录页（2026-09-14 复核，见 knowledge/changelog.md）。
  defaultLoginUrl: 'http://218.204.129.252:8088/jwglxt/xtgl/login_slogin.html',
  retiredLoginHosts: const ['jwxt.ncpu.edu.cn'],
);

/// 南昌工学院 2026-2027 学年校历作息（10 节；晚上最多两节）。
const _ncpuBell = BellSchedule(
  sections: [
    SectionSpec(
      index: 1,
      start: '08:20',
      end: '09:00',
      group: SectionGroup.morning,
    ),
    SectionSpec(
      index: 2,
      start: '09:10',
      end: '09:50',
      group: SectionGroup.morning,
    ),
    // 第 3、4 节：明志楼/明德楼/至善楼提前 10 分钟，走 variants。
    SectionSpec(
      index: 3,
      start: '10:25',
      end: '11:05',
      group: SectionGroup.morning,
    ),
    SectionSpec(
      index: 4,
      start: '11:15',
      end: '11:55',
      group: SectionGroup.morning,
    ),
    SectionSpec(
      index: 5,
      start: '14:00',
      end: '14:40',
      group: SectionGroup.afternoon,
    ),
    SectionSpec(
      index: 6,
      start: '14:50',
      end: '15:30',
      group: SectionGroup.afternoon,
    ),
    SectionSpec(
      index: 7,
      start: '15:55',
      end: '16:35',
      group: SectionGroup.afternoon,
    ),
    SectionSpec(
      index: 8,
      start: '16:45',
      end: '17:25',
      group: SectionGroup.afternoon,
    ),
    SectionSpec(
      index: 9,
      start: '19:00',
      end: '19:40',
      group: SectionGroup.evening,
    ),
    SectionSpec(
      index: 10,
      start: '19:50',
      end: '20:30',
      group: SectionGroup.evening,
    ),
  ],
  variants: [
    ScheduleVariant(
      id: 'ncpu.mingzhi',
      keywords: ['明志', '明德', '至善'],
      overrides: {3: ('10:15', '10:55'), 4: ('11:05', '11:45')},
    ),
  ],
);

/// 全部内置档案。找不到时返回 null，调用方走通用兜底。
SchoolPreset? presetById(String id) {
  for (final preset in [ncpuPreset]) {
    if (preset.id == id) return preset;
  }
  return null;
}

/// 按学校名精确匹配内置档案（只用于数据修复：老学校的 `presetId` 为空时，
/// 校名与档案一致才认定是同一所，不做模糊匹配）。
SchoolPreset? presetByDisplayName(String displayName) {
  final name = displayName.trim();
  if (name.isEmpty) return null;
  for (final preset in [ncpuPreset]) {
    if (preset.displayName == name) return preset;
  }
  return null;
}
