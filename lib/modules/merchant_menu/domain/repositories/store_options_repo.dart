import 'package:client/common/data/models/merchant_service_option.dart';
import 'package:client/common/data/backend/backend.dart';

class StoreOptionsRepository {
  final Backend backend;

  StoreOptionsRepository({required this.backend});
  Future<List<MerchantServiceOptionModel>> fetchStoreOption(
      String merchantId) async {
    return backend.getMerchantOptions(merchantId: merchantId);
  }
}
