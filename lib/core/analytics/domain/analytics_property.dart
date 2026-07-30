// Canonical property key constants and allowed enum value registries.
// All analytics properties used in events MUST appear in this file.
// This is the ANALYTICS_PROPERTY_ENUMS registry.

abstract final class AnalyticsKeys {
  // ── Context (auto-attached by AnalyticsContextProvider) ──────────────────
  static const String schemaVersion = 'schema_version';
  static const String platform = 'platform';
  static const String appVersion = 'app_version';
  static const String buildNumber = 'build_number';
  static const String environment = 'environment';
  static const String sessionId = 'session_id';

  // ── Navigation ────────────────────────────────────────────────────────────
  static const String screenName = 'screen_name';
  static const String screenClass = 'screen_class';
  static const String previousScreen = 'previous_screen';
  static const String entrySource = 'entry_source';
  static const String launchType = 'launch_type';
  static const String navigationType = 'navigation_type';
  static const String deepLinkType = 'deep_link_type';

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String authMethod = 'auth_method';
  static const String identifierType = 'identifier_type'; // reserved: email|phone
  static const String hasSession = 'has_session';
  static const String otpContext = 'otp_context';
  static const String logoutTrigger = 'logout_trigger';
  static const String step = 'step';
  static const String stepNumber = 'step_number';
  static const String failureCode = 'failure_code';

  // ── Onboarding ────────────────────────────────────────────────────────────
  static const String cardKey = 'card_key';
  static const String completionBand = 'completion_band';

  // ── Category ─────────────────────────────────────────────────────────────
  static const String categoryKey = 'category_key';

  // ── Search ────────────────────────────────────────────────────────────────
  static const String queryLengthBucket = 'query_length_bucket';
  static const String queryTokenCountBucket = 'query_token_count_bucket';
  static const String filterCount = 'filter_count';
  static const String resultCountBucket = 'result_count_bucket';
  static const String latencyBucket = 'latency_bucket';
  static const String sortKey = 'sort_key';

  // ── Service / Booking ─────────────────────────────────────────────────────
  static const String serviceCategory = 'service_category';
  static const String optionType = 'option_type';
  static const String addonCount = 'addon_count';
  static const String availabilityResult = 'availability_result';
  static const String coverageResult = 'coverage_result';
  static const String surface = 'surface';
  static const String positionBucket = 'position_bucket';
  static const String recommendationType = 'recommendation_type';
  static const String addressSource = 'address_source';
  static const String scheduleType = 'schedule_type';
  static const String quoteResult = 'quote_result';
  static const String bookingStatusCategory = 'booking_status_category';

  // ── Payment ───────────────────────────────────────────────────────────────
  static const String paymentMethod = 'payment_method';
  static const String paymentStatus = 'payment_status';
  static const String currency = 'currency';
  static const String amountBand = 'amount_band';
  static const String checkoutProvider = 'checkout_provider';

  // ── Messaging ─────────────────────────────────────────────────────────────
  static const String conversationType = 'conversation_type';
  static const String contentType = 'content_type';

  // ── Notifications ─────────────────────────────────────────────────────────
  static const String notificationType = 'notification_type';
  static const String routeKey = 'route_key';
  static const String appState = 'app_state';
  static const String permissionState = 'permission_state';
  static const String deliveryChannel = 'delivery_channel';

  // ── Tracking ─────────────────────────────────────────────────────────────
  static const String trackingStatusCategory = 'tracking_status_category';
  static const String freshnessCategory = 'freshness_category';
  static const String connectionState = 'connection_state'; // reserved: future use

  // ── Profile ───────────────────────────────────────────────────────────────
  static const String fieldCategory = 'field_category';
  static const String verificationType = 'verification_type';
  static const String profileCompletionBand = 'profile_completion_band';

  // ── Support ───────────────────────────────────────────────────────────────
  static const String supportCategory = 'support_category';

  // ── Review ────────────────────────────────────────────────────────────────
  static const String ratingBucket = 'rating_bucket';
  static const String hasPublicComment = 'has_public_comment';
  static const String hasPrivateFeedback = 'has_private_feedback';

  // ── Safety ────────────────────────────────────────────────────────────────
  static const String safetyPath = 'safety_path';
  static const String severity = 'severity';

  // ── Recovery ─────────────────────────────────────────────────────────────
  static const String operationType = 'operation_type';
  static const String recoveryResult = 'recovery_result';
  static const String retryCountBucket = 'retry_count_bucket';
  static const String failureCategory = 'failure_category';

  // ── Experiments ───────────────────────────────────────────────────────────
  static const String experimentKey = 'experiment_key';
  static const String variantKey = 'variant_key';
  static const String assignmentId = 'assignment_id';
  static const String flagKey = 'flag_key';
  static const String resolvedValue = 'resolved_value';
  static const String evaluationSource = 'evaluation_source';

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  static const String accountState = 'account_state';
  static const String lifecycleStage = 'lifecycle_stage';
  static const String hasCompletedBooking = 'has_completed_booking';

