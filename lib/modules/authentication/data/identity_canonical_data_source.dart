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
    // `channel` is an ENUM of exactly {'otp', 'link'} — it is not the kind of
    // identifier being resent to. This used to send `'email'`, which is not a
    // member, and the handler's `body.channel === 'link' ? 'link' : 'otp'`
    // quietly resolved it to 'otp'. Right answer, wrong reason: the value was
    // being corrected by a default, so the day someone wanted the link channel
    // the bug would have looked like a backend fault.
    await _api.post(
      V1Endpoints.authResendVerification(),
      body: <String, dynamic>{'identifier': email, 'channel': 'otp'},
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
      body: <String, dynamic>{'identifier': email, 'code': otp},
    );
  }

  /// `VerifyMobileRequest` is exactly `{idToken}`, `additionalProperties:false`.
  ///
  /// This used to post `{mobileNumber, otp}` and could never have succeeded —
  /// the handler reads `body.idToken` with no fallback and answers
  /// `VALIDATION_FAILED` for anything else. It was not a field rename: v1
  /// takes a Firebase phone credential as the proof, because the backend has
  /// no SMS sender of its own.
  @override
  Future<void> verifyMobile({required String idToken}) async {
    await _api.post(
      V1Endpoints.authVerifyMobile(),
      body: <String, dynamic>{'idToken': idToken},
    );
  }

  @override
  Future<void> forgotPassword(String email) async {
    // `platform` is deliberately omitted: it chooses which allowlisted app the
    // reset link lands in, and the backend's default is the right one for this
    // client. Sending a value here would mean maintaining a second copy of an
    // allowlist that lives on the server.
    await _api.post(
      V1Endpoints.authForgotPassword(),
      body: <String, dynamic>{'identifier': email},
    );
  }

  /// [token] is Firebase's single-use `oobCode` from the reset email.
  ///
  /// The interface name is generic; the wire name is not, and the handler has
  /// no fallback for it — `auth.resetPassword` reads `body.oobCode` and
  /// `body.newPassword` and answers `VALIDATION_FAILED` for anything else.
  /// This previously sent `{token, password}` and so could never have
  /// succeeded.
  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _api.post(
      V1Endpoints.authResetPassword(),
      body: <String, dynamic>{'oobCode': token, 'newPassword': newPassword},
    );
  }

  @override
  Future<void> logout() async {
    await _api.post(V1Endpoints.authLogout());
  }
}
