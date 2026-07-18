/// Typed, normalized authentication identifier (email or Philippine mobile).
///
/// Use [AuthIdentifier.parse] to detect and wrap a raw input string.
/// The [normalized] getter always returns the backend-approved format.
sealed class AuthIdentifier {
  const AuthIdentifier(this.raw);

  /// Exactly what the user typed (trimmed).
  final String raw;

  /// Attempt to parse [input] into an [EmailIdentifier] or [MobileIdentifier].
  /// Returns `null` if the input is empty or matches neither format.
  static AuthIdentifier? parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    if (_looksLikeMobile(trimmed)) return MobileIdentifier(trimmed);
    if (_looksLikeEmail(trimmed)) return EmailIdentifier(trimmed);
    return null;
  }

  /// True when the trimmed input matches a Philippine mobile pattern but is
  /// not a valid email, so the UI can label the field appropriately.
  static bool isMobileInput(String input) =>
      _looksLikeMobile(input.trim()) && !_looksLikeEmail(input.trim());

  /// True when the trimmed input looks like an email address.
  static bool isEmailInput(String input) => _looksLikeEmail(input.trim());

  static bool _looksLikeMobile(String s) {
    // Strips spaces, dashes, parentheses then checks PH mobile patterns:
    // 09XXXXXXXXX, +639XXXXXXXXX, 639XXXXXXXXX (10 or 12 digits after prefix)
    final stripped = s.replaceAll(RegExp(r'[\s\-()]'), '');
    return RegExp(r'^(\+?63|0)[79]\d{9}$').hasMatch(stripped);
  }

  static bool _looksLikeEmail(String s) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);

  /// The value to send to the backend after normalization.
  String get normalized;

  /// A redacted version safe for logging (no raw PII).
  String get redacted;
}

class EmailIdentifier extends AuthIdentifier {
  const EmailIdentifier(super.raw);

  @override
  String get normalized => raw.trim().toLowerCase();

  @override
  String get redacted {
    final n = normalized;
    final at = n.indexOf('@');
    if (at <= 1) return '***@***';
    return '${n[0]}***${n.substring(at)}';
  }
}

class MobileIdentifier extends AuthIdentifier {
  const MobileIdentifier(super.raw);

  /// Normalizes to +63XXXXXXXXXX format.
  @override
  String get normalized {
    final stripped = raw.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    if (stripped.startsWith('0')) return '+63${stripped.substring(1)}';
    if (stripped.startsWith('63') && !stripped.startsWith('+')) {
      return '+$stripped';
    }
    return stripped;
  }

  @override
  String get redacted {
    final n = normalized; // e.g. +639171234567 (13 chars)
    if (n.length < 7) return '+63•••••••••';
    return '${n.substring(0, n.length - 4)}••••';
  }
}
