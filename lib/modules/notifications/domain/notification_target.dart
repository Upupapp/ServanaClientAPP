sealed class NotificationTarget {}

class BookingTarget extends NotificationTarget {
  final String bookingId;
  BookingTarget(this.bookingId);
}

class PaymentTarget extends NotificationTarget {
  final String bookingId;
  PaymentTarget(this.bookingId);
}

class ConversationTarget extends NotificationTarget {
  final String conversationId;
  ConversationTarget(this.conversationId);
}

class CategoryTarget extends NotificationTarget {
  final String categoryKey;
  CategoryTarget(this.categoryKey);
}

class SettingsTarget extends NotificationTarget {}

class SupportTicketTarget extends NotificationTarget {
  final String ticketKey;
  SupportTicketTarget(this.ticketKey);
}

class UnknownTarget extends NotificationTarget {
  final String routeKey;
  UnknownTarget(this.routeKey);
}

NotificationTarget? targetFromRoute(Map<String, dynamic>? route) {
  if (route == null) return null;
  final key = route['routeKey'] as String?;
  final resourceId = (route['resourceId'] as String?) ?? '';
  switch (key) {
    case 'BOOKING_DETAILS':
    case 'BOOKING_TRACKING':
      return resourceId.isNotEmpty ? BookingTarget(resourceId) : null;
    case 'PAYMENT_DETAILS':
    case 'PAYMENT_ACTION':
      return resourceId.isNotEmpty ? PaymentTarget(resourceId) : null;
    case 'CONVERSATION':
      return resourceId.isNotEmpty ? ConversationTarget(resourceId) : null;
    case 'CATEGORY':
      return resourceId.isNotEmpty ? CategoryTarget(resourceId) : null;
    case 'NOTIFICATION_SETTINGS':
    case 'SECURITY_SETTINGS':
      return SettingsTarget();
    case 'SUPPORT_TICKET':
      return resourceId.isNotEmpty ? SupportTicketTarget(resourceId) : null;
    case null:
      return null;
    default:
      return UnknownTarget(key);
  }
}
