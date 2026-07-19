enum ChatSender {
  customer,
  provider,
}

class ChatMessage {
  final String id;
  final String jobOrderId;
  final ChatSender sender;
  final String text;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.jobOrderId,
    required this.sender,
    required this.text,
    required this.createdAt,
  });

  bool get isFromCustomer => sender == ChatSender.customer;
}
