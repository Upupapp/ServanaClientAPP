import 'package:client/common/domain/booking/booking_draft_service.dart';
import 'package:client/common/domain/helpers/session_service.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/services/auth_state_service.dart';
import 'package:client/common/services/error_message_mapper.dart';
import 'package:client/modules/aircon_booking/data/aircon_booking_store.dart';
import 'package:client/modules/authentication/domain/authentication_repo.dart';
import 'package:client/modules/bw_booking/data/bw_booking_store.dart';
import 'package:client/modules/homepage/presentation/stores/hompage_store.dart';
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
    // No Loading state — passive session restore should be silent.
    // Only user-initiated actions (login, logout) emit Loading.
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
    // Reset all private-data singletons so no previous account's data
    // leaks to the next user of the device (LEAKSHIELD §5).
    try {
      dpLocator<HomeStore>().resetPrivateData();
      dpLocator<AirconBookingStore>().reset();
      dpLocator<BwBookingStore>().reset();
      dpLocator<BookingDraftService>().clear();
    } catch (_) {}
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
