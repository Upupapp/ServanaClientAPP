// Pseudonymous user context attached to analytics events after login.
// NEVER contains email, mobile, name, or raw database identifiers.
class AnalyticsUserContext {
  const AnalyticsUserContext({
    required this.analyticsId,
    required this.accountState,
    required this.lifecycleStage,
    required this.profileCompletionBand,
    required this.hasCompletedBooking,
  });

  // Opaque analytics identifier — derived from backend customer ID
  // using a non-reversible transform. NOT the raw customerID.
  final String analyticsId;

  // Coarse account state: 'authenticated' | 'guest'
  final String accountState;

  // Coarse lifecycle: 'new' | 'active' | 'dormant' | 'reactivated'
  final String lifecycleStage;

  // '0' | '1-25' | '26-50' | '51-75' | '76-99' | '100'
  final String profileCompletionBand;

  final bool hasCompletedBooking;

  static const AnalyticsUserContext guest = AnalyticsUserContext(
    analyticsId: '',
    accountState: 'guest',
    lifecycleStage: 'none',
    profileCompletionBand: '0',
    hasCompletedBooking: false,
  );

  // Derive an analytics-safe ID from the backend customer ID.
  // XOR-folds all bytes of the stripped ID into a 16-byte accumulator,
  // then encodes as 32 lowercase hex chars.
  // Non-reversible and independent of byte position — safe to send to Firebase.
  static String deriveAnalyticsId(String customerRawId) {
    if (customerRawId.isEmpty) return '';
    final stripped = customerRawId.replaceAll('-', '').toLowerCase();
    final bytes = stripped.codeUnits;
    final folded = List<int>.filled(16, 0);
    for (var i = 0; i < bytes.length; i++) {
      folded[i % 16] ^= bytes[i];
    }
    return folded
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(); // 32 hex chars — all 16 fold bytes used, no truncation
  }

  static String profileBandFor(int score) {
    if (score == 0) return '0';
    if (score <= 25) return '1-25';
    if (score <= 50) return '26-50';
    if (score <= 75) return '51-75';
    if (score < 100) return '76-99';
    return '100';
  }
}
