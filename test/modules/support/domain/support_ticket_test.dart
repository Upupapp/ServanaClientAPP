import 'package:client/modules/support/domain/support_ticket.dart';
import 'package:client/modules/support/domain/support_ticket_category.dart';
import 'package:client/modules/support/domain/support_ticket_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SupportTicketStatus', () {
    test('fromString maps known values', () {
      expect(SupportTicketStatus.fromString('submitted'),
          SupportTicketStatus.submitted);
      expect(SupportTicketStatus.fromString('open'), SupportTicketStatus.open);
      expect(SupportTicketStatus.fromString('waiting_for_support'),
          SupportTicketStatus.waitingForSupport);
      expect(SupportTicketStatus.fromString('waiting_for_customer'),
          SupportTicketStatus.waitingForCustomer);
      expect(SupportTicketStatus.fromString('escalated'),
          SupportTicketStatus.escalated);
      expect(SupportTicketStatus.fromString('resolved'),
          SupportTicketStatus.resolved);
      expect(
          SupportTicketStatus.fromString('closed'), SupportTicketStatus.closed);
    });

    test('fromString returns unknown for unrecognised value', () {
      expect(SupportTicketStatus.fromString('something_new'),
          SupportTicketStatus.unknown);
      expect(SupportTicketStatus.fromString(null), SupportTicketStatus.unknown);
    });

    test('isActive is true for open statuses only', () {
      expect(SupportTicketStatus.submitted.isActive, isTrue);
      expect(SupportTicketStatus.open.isActive, isTrue);
      expect(SupportTicketStatus.waitingForSupport.isActive, isTrue);
      expect(SupportTicketStatus.waitingForCustomer.isActive, isTrue);
      expect(SupportTicketStatus.escalated.isActive, isTrue);
      expect(SupportTicketStatus.resolved.isActive, isFalse);
      expect(SupportTicketStatus.closed.isActive, isFalse);
    });

    test('needsCustomerAction is true only for waitingForCustomer', () {
      for (final s in SupportTicketStatus.values) {
        expect(
          s.needsCustomerAction,
          s == SupportTicketStatus.waitingForCustomer,
          reason:
              'Expected needsCustomerAction=${s == SupportTicketStatus.waitingForCustomer} for $s',
        );
      }
    });
  });

  group('SupportTicketCategory', () {
    test('fromString maps all known apiKey values', () {
      expect(SupportTicketCategory.fromString('booking'),
          SupportTicketCategory.booking);
      expect(SupportTicketCategory.fromString('payment'),
          SupportTicketCategory.payment);
      expect(SupportTicketCategory.fromString('refund'),
          SupportTicketCategory.refund);
      expect(SupportTicketCategory.fromString('service_quality'),
          SupportTicketCategory.serviceQuality);
      expect(SupportTicketCategory.fromString('provider_conduct'),
          SupportTicketCategory.providerConduct);
      expect(SupportTicketCategory.fromString('account'),
          SupportTicketCategory.account);
      expect(SupportTicketCategory.fromString('technical'),
          SupportTicketCategory.technical);
      expect(SupportTicketCategory.fromString('promotion'),
          SupportTicketCategory.promotion);
      expect(SupportTicketCategory.fromString('privacy'),
          SupportTicketCategory.privacy);
      expect(SupportTicketCategory.fromString('safety'),
          SupportTicketCategory.safety);
      expect(SupportTicketCategory.fromString('other'),
          SupportTicketCategory.other);
    });

    test('fromString defaults to other for unknown', () {
      expect(
          SupportTicketCategory.fromString(null), SupportTicketCategory.other);
      expect(
          SupportTicketCategory.fromString('xyz'), SupportTicketCategory.other);
    });

    test('requiresBooking is true for booking, serviceQuality, providerConduct',
        () {
      expect(SupportTicketCategory.booking.requiresBooking, isTrue);
      expect(SupportTicketCategory.serviceQuality.requiresBooking, isTrue);
      expect(SupportTicketCategory.providerConduct.requiresBooking, isTrue);
      expect(SupportTicketCategory.payment.requiresBooking, isFalse);
    });

    test('isHighPriority is true for safety and providerConduct', () {
      expect(SupportTicketCategory.safety.isHighPriority, isTrue);
      expect(SupportTicketCategory.providerConduct.isHighPriority, isTrue);
      expect(SupportTicketCategory.booking.isHighPriority, isFalse);
    });
  });

  group('SupportTicket', () {
    SupportTicket makeTicket({
      String ticketKey = 'abc123',
      SupportTicketStatus status = SupportTicketStatus.open,
    }) {
      return SupportTicket(
        ticketKey: ticketKey,
        category: SupportTicketCategory.booking,
        status: status,
        title: 'Test ticket',
        safeSummary: 'Test summary',
        canReply: true,
        canClose: true,
        canReopen: false,
      );
    }

    test('shortRef returns first 8 chars uppercased', () {
      final t = makeTicket(ticketKey: 'abcdefgh1234');
      expect(t.shortRef, 'ABCDEFGH');
    });

    test('shortRef for short key returns full key uppercased', () {
      final t = makeTicket(ticketKey: 'abc');
      expect(t.shortRef, 'ABC');
    });

    test('copyWith replaces only specified fields', () {
      final t = makeTicket(status: SupportTicketStatus.open);
      final t2 = t.copyWith(status: SupportTicketStatus.resolved);
      expect(t2.status, SupportTicketStatus.resolved);
      expect(t2.ticketKey, t.ticketKey);
      expect(t2.title, t.title);
    });

    test('replies default to empty', () {
      expect(makeTicket().replies, isEmpty);
    });
  });

  group('SupportReply', () {
    test('optimistic factory sets isPending=true', () {
      final r = SupportReply.optimistic(
        ticketKey: 'tk1',
        body: 'Hello',
        clientReplyId: 'cr1',
      );
      expect(r.isPending, isTrue);
      expect(r.isFailed, isFalse);
      expect(r.author, SupportReplyAuthor.customer);
    });

    test('fromMap maps author correctly', () {
      final map = {
        'id': 'rk1',
        'safeBody': 'Hi there',
        'senderType': 'support',
        'createdAt': '2025-01-01T00:00:00.000Z',
        'isRead': false,
      };
      final r = SupportReply.fromMap(map, 'tk1');
      expect(r.author, SupportReplyAuthor.support);
      expect(r.body, 'Hi there');
      expect(r.isPending, isFalse);
    });

    test('fromMap defaults to unknown for unrecognised senderType', () {
      final map = {
        'safeBody': 'msg',
        'senderType': 'unknown_role',
      };
      final r = SupportReply.fromMap(map, 'tk1');
      expect(r.author, SupportReplyAuthor.unknown);
    });

    test('copyWith toggles isFailed', () {
      final r = SupportReply.optimistic(
        ticketKey: 'tk1',
        body: 'msg',
        clientReplyId: 'cr1',
      );
      final failed = r.copyWith(isPending: false, isFailed: true);
      expect(failed.isFailed, isTrue);
      expect(failed.isPending, isFalse);
      expect(failed.body, r.body);
    });
  });
}
