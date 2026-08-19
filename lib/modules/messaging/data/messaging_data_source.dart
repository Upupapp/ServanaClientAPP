/// The contract both messaging transports satisfy.
///
///     MessagingRepository
///       → MessagingCanonicalDataSource      when V1Capability.conversations
///       → MessagingCompatibilityDataSource  otherwise
///       → the same ConversationModel / MessageModel either way
///
/// ## R-10 was stale, and this tab measured it
///
/// TAB 01 recorded: *"Opening a booking chat may create the conversation …
/// SC-038 records the current lazy-create as a defect"*, and classified it
/// **BREAKS**. That is no longer true and the fix was upstream, not here.
/// `chat.controller.getBookingConversation` calls `getExistingConversation` and
/// returns 404 when there is none, with the comment: *"It does NOT create one:
/// a booking conversation is a consequence of a provider being confirmed …
/// not of a client opening a screen."* The client already maps that 404 to
/// null.
///
/// So the semantic hazard this migration was thought to carry does not exist.
/// What remains is a smaller, real one, and it runs the other way.
///
/// ## Resolving a booking conversation changes VERB, not just URL
///
/// | | legacy | canonical |
/// | --- | --- | --- |
/// | resolve by booking | `GET /api/bookings/:id/conversation` | `POST /api/v1/conversations` |
/// | absent | **404** | `CONVERSATION_NOT_AVAILABLE` (409) |
///
/// The canonical entry *"opens, OR resolves"* — one conversation per booking,
/// enforced by a unique constraint and an `ON CONFLICT` insert, so a repeat
/// returns the same thread. It is gated by `mayOpenConversation`: support may
/// open one on a booking with no provider, **the parties may not**. A customer
/// calling it before a provider is confirmed is refused rather than given a
/// thread.
///
/// Both therefore mean "not yet" for a customer, and both must surface as
/// `null` — otherwise flipping the capability turns a quiet empty state into an
/// error banner on a screen that is working correctly.
library;

import 'package:client/modules/messaging/data/models/conversation_model.dart';
import 'package:client/modules/messaging/data/models/message_model.dart';

/// Thrown when a caller invokes an operation the active transport lacks.
class UnsupportedMessagingAction extends UnsupportedError {
  UnsupportedMessagingAction(String action)
      : super('$action has no canonical successor and must be called on the '
            'compatibility source directly.');
}

abstract interface class MessagingDataSource {
  /// The caller's booking conversations, with unread counts.
  Future<List<ConversationModel>> listConversations();

  /// The conversation for [bookingId], or null when there is not one yet.
  ///
  /// Null is the normal answer for a booking whose provider has not been
  /// confirmed. Both transports produce it, from different signals.
  Future<ConversationModel?> resolveForBooking(String bookingId);

  /// A page of the transcript, newest first.
  Future<List<MessageModel>> getMessages({
    required int conversationId,
    int limit,
    int? before,
  });

  Future<MessageModel> sendMessage({
    required int conversationId,
    required String body,
    required String clientMsgId,
  });

  Future<void> markRead({
    required int conversationId,
    required int lastReadMessageId,
  });
}
