enum AdapterDiagnosticStage {
  profileSelection,
  pageRecognition,
  scriptExecution,
  dataExtraction,
  normalization,
  databaseWrite,
}

enum AdapterDiagnosticStatus { notMatched, failed, partial, success }

enum AdapterDiagnosticCode {
  pageNotMatched,
  loginRequired,
  timetablePageRequired,
  unsupportedPage,
  scriptExecutionFailed,
  malformedPayload,
  noCourseData,
  noValidCourses,
  partialCourses,
  importReady,
  writeFailed,
}

/// 仅由目录 ID、阶段与固定错误码组成；不接收原始页面、JS 错误或用户数据。
class AdapterAttemptDiagnostic {
  const AdapterAttemptDiagnostic({
    required this.adapterId,
    required this.familyId,
    required this.stage,
    required this.status,
    required this.code,
    this.variant,
  });

  final String adapterId;
  final String familyId;
  final String? variant;
  final AdapterDiagnosticStage stage;
  final AdapterDiagnosticStatus status;
  final AdapterDiagnosticCode code;

  String get safeCode => code.name;

  String get userMessage => switch (code) {
    AdapterDiagnosticCode.pageNotMatched => '当前页面未识别到相符的教务结构。',
    AdapterDiagnosticCode.loginRequired => '请先在学校教务页面完成登录。',
    AdapterDiagnosticCode.timetablePageRequired => '请先打开课表查询页面并加载课表。',
    AdapterDiagnosticCode.unsupportedPage => '当前页面结构暂未适配，请尝试停留在课表页面。',
    AdapterDiagnosticCode.scriptExecutionFailed => '该适配器未能读取当前页面。',
    AdapterDiagnosticCode.malformedPayload => '教务页面返回的数据格式无法读取。',
    AdapterDiagnosticCode.noCourseData => '当前页面没有提供可导入的课程数据。',
    AdapterDiagnosticCode.noValidCourses => '课程数据未通过字段校验，请检查课表页面后重试。',
    AdapterDiagnosticCode.partialCourses => '已识别课程，但有部分条目字段无效。',
    AdapterDiagnosticCode.importReady => '已取得并校验课程数据。',
    AdapterDiagnosticCode.writeFailed => '写入失败，数据库事务已回滚，请重试。',
  };

  String get developerDetail => switch (code) {
    AdapterDiagnosticCode.pageNotMatched =>
      'No configured DOM fingerprint matched.',
    AdapterDiagnosticCode.loginRequired =>
      'A password input was present without a timetable fingerprint.',
    AdapterDiagnosticCode.timetablePageRequired =>
      'No login form or timetable fingerprint was present.',
    AdapterDiagnosticCode.unsupportedPage =>
      'A configured profile matched but extraction produced no payload.',
    AdapterDiagnosticCode.scriptExecutionFailed =>
      'The local adapter injection failed.',
    AdapterDiagnosticCode.malformedPayload =>
      'A bridge payload was not valid JSON of the expected top-level type.',
    AdapterDiagnosticCode.noCourseData =>
      'The adapter completed without a non-empty course payload.',
    AdapterDiagnosticCode.noValidCourses =>
      'Course records were received but all failed normalization.',
    AdapterDiagnosticCode.partialCourses =>
      'At least one course passed normalization and at least one did not.',
    AdapterDiagnosticCode.importReady =>
      'At least one course passed the existing batch normalizer.',
    AdapterDiagnosticCode.writeFailed =>
      'The confirmImport transaction failed and was rolled back.',
  };

  /// 诊断导出只包含目录元数据与固定枚举，不包含域名、页面文本或运行期响应。
  Map<String, String> toSafeMap() => {
    'adapterId': adapterId,
    'familyId': familyId,
    'variant': variant ?? '',
    'stage': stage.name,
    'status': status.name,
    'code': safeCode,
    'detail': developerDetail,
  };
}
