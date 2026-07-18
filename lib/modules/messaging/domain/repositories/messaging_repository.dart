import 'package:client/common/data/backend/backend.dart';
import 'package:client/common/domain/helpers/session_service.dart';
import 'package:client/modules/messaging/data/models/chat_message.dart';

class MessagingRepository {
  final Backend backend;

  MessagingRepository({required this.backend});

  Future<List<ChatMessage>> getMessages(String jobOrderId) {
    return backend.getJobOrderMessages(jobOrderId: jobOrderId);
  }

  Future<ChatMessage> sendMessage({
    required String jobOrderId,
    required String text,
  }) async {
    final session = await SessionService.getSession();
    return backend.sendJobOrderMessage(
      jobOrderId: jobOrderId,
      text: text,
      fromCustomer: true,
      customerId: session?.customerID,
    );
  }
}

