import 'package:client/common/data/models/merchant_service.dart';

sealed class AddItemEvent {
  const AddItemEvent();

  List<Object?> get props => const [];
}

class AddedItemEvent extends AddItemEvent {
  final MerchantServiceModel item;
  const AddedItemEvent({required this.item});

  @override
  // TODO: implement props
  List<Object?> get props => ["AddedItemEvent", item];
}

class TooglePerHourEvent extends AddItemEvent {
  final bool value;
  const TooglePerHourEvent({required this.value});

  @override
  // TODO: implement props
  List<Object?> get props => ["TooglePerHourEvent", value];
}

class ToogleHasPerKilometerPriceEvent extends AddItemEvent {
  final bool value;
  const ToogleHasPerKilometerPriceEvent({required this.value});

  @override
  // TODO: implement props
  List<Object?> get props => ["ToogleHasPerKilometerPriceEvent", value];
}

class ToogleHasFreeFairEvent extends AddItemEvent {
  final bool value;
  const ToogleHasFreeFairEvent({required this.value});

  @override
  // TODO: implement props
  List<Object?> get props => ["ToogleHasFreeFairEvent", value];
}
