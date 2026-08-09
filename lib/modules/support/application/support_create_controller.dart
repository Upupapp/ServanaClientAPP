import 'package:client/common/domain/helpers/session_service.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/core/analytics/application/analytics_coordinator.dart';
import 'package:client/core/analytics/events/support_events.dart';
import 'package:client/modules/support/application/support_controller.dart';
import 'package:client/modules/support/data/support_draft_repository.dart';
import 'package:client/modules/support/data/support_repository.dart';
import 'package:client/modules/support/domain/support_draft.dart';
import 'package:client/modules/support/domain/support_ticket.dart';
import 'package:client/modules/support/domain/support_ticket_category.dart';
import 'package:flutter/foundation.dart';

enum CreateTicketStatus { idle, validating, submitting, succeeded, failed }

class SupportCreateController extends ChangeNotifier {
  SupportCreateController({
    required SupportRepository repository,
    required SupportDraftRepository draftRepository,
    required SupportController supportController,
  })  : _repository = repository,
        _draftRepo = draftRepository,
        _supportCtrl = supportController;

  final SupportRepository _repository;
  final SupportDraftRepository _draftRepo;
  final SupportController _supportCtrl;

  // Form state
  SupportTicketCategory _category = SupportTicketCategory.other;
  String? _bookingId;
  String? _bookingLabel;
  String _subject = '';
  String _description = '';
  final Map<String, String> _structuredAnswers = {};

  // Submission state
  CreateTicketStatus _status = CreateTicketStatus.idle;
  String? _error;
  SupportTicket? _createdTicket;
  bool _disposed = false;

  SupportTicketCategory get category => _category;
  String? get bookingId => _bookingId;
  String? get bookingLabel => _bookingLabel;
  String get subject => _subject;
  String get description => _description;
  Map<String, String> get structuredAnswers =>
      Map.unmodifiable(_structuredAnswers);
  CreateTicketStatus get status => _status;
  String? get error => _error;
  SupportTicket? get createdTicket => _createdTicket;
  bool get isSubmitting => _status == CreateTicketStatus.submitting;

  void setCategory(SupportTicketCategory c) {
    _category = c;
    _structuredAnswers.clear();
    _notify();
  }

  void setBookingContext({required String bookingId, String? bookingLabel}) {
    _bookingId = bookingId;
    _bookingLabel = bookingLabel;
    _notify();
  }

  void clearBookingContext() {
    _bookingId = null;
    _bookingLabel = null;
    _notify();
  }

  void setSubject(String v) {
    _subject = v;
    _notify();
  }

  void setDescription(String v) {
    _description = v;
    _notify();
  }

  void setAnswer(String key, String value) {
    _structuredAnswers[key] = value;
    _notify();
  }

  Future<void> saveDraft() async {
    try {
      final session = await SessionService.getSession();
      if (session == null) return;
      final draft = SupportDraft(
        draftId:
            'draft-${session.customerID}-${DateTime.now().millisecondsSinceEpoch}',
        category: _category,
        bookingId: _bookingId,
        bookingLabel: _bookingLabel,
        subject: _subject,
        description: _description,
        structuredAnswers: Map.from(_structuredAnswers),
        savedAt: DateTime.now(),
      );
      await _draftRepo.saveDraft(session.customerID, draft);
    } catch (_) {}
  }

  Future<void> loadDraft() async {
    try {
      final session = await SessionService.getSession();
      if (session == null) return;
      final draft = await _draftRepo.loadDraft(session.customerID);
      if (draft == null) return;
      _category = draft.category;
      _bookingId = draft.bookingId;
      _bookingLabel = draft.bookingLabel;
      _subject = draft.subject;
      _description = draft.description;
      _structuredAnswers
        ..clear()
        ..addAll(draft.structuredAnswers);
      _notify();
    } catch (_) {}
  }

  Future<bool> submit() async {
    final descTrimmed = _description.trim();
    final subjectTrimmed =
        _subject.trim().isNotEmpty ? _subject.trim() : _category.customerLabel;

    if (descTrimmed.length < 10) {
      _error = 'Please describe your issue in at least a few words.';
      _notify();
      return false;
    }
    if (descTrimmed.length > 2000) {
      _error = 'Description is too long. Please shorten it.';
      _notify();
      return false;
    }

    _status = CreateTicketStatus.submitting;
    _error = null;
    _notify();

    try {
      // Session is optional — if secure storage is unavailable the prefix is
      // empty but the ticket can still be submitted; don't abort on error here.
      String cid = '';
      try {
        final session = await SessionService.getSession();
        cid = session?.customerID ?? '';
      } catch (_) {}
      final cidPrefix = cid.length > 6 ? cid.substring(0, 6) : cid;
      final clientRequestId =
          'cr-$cidPrefix-${descTrimmed.hashCode.abs()}-${_category.apiKey}';

      final ticket = await _repository.createTicket(
        subject: subjectTrimmed,
        description: descTrimmed,
        category: _category,
        clientRequestId: clientRequestId,
        bookingId: _bookingId,
      );

      _createdTicket = ticket;
      _status = CreateTicketStatus.succeeded;

      // Clear draft after successful submit
      if (cid.isNotEmpty) await _draftRepo.clearDraft(cid);

      // Refresh ticket list
      _supportCtrl.loadTickets(refresh: true).ignore();

      _track(SupportTicketSubmittedEvent(supportCategory: _category.apiKey));
      _notify();
      return true;
    } catch (e) {
      _status = CreateTicketStatus.failed;
      _error = _sanitize(e);
      _track(SupportTicketFailedEvent(
          supportCategory: _category.apiKey, failureCode: 'api_error'));
      _notify();
      return false;
    }
  }

  void reset() {
    _category = SupportTicketCategory.other;
    _bookingId = null;
    _bookingLabel = null;
    _subject = '';
    _description = '';
    _structuredAnswers.clear();
    _status = CreateTicketStatus.idle;
    _error = null;
    _createdTicket = null;
    _notify();
  }

  void resetPrivateData() {
    reset();
  }

  void _track(dynamic event) {
    try {
      dpLocator<AnalyticsCoordinator>().track(event).ignore();
    } catch (_) {}
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  String _sanitize(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('401')) return 'Session expired. Please sign in again.';
    if (msg.contains('network') || msg.contains('socket')) {
      return 'No internet connection. Please try again.';
    }
    return 'Could not submit your request. Please try again.';
  }
}
