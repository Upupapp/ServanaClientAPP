import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:client/common/data/models/address_data_model.dart';

sealed class MapPickerEvent extends Equatable {
  const MapPickerEvent();

  @override
  List<Object?> get props => throw UnimplementedError();
}

class LocLoading extends MapPickerEvent {
  const LocLoading();

  @override
  List<Object> get props => ['LocLoading'];
}

class LocLoaded extends MapPickerEvent {
  final AddressDataModel location;
  const LocLoaded({required this.location});

  @override
  List<Object> get props => ['LocLoaded', location];
}

class PickingLocation extends MapPickerEvent {
  final BuildContext context;
  const PickingLocation({required this.context});
  @override
  List<Object?> get props => ['PickingLocation', context];
}

class LocationPicked extends MapPickerEvent {
  final AddressDataModel location;
  const LocationPicked({required this.location});

  @override
  List<Object> get props => ['LocationPicked', location];
}

class LocationPickedFailed extends MapPickerEvent {
  final String error;
  const LocationPickedFailed({required this.error});

  @override
  List<Object> get props => ['LocationPickedFailed', error];
}
