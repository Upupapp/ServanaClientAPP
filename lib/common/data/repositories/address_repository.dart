import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/common/domain/helpers/session_service.dart';
import 'package:client/common/presentation/screens/address_form_screen.dart';

/// Result of loading or creating an address.
sealed class AddressResult {}

class AddressSuccess extends AddressResult {
  AddressSuccess(this.addresses);
  final List<Map<String, dynamic>> addresses;
}

class AddressCreated extends AddressResult {
  AddressCreated({required this.newAddress, required this.allAddresses});
  final Map<String, dynamic> newAddress;
  final List<Map<String, dynamic>> allAddresses;
}

class AddressError extends AddressResult {
  AddressError(this.message);
  final String message;
}

/// Centralises all address read/write operations for booking flows.
///
/// Extracts the ~50-line address-save blocks that were duplicated verbatim
/// in both [AirconCheckoutScreen] and [BwCheckoutScreen].
/// Widgets should never call [ServanaApiClient.addUserAddress] or
/// [ServanaApiClient.getAllUserAddresses] directly.
class AddressRepository {
  AddressRepository({required ServanaApiClient api}) : _api = api;

  final ServanaApiClient _api;

  /// Load all saved addresses for the currently authenticated user.
  Future<AddressResult> loadAddresses() async {
    try {
      final res = await _api.getAllUserAddresses();
      final raw = res['data'] ?? res['items'] ?? res;
      final list = raw is List
          ? raw.cast<Map<String, dynamic>>()
          : <Map<String, dynamic>>[];
      return AddressSuccess(list);
    } catch (e) {
      return AddressError(_sanitise(e));
    }
  }

  /// Save a new address from [AddressFormResult] and return it alongside the
  /// refreshed full list.
  ///
  /// Validates that a session exists before constructing the payload — never
  /// sends an empty userId to the backend.
  Future<AddressResult> createAddress({
    required AddressFormResult result,
    required bool isPrimary,
  }) async {
    try {
      final session = await SessionService.getSession();
      final userId = session?.customerID ?? '';
      if (userId.isEmpty) {
        return AddressError('You must be signed in to save an address.');
      }

      final lat = result.location.latitude;
      final lon = result.location.longitude;

      final payload = <String, dynamic>{
        'userId': userId,
        'locationId': 'loc_${lat.toStringAsFixed(6)}_${lon.toStringAsFixed(6)}',
        'addressOne': result.address,
        'addressTwo':
            [result.unit, result.street].where((s) => s.isNotEmpty).join(', '),
        'zipCode': '',
        'postTown': result.city.isNotEmpty ? result.city : result.province,
        'country': 'Philippines',
        'lat': lat,
        'lon': lon,
        'label': result.landmark.isNotEmpty
            ? result.landmark
            : (result.barangay.isNotEmpty ? result.barangay : 'Home'),
        'isPrimary': isPrimary,
      };

      final res = await _api.addUserAddress(payload: payload);

      // Reload the full list after creation.
      final listResult = await loadAddresses();
      if (listResult is! AddressSuccess) {
        return AddressError('Address saved but could not refresh list.');
      }

      // Identify the newly created address by the returned ID.
      final newId =
          res['data']?['addressId'] ?? res['addressId'] ?? res['data']?['id'];

      Map<String, dynamic> newAddress;
      if (newId != null) {
        newAddress = listResult.addresses.firstWhere(
          (a) => (a['addressId'] ?? a['id']) == newId,
          orElse: () => listResult.addresses.isNotEmpty
              ? listResult.addresses.last
              : <String, dynamic>{},
        );
      } else {
        // Fallback: assume the last address in the list is the one just created.
        newAddress = listResult.addresses.isNotEmpty
            ? listResult.addresses.last
            : <String, dynamic>{};
      }

      return AddressCreated(
        newAddress: newAddress,
        allAddresses: listResult.addresses,
      );
    } catch (e) {
      return AddressError(_sanitise(e));
    }
  }

  String _sanitise(Object e) {
    if (e is ServanaApiException) {
      return 'Could not save address (${e.statusCode}). Please try again.';
    }
    if (e.toString().toLowerCase().contains('network') ||
        e.toString().toLowerCase().contains('socket')) {
      return 'No internet connection. Please check your connection and try again.';
    }
    return 'Could not save address. Please try again.';
  }
}
