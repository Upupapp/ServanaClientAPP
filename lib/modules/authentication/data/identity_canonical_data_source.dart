/// Identity and verification over the canonical `/api/v1` namespace.
///
/// ## Not reachable in any shipped build
///
/// Selected only when `CanonicalAvailability.isAvailable(V1Capability.identity)`
/// is true, which requires `--dart-define=CANONICAL_V1_ENABLED=true` AND
/// `CANONICAL_V1_CAPABILITIES=identity`. No production build passes either:
/// `/api/v1` is absent from the backend's `origin/main`. This exists so that
/// the day v1 deploys, migration is a define and a test run.
///
/// ## Least privilege
///
/// `GET /api/v1/me` takes no identifier. The subject is the bearer token, so
/// this transport cannot be asked about another account even by a caller that
/// wanted to. That is the whole reason identity reads moved off the profile
/// route, which is keyed on a customer id the client supplies.
library;

import 'package:client/core/network/v1_api_client.dart';
import 'package:client/core/network/v1_endpoints.dart';
import 'package:client/modules/authentication/data/identity_data_source.dart';
import 'package:client/modules/authentication/domain/identity.dart';

class IdentityCanonicalDataSource implements IdentityDataSource {
  IdentityCanonicalDataSource(this._api);

  final V1ApiClient _api;

  @override
  Future<Identity> fetchIdentity() async {
    final envelope = await _api.get(V1Endpoints.me());
    return Identity.fromJson(envelope.asMap);
  }

  @override
  Future<void> resendEmailVerification(String email) async {
    await _api.post(
      V1Endpoints.authResendVerification(),
      body: <String, dynamic>{'email': email, 'channel': 'email'},
    );
  }

  @override
  Future<void> verifyEmail({required String email, required String otp}) async {
    // The code travels in the BODY, never the query string: a query string is
    // written to the access log on every request, and an OTP in a plaintext
    // log is a live credential sitting in something that gets rotated, backed
    // up and read by anyone with host access.
    await _api.post(
      V1Endpoints.authVerifyEmail(),
      body: <String, dynamic>{'email': email, 'otp': otp},
    );
  }

  @override
  Future<void> verifyMobile({
    required String mobileNumber,
    required String otp,
  }) async {
    await _api.post(
      V1Endpoints.authVerifyMobile(),
      body: <String, dynamic>{'mobileNumber': mobileNumber, 'otp': otp},
    );
  }

  @override
  Future<void> forgotPassword(String email) async {
    await _api.post(
      V1Endpoints.authForgotPassword(),
      body: <String, dynamic>{'email': email},
    );
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _api.post(
      V1Endpoints.authResetPassword(),
      body: <String, dynamic>{'token': token, 'password': newPassword},
    );
  }

  @override
  Future<void> logout() async {
    await _api.post(V1Endpoints.authLogout());
  }
}
