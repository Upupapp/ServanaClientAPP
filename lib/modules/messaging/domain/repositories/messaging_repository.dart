import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/modules/messaging/data/mappers/conversation_mapper.dart';
import 'package:client/modules/messaging/data/mappers/message_mapper.dart';
import 'package:client/modules/messaging/data/models/conversation_model.dart';
import 'package:client/modules/messaging/data/models/message_model.dart';

class MessagingRepository {
  MessagingRepository({required ServanaApiClient api}) : _api = api;

  final ServanaApiClient _api;

  // ── Conversations ─────────────────────────────────────────────────────────

  Future<List<ConversationModel>> listConversations() async {
    final json = await _api.listConversations();
    final data = json['data'];
    final List<dynamic> raw = data is List
        ? data
        : (data is Map ? (data['conversations'] as List<dynamic>? ?? []) : []);
    return raw
        .cast<Map<String, dynamic>>()
        .map(ConversationMapper.fromJson)
        .toList();
  }

  /// Resolve the conversation for a booking. Returns null if the conversation
  /// does not exist yet (provider not yet assigned).
  Future<ConversationModel?> resolveForBooking(String bookingId) async {
    try {
      final json = await _api.getBookingConversation(bookingId: bookingId);
      final data = json['data'] is Map<String, dynamic>
          ? json['data'] as Map<String, dynamic>
          : json;
      return ConversationMapper.fromJson(data);
    } on ServanaApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  // ── Messages ──────────────────────────────────────────────────────────────

  Future<List<MessageModel>> getMessages({
    required int conversationId,
    int limit = 40,
    int? before,
  }) async {
    final json = await _api.getMessages(
      conversationId: conversationId,
      limit: limit,
      before: before,
    );
    final data = json['data'];
    final List<dynamic> raw = data is List
        ? data
        : (data is Map ? (data['messages'] as List<dynamic>? ?? []) : []);
    return raw
        .cast<Map<String, dynamic>>()
        .map((m) => MessageMapper.fromJson(m, conversationId: conversationId))
        .toList();
  }

  // ── Send ──────────────────────────────────────────────────────────────────

  Future<MessageModel> sendMessage({
    required int conversationId,
    required String body,
    required String clientMsgId,
  }) async {
    final json = await _api.sendChatMessage(
      conversationId: conversationId,
      body: body,
      clientMsgId: clientMsgId,
    );
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    return MessageMapper.fromJson(data, conversationId: conversationId);
  }

  // ── Read receipts ─────────────────────────────────────────────────────────

  Future<void> markRead({
    required int conversationId,
    required int lastReadMessageId,
  }) async {
    await _api.markConversationRead(
      conversationId: conversationId,
      lastReadMessageId: lastReadMessageId,
    );
  }

  // ── Reporting ─────────────────────────────────────────────────────────────

  Future<void> reportMessage({
    required int conversationId,
    required int messageId,
    required String category,
    String? description,
  }) async {
    await _api.reportChatMessage(
      conversationId: conversationId,
      messageId: messageId,
      category: category,
      description: description,
    );
  }
}
