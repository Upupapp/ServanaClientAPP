enum ServanaNotificationType {
  bookingCreated,
  bookingConfirmed,
  bookingCancelled,
  bookingRescheduled,
  bookingReminder,
  providerAssigned,
  providerEnRoute,
  providerArrived,
  serviceStarted,
  serviceCompleted,
  paymentActionRequired,
  paymentProcessing,
  paymentPaid,
  paymentFailed,
  paymentRefunded,
  messageReceived,
  supportUpdate,
  securityAlert,
  accountUpdate,
  promotion,
  systemMaintenance,
  unknown,
}

ServanaNotificationType notificationTypeFromString(String? raw) {
  switch (raw) {
    case 'booking_created':
      return ServanaNotificationType.bookingCreated;
    case 'booking_confirmed':
      return ServanaNotificationType.bookingConfirmed;
    case 'booking_cancelled':
      return ServanaNotificationType.bookingCancelled;
    case 'booking_rescheduled':
      return ServanaNotificationType.bookingRescheduled;
    case 'booking_reminder':
      return ServanaNotificationType.bookingReminder;
    case 'provider_assigned':
      return ServanaNotificationType.providerAssigned;
    case 'provider_en_route':
      return ServanaNotificationType.providerEnRoute;
    case 'provider_arrived':
      return ServanaNotificationType.providerArrived;
    case 'service_started':
      return ServanaNotificationType.serviceStarted;
    case 'service_completed':
      return ServanaNotificationType.serviceCompleted;
    case 'payment_action_required':
      return ServanaNotificationType.paymentActionRequired;
    case 'payment_processing':
      return ServanaNotificationType.paymentProcessing;
    case 'payment_paid':
      return ServanaNotificationType.paymentPaid;
    case 'payment_failed':
      return ServanaNotificationType.paymentFailed;
    case 'payment_refunded':
      return ServanaNotificationType.paymentRefunded;
    case 'message_received':
      return ServanaNotificationType.messageReceived;
    case 'support_update':
      return ServanaNotificationType.supportUpdate;
    case 'security_alert':
      return ServanaNotificationType.securityAlert;
    case 'account_update':
      return ServanaNotificationType.accountUpdate;
    case 'promotion':
      return ServanaNotificationType.promotion;
    case 'system':
    case 'system_maintenance':
      return ServanaNotificationType.systemMaintenance;
    default:
      return ServanaNotificationType.unknown;
  }
}
