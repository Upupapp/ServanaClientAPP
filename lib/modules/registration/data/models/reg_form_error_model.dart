import 'package:freezed_annotation/freezed_annotation.dart';

part 'reg_form_error_model.freezed.dart';

@freezed
class RegFormErrorModel with _$RegFormErrorModel {
  const factory RegFormErrorModel({
    final String? ownerName,
    final String? ownerEmail,
    final String? ownerPhoneNo,
    final String? ownerPassword,
    final String? ownerConfirmPassword,
    final String? nameOfBusiness,
    final String? typeOfBusiness,
    final String? businessPhone,
    final String? businessLocationCoordinates,
    final String? province,
    final String? city,
    final String? barangay,
    final String? streetAddress,
    final String? logo,
    final String? banner,
    final String? certificateOfRegistration,
    final String? businessPermit,
    final String? bir2303,
    final String? bank,
    final String? bankAccountHolder,
    final String? bankAccountNumber,
    final String? bankCertificate,
    final String? bankAccountHolderIdType,
    final String? bankAccountHolderIdNumber,
    final String? bankAccountHolderIdFront,
    final String? bankAccountHolderIdBack,
    final String? authorizedPersonelName,
    final String? authorizedPersonelIdType,
    final String? authorizedPersonelIdNumer,
    final String? authorizedPersonelIdFront,
    final String? authorizedPersonelIdBack,
  }) = _RegFormErrorModel;
}
