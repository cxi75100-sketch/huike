import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 内置适配器目录条目。
///
/// 目录来自 `assets/adapters/catalog.json`。脚本文件本身是社区开源
/// 适配脚本（MIT，署名见 THIRD_PARTY_NOTICES.md），运行在用户登录的
/// 教务页面里；本 App 只提供桥与预览确认，不替用户请求任何数据。
class AdapterCatalogEntry {
  const AdapterCatalogEntry({
    required this.id,
    required this.name,
    required this.kind,
    required this.asset,
    required this.description,
    required this.hints,
    required this.maintainer,
  });

  final String id;
  final String name;

  /// 目前只有 `jsScript`；保留字段为将来扩展 JSON 直连接口。
  final String kind;
  final String asset;
  final String description;
  final String hints;
  final String maintainer;

  static AdapterCatalogEntry fromJson(Map<String, dynamic> json) =>
      AdapterCatalogEntry(
        id: json['id'] as String,
        name: json['name'] as String,
        kind: json['kind'] as String? ?? 'jsScript',
        asset: json['asset'] as String,
        description: json['description'] as String? ?? '',
        hints: json['hints'] as String? ?? '',
        maintainer: json['maintainer'] as String? ?? '',
      );
}

class AdapterCatalog {
  const AdapterCatalog({required this.entries});

  final List<AdapterCatalogEntry> entries;

  AdapterCatalogEntry? byId(String id) {
    for (final entry in entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  Future<String> scriptFor(AdapterCatalogEntry entry) =>
      rootBundle.loadString('assets/adapters/${entry.asset}');

  static Future<AdapterCatalog> load() async {
    final raw = await rootBundle.loadString('assets/adapters/catalog.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final list = (json['adapters'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(AdapterCatalogEntry.fromJson)
        .toList();
    return AdapterCatalog(entries: list);
  }
}

final adapterCatalogProvider = FutureProvider<AdapterCatalog>(
  (ref) => AdapterCatalog.load(),
);
