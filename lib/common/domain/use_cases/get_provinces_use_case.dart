import 'package:client/common/data/models/province.dart';
import 'package:client/common/domain/repositories/address_repo.dart';
import 'package:client/common/domain/use_cases/use_case.dart';

class GetProvincesUseCase extends UseCase<List<ProvinceModel>, String?> {
  final addressRepo = AddressRepository();
  @override
  Future<List<ProvinceModel>> call({String? params}) async {
    var provinces = await addressRepo.fetchProvinces();
    return provinces;
  }
}
