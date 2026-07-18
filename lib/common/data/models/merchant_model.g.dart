// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'merchant_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MerchantModelImpl _$$MerchantModelImplFromJson(Map<String, dynamic> json) =>
    _$MerchantModelImpl(
      merchantID: json['merchantID'] as String,
      bankID: (json['bankID'] as num).toInt(),
      merchantName: json['merchantName'] as String,
      businessOwnerName: json['businessOwnerName'] as String,
      merchantStatus: (json['merchantStatus'] as num).toInt(),
      contactNumber: json['contactNumber'] as String,
      emailAddress: json['emailAddress'] as String,
      password: json['password'] as String?,
      bannerImage: json['bannerImage'] as String?,
      bannerImageBase64: json['bannerImageBase64'] as String?,
      listImage: json['listImage'] as String?,
      listImageBase64: json['listImageBase64'] as String?,
      longitude: (json['longitude'] as num?)?.toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      officeAddress: json['officeAddress'] as String,
      officeContactNumber: json['officeContactNumber'] as String,
      region: json['region'] as String?,
      city: json['city'] as String?,
      barangay: json['barangay'] as String?,
      street: json['street'] as String?,
      zipCode: json['zipCode'] as String?,
      currentCredit: (json['currentCredit'] as num).toInt(),
      bankAccountNumber: json['bankAccountNumber'] as String,
      bankAccountName: json['bankAccountName'] as String,
      rating: (json['rating'] as num).toInt(),
      merchantFee: (json['merchantFee'] as num).toInt(),
      businessType: (json['businessType'] as num).toInt(),
      merchantStatusNote: json['merchantStatusNote'] as String?,
      authorizedRepresentative: json['authorizedRepresentative'] as String?,
      representativeIDType: (json['representativeIDType'] as num).toInt(),
      representativeIDFrontDocumentFilename:
          json['representativeIDFrontDocumentFilename'] as String,
      representativeIDFrontDocumentFilenameBase64:
          json['representativeIDFrontDocumentFilenameBase64'] as String?,
      representativeIDBackDocumentFilename:
          json['representativeIDBackDocumentFilename'] as String,
      representativeIDBackDocumentFilenameBase64:
          json['representativeIDBackDocumentFilenameBase64'] as String?,
      tin: json['tin'] as String,
      distanceCoverage: (json['distanceCoverage'] as num).toInt(),
      totalWorkerPerDay: (json['totalWorkerPerDay'] as num?)?.toInt(),
      freeDistanceTransportationFee:
          (json['freeDistanceTransportationFee'] as num).toInt(),
      createdDate: DateTime.parse(json['createdDate'] as String),
    );

Map<String, dynamic> _$$MerchantModelImplToJson(_$MerchantModelImpl instance) =>
    <String, dynamic>{
      'merchantID': instance.merchantID,
      'bankID': instance.bankID,
      'merchantName': instance.merchantName,
      'businessOwnerName': instance.businessOwnerName,
      'merchantStatus': instance.merchantStatus,
      'contactNumber': instance.contactNumber,
      'emailAddress': instance.emailAddress,
      'password': instance.password,
      'bannerImage': instance.bannerImage,
      'bannerImageBase64': instance.bannerImageBase64,
      'listImage': instance.listImage,
      'listImageBase64': instance.listImageBase64,
      'longitude': instance.longitude,
      'latitude': instance.latitude,
      'officeAddress': instance.officeAddress,
      'officeContactNumber': instance.officeContactNumber,
      'region': instance.region,
      'city': instance.city,
      'barangay': instance.barangay,
      'street': instance.street,
      'zipCode': instance.zipCode,
      'currentCredit': instance.currentCredit,
      'bankAccountNumber': instance.bankAccountNumber,
      'bankAccountName': instance.bankAccountName,
      'rating': instance.rating,
      'merchantFee': instance.merchantFee,
      'businessType': instance.businessType,
      'merchantStatusNote': instance.merchantStatusNote,
      'authorizedRepresentative': instance.authorizedRepresentative,
      'representativeIDType': instance.representativeIDType,
      'representativeIDFrontDocumentFilename':
          instance.representativeIDFrontDocumentFilename,
      'representativeIDFrontDocumentFilenameBase64':
          instance.representativeIDFrontDocumentFilenameBase64,
      'representativeIDBackDocumentFilename':
          instance.representativeIDBackDocumentFilename,
      'representativeIDBackDocumentFilenameBase64':
          instance.representativeIDBackDocumentFilenameBase64,
      'tin': instance.tin,
      'distanceCoverage': instance.distanceCoverage,
      'totalWorkerPerDay': instance.totalWorkerPerDay,
      'freeDistanceTransportationFee': instance.freeDistanceTransportationFee,
      'createdDate': instance.createdDate.toIso8601String(),
    };
