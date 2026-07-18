import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/common/domain/helpers/session_service.dart';
import 'package:client/modules/authentication/domain/authentication_repo.dart';
import 'authentication_event.dart';
import 'authentication_state.dart';

class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  AuthenticationBloc({required this.repo})
      : super(AuthenticationUninitialized()) {
    on(mapEventToState);
  }

  final AuthenticationRepository repo;

  Future<void> mapEventToState(AuthenticationEvent event, Emitter emit) async {
    switch (event) {
      case AuthenticationInit():
        emit(AuthenticationLoading());

        final result = await repo.authenticate(
          email: event.email,
          password: event.password,
          fcmToken: event.fcmToken,
        );

        if (result.session != null) {
          SessionService.saveSession(result.session!);
          emit(AuthenticationAuthenticated());
        } else {
          emit(AuthenticationUnauthenticated(message: result.error));
        }
        break;
      case LoggedIn():
        //     yield AuthenticationLoading();
        // await Future.delayed(
        //     const Duration(seconds: 1)); // Simulate a delay for logging in
        // yield AuthenticationAuthenticated();
        break;
      case LoggedOut():
        //         yield AuthenticationLoading();
        // await Future.delayed(
        //     const Duration(seconds: 1)); // Simulate a delay for logging out
        // yield AuthenticationUnauthenticated();
        break;
      default:
    }
  }
}
