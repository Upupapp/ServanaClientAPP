/// Messaging feature repository.
///
///     MessagingRepository
///       → MessagingCanonicalDataSource      when V1Capability.conversations
///       → MessagingCompatibilityDataSource  otherwise
///       → the same ConversationModel / MessageModel either way
///
/// [canonical] and [router] are optional. Omitting either pins the repository
/// to the compatibility source, which is what every build does today.
///
/// The public surface is unchanged from before TAB 13, deliberately:
/// `MessagingStore`, `BookingChatScreen` and `MessagesInboxScreen` are
/// untouched and cannot tell which transport answered.
///
/// ## `reportMessage` never routes
///
/// There is no canonical successor for reporting, editing or deleting a
/// message — the `conversations` domain has six entries and none of them is
/// one. So [reportMessage] calls the compatibility source **directly, in every
/// configuration**, exactly as `NotificationsRepository.dismiss` does for
/// `DELETE /api/user/notifications/:key`.
///
/// That is the second kind of absence in this codebase's taxonomy: the
/// canonical side is missing a call the legacy side has. Expressing it here
/// rather than in the interface is what stops the canonical source from having
/// to invent an endpoint, or throw at runtime on a button the customer can see.
library;

import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/core/network/canonical_availability.dart';
import 'package:client/core/network/compat/canonical_router.dart';
import 'package:client/modules/messaging/data/messaging_data_source.dart';
import 'package:client/modules/messaging/data/models/conversation_model.dart';
import 'package:client/modules/messaging/data/models/message_model.dart';

class MessagingRepository {
  MessagingRepository({
    required ServanaApiClient api,
    required MessagingDataSource compatibility,
    MessagingDataSource? canonical,
    CanonicalRouter? router,
  })  : _api = api,
        _compatibility = compatibility,
        _canonical = canonical,
        _router = router;

  /// Retained for [reportMessage] only — the one call with no canonical
  /// successor. Every other call goes through a data source.
  final ServanaApiClient _api;

  final MessagingDataSource _compatibility;
  final MessagingDataSource? _canonical;
  final CanonicalRouter? _router;

  MessagingDataSource get _source {
    final canonical = _canonical;
    final router = _router;
    if (canonical == null || router == null) return _compatibility;
    return router.select<MessagingDataSource>(
      V1Capability.conversations,
      canonical: canonical,
      compatibility: _compatibility,
    );
  }

  /// True when conversations are served by `/api/v1`. Diagnostics only.
  bool get isCanonical =>
      _canonical != null &&
      (_router?.isCanonical(V1Capability.conversations) ?? false);

  // ── Conversations ─────────────────────────────────────────────────────────

  Future<List<ConversationModel>> listConversations() =>
      _source.listConversations();

  /// Resolve the conversation for a booking. Returns null if the conversation
  /// does not exist yet (provider not yet assigned).
  ///
  /// Null means the same thing on both transports and arrives from different
  /// signals — a 404 on legacy, `CONVERSATION_NOT_AVAILABLE` canonically. A
  /// real authorization refusal is NOT flattened into it.
  Future<ConversationModel?> resolveForBooking(String bookingId) =>
      _source.resolveForBooking(bookingId);

  // ── Messages ──────────────────────────────────────────────────────────────

  Future<List<MessageModel>> getMessages({
    required int conversationId,
    int limit = 40,
    int? before,
  }) =>
      _source.getMessages(
        conversationId: conversationId,
        limit: limit,
        before: before,
      );

  // ── Send ──────────────────────────────────────────────────────────────────

  Future<MessageModel> sendMessage({
    required int conversationId,
    required String body,
    required String clientMsgId,
  }) =>
      _source.sendMessage(
        conversationId: conversationId,
        body: body,
        clientMsgId: clientMsgId,
      );

  // ── Read receipts ─────────────────────────────────────────────────────────

  Future<void> markRead({
    required int conversationId,
    required int lastReadMessageId,
  }) =>
      _source.markRead(
        conversationId: conversationId,
        lastReadMessageId: lastReadMessageId,
      );

  // ── Reporting ─────────────────────────────────────────────────────────────

  /// Reports a message for moderation.
  ///
  /// Always legacy. `POST /api/chat/conversations/:id/messages/:msgId/report`
  /// has no canonical successor, and neither do message edit or delete. Calling
  /// the compatibility path directly — rather than routing — is what keeps this
  /// working when the rest of the domain goes canonical.
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
