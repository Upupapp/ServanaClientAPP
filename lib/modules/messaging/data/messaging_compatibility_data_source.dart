/// Conversations as the app does them today.
///
/// This is the source every shipped build uses. It is the previous
/// `MessagingRepository` body, moved behind [MessagingDataSource] unchanged,
/// including its envelope handling — the chat routes do **not** use an
/// envelope, and the stores read a top-level `conversations` key, which the
/// backend's own contract note calls out as a shape that must be kept exactly.
///
/// ## The 404 is a contract, not an accident
///
/// `resolveForBooking` maps 404 to null because
/// `GET /api/bookings/:bookingId/conversation` returns 404 when no thread
/// exists — and the backend comment names this client as the reason:
/// *"404 when it does not exist yet is the contract the customer app was
/// already written against."*
///
/// TAB 01's R-10 recorded this call as lazily creating a conversation and
/// classified the migration **BREAKS**. Measured in TAB 13 against
/// `chat.controller.ts`: it calls `getExistingConversation` and creates
/// nothing. R-10 is stale.
library;

import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/modules/messaging/data/mappers/conversation_mapper.dart';
import 'package:client/modules/messaging/data/mappers/message_mapper.dart';
import 'package:client/modules/messaging/data/messaging_data_source.dart';
import 'package:client/modules/messaging/data/models/conversation_model.dart';
import 'package:client/modules/messaging/data/models/message_model.dart';

class MessagingCompatibilityDataSource implements MessagingDataSource {
  const MessagingCompatibilityDataSource(this._api);

  final ServanaApiClient _api;

  @override
  Future<List<ConversationModel>> listConversations() async {
    final json = await _api.listConversations();
    // Backend returns: {success: true, conversations: [...]}
    final raw = json['conversations'] as List<dynamic>? ?? [];
    return raw
        .cast<Map<String, dynamic>>()
        .map(ConversationMapper.fromJson)
        .toList();
  }

  @override
  Future<ConversationModel?> resolveForBooking(String bookingId) async {
    try {
      final json = await _api.getBookingConversation(bookingId: bookingId);
      // Backend returns: {success: true, conversation: {...}}
      final data = (json['conversation'] as Map<String, dynamic>?) ?? json;
      return ConversationMapper.fromJson(data);
    } on ServanaApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
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
    // Backend returns: {success: true, messages: [...], nextCursor: id|null}
    final raw = json['messages'] as List<dynamic>? ?? [];
    return raw
        .cast<Map<String, dynamic>>()
        .map((m) => MessageMapper.fromJson(m, conversationId: conversationId))
        .toList();
  }

  @override
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
    // Backend returns: {success: true, message: {...}}
    final data = (json['message'] as Map<String, dynamic>?) ?? json;
    return MessageMapper.fromJson(data, conversationId: conversationId);
  }

  @override
  Future<void> markRead({
    required int conversationId,
    required int lastReadMessageId,
  }) async {
    await _api.markConversationRead(
      conversationId: conversationId,
      lastReadMessageId: lastReadMessageId,
    );
  }
}
