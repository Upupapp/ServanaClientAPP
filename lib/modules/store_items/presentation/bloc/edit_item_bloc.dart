import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/common/data/models/merchant_service.dart';
import 'package:client/modules/store_items/domain/repositories/store_items_repo.dart';
import 'package:client/modules/store_items/presentation/bloc/edit_item_events.dart';
import 'package:client/modules/store_items/presentation/bloc/edit_item_state.dart';

class EditItemBloc extends Bloc<EditItemEvent, EditItemState> {
  final StoreItemsReporsitory repo;
  MerchantServiceModel? service;
  List<SelectionOption> selectedOptions = [];
  bool isItem24hrs = false;

  EditItemBloc({required this.repo}) : super(const InitialEditItemState()) {
    on<EditItemEvent>((event, emit) async {
      switch (event) {
        case EditedItemEvent():
          await onEditedItemEvent(event, emit);
          break;
        case ToogleEditItemEvent():
          onToogleItemEvent(event, emit);
          break;
        case InitEditItemEvent():
          onInitEditItemEvent(event, emit);
          break;
      }
    });
  }

  void onInitEditItemEvent(InitEditItemEvent event, Emitter emit) {
    emit(const LoadingEditItemState());
    service = event.item;
    selectedOptions = event.selectedOptions;
    emit(const LoadedEditItemState());
  }

  void onToogleItemEvent(ToogleEditItemEvent event, Emitter emit) {
    emit(const LoadingEditItemState());
    isItem24hrs = event.value;
    emit(const InitialEditItemState());
  }

  Future<void> onEditedItemEvent(EditedItemEvent event, Emitter emit) async {
    emit(const LoadingEditItemState());
    final res = await repo.updateService(event.item);
    if (res.isSuccess) {
      emit(EditedItemState(item: event.item));
    } else {
      emit(EditFailedItemState(
          item: event.item, error: res.error ?? "Unknown Error"));
    }
  }
}
