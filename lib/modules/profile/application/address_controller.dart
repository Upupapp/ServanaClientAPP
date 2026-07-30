import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/common/data/repositories/address_repository.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/core/analytics/application/analytics_coordinator.dart';
import 'package:client/core/analytics/events/profile_events.dart';
import 'package:client/modules/profile/domain/customer_address.dart';
import 'package:flutter/foundation.dart';

class AddressController extends ChangeNotifier {
  AddressController({
    required AddressRepository repository,
    required ServanaApiClient api,
  })  : _repository = repository,
        _api = api;

  final AddressRepository _repository;
  final ServanaApiClient _api;

  List<CustomerAddress> _addresses = [];
  bool _isLoading = false;
  bool _isMutating = false;
  String? _error;
  bool _disposed = false;

  List<CustomerAddress> get addresses => List.unmodifiable(_addresses);
  bool get isLoading => _isLoading;
  bool get isMutating => _isMutating;
  String? get error => _error;

  CustomerAddress? get primaryAddress {
    for (final a in _addresses) {
      if (a.isPrimary) return a;
    }
    return _addresses.isNotEmpty ? _addresses.first : null;
  }

  Future<void> loadAddresses() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    _notify();
    try {
      final result = await _repository.loadAddresses();
      if (result is AddressSuccess) {
        _addresses = result.addresses.map(_fromJson).toList();
      } else if (result is AddressError) {
        _error = result.message;
      }
    } catch (e) {
      _error = 'Could not load addresses. Please try again.';
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  Future<bool> setPrimaryAddress(String addressId) async {
    _isMutating = true;
    _error = null;
    _notify();
    try {
      await _api.makeAddressPrimary(addressId: addressId);
      // Update locally without round-trip for instant feedback.
      _addresses = _addresses
          .map((a) => CustomerAddress(
                addressId: a.addressId,
                userId: a.userId,
                locationId: a.locationId,
                addressOne: a.addressOne,
                addressTwo: a.addressTwo,
                zipCode: a.zipCode,
                postTown: a.postTown,
                country: a.country,
                label: a.label,
                isPrimary: a.addressId == addressId,
                lat: a.lat,
                lon: a.lon,
              ))
          .toList();
      _isMutating = false;
      _track(const AddressSetPrimaryEvent());
      _notify();
      return true;
    } catch (e) {
      _error = 'Could not set primary address. Please try again.';
      _isMutating = false;
      _notify();
      return false;
    }
  }

  Future<bool> deleteAddress(String addressId) async {
    _isMutating = true;
    _error = null;
    _notify();
    try {
      await _api.deleteAddress(addressId: addressId);
      _addresses = _addresses.where((a) => a.addressId != addressId).toList();
      _isMutating = false;
      _track(const AddressDeletedEvent());
      _notify();
      return true;
    } catch (e) {
      _error = 'Could not delete address. Please try again.';
      _isMutating = false;
      _notify();
      return false;
    }
  }

  void _track(dynamic event) {
    try {
      dpLocator<AnalyticsCoordinator>().track(event).ignore();
    } catch (_) {}
  }

  void resetPrivateData() {
    _addresses = [];
    _isLoading = false;
    _isMutating = false;
    _error = null;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  CustomerAddress _fromJson(Map<String, dynamic> data) {
    return CustomerAddress(
      addressId:
          data['addressId']?.toString() ?? data['id']?.toString() ?? '',
      userId: data['userId']?.toString() ?? data['user_id']?.toString() ?? '',
      locationId: data['locationId']?.toString(),
      addressOne: data['addressOne'] ?? data['address_one'] ?? '',
      addressTwo: data['addressTwo'] ?? data['address_two'],
      zipCode: data['zipCode']?.toString(),
      postTown: data['postTown'] ?? data['post_town'],
      country: data['country'],
      label: data['label'],
      isPrimary: data['isPrimary'] == true ||
          data['is_primary'] == true ||
          data['isPrimary'].toString() == 'true',
      lat: _toDouble(data['lat']),
      lon: _toDouble(data['lon']),
    );
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
