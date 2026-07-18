import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/common/data/models/merchant_service_option.dart';
import 'package:client/modules/store_items/domain/use_cases/get_store_options_use_case.dart';
import 'package:client/modules/store_items/presentation/bloc/store_options_events.dart';
import 'package:client/modules/store_items/presentation/bloc/store_options_states.dart';

class StoreOptionsBloc extends Bloc<StoreOptionsEvent, StoreOptionsState> {
  final GetStoreOptionsUseCase getStoreOptionsUseCase;

  final List<MerchantServiceOptionModel> options = [];
  final List<MerchantServiceOptionModel> optionsToLink = [];

  StoreOptionsBloc({required this.getStoreOptionsUseCase})
      : super(const InitialStoreOptionsState()) {
    on<StoreOptionsEvent>((event, emit) async {
      switch (event) {
        case AddStoreOptionsEvent():
          // TODO: Handle this case.
          break;
        case DeleteStoreOptionsEvent():
          // TODO: Handle this case.
          break;
        case LoadStoreOptionsEvent():
          await onLoadStoreOptionsEvent(event, emit);
          break;
        case AddStoreOptionToLinkListEvent():
          onAddStoreOptionToLinkListEvent(event, emit);
          break;
        case RemoveStoreOptionToLinkListEvent():
          onRemoveStoreOptionToLinkListEvent(event, emit);
          break;
      }
    });
  }

  void onAddStoreOptionToLinkListEvent(
      AddStoreOptionToLinkListEvent event, Emitter emit) {
    emit(const LoadingStoreOptionsState());
    optionsToLink.add(event.option);
    emit(AddedStoreOptionToLinkListState(option: event.option));
  }

  void onRemoveStoreOptionToLinkListEvent(
      RemoveStoreOptionToLinkListEvent event, Emitter emit) {
    emit(const LoadingStoreOptionsState());
    optionsToLink.remove(event.option);
    emit(RemovedStoreOptionToLinkListState(option: event.option));
  }

  Future<void> onLoadStoreOptionsEvent(
      LoadStoreOptionsEvent event, Emitter emit) async {
    var fetchRes = await getStoreOptionsUseCase();
    emit(const LoadingStoreOptionsState());
    options.clear();
    options.addAll(fetchRes);
    emit(const LoadedStoreOptionsState());
  }
}
