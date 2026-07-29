import 'package:client/modules/support/application/support_controller.dart';
import 'package:client/modules/support/application/support_create_controller.dart';
import 'package:client/modules/support/data/support_draft_repository.dart';
import 'package:client/modules/support/data/support_repository.dart';
import 'package:client/modules/support/domain/support_ticket.dart';
import 'package:client/modules/support/domain/support_ticket_category.dart';
import 'package:client/modules/support/domain/support_ticket_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSupportRepository extends Mock implements SupportRepository {}
class MockSupportDraftRepository extends Mock implements SupportDraftRepository {}
class MockSupportController extends Mock implements SupportController {}

void main() {
  late MockSupportRepository repo;
  late MockSupportDraftRepository draftRepo;
  late MockSupportController supportCtrl;
  late SupportCreateController ctrl;

  SupportTicket makeCreatedTicket() => SupportTicket(
    ticketKey: 'new-ticket-key',
    category: SupportTicketCategory.booking,
    status: SupportTicketStatus.submitted,
    title: 'Test',
    safeSummary: '',
    canReply: true,
    canClose: false,
    canReopen: false,
  );

  setUp(() {
    repo = MockSupportRepository();
    draftRepo = MockSupportDraftRepository();
    supportCtrl = MockSupportController();
    ctrl = SupportCreateController(
      repository: repo,
      draftRepository: draftRepo,
      supportController: supportCtrl,
    );

    // Default stubs
    when(() => draftRepo.saveDraft(any(), any())).thenAnswer((_) async {});
    when(() => draftRepo.clearDraft(any())).thenAnswer((_) async {});
    when(() => supportCtrl.loadTickets(refresh: any(named: 'refresh')))
        .thenAnswer((_) async {});
  });

  tearDown(() => ctrl.dispose());

  test('initial state', () {
    expect(ctrl.status, CreateTicketStatus.idle);
    expect(ctrl.category, SupportTicketCategory.other);
    expect(ctrl.subject, '');
    expect(ctrl.description, '');
    expect(ctrl.isSubmitting, isFalse);
    expect(ctrl.error, isNull);
  });

  test('setCategory clears structuredAnswers', () {
    ctrl.setAnswer('key1', 'value1');
    ctrl.setCategory(SupportTicketCategory.booking);
    expect(ctrl.structuredAnswers, isEmpty);
    expect(ctrl.category, SupportTicketCategory.booking);
  });

  test('submit fails validation when description < 10 chars', () async {
    ctrl.setDescription('short');
    final ok = await ctrl.submit();
    expect(ok, isFalse);
    expect(ctrl.status, CreateTicketStatus.idle);
    expect(ctrl.error, isNotNull);
    verifyNever(() => repo.createTicket(
      subject: any(named: 'subject'),
      description: any(named: 'description'),
      category: any(named: 'category'),
    ));
  });

  test('submit fails validation when description > 2000 chars', () async {
    ctrl.setDescription('a' * 2001);
    final ok = await ctrl.submit();
    expect(ok, isFalse);
    expect(ctrl.error, isNotNull);
  });

  test('submit succeeds when description is valid', () async {
    final ticket = makeCreatedTicket();
    when(() => repo.createTicket(
      subject: any(named: 'subject'),
      description: any(named: 'description'),
      category: any(named: 'category'),
      clientRequestId: any(named: 'clientRequestId'),
      bookingId: any(named: 'bookingId'),
    )).thenAnswer((_) async => ticket);

    ctrl.setDescription('A valid description with enough length to pass.');
    final ok = await ctrl.submit();

    expect(ok, isTrue);
    expect(ctrl.status, CreateTicketStatus.succeeded);
    expect(ctrl.createdTicket, ticket);
    expect(ctrl.error, isNull);
  });

  test('submit sets failed state on API error', () async {
    when(() => repo.createTicket(
      subject: any(named: 'subject'),
      description: any(named: 'description'),
      category: any(named: 'category'),
      clientRequestId: any(named: 'clientRequestId'),
      bookingId: any(named: 'bookingId'),
    )).thenThrow(Exception('network error'));

    ctrl.setDescription('A valid description with enough length to pass.');
    final ok = await ctrl.submit();

    expect(ok, isFalse);
    expect(ctrl.status, CreateTicketStatus.failed);
    expect(ctrl.error, isNotNull);
  });

  test('reset clears all state back to defaults', () async {
    ctrl.setCategory(SupportTicketCategory.payment);
    ctrl.setDescription('Some description text here.');
    ctrl.setAnswer('key', 'val');

    ctrl.reset();

    expect(ctrl.category, SupportTicketCategory.other);
    expect(ctrl.description, '');
    expect(ctrl.structuredAnswers, isEmpty);
    expect(ctrl.status, CreateTicketStatus.idle);
  });

  test('idempotency key is stable for same category and description', () async {
    // Two submit calls with the same description/category should produce
    // the same clientRequestId, meaning the same request will be idempotent
    // on the backend. We verify this by capturing the value passed.
    final ticket = makeCreatedTicket();
    String? capturedId;

    when(() => repo.createTicket(
      subject: any(named: 'subject'),
      description: any(named: 'description'),
      category: any(named: 'category'),
      clientRequestId: any(named: 'clientRequestId'),
      bookingId: any(named: 'bookingId'),
    )).thenAnswer((inv) async {
      capturedId = inv.namedArguments[#clientRequestId] as String?;
      return ticket;
    });

    const desc = 'A valid description with enough length to pass.';
    ctrl.setDescription(desc);
    ctrl.setCategory(SupportTicketCategory.booking);
    await ctrl.submit();

    final firstId = capturedId;
    ctrl.reset();
    ctrl.setDescription(desc);
    ctrl.setCategory(SupportTicketCategory.booking);
    await ctrl.submit();

    // Note: customerID is empty in test env (no session), so both keys match.
    expect(capturedId, firstId);
  });
}
