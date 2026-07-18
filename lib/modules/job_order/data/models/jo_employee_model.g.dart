// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jo_employee_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$JOEmployeeModelImpl _$$JOEmployeeModelImplFromJson(
        Map<String, dynamic> json) =>
    _$JOEmployeeModelImpl(
      name: json['name'] as String,
      contactNo: json['contactNo'] as String,
      photoURL: json['photoURL'] as String?,
    );

Map<String, dynamic> _$$JOEmployeeModelImplToJson(
        _$JOEmployeeModelImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'contactNo': instance.contactNo,
      'photoURL': instance.photoURL,
    };
