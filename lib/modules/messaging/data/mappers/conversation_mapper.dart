import 'package:client/modules/messaging/data/mappers/message_mapper.dart';
import 'package:client/modules/messaging/data/models/conversation_model.dart';

class ConversationMapper {
  static ConversationModel fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as num).toInt();
    final rawBookingId = json['bookingId'] ?? json['booking_id'];
    final bookingId = rawBookingId?.toString() ?? '';

    final rawLastMessage = json['lastMessage'] ?? json['last_message'];
    final lastMessage = rawLastMessage is Map<String, dynamic>
        ? MessageMapper.fromJson(rawLastMessage, conversationId: id)
        : null;

    final rawLastMsgAt = json['lastMessageAt'] ?? json['last_message_at'];

    return ConversationModel(
      id: id,
      bookingId: bookingId,
      unreadCount:
          (json['unreadCount'] as num? ?? json['unread_count'] as num? ?? 0)
              .toInt(),
      isClosed:
          (json['isClosed'] as bool? ?? json['is_closed'] as bool? ?? false),
      lastMessageAt: rawLastMsgAt != null
          ? DateTime.tryParse(rawLastMsgAt.toString())?.toLocal()
          : null,
      lastMessage: lastMessage,
    );
  }
}
