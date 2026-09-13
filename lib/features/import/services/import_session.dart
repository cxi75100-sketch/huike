import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/adapter_batch.dart';

/// 一次导入会话在内存中的暂存区。
///
/// 脚本通过桥写入的三类原始数据全部落在这里（仅内存，不落盘、不写日志），
/// 任一部分到达后立即合并重新规范化，预览页只读 [normalized]。
/// 离开导入页时 [ImportSessionNotifier.reset]。
class AdapterImportSession {
  const AdapterImportSession({
    this.rawCourses,
    this.rawTimeSlots,
    this.rawConfig,
    this.normalized,
    this.completed = false,
  });

  final List<dynamic>? rawCourses;
  final List<dynamic>? rawTimeSlots;
  final Map<String, dynamic>? rawConfig;
  final AdapterImportBatch? normalized;
  final bool completed;
}

class ImportSessionNotifier extends Notifier<AdapterImportSession> {
  final _normalizer = const AdapterBatchNormalizer();

  @override
  AdapterImportSession build() => const AdapterImportSession();

  bool stageCourses(String rawJson) {
    final decoded = _decodeList(rawJson);
    if (decoded == null) return false;
    _rebuild(rawCourses: decoded);
    return true;
  }

  bool stageTimeSlots(String rawJson) {
    final decoded = _decodeList(rawJson);
    if (decoded == null) return false;
    _rebuild(rawTimeSlots: decoded);
    return true;
  }

  bool stageConfig(String rawJson) {
    final decoded = _decodeMap(rawJson);
    if (decoded == null) return false;
    _rebuild(rawConfig: decoded);
    return true;
  }

  void complete() {
    state = AdapterImportSession(
      rawCourses: state.rawCourses,
      rawTimeSlots: state.rawTimeSlots,
      rawConfig: state.rawConfig,
      normalized: state.normalized,
      completed: true,
    );
  }

  void reset() {
    state = const AdapterImportSession();
  }

  void _rebuild({
    List<dynamic>? rawCourses,
    List<dynamic>? rawTimeSlots,
    Map<String, dynamic>? rawConfig,
  }) {
    final courses = rawCourses ?? state.rawCourses;
    final slots = rawTimeSlots ?? state.rawTimeSlots;
    final config = rawConfig ?? state.rawConfig;
    final batch = _normalizer.normalize(
      rawCourses: courses ?? const [],
      rawTimeSlots: slots,
      rawConfig: config,
    );
    state = AdapterImportSession(
      rawCourses: courses,
      rawTimeSlots: slots,
      rawConfig: config,
      normalized: batch,
      completed: false,
    );
  }

  List<dynamic>? _decodeList(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      return decoded is List ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  Map<String, dynamic>? _decodeMap(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      return decoded is Map ? decoded.cast<String, dynamic>() : null;
    } on FormatException {
      return null;
    }
  }
}

final importSessionProvider =
    NotifierProvider<ImportSessionNotifier, AdapterImportSession>(
      ImportSessionNotifier.new,
    );
