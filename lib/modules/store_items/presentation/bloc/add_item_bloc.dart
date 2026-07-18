import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/modules/store_items/domain/repositories/store_items_repo.dart';
import 'package:client/modules/store_items/presentation/bloc/add_item_events.dart';
import 'package:client/modules/store_items/presentation/bloc/add_item_state.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';

class AddItemBloc extends Bloc<AddItemEvent, AddItemState> {
  final StoreItemsReporsitory repo;

  bool isItem24hrs = false;
  bool hasPerKilometerPrice = false;
  bool hasFreeFair = false;
  String? newCategory;
  String? selectedCategory;
  List<({int key, String value})> categories = <({int key, String value})>[];

  int? get categoryId => categories
      .firstWhereOrNull((element) => element.value == selectedCategory)
      ?.key;

  AddItemBloc({required this.repo}) : super(const InitialAddItemState()) {
    on<AddItemEvent>((event, emit) async {
      switch (event) {
        case AddedItemEvent():
          break;
        case TooglePerHourEvent():
          onTooglePerHourEvent(event, emit);
          break;
        case ToogleHasPerKilometerPriceEvent():
          onToogleHasPerKilometerPriceEvent(event, emit);
          break;
        case ToogleHasFreeFairEvent():
          onToogleHasFreeFairEvent(event, emit);
          break;
      }
    });
  }

  void onToogleHasPerKilometerPriceEvent(
      ToogleHasPerKilometerPriceEvent event, Emitter emit) {
    emit(const LoadingAddItemState());
    hasPerKilometerPrice = event.value;
    emit(const InitialAddItemState());
  }

  void onToogleHasFreeFairEvent(ToogleHasFreeFairEvent event, Emitter emit) {
    emit(const LoadingAddItemState());
    hasFreeFair = event.value;
    emit(const InitialAddItemState());
  }

  void onTooglePerHourEvent(TooglePerHourEvent event, Emitter emit) {
    emit(const LoadingAddItemState());
    isItem24hrs = event.value;
    emit(const InitialAddItemState());
  }
}
