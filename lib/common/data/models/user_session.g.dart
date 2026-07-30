// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserSessionAdapter extends TypeAdapter<UserSession> {
  @override
  final int typeId = 5;

  @override
  UserSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSession(
      customerID: fields[51] as String,
      mobileNumber: fields[52] as String,
      referralCode: fields[53] as String?,
      fullname: fields[54] as String,
      emailAddress: fields[56] as String?,
      token: fields[58] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, UserSession obj) {
    writer
      ..writeByte(6)
      ..writeByte(51)
      ..write(obj.customerID)
      ..writeByte(52)
      ..write(obj.mobileNumber)
      ..writeByte(53)
      ..write(obj.referralCode)
      ..writeByte(54)
      ..write(obj.fullname)
      ..writeByte(56)
      ..write(obj.emailAddress)
      ..writeByte(58)
      ..write(obj.token);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserSessionImpl _$$UserSessionImplFromJson(Map<String, dynamic> json) =>
    _$UserSessionImpl(
      customerID: json['customerID'] as String,
      mobileNumber: json['mobileNumber'] as String,
      referralCode: json['referralCode'] as String?,
      fullname: json['fullname'] as String,
      emailAddress: json['emailAddress'] as String?,
      token: json['token'] as String? ?? '',
    );

Map<String, dynamic> _$$UserSessionImplToJson(_$UserSessionImpl instance) =>
    <String, dynamic>{
      'customerID': instance.customerID,
      'mobileNumber': instance.mobileNumber,
      'referralCode': instance.referralCode,
      'fullname': instance.fullname,
      'emailAddress': instance.emailAddress,
      'token': instance.token,
    };
