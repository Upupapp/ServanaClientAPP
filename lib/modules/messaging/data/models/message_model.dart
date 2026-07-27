import 'package:client/modules/messaging/data/models/message_attachment_model.dart';

enum MessageType { text, image, system, unknown }

enum MessageSendStatus { sent, pending, failed }

class MessageModel {
  const MessageModel({
    this.id,
    required this.conversationId,
    this.senderUid,
    this.senderRole,
    required this.type,
    this.body,
    required this.createdAt,
    this.editedAt,
    this.deletedAt,
    this.clientMsgId,
    this.sendStatus = MessageSendStatus.sent,
    this.attachments = const [],
  });

  /// null for optimistic/pending messages that have not yet received a server id
  final int? id;
  final int conversationId;

  /// null for system messages
  final String? senderUid;

  /// null for system messages; 0/1=admin, 2=provider, 3=customer
  final int? senderRole;

  final MessageType type;

  /// null after soft-delete
  final String? body;

  final DateTime createdAt;
  final DateTime? editedAt;
  final DateTime? deletedAt;

  /// Client-generated idempotency key for pending messages
  final String? clientMsgId;

  final MessageSendStatus sendStatus;
  final List<MessageAttachmentModel> attachments;

  bool get isSystem => senderUid == null && type != MessageType.unknown;
  bool get isDeleted => deletedAt != null;
  bool get isPending => sendStatus == MessageSendStatus.pending;
  bool get isFailed => sendStatus == MessageSendStatus.failed;

  /// role 3 = customer; used to distinguish "my" side in the bubble layout
  bool get isFromCustomer => senderRole == 3;

  MessageModel copyWith({
    int? id,
    MessageSendStatus? sendStatus,
    String? body,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId,
      senderUid: senderUid,
      senderRole: senderRole,
      type: type,
      body: body ?? this.body,
      createdAt: createdAt,
      editedAt: editedAt,
      deletedAt: deletedAt,
      clientMsgId: clientMsgId,
      sendStatus: sendStatus ?? this.sendStatus,
      attachments: attachments,
    );
  }
}
