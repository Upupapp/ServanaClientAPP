import 'package:freezed_annotation/freezed_annotation.dart';

part 'merchant_model.freezed.dart';
part 'merchant_model.g.dart';

@freezed
class MerchantModel with _$MerchantModel {
  factory MerchantModel({
    required String merchantID,
    required int bankID,
    required String merchantName,
    required String businessOwnerName,
    required int merchantStatus,
    required String contactNumber,
    required String emailAddress,
    String? password,
    String? bannerImage,
    String? bannerImageBase64,
    String? listImage,
    String? listImageBase64,
    double? longitude,
    double? latitude,
    required String officeAddress,
    required String officeContactNumber,
    String? region,
    String? city,
    String? barangay,
    String? street,
    String? zipCode,
    required int currentCredit,
    required String bankAccountNumber,
    required String bankAccountName,
    required int rating,
    required int merchantFee,
    required int businessType,
    String? merchantStatusNote,
    String? authorizedRepresentative,
    required int representativeIDType,
    required String representativeIDFrontDocumentFilename,
    String? representativeIDFrontDocumentFilenameBase64,
    required String representativeIDBackDocumentFilename,
    String? representativeIDBackDocumentFilenameBase64,
    required String tin,
    required int distanceCoverage,
    int? totalWorkerPerDay,
    required int freeDistanceTransportationFee,
    required DateTime createdDate,
  }) = _MerchantModel;

  factory MerchantModel.fromJson(Map<String, dynamic> json) =>
      _$MerchantModelFromJson(json);
}
