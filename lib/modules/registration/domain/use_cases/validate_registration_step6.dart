import 'package:client/common/domain/use_cases/use_case.dart';
import 'package:client/modules/registration/data/models/reg_form_error_model.dart';
import 'package:client/modules/registration/data/models/registration_form_model.dart';
import 'package:client/modules/registration/data/resources/form_state.dart';

class ValidateRegistrationForm6UseCase
    implements UseCase<FormState, RegistrationFormModel> {
  @override
  Future<FormState> call({RegistrationFormModel? params}) async {
    // ignore: unused_local_variable
    var hash = params.hashCode;

    if (params != null) {
      var name = isNameValid(params);
      var idType = isIdTypeValid(params);
      var idNo = isIdNumberValid(params);
      var idFront = hasIdFront(params);
      var idBack = hasIdBack(params);
      if (name.isValid &&
          idType.isValid &&
          idNo.isValid &&
          idFront.isValid &&
          idBack.isValid) {
        return const FormValid();
      } else {
        return FormInvalid(
          RegFormErrorModel(
            authorizedPersonelName: name.error,
            authorizedPersonelIdType: idType.error,
            authorizedPersonelIdNumer: idNo.error,
            authorizedPersonelIdFront: idFront.error,
            authorizedPersonelIdBack: idBack.error,
          ),
        );
      }
    } else {
      return const FormInvalid(RegFormErrorModel());
    }
  }

  ({bool isValid, String? error}) isNameValid(RegistrationFormModel params) {
    if ((params.authorizedPersonelName?.length ?? 0) <= 0) {
      return (isValid: false, error: "This field is required!");
    }

    if ((params.authorizedPersonelName?.length ?? 0) > 60) {
      return (isValid: false, error: "Max length is 60");
    }

    return (isValid: true, error: null);
  }

  ({bool isValid, String? error}) isIdTypeValid(RegistrationFormModel params) {
    if ((params.authorizedPersonelIdType?.length ?? 0) <= 0) {
      return (isValid: false, error: "This field is required!");
    }

    if ((params.authorizedPersonelIdType?.length ?? 0) > 60) {
      return (isValid: false, error: "Max length is 60");
    }

    return (isValid: true, error: null);
  }

  ({bool isValid, String? error}) isIdNumberValid(
      RegistrationFormModel params) {
    if ((params.authorizedPersonelIdNumer?.length ?? 0) <= 0) {
      return (isValid: false, error: "This field is required!");
    }

    if ((params.authorizedPersonelIdNumer?.length ?? 0) > 60) {
      return (isValid: false, error: "Max length is 60");
    }

    return (isValid: true, error: null);
  }

  ({bool isValid, String? error}) hasIdFront(RegistrationFormModel params) {
    if ((params.authorizedPersonelIdFrontFile?.path.length ?? 0) <= 0) {
      return (isValid: false, error: "This file is required!");
    }

    return (isValid: true, error: null);
  }

  ({bool isValid, String? error}) hasIdBack(RegistrationFormModel params) {
    if ((params.authorizedPersonelIdBackFile?.path.length ?? 0) <= 0) {
      return (isValid: false, error: "This file is required!");
    }

    return (isValid: true, error: null);
  }
}
