import 'package:client/common/data/models/merchant_service.dart';
import 'package:client/common/domain/use_cases/use_case.dart';
import 'package:client/modules/store_items/domain/repositories/store_items_repo.dart';

class GetStoreItemsUseCase extends UseCase<List<MerchantServiceModel>, String> {
  final StoreItemsReporsitory storeItemsRepo;

  GetStoreItemsUseCase({required this.storeItemsRepo});
  @override
  Future<List<MerchantServiceModel>> call({String? params}) async {
    var items = await storeItemsRepo.fetchStoreItems(params ?? '');

    return items;
  }
}
