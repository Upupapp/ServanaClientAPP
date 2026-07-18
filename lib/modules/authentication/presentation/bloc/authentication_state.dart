import 'package:equatable/equatable.dart';

abstract class AuthenticationState extends Equatable {
  @override
  List<Object> get props => [];
}

class AuthenticationUninitialized extends AuthenticationState {}

class AuthenticationAuthenticated extends AuthenticationState {}

class AuthenticationUnauthenticated extends AuthenticationState {
  final String? message;

  AuthenticationUnauthenticated({this.message});

  @override
  List<Object> get props => [message ?? ''];
}

class AuthenticationLoading extends AuthenticationState {}
