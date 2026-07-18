import 'package:client/common/data/backend/backend.dart';
import 'package:client/common/data/models/user_session.dart';

class AuthenticationRepository {
  final Backend backend;

  AuthenticationRepository({required this.backend});

  Future<({UserSession? session, String? error})> authenticate({
    required final String email,
    required final String password,
    final String fcmToken = '',
  }) async {
    return backend.authenticate(
      email: email,
      password: password,
      fcmToken: fcmToken,
    );
  }
}
