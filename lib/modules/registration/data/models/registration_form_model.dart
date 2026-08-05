// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';
import 'package:client/common/data/models/x_file_mod.dart';
import 'package:client/common/data/models/location_coordinates_model.dart';

part 'registration_form_model.freezed.dart';
part 'registration_form_model.g.dart';

@HiveType(typeId: 0)
@Freezed(toJson: true, fromJson: true)
class RegistrationFormModel with _$RegistrationFormModel {
  const factory RegistrationFormModel({
    @HiveField(01) final String? ownerName,
    @HiveField(02) final String? ownerEmail,
    @HiveField(03) final String? ownerPhoneNo,

    // The password fields are deliberately NOT @HiveField and NOT serialised.
    //
    // They carried @HiveField(04) and @HiveField(05), so the generated adapter
    // contained `..write(obj.ownerPassword)` and the generated toJson emitted
    // it. `RegistrationBloc` calls saveRegistrationToLocalUseCase with the full
    // form the moment signup succeeds — password included. The only reason a
    // plaintext password was not already on disk is that
    // RegistrationRepository.saveRegistrationToLocal is a `//todo: implement`
    // stub that returns without writing anything.
    //
    // That is not a safeguard, it is an accident of timing. The call site is
    // live, the serialiser is generated and ready, and the day somebody
    // implements that TODO the password lands in a Hive box with no further
    // review — the change would look like "finish the draft-saving feature".
    //
    // Dropping the annotations makes it structurally impossible instead: the
    // adapter cannot write a field it does not know about. Nothing has ever
    // been persisted, so there is no stored data to migrate and the field
    // numbers can simply retire. A resumed registration draft asking for the
    // password again is the correct behaviour anyway.
    @JsonKey(includeFromJson: false, includeToJson: false)
    final String? ownerPassword,
    @JsonKey(includeFromJson: false, includeToJson: false)
    final String? ownerConfirmPassword,
    @HiveField(06) final String? nameOfBusiness,
    @HiveField(07) final String? typeOfBusiness,
    @HiveField(08) final String? businessPhone,
    @HiveField(09) final LocationCoordinatesModel? businessLocationCoordinates,
    @HiveField(041) final String? province,
    @HiveField(042) final String? country,
    @HiveField(043) final String? postalCode,
    @HiveField(010) final String? city,
    @HiveField(011) final String? barangay,
    @HiveField(012) final String? streetAddress,
    @HiveField(013) final String? listTittle,
    @HiveField(014) final String? banner,
    @HiveField(015) final String? certificateOfRegistration,
    @HiveField(016)
    @JsonKey(includeFromJson: false, includeToJson: false)
    final XFileMod? certificateOfRegistrationFile,
    @HiveField(017) final String? businessPermit,
    @HiveField(018)
    @JsonKey(includeFromJson: false, includeToJson: false)
    final XFileMod? businessPermitFile,
    @HiveField(019) final String? bir2303,
    @HiveField(020)
    @JsonKey(includeFromJson: false, includeToJson: false)
    final XFileMod? bir2303File,
    @HiveField(021) final String? bank,
    @HiveField(022) final String? bankAccountHolder,
    @HiveField(023) final String? bankAccountNumber,
    @HiveField(024)
    @JsonKey(includeFromJson: false, includeToJson: false)
    final XFileMod? bankCertificate,
    @HiveField(025)
    @JsonKey(includeFromJson: false, includeToJson: false)
    final XFileMod? bankCertificateFile,
    @HiveField(026) final String? bankAccountHolderIdType,
    @HiveField(027) final String? bankAccountHolderIdNumber,
    @HiveField(028) final String? bankAccountHolderIdFront,
    @HiveField(029)
    @JsonKey(includeFromJson: false, includeToJson: false)
    final XFileMod? bankAccountHolderIdFrontFile,
    @HiveField(030) final String? bankAccountHolderIdBack,
    @HiveField(031)
    @JsonKey(includeFromJson: false, includeToJson: false)
    final XFileMod? bankAccountHolderIdBackFile,
    @HiveField(032) final String? authorizedPersonelName,
    @HiveField(033) final String? authorizedPersonelIdType,
    @HiveField(034) final String? authorizedPersonelIdNumer,
    @HiveField(035) final String? authorizedPersonelIdFront,
    @HiveField(036)
    @JsonKey(includeFromJson: false, includeToJson: false)
    final XFileMod? authorizedPersonelIdFrontFile,
    @HiveField(037) final String? authorizedPersonelIdBack,
    @HiveField(038)
    @JsonKey(includeFromJson: false, includeToJson: false)
    final XFileMod? authorizedPersonelIdBackFile,
    @HiveField(039)
    @JsonKey(includeFromJson: false, includeToJson: false)
    final XFileMod? listPicture,
    @HiveField(040)
    @JsonKey(includeFromJson: false, includeToJson: false)
    final XFileMod? bannerPicture,
  }) = _RegistrationFormModel;

  factory RegistrationFormModel.fromJson(Map<String, dynamic> json) =>
      _$RegistrationFormModelFromJson(json);
}
