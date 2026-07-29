import 'package:client/common/domain/helpers/session_service.dart';
import 'package:client/modules/profile/application/address_controller.dart';
import 'package:client/modules/profile/data/profile_repository.dart';
import 'package:client/modules/profile/domain/account_completeness.dart';
import 'package:client/modules/profile/domain/customer_profile.dart';
import 'package:flutter/foundation.dart';

enum ProfileLoadStatus { initial, loading, loaded, error }

class ProfileController extends ChangeNotifier {
  ProfileController({
    required ProfileRepository repository,
    required AddressController addressController,
  })  : _repository = repository,
        _addressController = addressController {
    _addressController.addListener(_onAddressChange);
  }

  final ProfileRepository _repository;
  final AddressController _addressController;

  CustomerProfile? _profile;
  ProfileLoadStatus _status = ProfileLoadStatus.initial;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  String? _error;
  String? _saveError;
  bool _disposed = false;

  CustomerProfile? get profile => _profile;
  ProfileLoadStatus get status => _status;
  bool get isLoading => _status == ProfileLoadStatus.loading;
  bool get isSaving => _isSaving;
  bool get isUploadingPhoto => _isUploadingPhoto;
  String? get error => _error;
  String? get saveError => _saveError;

  AccountCompleteness get completeness => AccountCompleteness(
        hasName: (_profile?.firstName?.isNotEmpty ?? false) ||
            (_profile?.lastName?.isNotEmpty ?? false),
        hasEmail: (_profile?.email.isNotEmpty) ?? false,
        isEmailVerified: _profile?.isEmailVerified ?? false,
        hasPhone: (_profile?.phoneNumber?.isNotEmpty) ?? false,
        hasSavedAddress: _addressController.addresses.isNotEmpty,
        hasPhoto: _profile?.hasPhoto ?? false,
        hasBirthdate: (_profile?.birthdate?.isNotEmpty) ?? false,
        hasGender: (_profile?.gender?.isNotEmpty) ?? false,
      );

  Future<void> loadProfile() async {
    if (_status == ProfileLoadStatus.loading) return;
    _status = ProfileLoadStatus.loading;
    _error = null;
    _notify();
    try {
      _profile = await _repository.loadProfile();
      _status = ProfileLoadStatus.loaded;
      // Keep local session in sync so other screens see the updated name/phone.
      if (_profile != null) await _syncSession(_profile!);
    } catch (e) {
      _status = ProfileLoadStatus.error;
      _error = _sanitize(e);
    }
    _notify();
  }

  Future<bool> updateProfile({
    required String fullname,
    String? mobileNumber,
    String? birthdate,
    String? gender,
  }) async {
    _isSaving = true;
    _saveError = null;
    _notify();
    try {
      await _repository.updateProfile(
        fullname: fullname,
        mobileNumber: mobileNumber,
        birthdate: birthdate,
        gender: gender,
      );
      await loadProfile();
      return true;
    } catch (e) {
      _saveError = _sanitize(e);
      _isSaving = false;
      _notify();
      return false;
    }
  }

  Future<bool> uploadPhoto(String base64Data) async {
    _isUploadingPhoto = true;
    _saveError = null;
    _notify();
    try {
      await _repository.uploadPhoto(base64Data);
      await loadProfile();
      return true;
    } catch (e) {
      _saveError = _sanitize(e);
      _isUploadingPhoto = false;
      _notify();
      return false;
    }
  }

  Future<bool> removePhoto() async {
    _isUploadingPhoto = true;
    _saveError = null;
    _notify();
    try {
      await _repository.removePhoto();
      await loadProfile();
      return true;
    } catch (e) {
      _saveError = _sanitize(e);
      _isUploadingPhoto = false;
      _notify();
      return false;
    }
  }

  void resetPrivateData() {
    _profile = null;
    _status = ProfileLoadStatus.initial;
    _isSaving = false;
    _isUploadingPhoto = false;
    _error = null;
    _saveError = null;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _addressController.removeListener(_onAddressChange);
    super.dispose();
  }

  void _onAddressChange() => _notify();

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _syncSession(CustomerProfile p) async {
    final session = await SessionService.getSession();
    if (session == null) return;
    final parts = [p.firstName?.trim(), p.lastName?.trim()]
        .where((s) => s != null && s.isNotEmpty)
        .join(' ');
    await SessionService.saveSession(session.copyWith(
      fullname: parts.isNotEmpty ? parts : session.fullname,
      mobileNumber: p.phoneNumber ?? session.mobileNumber,
      emailAddress: p.email.isNotEmpty ? p.email : session.emailAddress,
    ));
  }

  String _sanitize(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('401')) return 'Session expired. Please sign in again.';
    if (msg.contains('network') || msg.contains('socket')) {
      return 'No internet connection. Please try again.';
    }
    return 'Could not update profile. Please try again.';
  }
}
