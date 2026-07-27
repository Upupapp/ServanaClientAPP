import 'package:client/modules/messaging/data/models/message_model.dart';

class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.bookingId,
    required this.unreadCount,
    required this.isClosed,
    this.lastMessageAt,
    this.lastMessage,
  });

  final int id;

  /// Matches the jobOrderID string on JobOrder (e.g. "jo-001" or a UUID)
  final String bookingId;

  final int unreadCount;
  final bool isClosed;
  final DateTime? lastMessageAt;

  /// Most-recent message preview; may be null if the conversation has no messages yet
  final MessageModel? lastMessage;

  ConversationModel copyWith({int? unreadCount, MessageModel? lastMessage}) {
    return ConversationModel(
      id: id,
      bookingId: bookingId,
      unreadCount: unreadCount ?? this.unreadCount,
      isClosed: isClosed,
      lastMessageAt: lastMessageAt,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }
}
