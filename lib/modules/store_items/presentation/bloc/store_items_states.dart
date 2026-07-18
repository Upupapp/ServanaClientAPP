sealed class StoreItemsState {
  const StoreItemsState();

  // @override
  List<Object> get props => ['StoreItemsState'];
}

class StoreItemInitialState extends StoreItemsState {
  const StoreItemInitialState();

  @override
  List<Object> get props => ['StoreItemInitialState'];
}

class StoreItemAddedState extends StoreItemsState {
  const StoreItemAddedState();

  @override
  List<Object> get props => ['StoreItemAddedState'];
}

class StoreItemEditedState extends StoreItemsState {
  const StoreItemEditedState();

  @override
  List<Object> get props => ['StoreItemEditedState'];
}

class StoreItemDeletedState extends StoreItemsState {
  const StoreItemDeletedState();

  @override
  List<Object> get props => ['StoreItemDeletedState'];
}

class StoreItemLoadingState extends StoreItemsState {
  const StoreItemLoadingState();

  @override
  List<Object> get props => ['StoreItemLoadingState'];
}

class StoreItemLoadedState extends StoreItemsState {
  const StoreItemLoadedState();

  @override
  List<Object> get props => ['StoreItemLoadedState'];
}

class StoreItemCategoryEditingState extends StoreItemsState {
  const StoreItemCategoryEditingState();

  @override
  List<Object> get props => ['StoreItemCategoryEditingState'];
}

class StoreItemCategoryEditingOrdinalState extends StoreItemsState {
  final String categoryName;
  const StoreItemCategoryEditingOrdinalState({required this.categoryName});

  @override
  List<Object> get props =>
      ['StoreItemCategoryEditingOrdinalState', categoryName];
}
