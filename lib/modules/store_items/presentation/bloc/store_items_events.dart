import 'package:equatable/equatable.dart';

sealed class StoreItemsEvent extends Equatable {
  const StoreItemsEvent();

  @override
  List<Object?> get props => [];
}

class StoreItemAddEvent extends StoreItemsEvent {
  const StoreItemAddEvent();

  @override
  List<Object?> get props => ['StoreitemAddEvent'];
}

class StoreCategoryEditOrdinalEvent extends StoreItemsEvent {
  final String categoryName;
  const StoreCategoryEditOrdinalEvent({required this.categoryName});

  @override
  List<Object?> get props => ['StoreCategoryEditOrdinalEvent'];
}

class StoreItemEnableEvent extends StoreItemsEvent {
  final int itemId;
  final int categoryId;
  const StoreItemEnableEvent({required this.itemId, required this.categoryId});

  @override
  List<Object?> get props => ['StoreItemEnableEvent', itemId, categoryId];
}

class StoreItemDisableEvent extends StoreItemsEvent {
  final int itemId;
  final int categoryId;
  const StoreItemDisableEvent({required this.itemId, required this.categoryId});

  @override
  List<Object?> get props => ['StoreItemDisableEvent', itemId, categoryId];
}

class StoreCategoryEditOrdinalDoneEvent extends StoreItemsEvent {
  final String categoryName;

  const StoreCategoryEditOrdinalDoneEvent({
    required this.categoryName,
  });

  @override
  List<Object?> get props => ['StoreCategoryEditOrdinalDoneEvent'];
}

class StoreItemUpdateOrdinalEvent extends StoreItemsEvent {
  final int oldIndex;
  final int newIndex;
  final String categoryName;
  const StoreItemUpdateOrdinalEvent({
    required this.oldIndex,
    required this.newIndex,
    required this.categoryName,
  });

  @override
  List<Object?> get props => [
        'StoreItemUpdateOrdinalEvent',
        oldIndex,
        newIndex,
        categoryName,
      ];
}

class StoreCategoryUpdateOrdinalEvent extends StoreItemsEvent {
  final int oldIndex;
  final int newIndex;
  const StoreCategoryUpdateOrdinalEvent({
    required this.oldIndex,
    required this.newIndex,
  });

  @override
  List<Object?> get props => [
        'StoreCategoryUpdateOrdinalEvent',
        oldIndex,
        newIndex,
      ];
}

class StoreItemDeleteEvent extends StoreItemsEvent {
  const StoreItemDeleteEvent();

  @override
  List<Object?> get props => ['StoreitemDeleteEvent'];
}

class StoreItemLoadEvent extends StoreItemsEvent {
  final String merchantId;
  const StoreItemLoadEvent(this.merchantId);

  @override
  List<Object?> get props => ['StoreitemLoadEvent', merchantId];
}

class StoreItemLoadedEvent extends StoreItemsEvent {
  const StoreItemLoadedEvent();

  @override
  List<Object?> get props => ['StoreItemLoadedEvent'];
}

class StoreItemEditEvent extends StoreItemsEvent {
  const StoreItemEditEvent();

  @override
  List<Object?> get props => ['StoreitemEditEvent'];
}
