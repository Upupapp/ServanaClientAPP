import 'package:client/common/data/models/merchant_service_option.dart';
import 'package:client/common/domain/use_cases/use_case.dart';
import 'package:client/modules/store_items/domain/repositories/store_options_repo.dart';

class GetStoreOptionsUseCase
    extends UseCase<List<MerchantServiceOptionModel>, String> {
  final StoreOptionsRepository storeOptionsRepository;

  GetStoreOptionsUseCase({required this.storeOptionsRepository});
  @override
  Future<List<MerchantServiceOptionModel>> call({String? params}) async {
    var items = storeOptionsRepository.fetchStoreOption(params ?? '');

    return items;
  }
}
