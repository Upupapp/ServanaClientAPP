import 'dart:async';

import 'package:client/modules/support/application/support_controller.dart';
import 'package:client/modules/support/application/support_ticket_controller.dart';
import 'package:client/modules/support/data/support_repository.dart';
import 'package:client/modules/support/domain/support_ticket.dart';
import 'package:client/modules/support/domain/support_ticket_category.dart';
import 'package:client/modules/support/domain/support_ticket_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSupportRepository extends Mock implements SupportRepository {}
class MockSupportController extends Mock implements SupportController {}

void main() {
  late MockSupportRepository repo;
  late MockSupportController supportCtrl;
  late SupportTicketController ctrl;

  SupportTicket makeTicket({
    String key = 'tk1',
    SupportTicketStatus status = SupportTicketStatus.open,
    bool canReply = true,
    bool canClose = true,
    bool canReopen = false,
    List<SupportReply> replies = const [],
    int unreadCount = 0,
  }) {
    return SupportTicket(
      ticketKey: key,
      category: SupportTicketCategory.booking,
      status: status,
      title: 'Test Ticket',
      safeSummary: '',
      canReply: canReply,
      canClose: canClose,
      canReopen: canReopen,
      replies: replies,
      unreadCount: unreadCount,
    );
  }

  SupportReply makeReply({
    String replyId = 'r1',
    String ticketKey = 'tk1',
    String body = 'A reply',
    bool isPending = false,
    bool isFailed = false,
    String? clientReplyId,
  }) {
    return SupportReply(
      replyId: replyId,
      ticketKey: ticketKey,
      author: SupportReplyAuthor.customer,
      body: body,
      isPending: isPending,
      isFailed: isFailed,
      clientReplyId: clientReplyId,
    );
  }

  setUp(() {
    repo = MockSupportRepository();
    supportCtrl = MockSupportController();
    ctrl = SupportTicketController(
      repository: repo,
      supportController: supportCtrl,
    );
    when(() => supportCtrl.decrementUnread(any())).thenReturn(null);
    when(() => repo.markRead(any())).thenAnswer((_) async {});
  });

  tearDown(() => ctrl.dispose());

  test('initial state is correct', () {
    expect(ctrl.status, TicketDetailStatus.initial);
    expect(ctrl.ticket, isNull);
    expect(ctrl.error, isNull);
    expect(ctrl.isLoading, isFalse);
    expect(ctrl.isReplying, isFalse);
    expect(ctrl.isMutating, isFalse);
  });

  test('loadTicket sets loaded state on success', () async {
    final ticket = makeTicket();
    when(() => repo.getTicketDetail('tk1')).thenAnswer((_) async => ticket);

    await ctrl.loadTicket('tk1');

    expect(ctrl.status, TicketDetailStatus.loaded);
    expect(ctrl.ticket, ticket);
    expect(ctrl.error, isNull);
  });

  test('loadTicket clears previous ticket before notifying loading state', () async {
    when(() => repo.getTicketDetail('tk1'))
        .thenAnswer((_) async => makeTicket(key: 'tk1'));
    await ctrl.loadTicket('tk1');
    expect(ctrl.ticket?.ticketKey, 'tk1');

    // On the second load, ticket must be null while status is loading
    bool wasNullDuringLoad = false;
    ctrl.addListener(() {
      if (ctrl.status == TicketDetailStatus.loading && ctrl.ticket == null) {
        wasNullDuringLoad = true;
      }
    });

    when(() => repo.getTicketDetail('tk2'))
        .thenAnswer((_) async => makeTicket(key: 'tk2'));
    await ctrl.loadTicket('tk2');

    expect(wasNullDuringLoad, isTrue);
    expect(ctrl.ticket?.ticketKey, 'tk2');
  });

  test('loadTicket sets error state on failure', () async {
    when(() => repo.getTicketDetail('tk1')).thenThrow(Exception('net error'));

    await ctrl.loadTicket('tk1');

    expect(ctrl.status, TicketDetailStatus.error);
    expect(ctrl.error, isNotNull);
    expect(ctrl.ticket, isNull);
  });

  test('sendReply appends optimistic reply immediately', () async {
    when(() => repo.getTicketDetail('tk1'))
        .thenAnswer((_) async => makeTicket(key: 'tk1', replies: []));
    await ctrl.loadTicket('tk1');

    final completer = Completer<SupportTicket>();
    bool sawPending = false;
    ctrl.addListener(() {
      if (ctrl.ticket?.replies.any((r) => r.isPending) == true) {
        sawPending = true;
      }
    });

    when(() => repo.addReply('tk1', any()))
        .thenAnswer((_) async => completer.future);
    when(() => repo.getTicketDetail('tk1'))
        .thenAnswer((_) async => makeTicket(key: 'tk1'));

    final sendFuture = ctrl.sendReply('Hello');
    // Yield so the optimistic notification fires before the API resolves
    await Future.delayed(Duration.zero);
    expect(sawPending, isTrue);

    completer.complete(makeTicket(key: 'tk1'));
    await sendFuture;
  });

  test('sendReply returns true on success', () async {
    when(() => repo.getTicketDetail('tk1'))
        .thenAnswer((_) async => makeTicket(key: 'tk1'));
    await ctrl.loadTicket('tk1');

    when(() => repo.addReply('tk1', any()))
        .thenAnswer((_) async => makeTicket(key: 'tk1'));

    final ok = await ctrl.sendReply('Hello');
    expect(ok, isTrue);
    expect(ctrl.isReplying, isFalse);
  });

  test('sendReply marks reply failed on API error', () async {
    when(() => repo.getTicketDetail('tk1'))
        .thenAnswer((_) async => makeTicket(key: 'tk1'));
    await ctrl.loadTicket('tk1');

    when(() => repo.addReply('tk1', any())).thenThrow(Exception('net'));

    final ok = await ctrl.sendReply('Hello');

    expect(ok, isFalse);
    expect(ctrl.ticket?.replies.any((r) => r.isFailed), isTrue);
    expect(ctrl.mutationError, isNotNull);
    expect(ctrl.isReplying, isFalse);
  });

  test('retryReply removes failed reply and resends', () async {
    final failed = makeReply(
        body: 'retry me', isFailed: true, clientReplyId: 'crid-1');
    when(() => repo.getTicketDetail('tk1'))
        .thenAnswer((_) async => makeTicket(key: 'tk1', replies: [failed]));
    await ctrl.loadTicket('tk1');

    when(() => repo.addReply('tk1', 'retry me'))
        .thenAnswer((_) async => makeTicket(key: 'tk1'));
    when(() => repo.getTicketDetail('tk1'))
        .thenAnswer((_) async => makeTicket(key: 'tk1'));

    final ok = await ctrl.retryReply('crid-1');
    expect(ok, isTrue);
  });

  test('removeFailedReply removes the specified reply', () async {
    final failed = makeReply(isFailed: true, clientReplyId: 'crid-2');
    when(() => repo.getTicketDetail('tk1'))
        .thenAnswer((_) async => makeTicket(key: 'tk1', replies: [failed]));
    await ctrl.loadTicket('tk1');

    ctrl.removeFailedReply('crid-2');

    expect(ctrl.ticket?.replies, isEmpty);
  });

  test('closeTicket returns true and updates ticket status', () async {
    when(() => repo.getTicketDetail('tk1'))
        .thenAnswer((_) async => makeTicket(key: 'tk1', canClose: true));
    await ctrl.loadTicket('tk1');

    final closed = makeTicket(
        key: 'tk1',
        status: SupportTicketStatus.closed,
        canClose: false,
        canReopen: true);
    when(() => repo.closeTicket('tk1')).thenAnswer((_) async => closed);

    final ok = await ctrl.closeTicket();
    expect(ok, isTrue);
    expect(ctrl.ticket?.status, SupportTicketStatus.closed);
    expect(ctrl.isMutating, isFalse);
  });

  test('closeTicket returns false on error and clears isMutating', () async {
    when(() => repo.getTicketDetail('tk1'))
        .thenAnswer((_) async => makeTicket(key: 'tk1'));
    await ctrl.loadTicket('tk1');

    when(() => repo.closeTicket('tk1')).thenThrow(Exception('fail'));

    final ok = await ctrl.closeTicket();
    expect(ok, isFalse);
    expect(ctrl.isMutating, isFalse);
    expect(ctrl.mutationError, isNotNull);
  });

  test('reopenTicket returns true and updates ticket status', () async {
    final closed = makeTicket(
        key: 'tk1',
        status: SupportTicketStatus.closed,
        canClose: false,
        canReopen: true);
    when(() => repo.getTicketDetail('tk1')).thenAnswer((_) async => closed);
    await ctrl.loadTicket('tk1');

    final reopened = makeTicket(
        key: 'tk1',
        status: SupportTicketStatus.open,
        canClose: true,
        canReopen: false);
    when(() => repo.reopenTicket('tk1')).thenAnswer((_) async => reopened);

    final ok = await ctrl.reopenTicket();
    expect(ok, isTrue);
    expect(ctrl.ticket?.status, SupportTicketStatus.open);
  });

  test('resetPrivateData clears all state', () async {
    when(() => repo.getTicketDetail('tk1'))
        .thenAnswer((_) async => makeTicket(key: 'tk1'));
    await ctrl.loadTicket('tk1');

    ctrl.resetPrivateData();

    expect(ctrl.ticket, isNull);
    expect(ctrl.status, TicketDetailStatus.initial);
    expect(ctrl.error, isNull);
    expect(ctrl.isReplying, isFalse);
    expect(ctrl.isMutating, isFalse);
    expect(ctrl.mutationError, isNull);
  });

  test('stale response discarded after resetPrivateData', () async {
    final completer = Completer<SupportTicket>();
    when(() => repo.getTicketDetail('tk1'))
        .thenAnswer((_) async => completer.future);

    final loadFuture = ctrl.loadTicket('tk1');
    ctrl.resetPrivateData(); // increments generation
    completer.complete(makeTicket(key: 'tk1')); // resolve the stale response
    await loadFuture;

    // Stale response must be discarded
    expect(ctrl.ticket, isNull);
    expect(ctrl.status, TicketDetailStatus.initial);
  });

  test('markRead called after load and decrements parent unread count', () async {
    when(() => repo.getTicketDetail('tk1'))
        .thenAnswer((_) async => makeTicket(key: 'tk1', unreadCount: 2));
    when(() => repo.markRead('tk1')).thenAnswer((_) async {});

    await ctrl.loadTicket('tk1');
    // Allow the fire-and-forget markRead to run
    await Future.delayed(Duration.zero);

    verify(() => repo.markRead('tk1')).called(1);
    verify(() => supportCtrl.decrementUnread(2)).called(1);
  });
}
