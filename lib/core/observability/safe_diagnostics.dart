// Utility for determining whether an error is worth reporting to Crashlytics.
// Routine offline/network errors and expected validation failures MUST NOT
// flood Crashlytics — only actionable, unexpected errors get reported.
abstract final class SafeDiagnostics {
  // Returns true if the exception is a routine transient error that should
  // be silently handled — not reported as a non-fatal.
  static bool isRoutine(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('socketexception')) return true;
    if (msg.contains('connection refused')) return true;
    if (msg.contains('network is unreachable')) return true;
    if (msg.contains('host lookup failed')) return true;
    if (msg.contains('timeout')) return true;
    if (msg.contains('handshake')) return true;
    if (msg.contains('certificate')) return true;
    if (msg.contains('statuscode: 4')) return true; // 4xx — expected failures
    if (msg.contains('statuscode: 5')) return true; // 5xx — expected server errors
    return false;
  }

  // Sanitize an error message for Crashlytics — remove any pattern that
  // could contain PII (email, phone, URLs with IDs, etc.).
  static String sanitizeMessage(Object error) {
    var msg = error.toString();
    // Remove email-like strings
    msg = msg.replaceAll(
        RegExp(r'[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}'),
        '[email_redacted]');
    // Remove phone-like strings
    msg = msg.replaceAll(
        RegExp(r'(\+63|0)(9\d{9})'), '[phone_redacted]');
    // Remove URLs (could contain IDs or tokens)
    msg = msg.replaceAll(
        RegExp(r'https?://\S+'), '[url_redacted]');
    // Remove potential tokens (long alphanumeric strings > 30 chars)
    msg = msg.replaceAll(
        RegExp(r'\b[A-Za-z0-9_\-]{31,}\b'), '[token_redacted]');
    // Truncate to safe length
    if (msg.length > 500) msg = msg.substring(0, 500);
    return msg;
  }

  // Safe breadcrumb message — strips values, keeps only structural info.
  static String safeBreadcrumb(String template, {String? screen, String? action}) {
    var msg = template;
    if (screen != null && screen.length <= 50) msg += ' screen=$screen';
    if (action != null && action.length <= 30) msg += ' action=$action';
    return msg.length > 200 ? msg.substring(0, 200) : msg;
  }
}
