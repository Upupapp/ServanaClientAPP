import 'package:client/common/domain/use_cases/use_case.dart';
import 'package:client/modules/registration/data/models/reg_form_error_model.dart';
import 'package:client/modules/registration/data/models/registration_form_model.dart';
import 'package:client/modules/registration/data/resources/form_state.dart';

class ValidateRegistrationForm4UseCase
    implements UseCase<FormState, RegistrationFormModel> {
  @override
  Future<FormState> call({RegistrationFormModel? params}) async {
    // ignore: unused_local_variable
    var hash = params.hashCode;

    if (params != null) {
      var regCert = hasCOR(params);
      var permit = hasLicense(params);
      var bir = hasBIR(params);
      if (regCert.isValid && permit.isValid && bir.isValid) {
        return const FormValid();
      } else {
        return FormInvalid(
          RegFormErrorModel(
            certificateOfRegistration: regCert.error,
            businessPermit: permit.error,
            bir2303: bir.error,
          ),
        );
      }
    } else {
      return const FormInvalid(RegFormErrorModel());
    }
  }

  ({bool isValid, String? error}) hasCOR(RegistrationFormModel params) {
    if ((params.certificateOfRegistrationFile?.path.length ?? 0) <= 0) {
      return (isValid: false, error: "This file is required!");
    }

    return (isValid: true, error: null);
  }

  ({bool isValid, String? error}) hasBIR(RegistrationFormModel params) {
    if ((params.bir2303File?.path.length ?? 0) <= 0) {
      return (isValid: false, error: "This file is required!");
    }

    return (isValid: true, error: null);
  }

  ({bool isValid, String? error}) hasLicense(RegistrationFormModel params) {
    if ((params.businessPermitFile?.path.length ?? 0) <= 0) {
      return (isValid: false, error: "This file is required!");
    }

    return (isValid: true, error: null);
  }
}
