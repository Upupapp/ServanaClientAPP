// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_coordinates_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocationCoordinatesModelAdapter
    extends TypeAdapter<LocationCoordinatesModel> {
  @override
  final int typeId = 7;

  @override
  LocationCoordinatesModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocationCoordinatesModel(
      latitude: fields[71] as double,
      longhitude: fields[72] as double,
    );
  }

  @override
  void write(BinaryWriter writer, LocationCoordinatesModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(71)
      ..write(obj.latitude)
      ..writeByte(72)
      ..write(obj.longhitude);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationCoordinatesModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LocationCoordinatesModelImpl _$$LocationCoordinatesModelImplFromJson(
        Map<String, dynamic> json) =>
    _$LocationCoordinatesModelImpl(
      latitude: (json['latitude'] as num).toDouble(),
      longhitude: (json['longhitude'] as num).toDouble(),
    );

Map<String, dynamic> _$$LocationCoordinatesModelImplToJson(
        _$LocationCoordinatesModelImpl instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longhitude': instance.longhitude,
    };
