// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'x_file_mod.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class XFileModAdapter extends TypeAdapter<XFileMod> {
  @override
  final int typeId = 9;

  @override
  XFileMod read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return XFileMod(
      fields[91] as String,
      mimeType: fields[92] as String?,
      bytes: fields[95] as Uint8List?,
    );
  }

  @override
  void write(BinaryWriter writer, XFileMod obj) {
    writer
      ..writeByte(6)
      ..writeByte(91)
      ..write(obj.path)
      ..writeByte(92)
      ..write(obj.mimeType)
      ..writeByte(93)
      ..write(obj._name)
      ..writeByte(94)
      ..write(obj._length)
      ..writeByte(95)
      ..write(obj.bytes)
      ..writeByte(96)
      ..write(obj._lastModified);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XFileModAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
