import 'package:client/common/data/models/barangay.dart';
import 'package:client/common/domain/repositories/address_repo.dart';
import 'package:client/common/domain/use_cases/use_case.dart';

class GetBarangaysInCityUseCase extends UseCase<List<BarangayModel>, String?> {
  final addressRepo = AddressRepository();
  @override
  Future<List<BarangayModel>> call({String? params}) async {
    var barangays = await addressRepo.fetchBarangays(cityCode: params);
    return barangays;
  }
}
