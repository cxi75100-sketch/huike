/// Weekly-only presentation. Never persist this value or change import data.
/// Strip a leading campus label; strip its optional zone only when followed
/// by a known training-centre building. Unknown addresses stay intact.
String compactWeeklyLocation(String location) {
  final original = location.trim();
  final campus = RegExp(r'^.+?校区\s*').firstMatch(original);
  if (campus == null) return original;
  var compact = original.substring(campus.end).trim();
  if (compact.isEmpty) return original;
  compact = compact.replaceFirst(RegExp(r'^[东西南北]区\s*(?=实训中心)'), '');
  return compact;
}
