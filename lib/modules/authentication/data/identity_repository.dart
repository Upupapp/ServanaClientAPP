/// Identity feature repository — the TAB 02 compatibility pattern applied to
/// authentication state.
///
///     IdentityRepository
///       → IdentityCanonicalDataSource      when V1Capability.identity
///       → IdentityCompatibilityDataSource  otherwise
///       → Identity + ApiFailure either way
///
/// [canonical] and [router] are optional. Omitting either pins the repository
/// to the compatibility source with no behaviour change, which is what every
/// build does today because `/api/v1` is not deployed.
///
/// ## Why every method returns a typed failure
///
/// Above this line nothing throws `ServanaApiException` and nothing inspects a
/// status code. The screens that used to do `e.toString().contains('400')` can
/// ask [AuthFailureCopy] instead, which distinguishes an invalid code from an
/// expired one — a distinction a substring match cannot make and the customer
/// very much can.
library;

import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/core/network/api_error_mapper.dart';
import 'package:client/core/network/api_failure.dart';
import 'package:client/core/network/canonical_availability.dart';
import 'package:client/core/network/compat/canonical_router.dart';
import 'package:client/modules/authentication/data/identity_data_source.dart';
import 'package:client/modules/authentication/domain/identity.dart';

class IdentityRepository {
  IdentityRepository({
    required IdentityDataSource compatibility,
    IdentityDataSource? canonical,
    CanonicalRouter? router,
    ApiErrorMapper mapper = const ApiErrorMapper(),
  })  : _compatibility = compatibility,
        _canonical = canonical,
        _router = router,
        _mapper = mapper;

  final IdentityDataSource _compatibility;
  final IdentityDataSource? _canonical;
  final CanonicalRouter? _router;
  final ApiErrorMapper _mapper;

  /// The transport answering right now.
  ///
  /// Falls back to compatibility whenever the canonical source or the router
  /// is absent, so a half-wired injector cannot route at a transport that does
  /// not exist.
  IdentityDataSource get _source {
    final canonical = _canonical;
    final router = _router;
    if (canonical == null || router == null) return _compatibility;
    return router.select<IdentityDataSource>(
      V1Capability.identity,
      canonical: canonical,
      compatibility: _compatibility,
    );
  }

  /// True when identity reads are going to `/api/v1`. Diagnostics only.
  bool get isCanonical =>
      _canonical != null &&
      (_router?.isCanonical(V1Capability.identity) ?? false);

  Future<Identity> fetchIdentity() =>
      _guard(() => _source.fetchIdentity(), 'fetchIdentity');

  Future<void> resendEmailVerification(String email) => _guard(
      () => _source.resendEmailVerification(email), 'resendEmailVerification');

  Future<void> verifyEmail({required String email, required String otp}) =>
      _guard(() => _source.verifyEmail(email: email, otp: otp), 'verifyEmail');

  /// Claims the mobile number proven by a Firebase phone credential.
  ///
  /// [idToken] comes from Firebase's own SMS OTP, never from a code this app
  /// collected — see [IdentityDataSource.verifyMobile].
  Future<void> verifyMobile({required String idToken}) => _guard(
        () => _source.verifyMobile(idToken: idToken),
        'verifyMobile',
      );

  Future<void> forgotPassword(String email) =>
      _guard(() => _source.forgotPassword(email), 'forgotPassword');

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) =>
      _guard(
        () => _source.resetPassword(token: token, newPassword: newPassword),
        'resetPassword',
      );

  /// Revokes the session server-side.
  ///
  /// Never throws. Logout is something the customer asked for, and a server
  /// that refuses must not be able to trap them in a signed-in app — the local
  /// cleanup runs regardless. Returns the failure so the caller can log it.
  Future<ApiFailure?> logout() async {
    try {
      await _source.logout();
      return null;
    } catch (error) {
      return _asFailure(error);
    }
  }

  /// Normalises everything the transports can throw into [ApiFailure].
  Future<T> _guard<T>(Future<T> Function() action, String operation) async {
    try {
      return await action();
    } catch (error) {
      throw _asFailure(error, operation: operation);
    }
  }

  ApiFailure _asFailure(Object error, {String? operation}) {
    // Already canonical — the v1 client throws these directly.
    if (error is ApiFailure) return error;

    // The legacy client throws this, carrying a status and a raw body.
    if (error is ServanaApiException) {
      return _mapper.fromResponse(
        status: error.statusCode,
        body: error.body,
      );
    }

    // A transport that cannot do the thing at all. Deterministic, so it is
    // NOT retryable — classifying it as a network blip would have the UI
    // offer a retry that can never succeed.
    if (error is UnsupportedTransportOperation) {
      return UnknownFailure(
        safeMessage: 'This is not available in this version of the app.',
        code: 'TRANSPORT_UNSUPPORTED',
        debugDetail: error.toString(),
      );
    }

    return _mapper.fromTransport(error);
  }
}
