import 'package:client/modules/support/data/support_repository.dart';
import 'package:client/modules/support/domain/support_ticket.dart';
import 'package:client/modules/support/domain/support_ticket_status.dart';
import 'package:flutter/foundation.dart';

enum SupportLoadStatus { initial, loading, loaded, error }

class SupportController extends ChangeNotifier {
  SupportController({required SupportRepository repository})
      : _repository = repository;

  final SupportRepository _repository;

  List<SupportTicket> _tickets = [];
  SupportLoadStatus _status = SupportLoadStatus.initial;
  String? _error;
  int _unreadCount = 0;
  bool _disposed = false;
  // Active filter shown in ticket list
  TicketFilter _filter = TicketFilter.open;

  List<SupportTicket> get tickets => _tickets;
  SupportLoadStatus get status => _status;
  String? get error => _error;
  int get unreadCount => _unreadCount;
  TicketFilter get filter => _filter;
  bool get isLoading => _status == SupportLoadStatus.loading;

  List<SupportTicket> get filteredTickets {
    switch (_filter) {
      case TicketFilter.open:
        return _tickets.where((t) => t.status.isActive).toList();
      case TicketFilter.needsAction:
        return _tickets.where((t) => t.status.needsCustomerAction).toList();
      case TicketFilter.resolved:
        return _tickets.where((t) => t.status == SupportTicketStatus.resolved).toList();
      case TicketFilter.closed:
        return _tickets.where((t) => t.status == SupportTicketStatus.closed).toList();
      case TicketFilter.all:
        return List.unmodifiable(_tickets);
    }
  }

  void setFilter(TicketFilter f) {
    _filter = f;
    _notify();
  }

  Future<void> loadTickets({bool refresh = false}) async {
    if (_status == SupportLoadStatus.loading) return;
    _status = SupportLoadStatus.loading;
    _error = null;
    _notify();
    try {
      _tickets = await _repository.listTickets();
      _status = SupportLoadStatus.loaded;
    } catch (e) {
      _status = SupportLoadStatus.error;
      _error = _sanitize(e);
    }
    _notify();
  }

  Future<void> refreshUnreadCount() async {
    try {
      _unreadCount = await _repository.getUnreadCount();
      _notify();
    } catch (_) {}
  }

  void decrementUnread(int by) {
    _unreadCount = (_unreadCount - by).clamp(0, 9999);
    _notify();
  }

  void resetPrivateData() {
    _tickets = [];
    _status = SupportLoadStatus.initial;
    _error = null;
    _unreadCount = 0;
    _filter = TicketFilter.open;
    _notify();
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
    return 'Could not load support requests. Please try again.';
  }
}

enum TicketFilter { open, needsAction, resolved, closed, all }
