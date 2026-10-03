import 'dart:convert';

import '../../schools/services/adapter_catalog.dart';

/// 页面检测结果仅保留布尔标记和协议族 ID；不返回或保存页面文本/表单值。
class AdapterPageFeatures {
  const AdapterPageFeatures({
    this.families = const {},
    this.loginFormPresent = false,
    this.timetableMarkerPresent = false,
    this.framePaths = const {},
    this.inaccessibleFramePresent = false,
  });

  final Set<String> families;
  final bool loginFormPresent;
  final bool timetableMarkerPresent;
  final Map<String, List<int>> framePaths;
  final bool inaccessibleFramePresent;

  bool matches(AdapterCatalogEntry entry) => families.contains(entry.familyId);

  static const readOnlyProbeJs = '''
(function () {
  var result = {matches: {}, framePaths: {}, loginFormPresent: false,
    timetableMarkerPresent: false, inaccessibleFramePresent: false};
  var visited = 0;
  function inspect(win, path) {
  if (++visited > 32 || path.length > 4) return;
  var doc;
  try { doc = win.document; if (!doc) return; }
  catch (_) { result.inaccessibleFramePresent = true; return; }
  function has(selector) { return doc.querySelector(selector) !== null; }
  var tables = Array.prototype.slice.call(doc.querySelectorAll('table'));
  var qingguo = tables.some(function (table) {
    var text = table.innerText || '';
    return text.indexOf('星期一') >= 0 && text.indexOf('[') >= 0;
  });
  var matches = {
    zhengfang: has('#kbgrid_table_0') || has('#kblist_table'),
    qingguo: qingguo,
    urp: has('td[id*="_"] .class_div') && has('th[id^="0_"]'),
    chaoxing: has('#xhid') && has('#xqdm')
  };
  result.loginFormPresent = result.loginFormPresent || has('input[type="password"]');
  Object.keys(matches).forEach(function (key) {
    if (matches[key]) {
      result.matches[key] = true;
      result.timetableMarkerPresent = true;
      if (!Object.prototype.hasOwnProperty.call(result.framePaths, key))
        result.framePaths[key] = path;
    }
  });
  for (var i = 0; i < win.frames.length && visited < 32; i++)
    inspect(win.frames[i], path.concat(i));
  }
  inspect(window, []);
  return JSON.stringify(result);
})();
''';

  factory AdapterPageFeatures.fromJson(Object? raw) {
    if (raw is! Map) return const AdapterPageFeatures();
    final matches = raw['matches'];
    final families = <String>{};
    if (matches is Map) {
      for (final entry in matches.entries) {
        if (entry.value == true) families.add('${entry.key}');
      }
    }
    return AdapterPageFeatures(
      families: Set.unmodifiable(families),
      loginFormPresent: raw['loginFormPresent'] == true,
      timetableMarkerPresent:
          raw['timetableMarkerPresent'] == true || families.isNotEmpty,
      inaccessibleFramePresent: raw['inaccessibleFramePresent'] == true,
      framePaths: Map.unmodifiable({
        if (raw['framePaths'] is Map)
          for (final entry in (raw['framePaths'] as Map).entries)
            if (families.contains(entry.key) &&
                entry.value is List &&
                (entry.value as List).length <= 4 &&
                (entry.value as List).every(
                  (i) => i is int && i >= 0 && i < 32,
                ))
              '${entry.key}': List<int>.unmodifiable(entry.value as List),
      }),
    );
  }

  factory AdapterPageFeatures.decode(String? raw) {
    if (raw == null || raw.isEmpty) return const AdapterPageFeatures();
    try {
      final decoded = jsonDecode(raw);
      return AdapterPageFeatures.fromJson(
        decoded is String ? jsonDecode(decoded) : decoded,
      );
    } on FormatException {
      return const AdapterPageFeatures();
    }
  }
}

/// Finite, read-only sampling. Losing page ownership stops every later poll.
class AdapterPageReader {
  const AdapterPageReader();

  Future<AdapterPageFeatures> read({
    required Future<dynamic> Function(String source) evaluate,
    required bool Function() isCurrent,
    Future<void> Function(Duration)? wait,
  }) async {
    var features = const AdapterPageFeatures();
    for (var poll = 0; poll < 9; poll++) {
      if (!isCurrent()) break;
      try {
        final raw = await evaluate(AdapterPageFeatures.readOnlyProbeJs);
        if (!isCurrent()) break;
        if (raw is Map) features = AdapterPageFeatures.fromJson(raw);
        if (raw is String) features = AdapterPageFeatures.decode(raw);
        if (features.timetableMarkerPresent) return features;
      } catch (_) {
        // Preserve compatibility fallback on unsupported JS evaluation.
        break;
      }
      if (poll < 8) {
        const gap = Duration(milliseconds: 500);
        await (wait?.call(gap) ?? Future<void>.delayed(gap));
      }
    }
    return features;
  }
}

