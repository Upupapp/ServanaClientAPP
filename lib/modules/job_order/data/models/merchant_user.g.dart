// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'merchant_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MerchantUserImpl _$$MerchantUserImplFromJson(Map<String, dynamic> json) =>
    _$MerchantUserImpl(
      merchantUserID: json['merchantUserID'] as String,
      merchantUserRoleType: (json['merchantUserRoleType'] as num).toInt(),
      jobOrderPersonnelID: (json['jobOrderPersonnelID'] as num?)?.toInt(),
      contactNumber: json['contactNumber'] as String,
      merchantUserStatus: (json['merchantUserStatus'] as num).toInt(),
      profilePictureURL: json['profilePictureURL'] as String,
      fullname: json['fullname'] as String,
    );

Map<String, dynamic> _$$MerchantUserImplToJson(_$MerchantUserImpl instance) =>
    <String, dynamic>{
      'merchantUserID': instance.merchantUserID,
      'merchantUserRoleType': instance.merchantUserRoleType,
      'jobOrderPersonnelID': instance.jobOrderPersonnelID,
      'contactNumber': instance.contactNumber,
      'merchantUserStatus': instance.merchantUserStatus,
      'profilePictureURL': instance.profilePictureURL,
      'fullname': instance.fullname,
    };
