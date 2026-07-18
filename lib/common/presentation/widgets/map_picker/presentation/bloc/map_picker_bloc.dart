import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/common/data/models/address_data_model.dart';
import 'package:client/common/helpers/location_helper.dart';
import 'package:client/common/presentation/widgets/map_picker/presentation/bloc/map_picker_events.dart';
import 'package:client/common/presentation/widgets/map_picker/presentation/bloc/map_picker_states.dart';

class MapPickerBloc extends Bloc<MapPickerEvent, MapPickerState> {
  AddressDataModel? address;
  final locationHelper = LocationHelper();

  MapPickerBloc() : super(const MapInitialState()) {
    on<MapPickerEvent>((event, emit) async {
      switch (event) {
        case LocLoading():
          break;
        case LocLoaded():
          // TODO: Handle this case.
          break;
        case PickingLocation():
          await onPickingLocation(event, emit);
          break;
        case LocationPicked():
          // TODO: Handle this case.
          break;
        case LocationPickedFailed():
          // TODO: Handle this case.
          break;
      }
    });
  }

  Future<void> onPickingLocation(
      PickingLocation event, Emitter<MapPickerState> emit) async {
    emit(const MapLoadingState());
    var locationRes = await locationHelper.showPlacePicker(event.context);
    address = locationRes;
    // emit(MapPickedState(location: locationRes));
  }
}
