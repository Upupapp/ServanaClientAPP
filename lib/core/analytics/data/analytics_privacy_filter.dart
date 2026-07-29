import '../domain/analytics_event.dart';
import '../domain/analytics_property.dart';

// Enforces two-layer protection:
// 1. BANNED_KEYS: any key on this list is stripped even if the event author
//    accidentally included it. Treated as a developer error in debug mode.
// 2. ALLOWED_KEYS: only keys on this allowlist may pass through to Firebase.
//    Unrecognized keys are stripped silently (defence-in-depth).
final class AnalyticsPrivacyFilter {
  const AnalyticsPrivacyFilter();

  // Keys that are NEVER permitted in analytics regardless of context.
  // Matches case-insensitively; also matches substrings marked with *.
  static const Set<String> _bannedKeys = {
    'email',
    'mobile',
    'phone',
    'phone_number',
    'mobile_number',
    'name',
    'first_name',
    'last_name',
    'full_name',
    'fullname',
    'customer_name',
    'display_name',
    'address',
    'address_one',
    'address_two',
    'full_address',
    'street_address',
    'postal_code',
    'zip_code',
    'barangay',
    'lat',
    'latitude',
    'lon',
    'longitude',
    'lng',
    'coordinates',
    'coordinate',
    'location',
    'otp',
    'otp_code',
    'verification_code',
    'pin',
    'password',
    'token',
    'auth_token',
    'id_token',
    'access_token',
    'firebase_token',
    'fcm_token',
    'refresh_token',
    'secret',
    'checkout_url',
    'payment_url',
    'redirect_url',
    'return_url',
    'attachment_url',
    'file_url',
    'photo_url',
    'image_url',
    'file_name',
    'filename',
    'message_body',
    'message_text',
    'message_content',
    'body',
    'text',
    'content',
    'support_description',
    'support_title',
    'ticket_description',
    'ticket_body',
    'ticket_subject',
    'review_text',
    'review_content',
    'public_comment',
    'private_feedback',
    'comment',
    'feedback',
    'description',
    'customer_id',
    'user_id',
    'uid',
    'booking_id',
    'job_order_id',
    'booking_reference',
    'provider_id',
    'provider_uid',
    'technician_id',
    'conversation_id',
    'chat_id',
    'ticket_key',
    'incident_id',
  };

