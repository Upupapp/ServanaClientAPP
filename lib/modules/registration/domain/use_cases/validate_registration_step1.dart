import 'package:client/common/domain/use_cases/use_case.dart';
import 'package:client/modules/registration/data/models/reg_form_error_model.dart';
import 'package:client/modules/registration/data/models/registration_form_model.dart';
import 'package:client/modules/registration/data/resources/form_state.dart';
import 'package:email_validator_flutter/email_validator_flutter.dart';

class ValidateRegistrationFormUseCase
    implements UseCase<FormState, RegistrationFormModel> {
  @override
  Future<FormState> call({RegistrationFormModel? params}) async {
    // ignore: unused_local_variable
    var hash = params.hashCode;

    if (params != null) {
      var name = isNameValid(params);
      var email = isEmailValid(params);
      var password = isPasswordValid(params);
      var confirmPassword = isPasswordsmatched(params);
      if (name.isValid &&
          email.isValid &&
          password.isValid &&
          confirmPassword.isValid) {
        return const FormValid();
      } else {
        return FormInvalid(
          RegFormErrorModel(
            ownerName: name.error,
            ownerEmail: email.error,
            ownerPassword: password.error,
            ownerConfirmPassword: confirmPassword.error,
          ),
        );
      }
    } else {
      return const FormInvalid(RegFormErrorModel());
    }
  }

  ({bool isValid, String? error}) isNameValid(RegistrationFormModel params) {
    if ((params.ownerName?.length ?? 0) <= 0) {
      return (isValid: false, error: "This field is required!");
    }

    if ((params.ownerName?.length ?? 0) > 60) {
      return (isValid: false, error: "Max length is 60");
    }

    return (isValid: true, error: null);
  }

  ({bool isValid, String? error}) isEmailValid(RegistrationFormModel params) {
    EmailValidatorFlutter emailValidatorFlutter = EmailValidatorFlutter();

    if (params.ownerEmail != null) {
      if (emailValidatorFlutter.validateEmail(params.ownerEmail!)) {
        return (isValid: true, error: null);
      } else {
        return (isValid: false, error: "Invalid Email");
      }
    } else {
      return (isValid: false, error: "Email is required!");
    }
  }

  ({bool isValid, String? error}) isPasswordValid(
      RegistrationFormModel params) {
    if ((params.ownerPassword?.length ?? 0) < 6) {
      return (
        isValid: false,
        error: "Password must be more than 6 characters."
      );
    }

    if ((params.ownerPassword?.length ?? 0) > 60) {
      return (isValid: false, error: "Max length is 60");
    }

    return (isValid: true, error: null);
  }

  ({bool isValid, String? error}) isPasswordsmatched(
      RegistrationFormModel params) {
    if (params.ownerPassword == params.ownerConfirmPassword) {
      return (isValid: true, error: null);
    } else {
      return (isValid: false, error: "Password did not matched");
    }
  }
}
