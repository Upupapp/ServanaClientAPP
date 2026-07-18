import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/modules/store_items/data/models/store_option_items.dart';
import 'package:client/modules/store_items/presentation/bloc/add_options_events.dart';
import 'package:client/modules/store_items/presentation/bloc/add_options_state.dart';

class AddOptionBloc extends Bloc<AddOptionEvent, AddOptionState> {
  final optionItems = <StoreOptionItem>[];
  bool isItemPerHr = false;
  bool hasPerKilometerPrice = false;
  bool hasFreeFair = false;

  AddOptionBloc() : super(const InitialAddOptionState()) {
    on<AddOptionEvent>((event, emit) {
      switch (event) {
        case AddedOptionItemEvent():
          onAddedOptionItemEvent(event, emit);
          break;
        case DeleteOptionItemEvent():
          onDeleteOptionItemEvent(event, emit);
          break;
        case ToogleOptionPerHourEvent():
          onToogleOptionPerHourEvent(event, emit);
          break;
        case ToogleOptionHasPerKilometerPriceEvent():
          onToogleOptionHasPerKilometerPriceEvent(event, emit);
          break;
        case ToogleOptionnHasFreeFairEvent():
          onToogleOptionnHasFreeFairEvent(event, emit);
          break;
      }
    });
  }

  void onToogleOptionPerHourEvent(
      ToogleOptionPerHourEvent event, Emitter emit) {
    emit(const LoadedAddOptionState());
    isItemPerHr = event.value;
    emit(const InitialAddOptionState());
  }

  void onToogleOptionHasPerKilometerPriceEvent(
      ToogleOptionHasPerKilometerPriceEvent event, Emitter emit) {
    emit(const LoadedAddOptionState());
    hasPerKilometerPrice = event.value;
    emit(const InitialAddOptionState());
  }

  void onToogleOptionnHasFreeFairEvent(
      ToogleOptionnHasFreeFairEvent event, Emitter emit) {
    emit(const LoadedAddOptionState());
    hasFreeFair = event.value;
    emit(const InitialAddOptionState());
  }

  void onAddedOptionItemEvent(AddedOptionItemEvent event, Emitter emit) {
    emit(const LoadingAddOptionState());
    optionItems.add(event.item);
    emit(AddedOptionItemState(item: event.item));
  }

  void onDeleteOptionItemEvent(DeleteOptionItemEvent event, Emitter emit) {
    emit(const LoadingAddOptionState());
    optionItems.remove(event.item);
    emit(AddedOptionItemState(item: event.item));
  }
}
