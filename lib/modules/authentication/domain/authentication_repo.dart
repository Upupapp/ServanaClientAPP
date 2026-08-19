import 'package:client/common/data/backend/backend.dart';
import 'package:client/common/data/models/user_session.dart';

class AuthenticationRepository {
  final Backend backend;
  AuthenticationRepository({required this.backend});

  Future<({UserSession? session, String? error, int? statusCode})> authenticate({
    required final String email,
    required final String password,
    final String fcmToken = '',
  }) {
    return backend.authenticate(
      email: email,
      password: password,
      fcmToken: fcmToken,
    );
  }

  /// Client-side logout. Backend logout is called when supported; session is
  /// always cleared locally even if the backend call fails.
  Future<void> logout() async {
    try {
      await backend.logout();
    } catch (_) {
      // Backend logout is optional / best-effort.
    }
  }
}
