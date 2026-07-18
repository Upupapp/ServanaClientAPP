import 'package:flutter/foundation.dart';

enum AuthStatus { unknown, guest, authenticated, expired }

/// Singleton [ChangeNotifier] that the GoRouter listens to via
/// [GoRouter.refreshListenable]. Updated by [AuthenticationBloc] whenever
/// the auth state changes.
///
/// Registered in GetIt (dpLocator) so both the BLoC and the router can reach
/// it without circular dependency.
class AuthStateService extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;

  AuthStatus get status => _status;

  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isGuest => _status == AuthStatus.guest;

  void update(AuthStatus newStatus) {
    if (_status == newStatus) return;
    _status = newStatus;
    notifyListeners();
  }
}
