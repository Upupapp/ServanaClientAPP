import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/modules/support/domain/safety_incident.dart';
import 'package:client/modules/support/domain/support_ticket.dart';
import 'package:client/modules/support/domain/support_ticket_category.dart';
import 'package:client/modules/support/domain/support_ticket_status.dart';

class SupportRepository {
  SupportRepository({required ServanaApiClient api}) : _api = api;

  final ServanaApiClient _api;

  // ── Tickets ──────────────────────────────────────────────────────────────────

  Future<List<SupportTicket>> listTickets() async {
    final res = await _api.listSupportTickets();
    final data = _list(res['data']);
    return data.map((e) => _mapTicket(_map(e))).toList();
  }

  Future<SupportTicket> createTicket({
    required String subject,
    required String description,
    required SupportTicketCategory category,
    String? clientRequestId,
    String? bookingId,
  }) async {
    final res = await _api.createSupportTicket(
      subject: subject,
      description: description,
      category: category.apiKey,
      clientRequestId: clientRequestId,
      bookingId: bookingId,
    );
    return _mapTicket(_map(res['data']));
  }

  Future<SupportTicket> getTicketDetail(String ticketKey) async {
    final res = await _api.getSupportTicketDetail(ticketKey);
    final data = _map(res['data']);
    final replies = _list(data['replies'])
        .map((r) => SupportReply.fromMap(_map(r), ticketKey))
        .toList();
    return _mapTicket(data).copyWith(replies: replies);
  }

  Future<SupportTicket> addReply(String ticketKey, String message) async {
    final res = await _api.addSupportTicketReply(
        ticketKey: ticketKey, message: message);
    return _mapTicket(_map(res['data']));
  }

  Future<void> markRead(String ticketKey) async {
    await _api.markSupportTicketRead(ticketKey);
  }

  Future<SupportTicket> closeTicket(String ticketKey) async {
    final res = await _api.closeSupportTicket(ticketKey);
    return _mapTicket(_map(res['data']));
  }

  Future<SupportTicket> reopenTicket(String ticketKey) async {
    final res = await _api.reopenSupportTicket(ticketKey);
    return _mapTicket(_map(res['data']));
  }

  Future<int> getUnreadCount() async {
    final res = await _api.getSupportUnreadCount();
    return ((_map(res['data'])['count']) as num?)?.toInt() ?? 0;
  }

  // ── Safety ───────────────────────────────────────────────────────────────────

  Future<List<EmergencyLine>> getEmergencyConfig() async {
    final res = await _api.getSupportEmergencyConfig();
    final data = _map(res['data']);
    final lines = _list(data['lines']);
    return lines.map((l) => EmergencyLine.fromMap(_map(l))).toList();
  }

  Future<List<SafetyIncident>> listSafetyIncidents() async {
    final res = await _api.listSafetyIncidents();
    final data = _list(res['data']);
    return data.map((m) => SafetyIncident.fromMap(_map(m))).toList();
  }

  Future<Map<String, dynamic>> submitSafetyIncident({
    required String clientIncidentId,
    required SafetyIncidentCategory category,
    required SafetyIncidentSeverity severity,
    required String description,
    String? bookingId,
    bool immediateDanger = false,
  }) async {
    return await _api.submitSafetyIncident(
      clientIncidentId: clientIncidentId,
      category: category.apiKey,
      severity: severity.apiKey,
      description: description,
      bookingId: bookingId,
      immediateDanger: immediateDanger,
    );
  }

  // ── Private helpers ───────────────────────────────────────────────────────────

  static SupportTicket _mapTicket(Map<String, dynamic> m) => SupportTicket(
        ticketKey: m['ticketKey']?.toString() ?? '',
        category: SupportTicketCategory.fromString(m['category'] as String?),
        status: SupportTicketStatus.fromString(m['status'] as String?),
        title: (m['title'] as String?) ?? '',
        safeSummary: (m['safeSummary'] as String?) ?? '',
        bookingId: m['bookingId'] as String?,
        createdAt: m['createdAt'] != null
            ? DateTime.tryParse(m['createdAt'].toString())
            : null,
        updatedAt: m['updatedAt'] != null
            ? DateTime.tryParse(m['updatedAt'].toString())
            : null,
        canReply: (m['canReply'] as bool?) ?? false,
        canClose: (m['canClose'] as bool?) ?? false,
        canReopen: (m['canReopen'] as bool?) ?? false,
      );

  static Map<String, dynamic> _map(dynamic v) =>
      v is Map<String, dynamic> ? v : <String, dynamic>{};

  static List<dynamic> _list(dynamic v) => v is List ? v : <dynamic>[];
}
