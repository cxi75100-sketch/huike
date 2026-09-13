/// 一所学校的运行时档案。
///
/// 不含校历与作息（那是 [Semester] 与 BellSchedule 的职责），
/// 只承载身份与网络策略；数据来自 `schools` 表，由用户显式创建。
class SchoolProfile {
  const SchoolProfile({
    required this.id,
    required this.displayName,
    required this.adapterId,
    required this.loginUrl,
    required this.acceptedHosts,
    required this.createdAt,
  });

  final String id;
  final String displayName;

  /// `assets/adapters/catalog.json` 里的适配器 id；手动学校为空串。
  final String adapterId;
  final String loginUrl;
  final List<String> acceptedHosts;
  final DateTime createdAt;

  /// 用户提供且显式确认过的登录主机。导航白名单以它为根，
  /// 其余 acceptedHosts 只能来自用户后续确认，不允许凭空扩展。
  String? get confirmedHost {
    if (loginUrl.isEmpty) return null;
    return Uri.tryParse(loginUrl)?.host;
  }
}
