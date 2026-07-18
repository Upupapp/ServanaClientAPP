import 'package:client/common/data/models/job_order_model.dart';
import 'package:client/common/data/models/merchant_light.dart';
import 'package:client/common/data/backend/backend.dart';
import 'package:client/common/domain/helpers/session_service.dart';
import 'package:client/common/services/location_service.dart';
import 'package:client/modules/homepage/data/models/search_service_result.dart';

class HomeRepository {
  final Backend backend;
  final LocationService locationService;

  HomeRepository({
    required this.backend,
    required this.locationService,
  });

  Future<List<MerchantLight>> getNearbyMerchants() async {
    final location = await locationService.getLocation();
    return backend.getNearbyMerchants(
      latitude: location.latitude,
      longitude: location.longitude,
    );
  }

  Future<List<JobOrder>> getBookings() async {
    final session = await SessionService.getSession();
    if (session == null) return [];
    return backend.getBookings(customerId: session.customerID);
  }

  Future<List<SearchServiceResult>> searchService(String keyword) async {
    return backend.searchService(keyword: keyword);
  }
}
