import 'package:flutter_test/flutter_test.dart';
import 'package:huike_timetable/features/import/services/login_recovery_policy.dart';

void main() {
  test('only trusted auth/redirect loop signals recover once', () {
    final policy = LoginRecoveryPolicy();
    expect(policy.claim(trusted: true, httpStatus: 403), isFalse);
    expect(policy.claim(trusted: true), isFalse);
    expect(policy.claim(trusted: false, httpStatus: 401), isFalse);
    expect(policy.claim(trusted: true, httpStatus: 401), isTrue);
    expect(policy.claim(trusted: true, redirectLoop: true), isFalse);
  });
  test('manual recovery suppresses further automatic resets', () {
    final policy = LoginRecoveryPolicy()..markManualRecovery();
    expect(policy.claim(trusted: true, httpStatus: 401), isFalse);
    expect(
      LoginRecoveryPolicy().claim(trusted: true, redirectLoop: true),
      isTrue,
    );
  });
}
