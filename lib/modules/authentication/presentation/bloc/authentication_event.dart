import 'package:equatable/equatable.dart';

abstract class AuthenticationEvent extends Equatable {
  @override
  List<Object> get props => [];
}

/// Submit login credentials. Accepts email OR normalized mobile number.
class AuthenticationInit extends AuthenticationEvent {
  final String email;
  final String password;
  final String fcmToken;

  AuthenticationInit({
    required this.email,
    required this.password,
    this.fcmToken = '',
  });
}

/// User chose to browse without an account.
class AuthBrowseAsGuest extends AuthenticationEvent {}

/// Restore session from Hive on app start. Emits [AuthenticationGuest] if
/// no valid session is found, [AuthenticationAuthenticated] if valid.
class AuthCheckSession extends AuthenticationEvent {}

/// Log the current user out: clear session, reset state, return to guest.
class AuthLogout extends AuthenticationEvent {}

/// Previously used but not yet wired — kept for backward compatibility.
class LoggedIn extends AuthenticationEvent {}

/// Kept for backward compatibility; use [AuthLogout] for new code.
class LoggedOut extends AuthenticationEvent {}
