/// Maps raw backend messages / exception types to user-friendly copy.
/// No raw backend strings or stack traces should ever reach the UI directly.
class ErrorMessageMapper {
  const ErrorMessageMapper._();

  static String forLogin(String? raw) {
    if (raw == null || raw.isEmpty) return _defaultLogin;
    final lower = raw.toLowerCase();

    if (_contains(lower, ['invalid', 'incorrect', 'wrong', 'bad credential',
        'not found', 'no account', 'does not exist'])) {
      return 'The email or password is incorrect.';
    }
    if (_contains(lower, ['verify', 'verified', 'verification', 'confirm'])) {
      return 'Please verify your account before signing in.';
    }
    if (_contains(lower, ['rate limit', 'too many', 'throttle', 'blocked'])) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (_contains(lower, ['network', 'connection', 'reach server', 'offline',
        'socket', 'timeout'])) {
      return 'You appear to be offline. Check your connection and try again.';
    }
    if (_contains(lower, ['server', '500', '503', 'unavailable'])) {
      return "We couldn't complete that request. Please try again.";
    }
    if (_contains(lower, ['disabled', 'suspended', 'locked', 'revoked'])) {
      return 'This account has been disabled. Please contact support.';
    }
    return _defaultLogin;
  }

  static String forRegistration(String? raw) {
    if (raw == null || raw.isEmpty) return _defaultRegistration;
    final lower = raw.toLowerCase();

    if (_contains(lower, ['already', 'exist', 'duplicate', 'taken'])) {
      return 'An account with this email already exists. Try signing in instead.';
    }
    if (_contains(lower, ['network', 'connection', 'reach server', 'offline'])) {
      return 'You appear to be offline. Check your connection and try again.';
    }
    if (_contains(lower, ['password', 'weak', 'strength'])) {
      return 'Your password does not meet the requirements. Please choose a stronger one.';
    }
    if (_contains(lower, ['email', 'invalid'])) {
      return 'The email address you entered is not valid.';
    }
    return _defaultRegistration;
  }

  static String forSessionExpiry() =>
      'Your session has expired. Sign in again to continue.';

  static String forNetwork() =>
      'You appear to be offline. Check your connection and try again.';

  static String forServerError() =>
      "We couldn't complete that request. Please try again.";

  // ─────────────────────── private ───────────────────────

  static const _defaultLogin = 'The email or password is incorrect.';
  static const _defaultRegistration =
      'Registration failed. Please check your details and try again.';

  static bool _contains(String lower, List<String> terms) =>
      terms.any(lower.contains);
}
