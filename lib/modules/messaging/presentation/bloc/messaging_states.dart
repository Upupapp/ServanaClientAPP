import 'package:client/modules/messaging/data/models/chat_message.dart';

sealed class MessagingState {
  const MessagingState();
}

class MessagingInitial extends MessagingState {
  const MessagingInitial();
}

class MessagingLoading extends MessagingState {
  const MessagingLoading();
}

class MessagingLoaded extends MessagingState {
  final String jobOrderId;
  final List<ChatMessage> messages;
  const MessagingLoaded({
    required this.jobOrderId,
    required this.messages,
  });
}

class MessagingError extends MessagingState {
  final String message;
  const MessagingError(this.message);
}

