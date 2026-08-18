/// Identity and verification over the legacy routes.
///
/// This is the source every shipped build uses. Behaviour is unchanged from
/// before TAB 03 — the same four calls to [ServanaApiClient] the profile
/// repository and the verification screen already made. What is new is only
/// that they now sit behind [IdentityDataSource] and return an [Identity].
///
/// ## Where the legacy identity actually comes from
///
/// There is no legacy `/me`. `GET /api/user/profile` is the closest thing and
/// the backend's migration matrix classifies it `ROLE_SPECIFIC` rather than an
/// alias of `/api/v1/me`, because it returns the customer *aggregate*
/// (addresses, preferences) and not the identity record. So this source reads
/// that route and projects the identity fields out of it, which is a narrowing
/// and therefore safe; the canonical source will read a smaller, purpose-built
/// payload instead.
library;

import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/modules/authentication/data/identity_data_source.dart';
import 'package:client/modules/authentication/domain/identity.dart';

class IdentityCompatibilityDataSource implements IdentityDataSource {
  IdentityCompatibilityDataSource(this._api);

  final ServanaApiClient _api;

  @override
  Future<Identity> fetchIdentity() async {
    final body = await _api.loadProfile();
    // Legacy responses nest under `data` and sometimes under `data.user`;
    // both are unwrapped here so no shape detail escapes this file.
    final data = body['data'];
    final map = data is Map<String, dynamic>
        ? (data['user'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(data['user'] as Map)
            : data)
        : body;
    return Identity.fromJson(Map<String, dynamic>.from(map));
  }

  @override
  Future<void> resendEmailVerification(String email) async {
    await _api.resendEmailOtp(email: email);
  }

  @override
  Future<void> verifyEmail({required String email, required String otp}) async {
    await _api.verifyEmailOtp(email: email, otp: otp);
  }

  /// No legacy route exists.
  ///
  /// The backend's mobile verification arrived with the v1 namespace; there is
  /// nothing on the legacy surface to call. Throwing a deterministic
  /// [UnsupportedTransportOperation] is the honest answer — a silent no-op
  /// would report a number as verified when nothing verified it.
  @override
  Future<void> verifyMobile({
    required String mobileNumber,
    required String otp,
  }) async {
    throw const UnsupportedTransportOperation(
      'verifyMobile',
      'The legacy API has no mobile-verification route; it exists only under '
          '/api/v1, which is not deployed.',
    );
  }

  /// Asks the backend to email a Firebase reset link.
  ///
  /// This used to throw, on the stated grounds that *"the customer app
  /// initiates password reset through Firebase, not the legacy API"*. That
  /// was not true of this app: `sendPasswordResetEmail`,
  /// `confirmPasswordReset` and `verifyPasswordResetCode` appear nowhere in
  /// it. Nothing initiated a reset by any route, and the login screen told
  /// customers the feature was "coming soon" while
  /// `POST /api/auth/forgot-password` had been deployed and rate-limited the
  /// whole time.
  @override
  Future<void> forgotPassword(String email) async {
    await _api.forgotPassword(email: email);
  }

  /// There is nothing for this app to complete.
  ///
  /// The legacy route emails a Firebase reset LINK, and the customer sets
  /// their new password on Firebase's hosted page in a browser. The app never
  /// sees the `oobCode`, so it has no reset to finish — this is a genuine
  /// absence of a step, not a missing route.
  ///
  /// It stays a refusal rather than a silent no-op: a no-op here would report
  /// a password as changed when nothing changed it.
  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    throw const UnsupportedTransportOperation(
      'resetPassword',
      'Legacy recovery completes on Firebase\'s hosted page, not in the app — '
          'this client never receives an oobCode to spend.',
    );
  }

  @override
  Future<void> logout() async {
    await _api.logout();
  }
}
