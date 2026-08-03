import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/common/data/repositories/address_repository.dart';
import 'package:client/modules/profile/application/address_controller.dart';
import 'package:client/modules/profile/application/profile_controller.dart';
import 'package:client/modules/profile/data/profile_repository.dart';
import 'package:client/modules/profile/domain/customer_profile.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Fake ProfileRepository ────────────────────────────────────────────────────

class _FakeProfileRepo extends Fake implements ProfileRepository {
  CustomerProfile? _next;
  Object? _error;
  int updateCallCount = 0;
  int uploadCallCount = 0;
  int removeCallCount = 0;

  void willReturn(CustomerProfile p) {
    _next = p;
    _error = null;
  }

  void willThrow(Object e) {
    _error = e;
    _next = null;
  }

  @override
  Future<CustomerProfile?> loadProfile() async {
    if (_error != null) throw _error!;
    return _next;
  }

  @override
  Future<void> updateProfile({
    String? fullname,
    String? mobileNumber,
    String? birthdate,
    String? gender,
  }) async {
    updateCallCount++;
    if (_error != null) throw _error!;
  }

  @override
  Future<void> uploadPhoto(String photoDataUri) async {
    uploadCallCount++;
    if (_error != null) throw _error!;
  }

  @override
  Future<void> removePhoto() async {
    removeCallCount++;
    if (_error != null) throw _error!;
  }

  @override
  Future<void> resendEmailVerification() async {}

  @override
  Future<void> verifyEmailOtp(String otp) async {}
}

// ── Fake AddressController ────────────────────────────────────────────────────

class _FakeAddressRepo extends Fake implements AddressRepository {
  @override
  Future<AddressResult> loadAddresses() async => AddressSuccess([]);
}

class _FakeApiClient extends Fake implements ServanaApiClient {
  @override
  Future<Map<String, dynamic>> makeAddressPrimary({
    required String addressId,
  }) async =>
      {'status': 'success'};

  @override
  Future<Map<String, dynamic>> deleteAddress({
    required String addressId,
  }) async =>
      {'status': 'success'};
}

AddressController _makeAddressCtrl() => AddressController(
      repository: _FakeAddressRepo(),
      api: _FakeApiClient(),
    );

// ── Helpers ───────────────────────────────────────────────────────────────────

const _profile = CustomerProfile(
  id: 'uid-1',
  firstName: 'Maria',
  lastName: 'Cruz',
  email: 'maria@example.com',
  isEmailVerified: true,
  phoneNumber: '+639171234567',
  photoUrl: 'https://example.com/photo.jpg',
  birthdate: '1990-05-12',
  gender: 'female',
);

