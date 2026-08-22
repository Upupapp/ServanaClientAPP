/// Conversations over `/api/v1/conversations*`.
///
/// ## Not reachable in any shipped build
///
/// Selected only when `CanonicalAvailability.isAvailable(V1Capability.conversations)`.
/// That value has existed since TAB 02 and has never been enabled — it was
/// defined before the transport behind it, and TAB 13 is what fills it in.
///
/// ## The DTOs did not have to change, and that is a finding
///
/// The canonical `Conversation` names `id`, `bookingId`, `unreadCount`,
/// `isClosed`, `lastMessageAt` and `lastMessage` — exactly the keys
/// `ConversationMapper` already reads. `isClosed` is documented as *"the
/// pre-status compatibility boolean, republished … kept correct for clients
/// that know nothing about `status`"*, which is this client precisely.
///
/// So the mapper is reused rather than duplicated. What the canonical shape
/// adds on top — `status`, `viewerSeat`, `canSend`, `cannotSendReason` — is
/// read into the additive fields on [ConversationModel] and is null on legacy.
///
/// ## Resolve is a POST here
///
/// See [MessagingDataSource] for why. The short version: the canonical entry
/// opens-or-resolves under a unique constraint, is gated by
/// `mayOpenConversation` so a customer cannot conjure a thread on an
/// unassigned booking, and answers `CONVERSATION_NOT_AVAILABLE` where the
/// legacy GET answers 404. Both mean "not yet"; both return null.
library;

import 'package:client/core/network/api_failure.dart';
import 'package:client/core/network/v1_api_client.dart';
import 'package:client/core/network/v1_endpoints.dart';
import 'package:client/modules/messaging/data/mappers/conversation_mapper.dart';
import 'package:client/modules/messaging/data/mappers/message_mapper.dart';
import 'package:client/modules/messaging/data/messaging_data_source.dart';
import 'package:client/modules/messaging/data/models/conversation_model.dart';
import 'package:client/modules/messaging/data/models/message_model.dart';

class MessagingCanonicalDataSource implements MessagingDataSource {
  const MessagingCanonicalDataSource(this._api);

  final V1ApiClient _api;

  @override
  Future<List<ConversationModel>> listConversations() async {
    final envelope = await _api.get(V1Endpoints.conversations());
    // `ConversationList` is a bare array in the v1 envelope's `data`, unlike
    // the legacy shape which nests under a `conversations` key. `listAt` with
    // no key reads the array directly.
    return envelope
        .listAt()
        .map(ConversationMapper.fromJson)
        .toList(growable: false);
  }

  @override
  Future<ConversationModel?> resolveForBooking(String bookingId) async {
    try {
      final envelope = await _api.post(
        V1Endpoints.conversations(),
        body: <String, dynamic>{
          'bookingId': int.tryParse(bookingId) ?? bookingId
        },
      );
      return ConversationMapper.fromJson(envelope.asMap);
    } on ApiFailure catch (failure) {
      // The canonical "not yet" — a booking whose provider is not confirmed, so
      // the parties may not open a thread. The legacy transport says 404 for
      // the same situation and the repository maps that to null; mapping this
      // to anything else would turn a working empty state into an error banner
      // the moment the capability is enabled.
      if (failure.code == 'CONVERSATION_NOT_AVAILABLE') return null;

      // Deliberately NOT swallowed: a genuine authorization refusal on somebody
      // else's booking must not read as "no conversation yet".
      rethrow;
    }
  }

  @override
  Future<List<MessageModel>> getMessages({
    required int conversationId,
    int limit = 40,
    int? before,
  }) async {
    final envelope = await _api.get(
      V1Endpoints.conversationMessages('$conversationId'),
      query: <String, dynamic>{
        'limit': limit,
        // Cursor-paged, newest first. Null is dropped by the client rather
        // than sent as the string "null".
        if (before != null) 'before': before,
      },
    );
    return envelope
        .listAt('messages')
        .map((m) => MessageMapper.fromJson(m, conversationId: conversationId))
        .toList(growable: false);
  }

  @override
  Future<MessageModel> sendMessage({
    required int conversationId,
    required String body,
    required String clientMsgId,
  }) async {
    final envelope = await _api.post(
      V1Endpoints.conversationMessages('$conversationId'),
      body: <String, dynamic>{'body': body, 'clientMsgId': clientMsgId},
    );
    // `clientMsgId` IS the idempotency mechanism here, in the body rather than
    // a header — the contract calls a bad one MESSAGE_IDEMPOTENCY_KEY_INVALID
    // rather than the generic code, because it is a message field and not the
    // transport-level `Idempotency-Key`. So no header is sent.
    return MessageMapper.fromJson(envelope.asMap,
        conversationId: conversationId);
  }

  @override
  Future<MessageModel> sendAttachment({
    required int conversationId,
    required String dataUri,
    required String fileName,
    required String mimeType,
    required String clientMsgId,
    String caption = '',
  }) async {
    // Same two steps and the same order as the legacy transport: store, then
    // reference. The paths differ; the semantics must not, or flipping the
    // capability would change what a customer's attachment does.
    final uploaded = await _api.post(
      V1Endpoints.conversationAttachments('$conversationId'),
      body: <String, dynamic>{'file': dataUri, 'name': fileName},
    );

    final stored = uploaded.asMap;
    final url = stored['previewUrl']?.toString() ?? '';
    if (url.isEmpty) {
      throw StateError(
        'conversations.attachments.create returned no previewUrl; '
        'keys: ${stored.keys.join(', ')}',
      );
    }

    final envelope = await _api.post(
      V1Endpoints.conversationMessages('$conversationId'),
      body: <String, dynamic>{
        'type': mimeType.startsWith('image/') ? 'image' : 'file',
        'body': caption,
        'clientMsgId': clientMsgId,
        'attachments': [
          {
            'url': url,
            'fileName': stored['fileName']?.toString() ?? fileName,
            'mimeType': stored['mimeType']?.toString() ?? mimeType,
            if (stored['sizeBytes'] != null) 'sizeBytes': stored['sizeBytes'],
          },
        ],
      },
    );

    return MessageMapper.fromJson(envelope.asMap,
        conversationId: conversationId);
  }

  @override
  Future<void> markRead({
    required int conversationId,
    required int lastReadMessageId,
  }) async {
    await _api.post(
      V1Endpoints.conversationRead('$conversationId'),
      body: <String, dynamic>{'lastReadMessageId': lastReadMessageId},
    );
    // `ConversationReadState` carries the authoritative post-move unreadCount.
    // Discarded because the existing repository signature returns void and the
    // store re-reads the list; wiring it through is a store change this tab
    // does not need to make. Recorded in TAB13_CERTIFICATION.md.
  }
}
