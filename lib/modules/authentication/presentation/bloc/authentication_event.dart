import 'package:equatable/equatable.dart';

abstract class AuthenticationEvent extends Equatable {
  @override
  List<Object> get props => [];
}

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

class LoggedIn extends AuthenticationEvent {}

class LoggedOut extends AuthenticationEvent {}
