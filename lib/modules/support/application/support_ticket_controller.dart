import 'package:client/common/injectors/main_injector.dart';
import 'package:client/core/analytics/application/analytics_coordinator.dart';
import 'package:client/core/analytics/events/support_events.dart';
import 'package:client/modules/support/application/support_controller.dart';
import 'package:client/modules/support/data/support_repository.dart';
import 'package:client/modules/support/domain/support_ticket.dart';
import 'package:flutter/foundation.dart';

enum TicketDetailStatus { initial, loading, loaded, error }

class SupportTicketController extends ChangeNotifier {
  SupportTicketController({
    required SupportRepository repository,
    required SupportController supportController,
  })  : _repository = repository,
        _supportCtrl = supportController;

  final SupportRepository _repository;
  final SupportController _supportCtrl;

  SupportTicket? _ticket;
  TicketDetailStatus _status = TicketDetailStatus.initial;
  String? _error;
  bool _isReplying = false;
  bool _isMutating = false;
  String? _mutationError;
  bool _disposed = false;
  int _generation = 0;

  SupportTicket? get ticket => _ticket;
  TicketDetailStatus get status => _status;
  String? get error => _error;
  bool get isLoading => _status == TicketDetailStatus.loading;
  bool get isReplying => _isReplying;
  bool get isMutating => _isMutating;
  String? get mutationError => _mutationError;

  Future<void> loadTicket(String ticketKey) async {
    final gen = ++_generation;
    _status = TicketDetailStatus.loading;
    _ticket =
        null; // clear stale data so the UI shows loading, not the previous ticket
    _error = null;
    _notify();
    try {
      final ticket = await _repository.getTicketDetail(ticketKey);
      if (gen != _generation) return;
      _ticket = ticket;
      _status = TicketDetailStatus.loaded;
      // Mark all support replies as read
      _markReadSilently(ticketKey, ticket.unreadCount);
    } catch (e) {
      if (gen != _generation) return;
      _status = TicketDetailStatus.error;
      _error = _sanitize(e);
    }
    _notify();
  }

  Future<bool> sendReply(String body) async {
    if (_ticket == null) return false;
    final ticketKey = _ticket!.ticketKey;
    final clientReplyId =
        '${DateTime.now().millisecondsSinceEpoch}-${body.hashCode.abs()}';

    // Optimistic append
    final optimistic = SupportReply.optimistic(
      ticketKey: ticketKey,
      body: body,
      clientReplyId: clientReplyId,
    );
    _ticket = _ticket!.copyWith(
      replies: [..._ticket!.replies, optimistic],
    );
    _isReplying = true;
    _mutationError = null;
    _notify();

    try {
      await _repository.addReply(ticketKey, body);
      // Reload full detail to get reconciled replies
      await loadTicket(ticketKey);
      _isReplying = false;
      _mutationError = null;
      _track(const SupportReplySucceededEvent());
      // update parent list if needed
      _notify();
      return true;
    } catch (e) {
      // Mark optimistic reply as failed
      final failedReplies = _ticket!.replies.map((r) {
        if (r.clientReplyId == clientReplyId) {
          return r.copyWith(isPending: false, isFailed: true);
        }
        return r;
      }).toList();
      _ticket = _ticket!.copyWith(replies: failedReplies);
      _isReplying = false;
      _mutationError = _sanitize(e);
      _notify();
      return false;
    }
  }

  Future<bool> retryReply(String clientReplyId) async {
    final failed = _ticket?.replies
        .where((r) => r.clientReplyId == clientReplyId && r.isFailed)
        .firstOrNull;
    if (failed == null) return false;
    // Remove failed reply and resend
    _ticket = _ticket!.copyWith(
      replies: _ticket!.replies
          .where((r) => r.clientReplyId != clientReplyId)
          .toList(),
    );
    return sendReply(failed.body);
  }

  void removeFailedReply(String clientReplyId) {
    if (_ticket == null) return;
    _ticket = _ticket!.copyWith(
      replies: _ticket!.replies
          .where((r) => r.clientReplyId != clientReplyId)
          .toList(),
    );
    _notify();
  }

  Future<bool> closeTicket() async {
    if (_ticket == null) return false;
    _isMutating = true;
    _mutationError = null;
    _notify();
    try {
      final updated = await _repository.closeTicket(_ticket!.ticketKey);
      _ticket = updated.copyWith(replies: _ticket!.replies);
      _isMutating = false;
      _track(const SupportTicketClosedEvent());
      _notify();
      return true;
    } catch (e) {
      _mutationError = _sanitize(e);
      _isMutating = false;
      _notify();
      return false;
    }
  }

  Future<bool> reopenTicket() async {
    if (_ticket == null) return false;
    _isMutating = true;
    _mutationError = null;
    _notify();
    try {
      final updated = await _repository.reopenTicket(_ticket!.ticketKey);
      _ticket = updated.copyWith(replies: _ticket!.replies);
      _isMutating = false;
      _track(const SupportTicketReopenedEvent());
      _notify();
      return true;
    } catch (e) {
      _mutationError = _sanitize(e);
      _isMutating = false;
      _notify();
      return false;
    }
  }

  void _track(dynamic event) {
    try {
      dpLocator<AnalyticsCoordinator>().track(event).ignore();
    } catch (_) {}
  }

  void resetPrivateData() {
    _ticket = null;
    _status = TicketDetailStatus.initial;
    _error = null;
    _isReplying = false;
    _isMutating = false;
    _mutationError = null;
    ++_generation;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _markReadSilently(String ticketKey, int prevUnread) {
    _repository.markRead(ticketKey).then((_) {
      if (prevUnread > 0) _supportCtrl.decrementUnread(prevUnread);
    }).catchError((_) {});
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  String _sanitize(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('401')) return 'Session expired. Please sign in again.';
    if (msg.contains('network') || msg.contains('socket')) {
      return 'No internet connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
