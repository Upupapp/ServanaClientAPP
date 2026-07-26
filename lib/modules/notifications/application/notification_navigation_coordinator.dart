import 'package:client/modules/bookings/presentation/screens/bookings_screen.dart';
import 'package:client/modules/messaging/presentation/screens/messages_inbox_screen.dart';
import 'package:client/modules/notifications/domain/notification_target.dart';
import 'package:client/modules/notifications/domain/servana_notification.dart';
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
      case BookingTarget():
        context.pushNamed(BookingsScreen.routeName);
      case PaymentTarget():
        context.pushNamed(BookingsScreen.routeName);
      case ConversationTarget():
        context.pushNamed(MessagesInboxScreen.routeName);
      case CategoryTarget():
        // Navigate home — category tap is handled by the user on the home screen.
        context.go('/HomeScreen');
      case SettingsTarget():
        context.go('/HomeScreen');
      case UnknownTarget():
        break;
    }
  }
}
