import 'package:equatable/equatable.dart';
import 'package:client/common/data/models/merchant_service_option.dart';

sealed class StoreOptionsState extends Equatable {
  const StoreOptionsState();
  @override
  // TODO: implement props
  List<Object?> get props => const [];
}

class InitialStoreOptionsState extends StoreOptionsState {
  const InitialStoreOptionsState();

  @override
  List<Object> get props => ["InitialStoreOptionsState"];
}

class AddedStoreOptionsState extends StoreOptionsState {
  const AddedStoreOptionsState();

  @override
  List<Object> get props => ["AddedStoreOptionsState"];
}

class LoadedStoreOptionsState extends StoreOptionsState {
  const LoadedStoreOptionsState();

  @override
  List<Object> get props => ["LoadedStoreOptionsState"];
}

class AddedStoreOptionToLinkListState extends StoreOptionsState {
  final MerchantServiceOptionModel option;
  const AddedStoreOptionToLinkListState({required this.option});

  @override
  List<Object> get props => ["AddedStoreOptionToLinkListState", option];
}

class RemovedStoreOptionToLinkListState extends StoreOptionsState {
  final MerchantServiceOptionModel option;
  const RemovedStoreOptionToLinkListState({required this.option});

  @override
  List<Object> get props => ["RemovedStoreOptionToLinkListState", option];
}

class LoadingStoreOptionsState extends StoreOptionsState {
  const LoadingStoreOptionsState();

  @override
  List<Object> get props => ["LoadingStoreOptionsState"];
}