  // ── Attribution ───────────────────────────────────────────────────────────
  static const String utmSource = 'utm_source';
  static const String utmMedium = 'utm_medium';
  static const String utmCampaign = 'utm_campaign';
  static const String referralCategory = 'referral_category';

  // ── Generic ───────────────────────────────────────────────────────────────
  static const String result = 'result';
  static const String modelVersion = 'model_version';
  static const String promotionCategory = 'promotion_category';
  static const String featureKey = 'feature_key';
  static const String errorCategory = 'error_category';
  static const String appLanguage = 'app_language';
  static const String deviceLocale = 'device_locale';
}

// ── Allowed enum value sets ───────────────────────────────────────────────────
// Use values from these sets when constructing event properties.

abstract final class AuthMethodValues {
  static const String email = 'email';
  static const String google = 'google';
  static const String facebook = 'facebook';
  static const String sessionRestore = 'session_restore';
}

abstract final class FailureCodeValues {
  static const String invalidCredentials = 'invalid_credentials';
  static const String invalidOtp = 'invalid_otp';
  static const String expiredOtp = 'expired_otp';
  static const String rateLimited = 'rate_limited';
  static const String networkError = 'network_error';
  static const String accountDisabled = 'account_disabled';
  static const String notFound = 'not_found';
  static const String conflict = 'conflict';
  static const String forbidden = 'forbidden';
  static const String validation = 'validation';
  static const String timeout = 'timeout';
  static const String backendUnavailable = 'backend_unavailable';
  static const String paymentDeclined = 'payment_declined';
  static const String resourceChanged = 'resource_changed';
  static const String unknown = 'unknown';
}

abstract final class ResultValues {
  static const String success = 'success';
  static const String failure = 'failure';
  static const String cancelled = 'cancelled';
  static const String timeout = 'timeout';
  static const String skipped = 'skipped';
  static const String notEligible = 'not_eligible';
  static const String duplicate = 'duplicate';
}

abstract final class EntrySourceValues {
  static const String home = 'home';
  static const String search = 'search';
  static const String category = 'category';
  static const String notification = 'notification';
  static const String deepLink = 'deep_link';
  static const String bookingDetail = 'booking_detail';
  static const String profilePrompt = 'profile_prompt';
  static const String quickBook = 'quick_book';
  static const String rebooking = 'rebooking';
  static const String direct = 'direct';
  static const String unknown = 'unknown';
}

abstract final class BookingStatusCategoryValues {
  static const String actionRequired = 'action_required';
  static const String upcoming = 'upcoming';
  static const String active = 'active';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
  static const String pending = 'pending';
}

abstract final class PaymentMethodValues {
  static const String card = 'card';
  static const String eWallet = 'e_wallet';
  static const String gcash = 'gcash';
  static const String maya = 'maya';
  static const String grabPay = 'grab_pay';
  static const String paymongo = 'paymongo';
  static const String unknown = 'unknown';
}

abstract final class NotificationTypeValues {
  static const String bookingUpdate = 'booking_update';
  static const String paymentUpdate = 'payment_update';
  static const String messageNew = 'message_new';
  static const String assignmentUpdate = 'assignment_update';
  static const String supportUpdate = 'support_update';
  static const String systemUpdate = 'system_update';
  static const String promotion = 'promotion';
  static const String unknown = 'unknown';
}

abstract final class SupportCategoryValues {
  static const String bookingIssue = 'booking_issue';
  static const String paymentIssue = 'payment_issue';
  static const String providerIssue = 'provider_issue';
  static const String serviceQuality = 'service_quality';
  static const String accountIssue = 'account_issue';
  static const String refundRequest = 'refund_request';
  static const String safety = 'safety';
  static const String other = 'other';
}

abstract final class RecoveryOperationValues {
  static const String booking = 'booking';
  static const String payment = 'payment';
  static const String message = 'message';
  static const String upload = 'upload';
  static const String profile = 'profile';
  static const String unknown = 'unknown';
}

abstract final class AmountBandValues {
  static const String band0 = '0';
  static const String band1to500 = '1-500';
  static const String band501to1000 = '501-1000';
  static const String band1001to2000 = '1001-2000';
  static const String band2001to5000 = '2001-5000';
  static const String band5001plus = '5001+';

  static String forAmount(num amountPHP) {
    if (amountPHP <= 0) return band0;
    if (amountPHP <= 500) return band1to500;
    if (amountPHP <= 1000) return band501to1000;
    if (amountPHP <= 2000) return band1001to2000;
    if (amountPHP <= 5000) return band2001to5000;
    return band5001plus;
  }
}

abstract final class CountBucketValues {
  static String forCount(int count) {
    if (count == 0) return '0';
    if (count == 1) return '1';
    if (count <= 3) return '2-3';
    if (count <= 5) return '4-5';
    if (count <= 10) return '6-10';
    return '11+';
  }
}

abstract final class LatencyBucketValues {
  static String forMillis(int ms) {
    if (ms < 500) return '<500ms';
    if (ms < 1000) return '500-999ms';
    if (ms < 2000) return '1-2s';
    if (ms < 5000) return '2-5s';
    return '5s+';
  }
}
