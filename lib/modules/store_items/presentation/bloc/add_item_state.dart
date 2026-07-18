import 'package:client/common/data/models/merchant_service.dart';

sealed class AddItemState {
  const AddItemState();

  List<Object?> get props => throw UnimplementedError();
}

class InitialAddItemState extends AddItemState {
  const InitialAddItemState();

  @override
  List<Object?> get props => ["InitialAddItemState"];
}

class LoadingAddItemState extends AddItemState {
  const LoadingAddItemState();

  @override
  List<Object?> get props => ["LoadingAddItemState"];
}

class LoadedAddItemState extends AddItemState {
  const LoadedAddItemState();

  @override
  List<Object?> get props => ["LoadedAddItemState"];
}

class AddedItemState extends AddItemState {
  final MerchantServiceModel item;
  const AddedItemState({required this.item});

  @override
  List<Object?> get props => ["AddedItemState", item];
}

class AddFailedItemState extends AddItemState {
  final MerchantServiceModel item;
  const AddFailedItemState({required this.item});

  @override
  List<Object?> get props => ["AddedItemState", item];
}

class SubmittedAddItemState extends AddItemState {
  const SubmittedAddItemState();

  @override
  List<Object?> get props => ["SubmittedAddItemState"];
}
