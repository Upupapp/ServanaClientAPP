/// The only place `/api/v1` paths are written.
///
/// ## Why paths are functions and not strings at call sites
///
/// The acceptance gate for this work is that no screen contains a raw endpoint
/// string. That is enforceable only if there is somewhere else for the string
/// to live. Every path the canonical client can reach is constructed here, from
/// the backend's generated `docs/api/API_ENDPOINT_REGISTRY.md`, so a route
/// rename is one edit and a typo is a compile error rather than a 404 in
/// somebody's hands.
///
/// ## Only implemented endpoints
///
/// The backend contract distinguishes `implemented` from `planned`, and calling
/// a planned entry returns 404 by design. Only implemented entries appear here.
/// The four planned admin endpoints are deliberately absent — a customer app
/// must never hold them anyway.
///
/// ## No base URL
///
/// These are paths, never absolute URLs. The origin comes from
/// `AppConfig.baseUrl` and is applied by [V1ApiClient]. Nothing in this file
/// knows whether it is talking to production, staging or a laptop.
library;

class V1Endpoints {
  V1Endpoints._();

  /// Namespace prefix. Matches the backend's `V1_PREFIX`.
  static const String prefix = '/api/v1';

  // ── Catalog ────────────────────────────────────────────────────────────────
  static String catalog() => '$prefix/catalog';
  static String catalogSummary() => '$prefix/catalog/summary';
  static String catalogServices() => '$prefix/catalog/services';
  static String catalogService(String serviceId) =>
      '$prefix/catalog/services/${_seg(serviceId)}';
  static String catalogSearch() => '$prefix/catalog/search';
  static String catalogCategories() => '$prefix/catalog/categories';
  static String catalogCategory(String categoryId) =>
      '$prefix/catalog/categories/${_seg(categoryId)}';
  static String catalogCategorySubcategories(String categoryId) =>
      '$prefix/catalog/categories/${_seg(categoryId)}/subcategories';
  static String catalogSubcategory(String subcategoryId) =>
      '$prefix/catalog/subcategories/${_seg(subcategoryId)}';
  static String catalogSubcategoryServices(String subcategoryId) =>
      '$prefix/catalog/subcategories/${_seg(subcategoryId)}/services';

  // ── Identity and account ───────────────────────────────────────────────────
  static String me() => '$prefix/me';
  static String meSettings() => '$prefix/me/settings';
  static String meSecurity() => '$prefix/me/security';
  static String meCompletion() => '$prefix/me/completion';
  static String meDevices() => '$prefix/me/devices';
  static String meNotificationPreferences() =>
      '$prefix/me/notification-preferences';

  // ── Customer profile and addresses ─────────────────────────────────────────
  static String customerProfile() => '$prefix/customer/profile';
  static String customerAddresses() => '$prefix/customer/addresses';
  static String customerAddress(String addressId) =>
      '$prefix/customer/addresses/${_seg(addressId)}';
  static String customerAddressDefault(String addressId) =>
      '$prefix/customer/addresses/${_seg(addressId)}/default';

  // ── Bookings ───────────────────────────────────────────────────────────────
  //
  // Read and lifecycle only. There is deliberately no `createBooking` here:
  // the canonical contract has no `POST /api/v1/bookings`, and inventing one
  // would produce a client that 404s the moment v1 deploys.
  static String bookings() => '$prefix/bookings';
  static String booking(String bookingId) =>
      '$prefix/bookings/${_seg(bookingId)}';
  static String bookingTimeline(String bookingId) =>
      '$prefix/bookings/${_seg(bookingId)}/timeline';
  static String bookingTransitions(String bookingId) =>
      '$prefix/bookings/${_seg(bookingId)}/transitions';
  static String bookingCancel(String bookingId) =>
      '$prefix/bookings/${_seg(bookingId)}/cancel';
  static String bookingTracking(String bookingId) =>
      '$prefix/bookings/${_seg(bookingId)}/tracking';
  static String bookingOtpRequest(String bookingId) =>
      '$prefix/bookings/${_seg(bookingId)}/otp/request';
  static String bookingOtpVerify(String bookingId) =>
      '$prefix/bookings/${_seg(bookingId)}/otp/verify';
  static String bookingOtpStatus(String bookingId) =>
      '$prefix/bookings/${_seg(bookingId)}/otp/status';
  static String bookingReschedule(String bookingId) =>
      '$prefix/bookings/${_seg(bookingId)}/reschedule';
  static String bookingAdditionalWork(String bookingId) =>
      '$prefix/bookings/${_seg(bookingId)}/additional-work';
  static String bookingDisputes(String bookingId) =>
      '$prefix/bookings/${_seg(bookingId)}/disputes';
  static String bookingReview(String bookingId) =>
      '$prefix/bookings/${_seg(bookingId)}/review';
  static String bookingSupportCases(String bookingId) =>
      '$prefix/bookings/${_seg(bookingId)}/support-cases';

  // ── Payments ───────────────────────────────────────────────────────────────
  static String bookingPaymentIntents(String bookingId) =>
      '$prefix/bookings/${_seg(bookingId)}/payment-intents';
  static String bookingPayment(String bookingId) =>
      '$prefix/bookings/${_seg(bookingId)}/payment';
  static String bookingRefunds(String bookingId) =>
      '$prefix/bookings/${_seg(bookingId)}/refunds';

  // ── Notifications ──────────────────────────────────────────────────────────
  static String notifications() => '$prefix/notifications';
  static String notificationsUnreadCount() =>
      '$prefix/notifications/unread-count';
  static String notificationRead(String key) =>
      '$prefix/notifications/${_seg(key)}/read';
  static String notificationsReadAll() => '$prefix/notifications/read-all';

  // ── Conversations ──────────────────────────────────────────────────────────
  static String conversations() => '$prefix/conversations';
  static String conversation(String conversationId) =>
      '$prefix/conversations/${_seg(conversationId)}';
  static String conversationMessages(String conversationId) =>
      '$prefix/conversations/${_seg(conversationId)}/messages';
  static String conversationRead(String conversationId) =>
      '$prefix/conversations/${_seg(conversationId)}/read';

  // ── Reviews ────────────────────────────────────────────────────────────────
  static String providerReviews(String providerUid) =>
      '$prefix/reviews/providers/${_seg(providerUid)}';
  static String providerRating(String providerUid) =>
      '$prefix/reviews/providers/${_seg(providerUid)}/rating';

  // ── Discovery ──────────────────────────────────────────────────────────────
  static String search() => '$prefix/search';
  static String home() => '$prefix/home';
  static String homeSections() => '$prefix/home/sections';

  // ── Auth ───────────────────────────────────────────────────────────────────
  static String authRegister() => '$prefix/auth/register';
  static String authLogin() => '$prefix/auth/login';
  static String authRefresh() => '$prefix/auth/refresh';
  static String authLogout() => '$prefix/auth/logout';
  static String authForgotPassword() => '$prefix/auth/forgot-password';
  static String authResetPassword() => '$prefix/auth/reset-password';
  static String authVerifyEmail() => '$prefix/auth/verify-email';
  static String authResendVerification() => '$prefix/auth/resend-verification';
  static String authVerifyMobile() => '$prefix/auth/verify-mobile';

  // ── Settings ───────────────────────────────────────────────────────────────
  static String settingsNotificationPreferences() =>
      '$prefix/settings/notification-preferences';

  /// Percent-encodes one path segment.
  ///
  /// Ids reach here from deep links and cached payloads, so a segment
  /// containing `/` or `?` would otherwise silently retarget the request at a
  /// different route.
  static String _seg(String value) => Uri.encodeComponent(value);
}
