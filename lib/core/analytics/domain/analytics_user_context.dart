import 'dart:convert';

import 'package:crypto/crypto.dart';

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

  // Fixed namespace key — makes IDs stable across installs and consistent
  // across platforms, while preventing trivial dictionary attacks.
  static const _hmacNamespace = 'servana-analytics-v1';

  // Derive an analytics-safe ID from the backend customer ID using
  // HMAC-SHA256. The output is non-reversible and has full avalanche
  // properties — a 1-bit input change flips ~50% of the output bits.
  // Returns the first 32 hex chars (128 bits) of the digest.
  static String deriveAnalyticsId(String customerRawId) {
    if (customerRawId.isEmpty) return '';
    final key = utf8.encode(_hmacNamespace);
    final message = utf8.encode(customerRawId.trim().toLowerCase());
    final digest = Hmac(sha256, key).convert(message);
    return digest.toString().substring(0, 32);
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
