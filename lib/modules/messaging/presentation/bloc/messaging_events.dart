sealed class MessagingEvent {
  const MessagingEvent();
}

class LoadBookingThreadEvent extends MessagingEvent {
  final String jobOrderId;
  const LoadBookingThreadEvent(this.jobOrderId);
}

class SendBookingMessageEvent extends MessagingEvent {
  final String jobOrderId;
  final String text;
  const SendBookingMessageEvent({
    required this.jobOrderId,
    required this.text,
  });
}

