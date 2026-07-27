import 'package:client/modules/messaging/data/models/message_attachment_model.dart';
import 'package:client/modules/messaging/data/models/message_model.dart';

class MessageMapper {
  static MessageType _typeFrom(String? raw) {
    switch (raw) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.unknown;
    }
  }

  static MessageModel fromJson(Map<String, dynamic> json, {required int conversationId}) {
    final rawAttachments = json['attachments'] as List<dynamic>? ?? const [];
    final attachments = rawAttachments
        .cast<Map<String, dynamic>>()
        .map(MessageAttachmentModel.fromJson)
        .toList();

    return MessageModel(
      id: (json['id'] as num?)?.toInt(),
      conversationId: conversationId,
      senderUid: json['senderUid'] as String? ?? json['sender_uid'] as String?,
      senderRole: (json['senderRole'] as num? ?? json['sender_role'] as num?)?.toInt(),
      type: _typeFrom(json['type'] as String?),
      body: json['body'] as String?,
      createdAt: _parseDate(json['createdAt'] ?? json['created_at']),
      editedAt: _parseDateNullable(json['editedAt'] ?? json['edited_at']),
      deletedAt: _parseDateNullable(json['deletedAt'] ?? json['deleted_at']),
      clientMsgId: json['clientMsgId'] as String? ?? json['client_msg_id'] as String?,
      sendStatus: MessageSendStatus.sent,
      attachments: attachments,
    );
  }

  static DateTime _parseDate(dynamic raw) {
    if (raw is String) return DateTime.parse(raw).toLocal();
    return DateTime.now();
  }

  static DateTime? _parseDateNullable(dynamic raw) {
    if (raw is String) return DateTime.parse(raw).toLocal();
    return null;
  }
}
