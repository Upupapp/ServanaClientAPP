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

  /// v1 mobile verification is a different proof, not a renamed field.
  ///
  /// `VerifyMobileRequest` requires exactly one thing — `idToken`, a Firebase
  /// ID token whose sign-in provider is `phone`. Firebase only issues one
  /// after running its OWN SMS OTP, and the backend has no SMS sender of its
  /// own: `auth.verifyMobile` verifies the token, reads the phone number off
  /// the credential and refuses anything that does not prove one.
  ///
  /// This interface carries a `mobileNumber` and an `otp` the app collected
  /// itself. Neither can be turned into that token here, so there is no body
  /// to send. Posting the pair anyway would earn a `VALIDATION_FAILED` and
  /// read, at the call site, as a server problem.
  ///
  /// So it refuses in the open — the same answer the compatibility source
  /// gives for the same operation, for a different reason. Closing this needs
  /// a Firebase phone-auth flow in the app and an interface that carries a
  /// token, which is a redesign rather than a field rename.
  @override
  Future<void> verifyMobile({
    required String mobileNumber,
    required String otp,
  }) async {
    throw const UnsupportedTransportOperation(
      'verifyMobile',
      'v1 verifies a mobile number from a Firebase phone credential '
          '(idToken), not from a number and an OTP this app collected. The '
          'app has no such credential to send.',
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
