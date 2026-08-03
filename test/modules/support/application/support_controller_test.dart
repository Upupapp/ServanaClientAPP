import 'package:client/modules/support/application/support_controller.dart';
import 'package:client/modules/support/data/support_repository.dart';
import 'package:client/modules/support/domain/support_ticket.dart';
import 'package:client/modules/support/domain/support_ticket_category.dart';
import 'package:client/modules/support/domain/support_ticket_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSupportRepository extends Mock implements SupportRepository {}

void main() {
  late MockSupportRepository repo;
  late SupportController ctrl;

  SupportTicket makeTicket({
    String key = 'tk1',
    SupportTicketStatus status = SupportTicketStatus.open,
  }) {
    return SupportTicket(
      ticketKey: key,
      category: SupportTicketCategory.booking,
      status: status,
      title: 'T',
      safeSummary: '',
      canReply: true,
      canClose: false,
      canReopen: false,
    );
  }

  setUp(() {
    repo = MockSupportRepository();
    ctrl = SupportController(repository: repo);
  });

  tearDown(() => ctrl.dispose());

  test('initial state is correct', () {
    expect(ctrl.status, SupportLoadStatus.initial);
    expect(ctrl.tickets, isEmpty);
    expect(ctrl.unreadCount, 0);
    expect(ctrl.filter, TicketFilter.open);
  });

  test('loadTickets sets loaded state on success', () async {
    final tickets = [makeTicket(), makeTicket(key: 'tk2')];
    when(() => repo.listTickets()).thenAnswer((_) async => tickets);

    await ctrl.loadTickets();

    expect(ctrl.status, SupportLoadStatus.loaded);
    expect(ctrl.tickets, tickets);
    expect(ctrl.error, isNull);
  });

  test('loadTickets sets error state on failure', () async {
    when(() => repo.listTickets()).thenThrow(Exception('network error'));

    await ctrl.loadTickets();

    expect(ctrl.status, SupportLoadStatus.error);
    expect(ctrl.error, isNotNull);
  });

  test('setFilter changes filter and filteredTickets', () async {
    final tickets = [
      makeTicket(key: 'open1', status: SupportTicketStatus.open),
      makeTicket(key: 'closed1', status: SupportTicketStatus.closed),
    ];
    when(() => repo.listTickets()).thenAnswer((_) async => tickets);
    await ctrl.loadTickets();

    ctrl.setFilter(TicketFilter.all);
    expect(ctrl.filteredTickets.length, 2);

    ctrl.setFilter(TicketFilter.open);
    expect(ctrl.filteredTickets.length, 1);
    expect(ctrl.filteredTickets.first.ticketKey, 'open1');
  });

  test('filteredTickets needsAction returns only waitingForCustomer', () async {
    final tickets = [
      makeTicket(key: 'a', status: SupportTicketStatus.waitingForCustomer),
      makeTicket(key: 'b', status: SupportTicketStatus.open),
    ];
    when(() => repo.listTickets()).thenAnswer((_) async => tickets);
    await ctrl.loadTickets();

    ctrl.setFilter(TicketFilter.needsAction);
    expect(ctrl.filteredTickets.length, 1);
    expect(ctrl.filteredTickets.first.ticketKey, 'a');
  });

  test('decrementUnread clamps to 0', () {
    ctrl.decrementUnread(100);
    expect(ctrl.unreadCount, 0);
  });

  test('resetPrivateData clears all state', () async {
    when(() => repo.listTickets()).thenAnswer((_) async => [makeTicket()]);
    when(() => repo.getUnreadCount()).thenAnswer((_) async => 3);
    await ctrl.loadTickets();
    await ctrl.refreshUnreadCount();

    ctrl.resetPrivateData();

    expect(ctrl.tickets, isEmpty);
    expect(ctrl.status, SupportLoadStatus.initial);
    expect(ctrl.unreadCount, 0);
    expect(ctrl.filter, TicketFilter.open);
  });

  test('concurrent loadTickets calls do not interleave', () async {
    var callCount = 0;
    when(() => repo.listTickets()).thenAnswer((_) async {
      callCount++;
      return [makeTicket()];
    });

    // Fire two concurrent calls — second should be ignored while first runs.
    final f1 = ctrl.loadTickets();
    final f2 = ctrl.loadTickets();
    await Future.wait([f1, f2]);

    expect(callCount, 1);
  });
}
