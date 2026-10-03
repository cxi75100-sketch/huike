/// A single bounded recovery per import page, only for explicit auth/loop signals.
/// Connection errors and forbidden responses never trigger cookie deletion.
class LoginRecoveryPolicy {
  bool _attempted = false;

  bool claim({
    required bool trusted,
    int? httpStatus,
    bool redirectLoop = false,
  }) {
    if (_attempted || !trusted || (httpStatus != 401 && !redirectLoop)) {
      return false;
    }
    _attempted = true;
    return true;
  }

  void markManualRecovery() => _attempted = true;
}
