import 'package:equatable/equatable.dart';

abstract class AuthenticationState extends Equatable {
  @override
  List<Object> get props => [];
}

/// Initial — session check has not run yet.
class AuthenticationUninitialized extends AuthenticationState {}

/// Async operation in progress.
class AuthenticationLoading extends AuthenticationState {}

/// Session restored or login succeeded.
class AuthenticationAuthenticated extends AuthenticationState {}

/// Explicit guest mode: user chose to browse without signing in.
class AuthenticationGuest extends AuthenticationState {}

/// Login or session check failed — not authenticated.
class AuthenticationUnauthenticated extends AuthenticationState {
  final String? message;
  AuthenticationUnauthenticated({this.message});

  @override
  List<Object> get props => [message ?? ''];
}

/// Session was previously valid but has now expired.
class AuthenticationExpired extends AuthenticationState {}

/// User deliberately logged out.
class AuthenticationLoggedOut extends AuthenticationState {}
