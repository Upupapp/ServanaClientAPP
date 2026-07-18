import 'package:client/common/data/models/job_order_model.dart';
import 'package:client/common/data/models/merchant_light.dart';
import 'package:client/common/data/models/user_session.dart';
import 'package:client/common/domain/helpers/session_service.dart';
import 'package:client/common/services/location_service.dart';
import 'package:client/modules/homepage/data/models/search_service_result.dart';
import 'package:client/modules/homepage/data/repositories/home_repo.dart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobx/mobx.dart';

part 'hompage_store.g.dart';

class HomeStore extends _HomeStore with _$HomeStore {
  HomeStore({
    required super.repo,
    required super.locationSerive,
  });
}

abstract class _HomeStore with Store {
  final HomeRepository repo;
  final LocationService locationSerive;

  _HomeStore({
    required this.repo,
    required this.locationSerive,
  });

  // Incremented on every resetPrivateData() call. Async actions capture this
  // at the start and bail before writing results if it changed — prevents
  // stale in-flight responses from leaking after logout (LEAKSHIELD §7).
  int _generation = 0;

  @observable
  bool isLoading = false;

  @observable
  UserSession? session;

  @observable
  LatLng? currentLocation;

  @observable
  ObservableList<MerchantLight> merchants = ObservableList<MerchantLight>();

  @observable
  ObservableList<SearchServiceResult> searchResults =
      ObservableList<SearchServiceResult>();

  @observable
  ObservableList<JobOrder> bookings = ObservableList<JobOrder>();

  @action
  Future<void> loadnearbyMerchants() async {
    isLoading = true;

    session = await SessionService.getSession();

    final currentLocation = await locationSerive.getLocation();
    this.currentLocation =
        LatLng(currentLocation.latitude, currentLocation.longitude);

    final res = await repo.getNearbyMerchants();

    if (res.isNotEmpty) {
      merchants.clear();
      merchants.addAll(res);
    }

    isLoading = false;
  }

  @action
  Future<void> loadBookings() async {
    isLoading = true;
    final gen = _generation;
    session = await SessionService.getSession();

    try {
      final res = await repo.getBookings();
      // Discard response if logout fired while we were awaiting — prevents
      // stale old-account data from writing into a reset store (LEAKSHIELD §7).
      if (_generation != gen) return;
      // Always replace the list with the authoritative API response so an
      // empty result shows a truthful empty state (LEAKSHIELD §9).
      bookings.clear();
      bookings.addAll(res);
    } catch (_) {
      // Backend error — keep existing list rather than showing empty.
    }

    try {
      final currentLocation = await locationSerive.getLocation();
      this.currentLocation =
          LatLng(currentLocation.latitude, currentLocation.longitude);
    } catch (_) {}

    isLoading = false;
  }

  @action
  Future<void> searchService(String keyword) async {
    isLoading = true;
    final res = await repo.searchService(keyword);

    searchResults.clear();
    searchResults.addAll(res);

    isLoading = false;
  }

  /// Clear all private session data on logout so no previous account's data
  /// leaks to the next user of the device (LEAKSHIELD §5).
  @action
  void resetPrivateData() {
    _generation++;
    session = null;
    currentLocation = null;
    bookings.clear();
    merchants.clear();
    searchResults.clear();
  }

  /// Push a real API-created booking into the local list so it shows
  /// immediately. Upserts by id so re-adding the same booking (e.g. checkout
  /// then the confirmation screen's "Back to Home") doesn't duplicate the row.
  @action
  void addBooking(JobOrder booking) {
    bookings.removeWhere((b) => b.jobOrderID == booking.jobOrderID);
    bookings.insert(0, booking);
  }
}
