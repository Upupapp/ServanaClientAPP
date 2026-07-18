import 'package:client/common/constants/boxes.dart';
import 'package:client/common/data/resources/data_state.dart';
import 'package:client/common/domain/helpers/hive_repo.dart';
import 'package:client/common/domain/use_cases/use_case.dart';
import 'package:client/common/errors/app_error.dart';
import 'package:client/modules/registration/data/models/registration_form_model.dart';

class SaveRegistrationToLocalUseCase
    implements UseCase<void, RegistrationFormModel> {
  final repo = HiveHelper();
  final regbox = "registration";

  @override
  Future<DataState<RegistrationFormModel?>> call(
      {RegistrationFormModel? params}) async {
    if (params != null) {
      var regBox =
          await repo.openBox<RegistrationFormModel>(Boxes.registration);
      await regBox.put(Boxes.registration, params);
      await regBox.close();
      return DataSuccess(params);
    } else {
      return const DataFailed(AppError("Can't save to local storage"));
    }
  }
}
