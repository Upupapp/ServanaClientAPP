import 'package:client/common/domain/use_cases/use_case.dart';
import 'package:client/modules/registration/data/models/reg_form_error_model.dart';
import 'package:client/modules/registration/data/models/registration_form_model.dart';
import 'package:client/modules/registration/data/resources/form_state.dart';

class ValidateRegistrationForm5UseCase
    implements UseCase<FormState, RegistrationFormModel> {
  @override
  Future<FormState> call({RegistrationFormModel? params}) async {
    // ignore: unused_local_variable
    var hash = params.hashCode;

    if (params != null) {
      var bank = isBankValid(params);
      var accountHolder = isAccountHolderValid(params);
      var accountNo = isAccountNoValid(params);
      var bankCert = hasBankCert(params);
      var idType = isIdTypeValid(params);
      var idNo = isIdNumberValid(params);
      var idFront = hasIdFront(params);
      var idBack = hasIdBack(params);
      if (bank.isValid &&
          accountHolder.isValid &&
          accountNo.isValid &&
          bankCert.isValid &&
          idType.isValid &&
          idNo.isValid &&
          idFront.isValid &&
          idBack.isValid) {
        return const FormValid();
      } else {
        return FormInvalid(
          RegFormErrorModel(
            bank: bank.error,
            bankAccountHolder: accountHolder.error,
            bankAccountNumber: accountNo.error,
            bankCertificate: bankCert.error,
            bankAccountHolderIdType: idType.error,
            bankAccountHolderIdNumber: idNo.error,
            bankAccountHolderIdFront: idFront.error,
            bankAccountHolderIdBack: idBack.error,
          ),
        );
      }
    } else {
      return const FormInvalid(RegFormErrorModel());
    }
  }

  ({bool isValid, String? error}) isBankValid(RegistrationFormModel params) {
    if ((params.bank?.length ?? 0) <= 0) {
      return (isValid: false, error: "This field is required!");
    }

    if ((params.bank?.length ?? 0) > 60) {
      return (isValid: false, error: "Max length is 60");
    }

    return (isValid: true, error: null);
  }

  ({bool isValid, String? error}) isAccountHolderValid(
      RegistrationFormModel params) {
    if ((params.bankAccountHolder?.length ?? 0) <= 0) {
      return (isValid: false, error: "This field is required!");
    }

    if ((params.bankAccountHolder?.length ?? 0) > 60) {
      return (isValid: false, error: "Max length is 60");
    }

    return (isValid: true, error: null);
  }

  ({bool isValid, String? error}) isAccountNoValid(
      RegistrationFormModel params) {
    if ((params.bankAccountNumber?.length ?? 0) <= 0) {
      return (isValid: false, error: "This field is required!");
    }

    if ((params.bankAccountNumber?.length ?? 0) > 60) {
      return (isValid: false, error: "Max length is 60");
    }

    return (isValid: true, error: null);
  }

  ({bool isValid, String? error}) isIdTypeValid(RegistrationFormModel params) {
    if ((params.bankAccountHolderIdType?.length ?? 0) <= 0) {
      return (isValid: false, error: "This field is required!");
    }

    if ((params.bankAccountHolderIdType?.length ?? 0) > 60) {
      return (isValid: false, error: "Max length is 60");
    }

    return (isValid: true, error: null);
  }

  ({bool isValid, String? error}) isIdNumberValid(
      RegistrationFormModel params) {
    if ((params.bankAccountHolderIdNumber?.length ?? 0) <= 0) {
      return (isValid: false, error: "This field is required!");
    }

    if ((params.bankAccountHolderIdNumber?.length ?? 0) > 60) {
      return (isValid: false, error: "Max length is 60");
    }

    return (isValid: true, error: null);
  }

  ({bool isValid, String? error}) hasIdFront(RegistrationFormModel params) {
    if ((params.bankAccountHolderIdFrontFile?.path.length ?? 0) <= 0) {
      return (isValid: false, error: "This file is required!");
    }

    return (isValid: true, error: null);
  }

  ({bool isValid, String? error}) hasIdBack(RegistrationFormModel params) {
    if ((params.bankAccountHolderIdBackFile?.path.length ?? 0) <= 0) {
      return (isValid: false, error: "This file is required!");
    }

    return (isValid: true, error: null);
  }

  ({bool isValid, String? error}) hasBankCert(RegistrationFormModel params) {
    if ((params.bankCertificateFile?.path.length ?? 0) <= 0) {
      return (isValid: false, error: "This file is required!");
    }

    return (isValid: true, error: null);
  }
}
