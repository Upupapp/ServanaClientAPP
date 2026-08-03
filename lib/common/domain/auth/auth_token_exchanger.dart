import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/common/data/models/user_session.dart';

/// Extracts the Firebase→Servana token-exchange step from [AuthenticationBloc]
/// so it can be unit-tested without platform channels (FirebaseMessaging,
/// GoogleSignIn, FacebookAuth).
///
/// The caller is responsible for obtaining the Firebase [idToken] and the
/// optional [fcmToken]; this class only performs the backend call and maps
/// the response to a [UserSession] or an error string.
class AuthTokenExchanger {
  const AuthTokenExchanger(this._api);

  final ServanaApiClient _api;

  /// Exchange a Firebase [idToken] for a Servana [UserSession].
  ///
  /// Returns `(session: UserSession, error: null)` on success.
  /// Returns `(session: null, error: <message>)` when the backend response
  /// contains an empty or absent `token` field — the caller should emit
  /// [AuthenticationUnauthenticated] with the returned message.
  ///
  /// Throws [ServanaApiException] on non-2xx HTTP responses.
  Future<({UserSession? session, String? error})> exchange(
    String idToken,
    String fallbackEmail, {
    String? fcmToken,
  }) async {
    final body = await _api.firebaseLogin(idToken: idToken, fcmToken: fcmToken);
    final data = body['data'] as Map<String, dynamic>? ?? body;
    final token = (data['token'] ?? '').toString();
    if (token.isEmpty) {
      final msg =
          body['message']?.toString() ?? 'Sign-in failed. Please try again.';
      return (session: null, error: msg);
    }
    final session = UserSession(
      customerID: (data['id'] ?? data['customerID'] ?? '').toString(),
      mobileNumber:
          (data['phoneNumber'] ?? data['mobileNumber'] ?? '').toString(),
      fullname: (data['fullname'] ?? '').toString(),
      emailAddress:
          (data['email'] ?? data['emailAddress'] ?? fallbackEmail).toString(),
      token: token,
    );
    return (session: session, error: null);
  }
}
