import 'package:client/modules/notifications/domain/notification_permission_state.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationPermissionCoordinator {
  Future<NotificationPermissionState> currentState() async {
    try {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      return _map(settings.authorizationStatus);
    } catch (_) {
      return NotificationPermissionState.notDetermined;
    }
  }

  Future<NotificationPermissionState> requestPermission() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      return _map(settings.authorizationStatus);
    } catch (_) {
      return NotificationPermissionState.notDetermined;
    }
  }

  NotificationPermissionState _map(AuthorizationStatus status) =>
      switch (status) {
        AuthorizationStatus.authorized => NotificationPermissionState.authorized,
        AuthorizationStatus.provisional => NotificationPermissionState.provisional,
        AuthorizationStatus.denied => NotificationPermissionState.denied,
        AuthorizationStatus.notDetermined => NotificationPermissionState.notDetermined,
      };
}
