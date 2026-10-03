import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 内置适配器目录条目。ID保持既有脚本契约；family用于把学校配置与脚本分离。
class AdapterCatalogEntry {
  const AdapterCatalogEntry({
    required this.id,
    required this.name,
    required this.kind,
    required this.asset,
    required this.description,
    required this.hints,
    required this.maintainer,
    required this.familyId,
    this.category = '',
    this.supportsAttemptToken = false,
  });

  final String id;
  final String name;

  /// 当前只执行本地 JS；不支持远程下载或运行期更新。
  final String kind;
  final String asset;
  final String description;
  final String hints;
  final String maintainer;
  final String category;
  final String familyId;

  /// 当前仓库脚本可把尝试 ID 回传桥，隔离超时脚本的迟到回调。
  /// 缺少此字段的旧目录仍按无 token 桥契约运行。
  final bool supportsAttemptToken;

  static AdapterCatalogEntry fromJson(Map<String, dynamic> json) {
    final id = _requiredString(json, 'id');
    return AdapterCatalogEntry(
      id: id,
      name: _string(json['name'], fallback: id),
      kind: _string(json['kind'], fallback: 'jsScript'),
      asset: _requiredString(json, 'asset'),
      description: _string(json['description']),
      hints: _string(json['hints']),
      maintainer: _string(json['maintainer']),
      category: _string(json['category']),
      familyId: _string(json['family'], fallback: id),
      supportsAttemptToken: json['supportsAttemptToken'] == true,
    );
  }
}

/// 学校的精确 URL 匹配规则。主机不支持通配符，路径只允许前缀匹配。
class AdapterUrlRule {
  const AdapterUrlRule({required this.host, this.pathPrefix = ''});

  final String host;
  final String pathPrefix;

  factory AdapterUrlRule.fromJson(Map<String, dynamic> json) => AdapterUrlRule(
    host: _requiredString(json, 'host').toLowerCase(),
    pathPrefix: _string(json['pathPrefix']),
  );

  bool matches(Uri? uri) {
    if (uri == null ||
        !const ['http', 'https'].contains(uri.scheme.toLowerCase()) ||
        uri.host.toLowerCase() != host) {
      return false;
    }
    if (pathPrefix.isEmpty) return true;
    final prefix = pathPrefix.startsWith('/') ? pathPrefix : '/$pathPrefix';
    final path = uri.path;
    return path == prefix ||
        path.startsWith(prefix.endsWith('/') ? prefix : '$prefix/');
  }
}

/// 目录内的学校配置；不含用户登录状态、凭据或运行期页面数据。
class AdapterSchoolProfile {
  AdapterSchoolProfile({
    required this.id,
    required this.name,
    required this.adapterId,
    required this.aliases,
    required this.urlRules,
    required this.options,
    this.variant,
  });

  final String id;
  final String name;
  final String adapterId;
  final String? variant;
  final List<String> aliases;
  final List<AdapterUrlRule> urlRules;
  final Map<String, dynamic> options;

  /// 可选地把此协议变体输出中的字段别名映射回统一 bridge 模型字段。
  Map<String, String> get courseFieldAliases {
    final raw = options['courseFieldAliases'];
    if (raw is! Map) return const {};
    return Map.unmodifiable({
      for (final entry in raw.entries)
        if (entry.key is String && entry.value is String)
          entry.key as String: entry.value as String,
    });
  }

  factory AdapterSchoolProfile.fromJson(Map<String, dynamic> json) {
    final rawRules = json['urlRules'];
    final rules = rawRules is List
        ? rawRules
              .whereType<Map>()
              .map((rule) => AdapterUrlRule.fromJson(_stringKeyed(rule)))
              .toList(growable: false)
        : const <AdapterUrlRule>[];
    return AdapterSchoolProfile(
      id: _requiredString(json, 'id'),
      name: _requiredString(json, 'name'),
      adapterId: _requiredString(json, 'adapterId'),
      variant: _nullableString(json['variant']),
      aliases: _stringList(json['aliases']),
      urlRules: rules,
      options: Map<String, dynamic>.unmodifiable(
        _stringKeyedOrEmpty(json['options']),
      ),
    );
  }

