import 'package:bloc/bloc.dart';
import 'package:client/common/data/models/merchant_service.dart';
import 'package:client/modules/store_items/data/models/store_items_category.dart';
import 'package:client/modules/store_items/domain/repositories/store_items_repo.dart';
import 'package:client/modules/store_items/domain/use_cases/get_store_items_use_case.dart';
import 'package:client/modules/store_items/presentation/bloc/store_items_events.dart';
import 'package:client/modules/store_items/presentation/bloc/store_items_states.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';

class StoreItemsBloc extends Bloc<StoreItemsEvent, StoreItemsState> {
  final GetStoreItemsUseCase getStoreItemsUseCase;
  final StoreItemsReporsitory storeItemsRepo;

  final storeItemCategories = <StoreItemCategory>[];

  StoreItemsBloc(
      {required this.getStoreItemsUseCase, required this.storeItemsRepo})
      : super(const StoreItemInitialState()) {
    on<StoreItemsEvent>((event, emit) async {
      switch (event) {
        case StoreItemAddEvent():
          // TODO: Handle this case.
          break;
        case StoreItemDeleteEvent():
          // TODO: Handle this case.
          break;
        case StoreItemLoadEvent():
          await onStoreItemLoadEvent(event, emit);
          break;
        case StoreItemEditEvent():
          // TODO: Handle this case.
          break;
        // TODO: Handle this case.
        case StoreItemLoadedEvent():
          // TODO: Handle this case.
          break;
        case StoreCategoryEditOrdinalEvent():
          onStoreCategoryEditOrdinalEvent(event, emit);
          break;
        case StoreCategoryEditOrdinalDoneEvent():
          onStoreCategoryEditOrdinalDoneEvent(event, emit);
          break;
        case StoreItemUpdateOrdinalEvent():
          onStoreItemUpdateOrdinalEvent(event, emit);
          break;
        case StoreCategoryUpdateOrdinalEvent():
          onStoreCategoryUpdateOrdinalEvent(event, emit);
        case StoreItemEnableEvent():
          onStoreItemEnableEvent(event, emit);
          break;
        case StoreItemDisableEvent():
          onStoreItemDisableEvent(event, emit);
          break;
      }
    });
  }

  void onStoreItemEnableEvent(StoreItemEnableEvent event, Emitter emit) {
    emit(const StoreItemLoadingState());
    var currentCategory = storeItemCategories
        .firstWhere((element) => element.id == event.categoryId);
    var currentItems = <MerchantServiceModel>[];
    currentItems.addAll(currentCategory.services);

    var currentItem = currentItems
        .firstWhere((element) => element.merchantServiceID == event.itemId);

    final itemIndex = currentItems.indexWhere((element) =>
        element.merchantServiceID == currentItem.merchantServiceID);

    currentItem = currentItem.copyWith(isActive: true);
    currentItems.removeWhere((element) =>
        element.merchantServiceID == currentItem.merchantServiceID);

    if (itemIndex < currentItems.length) {
      currentItems.insert(itemIndex, currentItem);
    } else {
      currentItems.add(currentItem);
    }

    currentItems.sort(
      (a, b) => a.ordinal.compareTo(b.ordinal),
    );

    currentCategory = currentCategory.copyWith(services: currentItems);

    storeItemCategories
        .removeWhere((element) => element.id == currentCategory.id);
    storeItemCategories.add(currentCategory);

    storeItemCategories.sort(
      (a, b) => a.ordinal.compareTo(b.ordinal),
    );

    storeItemsRepo.toggleService(currentItem, true);

    emit(const StoreItemInitialState());
  }

  void onStoreItemDisableEvent(StoreItemDisableEvent event, Emitter emit) {
    emit(const StoreItemLoadingState());
    var currentCategory = storeItemCategories
        .firstWhere((element) => element.id == event.categoryId);
    var currentItems = <MerchantServiceModel>[];
    currentItems.addAll(currentCategory.services);

    var currentItem = currentItems
        .firstWhere((element) => element.merchantServiceID == event.itemId);

    currentItem = currentItem.copyWith(isActive: false);

    final itemIndex = currentItems.indexWhere((element) =>
        element.merchantServiceID == currentItem.merchantServiceID);

    currentItems.removeWhere((element) =>
        element.merchantServiceID == currentItem.merchantServiceID);

    if (itemIndex < currentItems.length) {
      currentItems.insert(itemIndex, currentItem);
    } else {
      currentItems.add(currentItem);
    }

    currentItems.sort(
      (a, b) => a.ordinal.compareTo(b.ordinal),
    );

    currentCategory = currentCategory.copyWith(services: currentItems);

    storeItemCategories
        .removeWhere((element) => element.id == currentCategory.id);
    storeItemCategories.add(currentCategory);

    storeItemCategories.sort(
      (a, b) => a.ordinal.compareTo(b.ordinal),
    );

    storeItemsRepo.toggleService(currentItem, false);

    emit(const StoreItemInitialState());
  }

