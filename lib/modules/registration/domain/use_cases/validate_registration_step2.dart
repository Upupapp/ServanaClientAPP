import 'package:client/common/domain/use_cases/use_case.dart';
import 'package:client/modules/registration/data/models/reg_form_error_model.dart';
import 'package:client/modules/registration/data/models/registration_form_model.dart';
import 'package:client/modules/registration/data/resources/form_state.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

class ValidateRegistrationForm2UseCase
    implements UseCase<FormState, RegistrationFormModel> {
  @override
  Future<FormState> call({RegistrationFormModel? params}) async {
    // ignore: unused_local_variable
    var hash = params.hashCode;

    if (params != null) {
      var name = isBusinessNameValid(params);
      var type = isBusinessTypeValid(params);
      var coords = isBusinessCoordinatesValid(params);
      var phone = await isBusinessPhoneValid(params);

      var streetAddr = isBusinessStreetAddressValid(params);
      if (name.isValid &&
          type.isValid &&
          phone.isValid &&
          coords.isValid &&
          streetAddr.isValid) {
        return const FormValid();
      } else {
        return FormInvalid(
          RegFormErrorModel(
            nameOfBusiness: name.error,
            typeOfBusiness: type.error,
            businessPhone: phone.error,
            businessLocationCoordinates: coords.error,
            streetAddress: streetAddr.error,
          ),
        );
      }
    } else {
      return const FormInvalid(RegFormErrorModel());
    }
  }

  ({bool isValid, String? error}) isBusinessNameValid(
      RegistrationFormModel params) {
    if ((params.nameOfBusiness?.length ?? 0) <= 0) {
      return (isValid: false, error: "This field is required!");
    }

    if ((params.nameOfBusiness?.length ?? 0) > 60) {
      return (isValid: false, error: "Max length is 60");
    }

    return (isValid: true, error: null);
  }

  ({bool isValid, String? error}) isBusinessTypeValid(
      RegistrationFormModel params) {
    if ((params.typeOfBusiness?.length ?? 0) <= 0) {
      return (isValid: false, error: "This field is required!");
    }

    if ((params.typeOfBusiness?.length ?? 0) > 60) {
      return (isValid: false, error: "Max length is 60");
    }

    return (isValid: true, error: null);
  }

  ({bool isValid, String? error}) isBusinessProvinceValid(
      RegistrationFormModel params) {
    if ((params.province?.length ?? 0) <= 0) {
      return (isValid: false, error: "This field is required!");
    }

    if ((params.province?.length ?? 0) > 60) {
      return (isValid: false, error: "Max length is 60");
    }

    return (isValid: true, error: null);
  }

  ({bool isValid, String? error}) isBusinessCityValid(
      RegistrationFormModel params) {
    if ((params.city?.length ?? 0) <= 0) {
      return (isValid: false, error: "This field is required!");
    }

    if ((params.city?.length ?? 0) > 60) {
      return (isValid: false, error: "Max length is 60");
    }

    return (isValid: true, error: null);
  }

  ({bool isValid, String? error}) isBusinessBarangayValid(
      RegistrationFormModel params) {
    if ((params.barangay?.length ?? 0) <= 0) {
      return (isValid: false, error: "This field is required!");
    }

    if ((params.barangay?.length ?? 0) > 60) {
      return (isValid: false, error: "Max length is 60");
    }

    return (isValid: true, error: null);
  }

  ({bool isValid, String? error}) isBusinessStreetAddressValid(
      RegistrationFormModel params) {
    if ((params.streetAddress?.length ?? 0) <= 0) {
      return (isValid: false, error: "This field is required!");
    }

    // if ((params.streetAddress?.length ?? 0) > 60) {
    //   return (isValid: false, error: "Max length is 60");
    // }

    return (isValid: true, error: null);
  }

  ({bool isValid, String? error}) isBusinessCoordinatesValid(
      RegistrationFormModel params) {
    if (params.businessLocationCoordinates == null) {
      return (isValid: false, error: "Please pick your location!");
    }

    return (isValid: true, error: null);
  }

  Future<({String? error, bool isValid})> isBusinessPhoneValid(
      RegistrationFormModel params) async {
    var phoneUtil =
        PhoneNumber.parse(params.ownerPhoneNo!, callerCountry: IsoCode.PH);
    if (params.businessPhone != null) {
      bool isValid = phoneUtil.isValid();
      if (isValid) {
        return (isValid: true, error: null);
      } else {
        return (isValid: false, error: "Invalid Phone Numer");
      }
    } else {
      return (isValid: false, error: "Phone Numer is required!");
    }
  }
}
