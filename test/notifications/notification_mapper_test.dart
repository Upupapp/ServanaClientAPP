import 'package:client/modules/notifications/data/notification_mapper.dart';
import 'package:client/modules/notifications/domain/notification_target.dart';
import 'package:client/modules/notifications/domain/notification_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mapNotification', () {
    test('maps a full backend notification JSON to ServanaNotification', () {
      final json = {
        'notificationKey': 'key-abc123',
        'type': 'booking_created',
        'status': 'unread',
        'severity': 'info',
        'title': 'Booking received',
        'safeBody': 'Your booking has been placed.',
        'safeContextLabel': 'Ref #4567',
        'route': {'routeKey': 'BOOKING_DETAILS', 'resourceId': '42'},
        'canMarkRead': true,
        'canDismiss': true,
        'canOpenDetail': true,
        'createdAt': '2025-01-15T10:00:00.000Z',
        'expiresAt': null,
        'readAt': null,
      };

      final n = mapNotification(json);

      expect(n.notificationKey, 'key-abc123');
      expect(n.type, ServanaNotificationType.bookingCreated);
      expect(n.title, 'Booking received');
      expect(n.safeBody, 'Your booking has been placed.');
      expect(n.safeContextLabel, 'Ref #4567');
      expect(n.isRead, isFalse);
      expect(n.canMarkRead, isTrue);
      expect(n.canDismiss, isTrue);
      expect(n.canOpenDetail, isTrue);
      expect(n.target, isA<BookingTarget>());
      expect((n.target as BookingTarget).bookingId, '42');
    });

    test('isRead is true when status is "read"', () {
      final json = {
        'notificationKey': 'k1',
        'type': 'message_received',
        'status': 'read',
        'title': 'New message',
        'safeBody': 'You have a new message.',
        'canMarkRead': false,
        'canDismiss': false,
        'canOpenDetail': false,
        'createdAt': '2025-01-15T10:00:00.000Z',
      };

      final n = mapNotification(json);
      expect(n.isRead, isTrue);
      expect(n.type, ServanaNotificationType.messageReceived);
    });

    test('unknown type maps to ServanaNotificationType.unknown', () {
      final json = {
        'notificationKey': 'k2',
        'type': 'some_future_type',
        'status': 'unread',
        'title': 'Future notification',
        'safeBody': 'Body.',
        'canMarkRead': false,
        'canDismiss': true,
        'canOpenDetail': false,
        'createdAt': '2025-01-15T10:00:00.000Z',
      };

      final n = mapNotification(json);
      expect(n.type, ServanaNotificationType.unknown);
    });

    test('null route produces null target', () {
      final json = {
        'notificationKey': 'k3',
        'type': 'system_maintenance',
        'status': 'unread',
        'title': 'Maintenance',
        'safeBody': 'Scheduled maintenance.',
        'route': null,
        'canMarkRead': false,
        'canDismiss': true,
        'canOpenDetail': false,
        'createdAt': '2025-01-15T10:00:00.000Z',
      };

      final n = mapNotification(json);
      expect(n.target, isNull);
    });

    test('CONVERSATION_THREAD routeKey maps to ConversationTarget', () {
      final json = {
        'notificationKey': 'k4',
        'type': 'message_received',
        'status': 'unread',
        'title': 'New message',
        'safeBody': 'Body.',
        'route': {'routeKey': 'CONVERSATION', 'resourceId': 'thread-99'},
        'canMarkRead': true,
        'canDismiss': true,
        'canOpenDetail': true,
        'createdAt': '2025-01-15T10:00:00.000Z',
      };

      final n = mapNotification(json);
      expect(n.target, isA<ConversationTarget>());
      expect((n.target as ConversationTarget).conversationId, 'thread-99');
    });
  });

  group('mapFcmDataToNotification', () {
    test('builds a ServanaNotification from FCM data payload', () {
      final data = {
        'notificationKey': 'fcm-key-1',
        'type': 'provider_assigned',
        'title': 'Provider assigned',
        'body': 'A provider has been assigned to your booking.',
        'schemaVersion': '1',
      };

      final n = mapFcmDataToNotification(data);
      expect(n, isNotNull);
      expect(n!.notificationKey, 'fcm-key-1');
      expect(n.type, ServanaNotificationType.providerAssigned);
      expect(n.title, 'Provider assigned');
      expect(n.safeBody, 'A provider has been assigned to your booking.');
      expect(n.isRead, isFalse);
    });

    test('returns null when notificationKey is missing', () {
      final data = {
        'type': 'booking_created',
        'title': 'Title',
        'body': 'Body.',
      };
      expect(mapFcmDataToNotification(data), isNull);
    });
  });
}
