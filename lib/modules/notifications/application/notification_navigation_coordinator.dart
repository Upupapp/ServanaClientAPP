import 'package:client/modules/bookings/presentation/screens/booking_detail_screen.dart';
import 'package:client/modules/bookings/presentation/screens/bookings_screen.dart';
import 'package:client/modules/messaging/presentation/screens/booking_chat_screen.dart';
import 'package:client/modules/messaging/presentation/screens/messages_inbox_screen.dart';
import 'package:client/modules/notifications/domain/notification_target.dart';
import 'package:client/modules/notifications/domain/servana_notification.dart';
import 'package:client/modules/support/presentation/screens/support_ticket_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotificationNavigationCoordinator {
  /// Navigate to the destination implied by [notification.target].
  /// Falls back gracefully if the target is unknown or context is stale.
  void navigateTo(BuildContext context, ServanaNotification notification) {
    if (!context.mounted) return;
    final target = notification.target;
    if (target == null) return;

    switch (target) {
      // ALIGN WARN-01: navigate to the specific booking, not just the list.
      case BookingTarget(:final bookingId):
        if (bookingId.isNotEmpty) {
          context.pushNamed(
            BookingDetailScreen.routeName,
            pathParameters: {'bookingId': bookingId},
          );
        } else {
          context.pushNamed(BookingsScreen.routeName);
        }

      case PaymentTarget(:final bookingId):
        if (bookingId.isNotEmpty) {
          context.pushNamed(
            BookingDetailScreen.routeName,
            pathParameters: {'bookingId': bookingId},
          );
        } else {
          context.pushNamed(BookingsScreen.routeName);
        }

      case ConversationTarget(:final conversationId):
        // Navigate to the inbox. When a conversationId is present it is passed
        // as a query parameter so the router can reconstruct the destination
        // after a cold start — state.extra does not survive process termination.
        if (conversationId.isNotEmpty) {
          context.pushNamed(
            MessagesInboxScreen.routeName,
            queryParameters: {'conversationId': conversationId},
          );
        } else {
          context.pushNamed(MessagesInboxScreen.routeName);
        }

      case CategoryTarget():
        context.go('/HomeScreen');

      // ALIGN WARN-02: go to the settings hub, not the home screen.
      case SettingsTarget():
        context.push('/settings');

      // REPEAT FAIL-04: use GoRouter so the auth guard applies.
      case SupportTicketTarget(:final ticketKey):
        context.pushNamed(
          SupportTicketDetailScreen.routeName,
          pathParameters: {'ticketKey': ticketKey},
        );

      case UnknownTarget():
        break;
    }
  }

  /// Navigate directly to a booking's chat screen.
  /// Used when FCM payload contains both bookingId and conversationId.
  void navigateToBookingChat(
    BuildContext context, {
    required String bookingId,
    String? title,
  }) {
    if (!context.mounted) return;
    context.pushNamed(
      BookingChatScreen.routeName,
      pathParameters: {'jobOrderId': bookingId},
      extra: title,
    );
  }
}