  bool matchesSchoolName(String? schoolName) {
    final normalized = _normalizeName(schoolName);
    if (normalized.isEmpty) return false;
    return <String>[
      name,
      ...aliases,
    ].map(_normalizeName).any((candidate) => candidate == normalized);
  }

  bool matchesUrl(Uri? uri) => urlRules.any((rule) => rule.matches(uri));
}

class AdapterCatalog {
  const AdapterCatalog({
    required this.entries,
    this.schoolProfiles = const [],
    this.schemaVersion = 1,
  });

  final List<AdapterCatalogEntry> entries;
  final List<AdapterSchoolProfile> schoolProfiles;
  final int schemaVersion;

  AdapterCatalogEntry? byId(String id) {
    for (final entry in entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  List<AdapterSchoolProfile> profilesForSchoolName(String? schoolName) =>
      schoolProfiles
          .where((profile) => profile.matchesSchoolName(schoolName))
          .toList(growable: false);

  List<AdapterSchoolProfile> profilesForUrl(Uri? uri) => schoolProfiles
      .where((profile) => profile.matchesUrl(uri))
      .toList(growable: false);

  Future<String> scriptFor(AdapterCatalogEntry entry) =>
      rootBundle.loadString('assets/adapters/${entry.asset}');

  static Future<AdapterCatalog> load() async {
    final raw = await rootBundle.loadString('assets/adapters/catalog.json');
    return fromJson(jsonDecode(raw));
  }

  static AdapterCatalog fromJson(Object? raw) {
    if (raw is! Map) {
      throw const FormatException('Adapter catalog must be an object');
    }
    final json = _stringKeyed(raw);
    final version = json['schemaVersion'] is int
        ? json['schemaVersion'] as int
        : 1;
    if (version < 1 || version > 2) {
      throw FormatException('Unsupported adapter catalog schema: $version');
    }
    final rawEntries = json['adapters'];
    if (rawEntries is! List) {
      throw const FormatException('Adapter catalog adapters must be a list');
    }
    final entries = rawEntries
        .whereType<Map>()
        .map((entry) => AdapterCatalogEntry.fromJson(_stringKeyed(entry)))
        .toList(growable: false);
    final rawProfiles = json['schoolProfiles'];
    final profiles = rawProfiles is List
        ? rawProfiles
              .whereType<Map>()
              .map(
                (profile) =>
                    AdapterSchoolProfile.fromJson(_stringKeyed(profile)),
              )
              .toList(growable: false)
        : const <AdapterSchoolProfile>[];
    return AdapterCatalog(
      entries: entries,
      schoolProfiles: profiles,
      schemaVersion: version,
    );
  }
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Adapter catalog field "$key" must be a string');
  }
  return value.trim();
}

String _string(Object? value, {String fallback = ''}) =>
    value is String ? value.trim() : fallback;

String? _nullableString(Object? value) {
  final string = _string(value);
  return string.isEmpty ? null : string;
}

List<String> _stringList(Object? value) => value is List
    ? value
          .whereType<String>()
          .map((item) => item.trim())
          .toList(growable: false)
    : const <String>[];

Map<String, dynamic> _stringKeyed(Map value) =>
    value.map((key, item) => MapEntry('$key', item));

Map<String, dynamic> _stringKeyedOrEmpty(Object? value) =>
    value is Map ? _stringKeyed(value) : const <String, dynamic>{};

String _normalizeName(String? value) => value?.trim().toLowerCase() ?? '';

final adapterCatalogProvider = FutureProvider<AdapterCatalog>(
  (ref) => AdapterCatalog.load(),
);
