import 'package:flutter_test/flutter_test.dart';
import 'package:huike_timetable/features/import/models/adapter_diagnostic.dart';

void main() {
  test('安全诊断只输出目录标识、固定阶段和错误码', () {
    const diagnostic = AdapterAttemptDiagnostic(
      adapterId: 'fixture-adapter',
      familyId: 'fixture-family',
      variant: 'fixture-variant',
      stage: AdapterDiagnosticStage.dataExtraction,
      status: AdapterDiagnosticStatus.failed,
      code: AdapterDiagnosticCode.unsupportedPage,
    );
    final encoded = diagnostic.toSafeMap().toString().toLowerCase();
    expect(diagnostic.safeCode, 'unsupportedPage');
    expect(diagnostic.userMessage, contains('页面结构'));
    for (final sensitive in [
      'username',
      'password',
      'cookie',
      'token=',
      'xhid',
      'https://',
      '<html',
    ]) {
      expect(encoded, isNot(contains(sensitive)));
    }
  });
}
