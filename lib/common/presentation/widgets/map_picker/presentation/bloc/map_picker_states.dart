import 'package:client/common/data/models/address_data_model.dart';

sealed class MapPickerState {
  const MapPickerState();

  List<Object?> get props => throw UnimplementedError();
}

class MapInitialState extends MapPickerState {
  const MapInitialState();

  @override
  List<Object> get props => ['MapInitialState'];
}

class MapLoadingState extends MapPickerState {
  const MapLoadingState();

  @override
  List<Object> get props => ['MapLoadingState'];
}

class MapLoadedState extends MapPickerState {
  final AddressDataModel location;
  const MapLoadedState({required this.location});

  @override
  List<Object> get props => ['MapLoadedState', location];
}

class MapPickedState extends MapPickerState {
  final AddressDataModel location;
  const MapPickedState({required this.location});

  @override
  List<Object> get props => ['MapPickedState', location];
}

class MapErrorState extends MapPickerState {
  final String error;
  const MapErrorState({required this.error});

  @override
  List<Object> get props => ['MapPickedState', error];
}
