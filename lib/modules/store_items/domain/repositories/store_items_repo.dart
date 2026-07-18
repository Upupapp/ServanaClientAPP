import 'package:client/common/data/models/merchant_category.dart';
import 'package:client/common/data/models/merchant_service.dart';
import 'package:client/common/data/models/merchant_service_option.dart';
import 'package:client/common/data/backend/backend.dart';

class StoreItemsReporsitory {
  final Backend backend;

  StoreItemsReporsitory({required this.backend});
  Future<List<MerchantServiceModel>> fetchStoreItems(String merchantID) async {
    return backend.getServices(merchantId: merchantID);
  }

  Future<List<MerchantServiceOptionModel>> fetchStoreOptions(
      String merchantID) async {
    return backend.getMerchantOptions(merchantId: merchantID);
  }

  Future<List<({int key, String value})>> fetchStoreCategories(
      String merchantID) async {
    return backend.getCategories(merchantId: merchantID);
  }

  Future<bool> addService(MerchantServiceModel service) async {
    await Future.delayed(const Duration(seconds: 1));
    return backend.addService(service: service);
  }

  Future<({bool isSuccess, String? error})> updateService(
      MerchantServiceModel service) async {
    await Future.delayed(const Duration(seconds: 1));
    return backend.editService(service: service);
  }

  Future<bool> toggleService(MerchantServiceModel service, bool isOn) async {
    await Future.delayed(const Duration(seconds: 1));
    return backend.toggleService(
      id: service.merchantServiceID.toString(),
      isOn: isOn,
    );
  }

  Future<bool> addServiceCategory(MerchantCategory category) async {
    await Future.delayed(const Duration(seconds: 1));
    return backend.addServiceCategory(category: category);
  }
}
