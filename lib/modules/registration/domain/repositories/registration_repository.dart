import 'package:client/common/data/resources/data_state.dart';
import 'package:client/common/data/backend/backend.dart';
import 'package:client/modules/registration/data/models/registration_form_model.dart';

class RegistrationRepository {
  final Backend backend;

  RegistrationRepository({required this.backend});

  Future<DataState<RegistrationFormModel?>> saveRegistrationToLocal(
      {required RegistrationFormModel registration}) async {
    return const DataSuccess(null);
    //todo: implement
  }

  Future<RegistrationFormModel?> loadRegistrationFromLocal() async {
    return null;
    //todo: implement
  }

  Future<({bool isSuccess, String? message, int? statusCode})>
      submitRegistration({required RegistrationFormModel registration}) async {
    return backend.registerCustomer(registration);
  }

  Future<({bool isSuccess, String? message, int? statusCode})>
      resendVerificationEmail({required String email}) async {
    return backend.resendVerificationEmail(email: email);
  }
}
