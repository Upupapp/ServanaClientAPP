import 'package:client/common/data/models/merchant_service.dart';

sealed class EditItemState {
  const EditItemState();

  List<Object?> get props => throw UnimplementedError();
}

class InitialEditItemState extends EditItemState {
  const InitialEditItemState();

  @override
  List<Object?> get props => ["InitialEditItemState"];
}

class LoadingEditItemState extends EditItemState {
  const LoadingEditItemState();

  @override
  List<Object?> get props => ["LoadingEditItemState"];
}

class LoadedEditItemState extends EditItemState {
  const LoadedEditItemState();

  @override
  List<Object?> get props => ["LoadedEditItemState"];
}

class EditedItemState extends EditItemState {
  final MerchantServiceModel item;
  const EditedItemState({required this.item});

  @override
  List<Object?> get props => ["EditedItemState", item];
}

class EditFailedItemState extends EditItemState {
  final String error;
  final MerchantServiceModel item;
  const EditFailedItemState({required this.item, required this.error});

  @override
  List<Object?> get props => ["EditFailedItemState", item, error];
}

class SubmittedEditItemState extends EditItemState {
  const SubmittedEditItemState();

  @override
  List<Object?> get props => ["SubmittedEditItemState"];
}