enum AdapterSelectionBasis {
  schoolProfile,
  schoolPreference,
  knownUrl,
  pageFeature,
  compatibilityFallback,
}

class AdapterCandidate {
  const AdapterCandidate({
    required this.entry,
    required this.basis,
    this.profileId,
    this.variant,
    this.options = const {},
    this.fieldAliases = const {},
  });

  final AdapterCatalogEntry entry;
  final AdapterSelectionBasis basis;
  final String? profileId;
  final String? variant;
  final Map<String, dynamic> options;
  final Map<String, String> fieldAliases;

  String get adapterId => entry.id;
  String get familyId => entry.familyId;
  bool get supportsAttemptToken => entry.supportsAttemptToken;

  /// 只把静态目录配置传给脚本；不包含学校名称、登录地址或页面数据。
  String contextBootstrap(String attemptId) {
    final payload = jsonEncode({
      'attemptId': attemptId,
      'adapterId': adapterId,
      'familyId': familyId,
      if (profileId != null) 'profileId': profileId,
      if (variant != null) 'variant': variant,
      'options': options,
    });
    return 'window.__huikeAdapterContext = $payload;';
  }
}

class AdapterProbePlanner {
  const AdapterProbePlanner();

  List<AdapterCandidate> plan({
    required AdapterCatalog catalog,
    required AdapterPageFeatures pageFeatures,
    String? schoolName,
    String? preferredAdapterId,
    Uri? currentUrl,
  }) {
    final result = <AdapterCandidate>[];
    final seen = <String>{};

    void addProfile(AdapterSchoolProfile profile, AdapterSelectionBasis basis) {
      final entry = catalog.byId(profile.adapterId);
      if (entry == null || !seen.add(entry.id)) return;
      result.add(
        AdapterCandidate(
          entry: entry,
          basis: basis,
          profileId: profile.id,
          variant: profile.variant,
          options: profile.options,
          fieldAliases: profile.courseFieldAliases,
        ),
      );
    }

    for (final profile in catalog.profilesForSchoolName(schoolName)) {
      addProfile(profile, AdapterSelectionBasis.schoolProfile);
    }

    final preferred = preferredAdapterId == null
        ? null
        : catalog.byId(preferredAdapterId);
    if (preferred != null && seen.add(preferred.id)) {
      result.add(
        AdapterCandidate(
          entry: preferred,
          basis: AdapterSelectionBasis.schoolPreference,
        ),
      );
    }

    final urlProfiles = catalog.profilesForUrl(currentUrl).toList()
      ..sort((a, b) {
        final aSpecificity = _profilePathSpecificity(a, currentUrl);
        final bSpecificity = _profilePathSpecificity(b, currentUrl);
        return bSpecificity.compareTo(aSpecificity);
      });
    for (final profile in urlProfiles) {
      addProfile(profile, AdapterSelectionBasis.knownUrl);
    }

    for (final entry in catalog.entries) {
      if (!pageFeatures.matches(entry) || !seen.add(entry.id)) continue;
      result.add(
        AdapterCandidate(
          entry: entry,
          basis: AdapterSelectionBasis.pageFeature,
        ),
      );
    }

    // 保留旧版「其余内置通用脚本逐个尝试」能力，未知学校不会被识别结果挡住。
    for (final entry in catalog.entries) {
      if (seen.add(entry.id)) {
        result.add(
          AdapterCandidate(
            entry: entry,
            basis: AdapterSelectionBasis.compatibilityFallback,
          ),
        );
      }
    }
    return result;
  }

  int _profilePathSpecificity(AdapterSchoolProfile profile, Uri? uri) {
    if (uri == null) return 0;
    var specificity = 0;
    for (final rule in profile.urlRules) {
      if (rule.matches(uri) && rule.pathPrefix.length > specificity) {
        specificity = rule.pathPrefix.length;
      }
    }
    return specificity;
  }
}

/// 候选的顺序消费器；一次失败只消费当前项，后续候选仍可继续尝试。
class AdapterCandidateSequence {
  AdapterCandidateSequence(Iterable<AdapterCandidate> candidates)
    : _candidates = List.unmodifiable(candidates);

  final List<AdapterCandidate> _candidates;
  int _index = 0;

  bool get hasNext => _index < _candidates.length;

  AdapterCandidate? takeNext() {
    if (!hasNext) return null;
    return _candidates[_index++];
  }
}
