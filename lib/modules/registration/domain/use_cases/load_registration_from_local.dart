import 'package:client/common/constants/boxes.dart';
import 'package:client/common/data/resources/data_state.dart';
import 'package:client/common/domain/helpers/hive_repo.dart';
import 'package:client/common/domain/use_cases/use_case.dart';
import 'package:client/common/errors/app_error.dart';
import 'package:client/modules/registration/data/models/registration_form_model.dart';

class LoadRegistrationFromLocalUseCase implements UseCase<DataState, void> {
  final repo = HiveHelper();
  final regbox = "registration";

  @override
  Future<DataState<RegistrationFormModel>> call({void params}) async {
    var regBox = await repo.openBox<RegistrationFormModel>(Boxes.registration);
    if (regBox.isNotEmpty) {
      var reg = regBox.get(Boxes.registration);
      await regBox.close();
      if (reg != null) {
        return DataSuccess(reg);
      } else {
        return const DataFailed(AppError("No Registration Saved Locally"));
      }
    } else {
      return const DataFailed(AppError("No Registration Saved Locally"));
    }
  }
}
