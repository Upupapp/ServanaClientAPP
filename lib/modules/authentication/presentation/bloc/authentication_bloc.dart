import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/common/domain/auth/auth_token_exchanger.dart';
import 'package:client/common/domain/booking/booking_draft_service.dart';
import 'package:client/common/domain/helpers/session_service.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/services/auth_state_service.dart';
import 'package:client/modules/categories/domain/category_reveal_policy.dart';
import 'package:client/common/services/error_message_mapper.dart';
import 'package:client/modules/aircon_booking/data/aircon_booking_store.dart';
import 'package:client/modules/authentication/domain/authentication_repo.dart';
import 'package:client/modules/bw_booking/data/bw_booking_store.dart';
import 'package:client/modules/homepage/presentation/stores/hompage_store.dart';
import 'package:client/modules/messaging/presentation/stores/messaging_store.dart';
import 'package:client/modules/notifications/application/fcm_coordinator.dart';
import 'package:client/modules/notifications/application/notifications_controller.dart';
import 'package:client/modules/profile/application/address_controller.dart';
import 'package:client/modules/profile/application/profile_controller.dart';
import 'package:client/modules/search/application/search_controller.dart';
import 'package:client/modules/search/data/search_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'authentication_event.dart';
import 'authentication_state.dart';

class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  AuthenticationBloc({
    required this.repo,
    GoogleSignIn? googleSignIn,
    FacebookAuth? facebookAuth,
  })  : _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _facebookAuth = facebookAuth ?? FacebookAuth.instance,
        super(AuthenticationUninitialized()) {
    on<AuthenticationInit>(_onLogin);
    on<AuthGoogleSignIn>(_onGoogleSignIn);
    on<AuthFacebookSignIn>(_onFacebookSignIn);
    on<AuthBrowseAsGuest>(_onBrowseAsGuest);
    on<AuthCheckSession>(_onCheckSession);
    on<AuthLogout>(_onLogout);
    on<LoggedOut>(_onLoggedOutLegacy);
    on<LoggedIn>((_, __) {});
  }

  final AuthenticationRepository repo;
  final GoogleSignIn _googleSignIn;

  // Injectable override — defaults to FacebookAuth.instance so all existing
  // call-sites that omit the parameter are unaffected.
  final FacebookAuth _facebookAuth;

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
      _notifyFcmLogin(result.session!.customerID);
      _notify(AuthStatus.authenticated);
      emit(AuthenticationAuthenticated());
    } else {
      final friendly = ErrorMessageMapper.forLogin(result.error);
      emit(AuthenticationUnauthenticated(message: friendly));
    }
  }

  Future<void> _onGoogleSignIn(
      AuthGoogleSignIn event, Emitter<AuthenticationState> emit) async {
    emit(AuthenticationLoading());
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User dismissed the picker — return to idle without an error message.
        emit(AuthenticationUnauthenticated());
        return;
      }
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;
      if (accessToken == null || idToken == null) {
        emit(AuthenticationUnauthenticated(
            message: 'Google sign-in failed. Please try again.'));
        return;
      }
      // Exchange for a Firebase ID token.
      final credential = GoogleAuthProvider.credential(
          accessToken: accessToken, idToken: idToken);
      final userCred =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseIdToken = await userCred.user?.getIdToken();
      if (firebaseIdToken == null) {
        emit(AuthenticationUnauthenticated(
            message: 'Google sign-in failed. Please try again.'));
        return;
      }
      await _loginWithFirebaseToken(
          firebaseIdToken, googleUser.email, emit);
    } catch (e) {
      debugPrint('[AuthBloc] Google sign-in error: $e');
      emit(AuthenticationUnauthenticated(
          message: 'Google sign-in failed. Please try again.'));
    }
  }

  Future<void> _onFacebookSignIn(
      AuthFacebookSignIn event, Emitter<AuthenticationState> emit) async {
    emit(AuthenticationLoading());
    try {
      final result = await _facebookAuth.login();
      if (result.status != LoginStatus.success || result.accessToken == null) {
        emit(AuthenticationUnauthenticated(
            message: result.status == LoginStatus.cancelled
                ? null
                : 'Facebook sign-in failed. Please try again.'));
        return;
      }
      final facebookToken = result.accessToken!.tokenString;
      final credential = FacebookAuthProvider.credential(facebookToken);
      final userCred =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseIdToken = await userCred.user?.getIdToken();
      final email = userCred.user?.email ?? '';
      if (firebaseIdToken == null) {
        emit(AuthenticationUnauthenticated(
            message: 'Facebook sign-in failed. Please try again.'));
        return;
      }
      await _loginWithFirebaseToken(firebaseIdToken, email, emit);
    } catch (e) {
      debugPrint('[AuthBloc] Facebook sign-in error: $e');
      emit(AuthenticationUnauthenticated(
          message: 'Facebook sign-in failed. Please try again.'));
    }
  }

  /// Shared tail: exchange a Firebase ID token for a Servana session.
  ///
  /// Token-exchange logic lives in [AuthTokenExchanger] so it can be
  /// unit-tested without platform channels.
  Future<void> _loginWithFirebaseToken(
    String idToken,
    String fallbackEmail,
    Emitter<AuthenticationState> emit,
  ) async {
    final api = dpLocator<ServanaApiClient>();
    String? fcmToken;
    try {
      fcmToken = await FirebaseMessaging.instance.getToken();
    } catch (_) {}
    final result = await AuthTokenExchanger(api).exchange(
      idToken,
      fallbackEmail,
      fcmToken: fcmToken,
    );
    if (result.session != null) {
      await SessionService.saveSession(result.session!);
      _notifyFcmLogin(result.session!.customerID);
      _notify(AuthStatus.authenticated);
      emit(AuthenticationAuthenticated());
    } else {
      emit(AuthenticationUnauthenticated(message: result.error));
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
        _notifyFcmLogin(session.customerID);
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
      dpLocator<MessagingStore>().resetPrivateData();
      dpLocator<AirconBookingStore>().reset();
      dpLocator<BwBookingStore>().reset();
      dpLocator<BookingDraftService>().clear();
      CategoryRevealPolicy.reset();
      SearchController.clearHistoryOnLogout().ignore();
      dpLocator<ProfileController>().resetPrivateData();
      dpLocator<AddressController>().resetPrivateData();
      dpLocator<SearchRepository>().clearCache();
    } catch (_) {}
    // FCM + notification cleanup (non-blocking; deactivates device token).
    try {
      dpLocator<NotificationsController>().clearOnLogout();
      await dpLocator<FcmCoordinator>().deactivateOnLogout();
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

  void _notifyFcmLogin(String uid) {
    try {
      dpLocator<NotificationsController>().init(uid).ignore();
      dpLocator<FcmCoordinator>().registerForAccount(uid).ignore();
      dpLocator<MessagingStore>().initForSession().ignore();
    } catch (_) {}
  }
}
