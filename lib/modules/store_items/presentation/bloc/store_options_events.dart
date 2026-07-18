import 'package:client/common/data/models/merchant_service_option.dart';

sealed class StoreOptionsEvent {
  const StoreOptionsEvent();
  // TODO: implement props
  List<Object?> get props => throw UnimplementedError();
}

class AddStoreOptionsEvent extends StoreOptionsEvent {
  const AddStoreOptionsEvent();

  @override
  List<Object> get props => ["AddedStoreOptionsEvent"];
}

class DeleteStoreOptionsEvent extends StoreOptionsEvent {
  const DeleteStoreOptionsEvent();

  @override
  List<Object> get props => ["DeleteStoreOptionsEvent"];
}

class LoadStoreOptionsEvent extends StoreOptionsEvent {
  const LoadStoreOptionsEvent();

  @override
  List<Object> get props => ["LoadStoreOptionsEvent"];
}

class AddStoreOptionToLinkListEvent extends StoreOptionsEvent {
  final MerchantServiceOptionModel option;
  const AddStoreOptionToLinkListEvent({required this.option});

  @override
  List<Object> get props => ["AddStoreOptionToLinkListEvent", option];
}

class RemoveStoreOptionToLinkListEvent extends StoreOptionsEvent {
  final MerchantServiceOptionModel option;
  const RemoveStoreOptionToLinkListEvent({required this.option});

  @override
  List<Object> get props => ["RemoveStoreOptionToLinkListEvent", option];
}