  void onStoreCategoryEditOrdinalEvent(
      StoreCategoryEditOrdinalEvent event, Emitter emit) {
    emit(
        StoreItemCategoryEditingOrdinalState(categoryName: event.categoryName));
  }

  void onStoreCategoryEditOrdinalDoneEvent(
      StoreCategoryEditOrdinalDoneEvent event, Emitter emit) {
    ////todo: save new item ordinal
    emit(const StoreItemInitialState());
  }

  void onStoreCategoryUpdateOrdinalEvent(
      StoreCategoryUpdateOrdinalEvent event, Emitter emit) {
    emit(const StoreItemLoadingState());

    ////update item index
    var currentItem = storeItemCategories[event.oldIndex];
    if (event.oldIndex > event.newIndex) {
      storeItemCategories.removeAt(event.oldIndex);
      storeItemCategories.insert(event.newIndex, currentItem);
    } else {
      storeItemCategories.insert(event.newIndex, currentItem);
      storeItemCategories.removeAt(event.oldIndex);
    }

    ////set ordinal according to new index
    final newItemOrdinal = <StoreItemCategory>[];
    storeItemCategories.forEachIndexed((index, element) {
      var newItem = element.copyWith(ordinal: index);
      newItemOrdinal.add(newItem);
    });

    storeItemCategories.clear();
    storeItemCategories.addAll(newItemOrdinal);

    storeItemCategories.sort(
      (a, b) => a.ordinal.compareTo(b.ordinal),
    );

    emit(const StoreItemInitialState());
  }

  void onStoreItemUpdateOrdinalEvent(
      StoreItemUpdateOrdinalEvent event, Emitter emit) {
    emit(const StoreItemLoadingState());

    ////get currentCategory and create a mutable list instance for service item list
    var currentCategoryItems = <MerchantServiceModel>[];
    var currentCategory = storeItemCategories
        .firstWhere((element) => element.name == event.categoryName);
    currentCategoryItems.addAll(currentCategory.services);

    ////update item index
    var currentItem = currentCategoryItems[event.oldIndex];
    if (event.oldIndex > event.newIndex) {
      currentCategoryItems.removeAt(event.oldIndex);
      currentCategoryItems.insert(event.newIndex, currentItem);
    } else {
      currentCategoryItems.insert(event.newIndex, currentItem);
      currentCategoryItems.removeAt(event.oldIndex);
    }

    ////set ordinal according to new index
    final newItemOrdinal = <MerchantServiceModel>[];
    currentCategoryItems.forEachIndexed((index, element) {
      var newItem = element.copyWith(ordinal: index);
      newItemOrdinal.add(newItem);
    });

    newItemOrdinal.sort(
      (a, b) => a.ordinal.compareTo(b.ordinal),
    );

    currentCategory = currentCategory.copyWith(services: newItemOrdinal);

    storeItemCategories.removeWhere(
      (element) {
        return element.name == currentCategory.name;
      },
    );

    storeItemCategories.add(currentCategory);

    storeItemCategories.sort(
      (a, b) => a.ordinal.compareTo(b.ordinal),
    );

    emit(
        StoreItemCategoryEditingOrdinalState(categoryName: event.categoryName));
  }

  Future<void> onStoreItemLoadEvent(
      StoreItemLoadEvent event, Emitter emit) async {
    emit(const StoreItemLoadingState());
    // Ensure we have a mutable list (mock backend returns unmodifiable lists).
    var items = (await getStoreItemsUseCase(params: event.merchantId)).toList();
    items.sort(
      (a, b) {
        return (a.ordinal).compareTo(b.ordinal);
      },
    );
    // Group by subcategory if available, otherwise fall back to category
    String? getGroupKey(MerchantServiceModel item) {
      return item.merchantSubcategoryName ?? item.merchantCategoryName;
    }

    var group = groupBy(items, getGroupKey);
    storeItemCategories.clear();
    group.forEach((key, value) {
      value.sort(
        (a, b) => a.ordinal.compareTo(b.ordinal),
      );
      var item = StoreItemCategory(
        id: value.first.merchantSubcategoryID != 0
            ? value.first.merchantSubcategoryID
            : value.first.merchantCategoryID,
        ordinal: value.first.ordinal,
        name: key ?? "UNKNOWN",
        services: value,
      );
      storeItemCategories.add(item);
    });
    storeItemCategories.sort(
      (a, b) => a.ordinal.compareTo(b.ordinal),
    );
    emit(const StoreItemLoadedState());
  }
}
