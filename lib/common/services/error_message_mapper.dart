/// Maps raw backend messages / exception types to user-friendly copy.
/// No raw backend strings or stack traces should ever reach the UI directly.
class ErrorMessageMapper {
  const ErrorMessageMapper._();

  /// [statusCode] is the HTTP status the attempt came back with, or null when
  /// the request never reached the server at all.
  ///
  /// **The status is consulted first and it wins.** A server that is failing
  /// does not reliably describe itself in prose, and a body it did not write —
  /// an nginx 502 page, an empty 504 — carries no keyword for any list below to
  /// match. Those used to fall through every branch and land on
  /// [_defaultLogin], telling the customer their password was wrong when the
  /// backend was simply down. Blaming the customer's credentials is the one
  /// thing this function must not do when it does not know.
  static String forLogin(String? raw, {int? statusCode}) {
    final byStatus = _byStatus(statusCode);
    if (byStatus != null) return byStatus;
    if (raw == null || raw.isEmpty) return _defaultLogin;
    final lower = raw.toLowerCase();

    if (_contains(lower, [
      'invalid',
      'incorrect',
      'wrong',
      'bad credential',
      'not found',
      'no account',
      'does not exist'
    ])) {
      return 'The email or password is incorrect.';
    }
    if (_contains(lower, ['verify', 'verified', 'verification', 'confirm'])) {
      return 'Please verify your account before signing in.';
    }
    if (_contains(lower, ['rate limit', 'too many', 'throttle', 'blocked'])) {
      return _tooManyAttempts;
    }
    if (_contains(lower, [
      'network',
      'connection',
      'reach server',
      'offline',
      'socket',
      'timeout'
    ])) {
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

  /// See [forLogin] for why [statusCode] is consulted first. The default here
  /// blames the customer's details, which is the same failure mode.
  static String forRegistration(String? raw, {int? statusCode}) {
    final byStatus = _byStatus(statusCode);
    if (byStatus != null) return byStatus;
    if (raw == null || raw.isEmpty) return _defaultRegistration;
    final lower = raw.toLowerCase();

    if (_contains(lower, ['already', 'exist', 'duplicate', 'taken'])) {
      return 'An account with this email already exists. Try signing in instead.';
    }
    if (_contains(
        lower, ['network', 'connection', 'reach server', 'offline'])) {
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

  /// Copy when the status alone settles the question, or null when the body is
  /// the better signal.
  ///
  /// 401 and 403 deliberately return null. "The credentials are wrong" is
  /// exactly what they mean, and the keyword lists draw distinctions the status
  /// cannot — an unverified account and a disabled one are both 401.
  ///
  /// A null status means the request never reached the server. That is left to
  /// the body too, which the transport has already written as a could-not-reach
  /// message.
  static String? _byStatus(int? status) {
    if (status == null) return null;
    if (status >= 500) return forServerError();
    if (status == 408) return forNetwork();
    if (status == 429) return _tooManyAttempts;
    return null;
  }

  static const _tooManyAttempts =
      'Too many attempts. Please wait a moment and try again.';

  // ─────────────────────── private ───────────────────────

  static const _defaultLogin = 'The email or password is incorrect.';
  static const _defaultRegistration =
      'Registration failed. Please check your details and try again.';

  static bool _contains(String lower, List<String> terms) =>
      terms.any(lower.contains);
}