ProfileController _makeCtrl({
  _FakeProfileRepo? repo,
  AddressController? addressCtrl,
}) =>
    ProfileController(
      repository: repo ?? _FakeProfileRepo(),
      addressController: addressCtrl ?? _makeAddressCtrl(),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('ProfileController.loadProfile()', () {
    test('transitions to loaded and exposes profile', () async {
      final repo = _FakeProfileRepo()..willReturn(_profile);
      final ctrl = _makeCtrl(repo: repo);

      await ctrl.loadProfile();

      expect(ctrl.status, ProfileLoadStatus.loaded);
      expect(ctrl.profile?.id, 'uid-1');
      expect(ctrl.profile?.displayName, 'Maria Cruz');
      expect(ctrl.isLoading, isFalse);
    });

    test('transitions to error state on exception', () async {
      final repo = _FakeProfileRepo()..willThrow(Exception('network error'));
      final ctrl = _makeCtrl(repo: repo);

      await ctrl.loadProfile();

      expect(ctrl.status, ProfileLoadStatus.error);
      expect(ctrl.error, isNotNull);
      expect(ctrl.profile, isNull);
    });

    test('ignores concurrent calls while loading', () async {
      final repo = _FakeProfileRepo()..willReturn(_profile);
      final ctrl = ProfileController(
        repository: repo,
        addressController: _makeAddressCtrl(),
      );
      // First call starts loading; immediately call again — should be a no-op.
      final f1 = ctrl.loadProfile();
      final f2 = ctrl.loadProfile();
      await Future.wait([f1, f2]);
      expect(ctrl.profile?.id, 'uid-1');
    });

    test('notifyListeners() is called after load', () async {
      final repo = _FakeProfileRepo()..willReturn(_profile);
      final ctrl = _makeCtrl(repo: repo);
      var notified = false;
      ctrl.addListener(() => notified = true);

      await ctrl.loadProfile();

      expect(notified, isTrue);
    });
  });

  group('ProfileController.updateProfile()', () {
    test('returns true and resets isSaving on success', () async {
      final repo = _FakeProfileRepo()..willReturn(_profile);
      final ctrl = _makeCtrl(repo: repo);

      final ok = await ctrl.updateProfile(fullname: 'Maria Cruz');

      expect(ok, isTrue);
      expect(ctrl.isSaving, isFalse);
      expect(ctrl.saveError, isNull);
      expect(repo.updateCallCount, 1);
    });

    test('returns false and exposes saveError on exception', () async {
      final repo = _FakeProfileRepo()..willThrow(Exception('500'));
      final ctrl = _makeCtrl(repo: repo);

      final ok = await ctrl.updateProfile(fullname: 'Maria');

      expect(ok, isFalse);
      expect(ctrl.isSaving, isFalse);
      expect(ctrl.saveError, isNotNull);
    });

    test('isSaving is true while awaiting and false afterward', () async {
      final repo = _FakeProfileRepo()..willReturn(_profile);
      final ctrl = _makeCtrl(repo: repo);
      final states = <bool>[];
      ctrl.addListener(() => states.add(ctrl.isSaving));

      await ctrl.updateProfile(fullname: 'Maria');

      // First notification: isSaving=true; last notification: isSaving=false.
      expect(states.first, isTrue);
      expect(states.last, isFalse);
    });
  });

  group('ProfileController.uploadPhoto()', () {
    test('returns true and resets isUploadingPhoto on success', () async {
      final repo = _FakeProfileRepo()..willReturn(_profile);
      final ctrl = _makeCtrl(repo: repo);

      final ok = await ctrl.uploadPhoto('data:image/jpeg;base64,abc123');

      expect(ok, isTrue);
      expect(ctrl.isUploadingPhoto, isFalse);
      expect(repo.uploadCallCount, 1);
    });

    test('returns false and resets isUploadingPhoto on error', () async {
      final repo = _FakeProfileRepo()..willThrow(Exception('upload failed'));
      final ctrl = _makeCtrl(repo: repo);

      final ok = await ctrl.uploadPhoto('data:image/jpeg;base64,abc');

      expect(ok, isFalse);
      expect(ctrl.isUploadingPhoto, isFalse);
      expect(ctrl.saveError, isNotNull);
    });

    test('isUploadingPhoto is true while awaiting and false afterward',
        () async {
      final repo = _FakeProfileRepo()..willReturn(_profile);
      final ctrl = _makeCtrl(repo: repo);
      final states = <bool>[];
      ctrl.addListener(() => states.add(ctrl.isUploadingPhoto));

      await ctrl.uploadPhoto('data:image/jpeg;base64,abc');

      expect(states.first, isTrue);
      expect(states.last, isFalse);
    });
  });

  group('ProfileController.removePhoto()', () {
    test('returns true and resets isUploadingPhoto on success', () async {
      final repo = _FakeProfileRepo()..willReturn(_profile);
      final ctrl = _makeCtrl(repo: repo);

      final ok = await ctrl.removePhoto();

      expect(ok, isTrue);
      expect(ctrl.isUploadingPhoto, isFalse);
      expect(repo.removeCallCount, 1);
    });

    test('returns false and resets isUploadingPhoto on error', () async {
      final repo = _FakeProfileRepo()..willThrow(Exception('remove failed'));
      final ctrl = _makeCtrl(repo: repo);

      final ok = await ctrl.removePhoto();

      expect(ok, isFalse);
      expect(ctrl.isUploadingPhoto, isFalse);
    });
  });

  group('ProfileController.resetPrivateData()', () {
    test('clears profile and returns to initial status', () async {
      final repo = _FakeProfileRepo()..willReturn(_profile);
      final ctrl = _makeCtrl(repo: repo);
      await ctrl.loadProfile();
      expect(ctrl.profile, isNotNull);

      ctrl.resetPrivateData();

      expect(ctrl.profile, isNull);
      expect(ctrl.status, ProfileLoadStatus.initial);
      expect(ctrl.isLoading, isFalse);
      expect(ctrl.isSaving, isFalse);
      expect(ctrl.isUploadingPhoto, isFalse);
      expect(ctrl.error, isNull);
    });

    test('notifies listeners', () async {
      final ctrl = _makeCtrl();
      var notified = false;
      ctrl.addListener(() => notified = true);

      ctrl.resetPrivateData();

      expect(notified, isTrue);
    });
  });

  group('ProfileController.completeness', () {
    test('returns 0 score when profile is null', () {
      final ctrl = _makeCtrl();
      expect(ctrl.completeness.score, 0);
    });

    test('counts verified email for 20 pts', () async {
      final repo = _FakeProfileRepo()..willReturn(_profile);
      final ctrl = _makeCtrl(repo: repo);
      await ctrl.loadProfile();
      expect(ctrl.completeness.isEmailVerified, isTrue);
      // name(20) + emailVerified(20) + phone(20) + photo(10) + birthdate(5) + gender(5) = 80
      expect(ctrl.completeness.score, 80);
    });

    test('counts hasSavedAddress from AddressController', () async {
      final repo = _FakeProfileRepo()..willReturn(_profile);
      // Address controller with a non-empty list would count hasSavedAddress.
      // Without loading, addresses is empty.
      final ctrl = _makeCtrl(repo: repo);
      await ctrl.loadProfile();
      expect(ctrl.completeness.hasSavedAddress, isFalse);
      expect(ctrl.completeness.score, lessThan(100));
    });

    test('isBookingReady is false when no phone', () {
      final ctrl = _makeCtrl();
      expect(ctrl.completeness.isBookingReady, isFalse);
    });

    test('pendingItems includes all missing fields for null profile', () {
      final ctrl = _makeCtrl();
      final items = ctrl.completeness.pendingItems;
      expect(items, contains('Add your name'));
      expect(items, contains('Verify your email'));
      expect(items, contains('Add a phone number'));
      expect(items, contains('Add a saved address'));
    });
  });

  group('CustomerProfile helpers', () {
    test('displayName returns first + last when both present', () {
      expect(_profile.displayName, 'Maria Cruz');
    });

    test('displayName returns first only when last absent', () {
      const p = CustomerProfile(id: '1', firstName: 'Maria', email: 'x@y.com');
      expect(p.displayName, 'Maria');
    });

    test('displayName falls back to email prefix when name absent', () {
      const p = CustomerProfile(id: '1', email: 'maria@example.com');
      expect(p.displayName, 'maria');
    });

    test('initials returns first letters of first + last names', () {
      expect(_profile.initials, 'MC');
    });

    test('initials returns single letter for single-word name', () {
      const p = CustomerProfile(id: '1', firstName: 'Maria', email: 'x@y.com');
      expect(p.initials, 'M');
    });

    test('hasPhoto is true when photoUrl is non-empty', () {
      expect(_profile.hasPhoto, isTrue);
    });

    test('hasPhoto is false when photoUrl is null', () {
      const p = CustomerProfile(id: '1', email: 'x@y.com');
      expect(p.hasPhoto, isFalse);
    });
  });
}
