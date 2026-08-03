import 'package:client/modules/store_items/data/models/store_option_items.dart';

sealed class AddOptionEvent {
  const AddOptionEvent();

  List<Object?> get props => const [];
}

class AddedOptionItemEvent extends AddOptionEvent {
  final StoreOptionItem item;
  const AddedOptionItemEvent({required this.item});

  @override
  // TODO: implement props
  List<Object?> get props => ["AddedOptionItemEvent", item];
}

class DeleteOptionItemEvent extends AddOptionEvent {
  final StoreOptionItem item;
  const DeleteOptionItemEvent({required this.item});

  @override
  // TODO: implement props
  List<Object?> get props => ["DeleteOptionItemEvent", item];
}

class ToogleOptionPerHourEvent extends AddOptionEvent {
  final bool value;
  const ToogleOptionPerHourEvent({required this.value});

  @override
  // TODO: implement props
  List<Object?> get props => ["ToogleOptionPerHourEvent", value];
}

class ToogleOptionHasPerKilometerPriceEvent extends AddOptionEvent {
  final bool value;
  const ToogleOptionHasPerKilometerPriceEvent({required this.value});

  @override
  // TODO: implement props
  List<Object?> get props => ["ToogleOptionHasPerKilometerPriceEvent", value];
}

class ToogleOptionnHasFreeFairEvent extends AddOptionEvent {
  final bool value;
  const ToogleOptionnHasFreeFairEvent({required this.value});

  @override
  // TODO: implement props
  List<Object?> get props => ["ToogleOptionnHasFreeFairEvent", value];
}
