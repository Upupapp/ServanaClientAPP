import 'package:client/modules/messaging/domain/repositories/messaging_repository.dart';
import 'package:client/modules/messaging/presentation/bloc/messaging_events.dart';
import 'package:client/modules/messaging/presentation/bloc/messaging_states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MessagingBloc extends Bloc<MessagingEvent, MessagingState> {
  final MessagingRepository repo;

  MessagingBloc({required this.repo}) : super(const MessagingInitial()) {
    on<MessagingEvent>((event, emit) async {
      switch (event) {
        case LoadBookingThreadEvent():
          await _onLoadThread(event, emit);
          break;
        case SendBookingMessageEvent():
          await _onSend(event, emit);
          break;
      }
    });
  }

  Future<void> _onLoadThread(
      LoadBookingThreadEvent event, Emitter<MessagingState> emit) async {
    emit(const MessagingLoading());
    try {
      final messages = await repo.getMessages(event.jobOrderId);
      emit(MessagingLoaded(jobOrderId: event.jobOrderId, messages: messages));
    } catch (e) {
      emit(MessagingError(e.toString()));
    }
  }

  Future<void> _onSend(
      SendBookingMessageEvent event, Emitter<MessagingState> emit) async {
    final prev = state;
    // Keep UI stable; don't flicker loading.
    try {
      await repo.sendMessage(jobOrderId: event.jobOrderId, text: event.text);
      final messages = await repo.getMessages(event.jobOrderId);
      emit(MessagingLoaded(jobOrderId: event.jobOrderId, messages: messages));
    } catch (e) {
      emit(MessagingError(e.toString()));
      if (prev is MessagingLoaded) {
        emit(prev);
      }
    }
  }
}

