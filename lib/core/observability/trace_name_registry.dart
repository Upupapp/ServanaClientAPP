// Stable trace name constants for Firebase Performance Monitoring.
// Only these names are permitted — dynamic trace names with IDs are forbidden.
abstract final class TraceNames {
  static const String appStartup = 'app_startup';
  static const String homeLoad = 'home_load';
  static const String searchRequest = 'search_request';
  static const String serviceDetailLoad = 'service_detail_load';
  static const String bookingSubmit = 'booking_submit';
  static const String checkoutCreate = 'checkout_create';
  static const String bookingDetailLoad = 'booking_detail_load';
  static const String conversationLoad = 'conversation_load';
  static const String trackingSnapshotLoad = 'tracking_snapshot_load';
  static const String profileLoad = 'profile_load';
  static const String supportTicketLoad = 'support_ticket_load';
  static const String reviewEligibilityCheck = 'review_eligibility_check';
  static const String notificationListLoad = 'notification_list_load';

  // HTTP route templates — path params replaced with {param}
  static const String httpGetBookings = 'GET /api/bookings';
  static const String httpGetBooking = 'GET /api/bookings/{bookingId}';
  static const String httpCreateBooking = 'POST /api/bookings';
  static const String httpGetConversation = 'GET /api/bookings/{id}/conversation';
  static const String httpGetMessages = 'GET /api/conversations/{id}/messages';
  static const String httpSendMessage = 'POST /api/conversations/{id}/messages';
  static const String httpGetProfile = 'GET /api/user/profile';
  static const String httpCreateCheckout = 'POST /api/payments/checkout';
  static const String httpGetPaymentStatus = 'GET /api/payments/{id}/status';
}
