import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/adapter_diagnostic.dart';
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
    this.activeAttemptId,
    this.adapterId,
    this.adapterFamilyId,
    this.adapterVariant,
    this.attemptTokenRequired = false,
    this.courseFieldAliases = const {},
    this.diagnostics = const [],
    this.completed = false,
  });

  final List<dynamic>? rawCourses;
  final List<dynamic>? rawTimeSlots;
  final Map<String, dynamic>? rawConfig;
  final AdapterImportBatch? normalized;
  final String? activeAttemptId;
  final String? adapterId;
  final String? adapterFamilyId;
  final String? adapterVariant;
  final bool attemptTokenRequired;
  final Map<String, String> courseFieldAliases;
  final List<AdapterAttemptDiagnostic> diagnostics;
  final bool completed;
}

class ImportSessionNotifier extends Notifier<AdapterImportSession> {
  final _normalizer = const AdapterBatchNormalizer();

  @override
  AdapterImportSession build() => const AdapterImportSession();

  void beginAttempt({
    required String attemptId,
    required String adapterId,
    required String familyId,
    required bool tokenRequired,
    Map<String, String> courseFieldAliases = const {},
    String? variant,
  }) {
    state = AdapterImportSession(
      activeAttemptId: attemptId,
      adapterId: adapterId,
      adapterFamilyId: familyId,
      adapterVariant: variant,
      attemptTokenRequired: tokenRequired,
      courseFieldAliases: Map.unmodifiable(courseFieldAliases),
    );
  }

  bool acceptsAttempt(String? attemptId) {
    final active = state.activeAttemptId;
    if (active == null) return attemptId == null;
    if (attemptId == null) return !state.attemptTokenRequired;
    return attemptId == active;
  }

  bool stageCourses(String rawJson, {String? attemptId}) {
    if (!acceptsAttempt(attemptId)) return false;
    final decoded = _decodeList(rawJson);
    if (decoded == null) return false;
    _rebuild(rawCourses: decoded);
    return true;
  }

  bool stageTimeSlots(String rawJson, {String? attemptId}) {
    if (!acceptsAttempt(attemptId)) return false;
    final decoded = _decodeList(rawJson);
    if (decoded == null) return false;
    _rebuild(rawTimeSlots: decoded);
    return true;
  }

  bool stageConfig(String rawJson, {String? attemptId}) {
    if (!acceptsAttempt(attemptId)) return false;
    final decoded = _decodeMap(rawJson);
    if (decoded == null) return false;
    _rebuild(rawConfig: decoded);
    return true;
  }

  void complete({String? attemptId}) {
    if (!acceptsAttempt(attemptId)) return;
    state = AdapterImportSession(
      rawCourses: state.rawCourses,
      rawTimeSlots: state.rawTimeSlots,
      rawConfig: state.rawConfig,
      normalized: state.normalized,
      activeAttemptId: state.activeAttemptId,
      adapterId: state.adapterId,
      adapterFamilyId: state.adapterFamilyId,
      adapterVariant: state.adapterVariant,
      attemptTokenRequired: state.attemptTokenRequired,
      courseFieldAliases: state.courseFieldAliases,
      diagnostics: state.diagnostics,
      completed: true,
    );
  }

  void setDiagnostics(List<AdapterAttemptDiagnostic> diagnostics) {
    state = AdapterImportSession(
      rawCourses: state.rawCourses,
      rawTimeSlots: state.rawTimeSlots,
      rawConfig: state.rawConfig,
      normalized: state.normalized,
      activeAttemptId: state.activeAttemptId,
      adapterId: state.adapterId,
      adapterFamilyId: state.adapterFamilyId,
      adapterVariant: state.adapterVariant,
      attemptTokenRequired: state.attemptTokenRequired,
      courseFieldAliases: state.courseFieldAliases,
      diagnostics: List.unmodifiable(diagnostics),
      completed: state.completed,
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
      courseFieldAliases: state.courseFieldAliases,
    );
    state = AdapterImportSession(
      rawCourses: courses,
      rawTimeSlots: slots,
      rawConfig: config,
      normalized: batch,
      activeAttemptId: state.activeAttemptId,
      adapterId: state.adapterId,
      adapterFamilyId: state.adapterFamilyId,
      adapterVariant: state.adapterVariant,
      attemptTokenRequired: state.attemptTokenRequired,
      courseFieldAliases: state.courseFieldAliases,
      diagnostics: state.diagnostics,
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