  // Only keys from the registered allowlist pass through.
  static final Set<String> _allowedKeys = {
    // Auto-attached context
    AnalyticsKeys.schemaVersion,
    AnalyticsKeys.platform,
    AnalyticsKeys.appVersion,
    AnalyticsKeys.buildNumber,
    AnalyticsKeys.environment,
    AnalyticsKeys.sessionId,
    // Navigation
    AnalyticsKeys.screenName,
    AnalyticsKeys.screenClass,
    AnalyticsKeys.previousScreen,
    AnalyticsKeys.entrySource,
    AnalyticsKeys.navigationType,
    AnalyticsKeys.deepLinkType,
    // Auth
    AnalyticsKeys.authMethod,
    AnalyticsKeys.identifierType,
    AnalyticsKeys.step,
    AnalyticsKeys.stepNumber,
    AnalyticsKeys.failureCode,
    // Onboarding
    AnalyticsKeys.cardKey,
    AnalyticsKeys.completionBand,
    // Category
    AnalyticsKeys.categoryKey,
    // Search
    AnalyticsKeys.queryLengthBucket,
    AnalyticsKeys.queryTokenCountBucket,
    AnalyticsKeys.filterCount,
    AnalyticsKeys.resultCountBucket,
    AnalyticsKeys.latencyBucket,
    AnalyticsKeys.sortKey,
    // Service / Booking
    AnalyticsKeys.serviceCategory,
    AnalyticsKeys.optionType,
    AnalyticsKeys.addonCount,
    AnalyticsKeys.availabilityResult,
    AnalyticsKeys.coverageResult,
    AnalyticsKeys.surface,
    AnalyticsKeys.positionBucket,
    AnalyticsKeys.recommendationType,
    AnalyticsKeys.addressSource,
    AnalyticsKeys.scheduleType,
    AnalyticsKeys.quoteResult,
    AnalyticsKeys.bookingStatusCategory,
    // Payment
    AnalyticsKeys.paymentMethod,
    AnalyticsKeys.paymentStatus,
    AnalyticsKeys.currency,
    AnalyticsKeys.amountBand,
    AnalyticsKeys.checkoutProvider,
    // Messaging
    AnalyticsKeys.conversationType,
    AnalyticsKeys.contentType,
    // Notifications
    AnalyticsKeys.notificationType,
    AnalyticsKeys.routeKey,
    AnalyticsKeys.appState,
    AnalyticsKeys.permissionState,
    AnalyticsKeys.deliveryChannel,
    // Tracking
    AnalyticsKeys.trackingStatusCategory,
    AnalyticsKeys.freshnessCategory,
    AnalyticsKeys.connectionState,
    // Profile
    AnalyticsKeys.fieldCategory,
    AnalyticsKeys.verificationType,
    AnalyticsKeys.profileCompletionBand,
    // Support
    AnalyticsKeys.supportCategory,
    // Review
    AnalyticsKeys.ratingBucket,
    AnalyticsKeys.hasPublicComment,
    AnalyticsKeys.hasPrivateFeedback,
    // Safety
    AnalyticsKeys.safetyPath,
    AnalyticsKeys.severity,
    // Recovery
    AnalyticsKeys.operationType,
    AnalyticsKeys.recoveryResult,
    AnalyticsKeys.retryCountBucket,
    AnalyticsKeys.failureCategory,
    // Experiments
    AnalyticsKeys.experimentKey,
    AnalyticsKeys.variantKey,
    AnalyticsKeys.assignmentId,
    AnalyticsKeys.flagKey,
    AnalyticsKeys.resolvedValue,
    AnalyticsKeys.evaluationSource,
    // Lifecycle
    AnalyticsKeys.accountState,
    AnalyticsKeys.lifecycleStage,
    AnalyticsKeys.hasCompletedBooking,
    // Attribution
    AnalyticsKeys.utmSource,
    AnalyticsKeys.utmMedium,
    AnalyticsKeys.utmCampaign,
    AnalyticsKeys.referralCategory,
    // Generic
    AnalyticsKeys.result,
    AnalyticsKeys.modelVersion,
    AnalyticsKeys.promotionCategory,
    AnalyticsKeys.featureKey,
    AnalyticsKeys.errorCategory,
    AnalyticsKeys.appLanguage,
    AnalyticsKeys.deviceLocale,
    // Extra allowed for auth/lifecycle events
    'has_session',
    'otp_context',
    'logout_trigger',
    'launch_type',
  };

  // Returns a filtered copy of the event's properties.
  // Banned keys are removed. Unrecognized keys (not in allowlist) are removed.
  // Returns the cleaned map plus a list of violations (for debug logging only).
  ({Map<String, Object?> clean, List<String> violations}) filter(
      AnalyticsEvent event) {
    final raw = event.properties;
    final clean = <String, Object?>{};
    final violations = <String>[];

    for (final entry in raw.entries) {
      final key = entry.key.toLowerCase();
      if (_bannedKeys.contains(key)) {
        violations.add('BANNED:${entry.key}');
        continue;
      }
      if (!_allowedKeys.contains(entry.key)) {
        violations.add('UNLISTED:${entry.key}');
        continue;
      }
      // Also check string values for PII patterns (defence-in-depth)
      if (entry.value is String) {
        final val = entry.value as String;
        if (_looksLikePii(val)) {
          violations.add('PII_VALUE:${entry.key}');
          continue;
        }
      }
      clean[entry.key] = entry.value;
    }

    return (clean: clean, violations: violations);
  }

  // Heuristic: email or phone-number-like strings in property values.
  // Does not block all PII but catches common accidents.
  static bool _looksLikePii(String value) {
    if (value.length > 200) return true; // oversized = likely free text
    if (_emailPattern.hasMatch(value)) return true;
    if (_phPhonePattern.hasMatch(value)) return true;
    return false;
  }

  static final _emailPattern = RegExp(r'[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}');
  static final _phPhonePattern = RegExp(r'(\+63|0)(9\d{9})');
}
