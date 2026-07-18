import 'package:client/common/domain/helpers/session_service.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/services/auth_state_service.dart';
import 'package:client/common/services/error_message_mapper.dart';
import 'package:client/modules/authentication/domain/authentication_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'authentication_event.dart';
import 'authentication_state.dart';

class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  AuthenticationBloc({required this.repo})
      : super(AuthenticationUninitialized()) {
    on<AuthenticationInit>(_onLogin);
    on<AuthBrowseAsGuest>(_onBrowseAsGuest);
    on<AuthCheckSession>(_onCheckSession);
    on<AuthLogout>(_onLogout);
    on<LoggedOut>(_onLoggedOutLegacy);
    on<LoggedIn>((_,__) {});
  }

  final AuthenticationRepository repo;

  // ───────────────── event handlers ─────────────────

  Future<void> _onLogin(
      AuthenticationInit event, Emitter<AuthenticationState> emit) async {
    emit(AuthenticationLoading());

    final result = await repo.authenticate(
      email: event.email,
      password: event.password,
      fcmToken: event.fcmToken,
    );

    if (result.session != null) {
      await SessionService.saveSession(result.session!);
      _notify(AuthStatus.authenticated);
      emit(AuthenticationAuthenticated());
    } else {
      final friendly = ErrorMessageMapper.forLogin(result.error);
      emit(AuthenticationUnauthenticated(message: friendly));
    }
  }

  Future<void> _onBrowseAsGuest(
      AuthBrowseAsGuest event, Emitter<AuthenticationState> emit) async {
    _notify(AuthStatus.guest);
    emit(AuthenticationGuest());
  }

  Future<void> _onCheckSession(
      AuthCheckSession event, Emitter<AuthenticationState> emit) async {
    emit(AuthenticationLoading());
    try {
      final session = await SessionService.getSession();
      if (session != null && session.token.isNotEmpty) {
        _notify(AuthStatus.authenticated);
        emit(AuthenticationAuthenticated());
      } else {
        _notify(AuthStatus.guest);
        emit(AuthenticationGuest());
      }
    } catch (_) {
      _notify(AuthStatus.guest);
      emit(AuthenticationGuest());
    }
  }

  Future<void> _onLogout(
      AuthLogout event, Emitter<AuthenticationState> emit) async {
    emit(AuthenticationLoading());
    try {
      await repo.logout();
    } catch (_) {
      // Logout is best-effort; always clear local state.
    }
    await SessionService.deleteSession();
    _notify(AuthStatus.guest);
    emit(AuthenticationLoggedOut());
  }

  Future<void> _onLoggedOutLegacy(
      LoggedOut event, Emitter<AuthenticationState> emit) async {
    // Legacy event — delegate to the real logout handler.
    add(AuthLogout());
  }

  // ─────────────────────── helpers ───────────────────────

  void _notify(AuthStatus status) {
    try {
      dpLocator<AuthStateService>().update(status);
    } catch (_) {}
  }
}
