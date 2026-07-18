import 'package:equatable/equatable.dart';
import 'package:client/common/data/models/x_file_mod.dart';
import 'package:client/common/data/models/address_data_model.dart';
import 'package:client/modules/registration/data/models/reg_form_error_model.dart';
import 'package:client/modules/registration/data/models/registration_form_model.dart';

sealed class RegistrationEvent extends Equatable {
  const RegistrationEvent();

  @override
  List<Object?> get props => [];
}

class ValidationReset extends RegistrationEvent {
  final RegFormErrorModel? errorModel;
  const ValidationReset({this.errorModel});

  @override
  List<Object> get props => ['ValidationReset', errorModel.hashCode];
}

class LoadCachedRegistrationForm extends RegistrationEvent {
  const LoadCachedRegistrationForm();

  @override
  List<Object> get props => ['LoadCachedRegistrationForm'];
}

class InitializeRegistrationForm extends RegistrationEvent {
  const InitializeRegistrationForm();

  @override
  List<Object> get props => ['InitializeRegistrationForm'];
}

class BarangaySelectedRegistrationForm extends RegistrationEvent {
  final String key;
  const BarangaySelectedRegistrationForm({required this.key});

  @override
  List<Object> get props => ['BarangaySelectedRegistrationForm', key];
}

class ProvinceSelectedRegistrationForm extends RegistrationEvent {
  final String key;
  const ProvinceSelectedRegistrationForm({required this.key});

  @override
  List<Object> get props => ['ProvinceSelectedRegistrationForm', key];
}

class CitySelectedRegistrationForm extends RegistrationEvent {
  final String key;
  const CitySelectedRegistrationForm({required this.key});

  @override
  List<Object> get props => ['CitySelectedRegistrationForm', key];
}

class SubmitRegistrationForm extends RegistrationEvent {
  final RegistrationFormModel registration;
  final int step;
  const SubmitRegistrationForm({
    required this.registration,
    required this.step,
  });

  @override
  List<Object> get props => ["SubmitRegistrationForm", registration.hashCode];
}

class PickedListPicture extends RegistrationEvent {
  final XFileMod picture;
  const PickedListPicture({
    required this.picture,
  });

  @override
  List<Object> get props => ["PickedListPicture", picture.hashCode];
}

class PickedBannerPicture extends RegistrationEvent {
  final XFileMod picture;
  const PickedBannerPicture({
    required this.picture,
  });

  @override
  List<Object> get props => ["PickedBannerPicture", picture.hashCode];
}

class PickedCOR extends RegistrationEvent {
  final XFileMod file;
  const PickedCOR({
    required this.file,
  });

  @override
  List<Object> get props => ["PickedCOR", file.hashCode];
}

class PickedPermit extends RegistrationEvent {
  final XFileMod file;
  const PickedPermit({
    required this.file,
  });

  @override
  List<Object> get props => ["PickedPermit", file.hashCode];
}

class PickedBIR2302 extends RegistrationEvent {
  final XFileMod file;
  const PickedBIR2302({
    required this.file,
  });

  @override
  List<Object> get props => ["PickedBIR2302", file.hashCode];
}

class PickedBankCert extends RegistrationEvent {
  final XFileMod file;
  const PickedBankCert({
    required this.file,
  });

  @override
  List<Object> get props => ["PickedBankCert", file.hashCode];
}

class PickedAccountHolderIdFront extends RegistrationEvent {
  final XFileMod picture;
  const PickedAccountHolderIdFront({
    required this.picture,
  });

  @override
  List<Object> get props => ["PickedAccountHolderIdFront", picture.hashCode];
}

class PickedAccountHolderIdBack extends RegistrationEvent {
  final XFileMod picture;
  const PickedAccountHolderIdBack({
    required this.picture,
  });

  @override
  List<Object> get props => ["PickedAccountHolderIdBack", picture.hashCode];
}

class PickedAuthorizedPersonIdFront extends RegistrationEvent {
  final XFileMod picture;
  const PickedAuthorizedPersonIdFront({
    required this.picture,
  });

  @override
  List<Object> get props => ["PickedAuthorizedPersonIdFront", picture.hashCode];
}

class PickedAuthorizedPersonIdBack extends RegistrationEvent {
  final XFileMod picture;
  const PickedAuthorizedPersonIdBack({
    required this.picture,
  });

  @override
  List<Object> get props => ["PickedAuthorizedPersonIdBack", picture.hashCode];
}

class PassVisibilityToggled extends RegistrationEvent {
  final bool isVisible;
  const PassVisibilityToggled({
    required this.isVisible,
  });

  @override
  List<Object> get props => ["PassVisibilityToggled", isVisible];
}

class ConfirmPassVisibilityToggled extends RegistrationEvent {
  final bool isVisible;
  const ConfirmPassVisibilityToggled({
    required this.isVisible,
  });

  @override
  List<Object> get props => ["ConfirmPassVisibilityToggled", isVisible];
}

class PickedMapLocation extends RegistrationEvent {
  final AddressDataModel addressDataModel;
  const PickedMapLocation({
    required this.addressDataModel,
  });

  @override
  List<Object> get props => ["PickedMapLocation", addressDataModel.hashCode];
}

class ValidateRegistrationForm extends RegistrationEvent {
  final RegistrationFormModel registration;
  const ValidateRegistrationForm({
    required this.registration,
  });

  @override
  List<Object> get props => ['ValidateRegistrationForm', registration.hashCode];
}

class SaveRegistrationFormToCache extends RegistrationEvent {
  final RegistrationFormModel registration;
  final int step;
  const SaveRegistrationFormToCache({
    required this.registration,
    required this.step,
  });

  @override
  List<Object> get props => ['SaveRegistrationFormToCache'];
}

class ResendVerificationEmail extends RegistrationEvent {
  final String email;
  const ResendVerificationEmail({required this.email});

  @override
  List<Object> get props => ['ResendVerificationEmail', email];
}
