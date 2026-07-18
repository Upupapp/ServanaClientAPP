import 'package:client/common/data/models/city.dart';
import 'package:client/common/domain/repositories/address_repo.dart';
import 'package:client/common/domain/use_cases/use_case.dart';

class GetCitiesInregionUseCase extends UseCase<List<CityModel>, String?> {
  final addressRepo = AddressRepository();

  @override
  Future<List<CityModel>> call({String? params}) async {
    var cities = await addressRepo.fetchCities(provinceCode: params);
    return cities;
  }
}
