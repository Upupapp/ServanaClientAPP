import 'package:client/modules/homepage/presentation/controllers/home_campaign_controller.dart';
import 'package:client/common/services/threat_detection/provider/threat_detection_provider.dart';
import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/common/domain/auth/auth_token_exchanger.dart';
import 'package:client/common/domain/booking/booking_draft_service.dart';
import 'package:client/common/domain/helpers/session_service.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/services/auth_state_service.dart';
import 'package:client/core/analytics/application/analytics_coordinator.dart';
import 'package:client/core/analytics/application/experiment_coordinator.dart';
import 'package:client/core/analytics/domain/analytics_property.dart';
import 'package:client/core/analytics/domain/analytics_user_context.dart';
import 'package:client/core/analytics/events/auth_events.dart';
import 'package:client/core/observability/crashlytics_service.dart';
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
import 'package:client/modules/review/application/review_detail_controller.dart';
import 'package:client/modules/review/application/review_form_controller.dart';
import 'package:client/modules/support/application/support_controller.dart';
import 'package:client/modules/support/application/support_create_controller.dart';
import 'package:client/modules/support/application/support_ticket_controller.dart';
import 'package:client/modules/support/data/support_draft_repository.dart';
import 'package:client/core/recovery/draft_repository.dart';
import 'package:client/core/recovery/operation_journal.dart';
import 'package:client/core/recovery/pending_payment_service.dart';
import 'package:client/core/recovery/session_generation_coordinator.dart';
import 'package:client/core/accessibility/live_region_manager.dart';
import 'package:client/common/constants/boxes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
    _trackEvent(const SignInStartedEvent(authMethod: AuthMethodValues.email));

    final result = await repo.authenticate(
      email: event.email,
      password: event.password,
      fcmToken: event.fcmToken,
    );

    if (result.session != null) {
      await SessionService.saveSession(result.session!);
      _notifyFcmLogin(result.session!.customerID);
      _setAnalyticsUserContext(result.session!.customerID);
      _trackEvent(
          const SignInSucceededEvent(authMethod: AuthMethodValues.email));
      _notify(AuthStatus.authenticated);
      emit(AuthenticationAuthenticated());
    } else {
      final friendly = ErrorMessageMapper.forLogin(result.error);
      _trackEvent(SignInFailedEvent(
        authMethod: AuthMethodValues.email,
        failureCode: _mapLoginError(result.error),
      ));
      emit(AuthenticationUnauthenticated(message: friendly));
    }
  }

  Future<void> _onGoogleSignIn(
      AuthGoogleSignIn event, Emitter<AuthenticationState> emit) async {
    emit(AuthenticationLoading());
    _trackEvent(const SignInStartedEvent(authMethod: AuthMethodValues.google));
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
        _trackEvent(const SignInFailedEvent(
          authMethod: AuthMethodValues.google,
          failureCode: FailureCodeValues.unknown,
        ));
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
        _trackEvent(const SignInFailedEvent(
          authMethod: AuthMethodValues.google,
          failureCode: FailureCodeValues.unknown,
        ));
        emit(AuthenticationUnauthenticated(
            message: 'Google sign-in failed. Please try again.'));
        return;
      }
      await _loginWithFirebaseToken(firebaseIdToken, googleUser.email, emit);
    } catch (e) {
      debugPrint('[AuthBloc] Google sign-in error: $e');
      _trackEvent(const SignInFailedEvent(
        authMethod: AuthMethodValues.google,
        failureCode: FailureCodeValues.networkError,
      ));
      emit(AuthenticationUnauthenticated(
          message: 'Google sign-in failed. Please try again.'));
    }
  }

  Future<void> _onFacebookSignIn(
      AuthFacebookSignIn event, Emitter<AuthenticationState> emit) async {
    emit(AuthenticationLoading());
    _trackEvent(
        const SignInStartedEvent(authMethod: AuthMethodValues.facebook));
    try {
      final result = await _facebookAuth.login();
      if (result.status != LoginStatus.success || result.accessToken == null) {
        // Only track non-cancellation failures — user-cancelled is intentional.
        if (result.status != LoginStatus.cancelled) {
          _trackEvent(const SignInFailedEvent(
            authMethod: AuthMethodValues.facebook,
            failureCode: FailureCodeValues.unknown,
          ));
        }
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
        _trackEvent(const SignInFailedEvent(
          authMethod: AuthMethodValues.facebook,
          failureCode: FailureCodeValues.unknown,
        ));
        emit(AuthenticationUnauthenticated(
            message: 'Facebook sign-in failed. Please try again.'));
        return;
      }
      await _loginWithFirebaseToken(firebaseIdToken, email, emit);
    } catch (e) {
      debugPrint('[AuthBloc] Facebook sign-in error: $e');
      _trackEvent(const SignInFailedEvent(
        authMethod: AuthMethodValues.facebook,
        failureCode: FailureCodeValues.networkError,
      ));
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
      _setAnalyticsUserContext(result.session!.customerID);
      _trackEvent(
          SignInSucceededEvent(authMethod: _authMethodFromIdToken(idToken)));
      _notify(AuthStatus.authenticated);
      emit(AuthenticationAuthenticated());
    } else {
      _trackEvent(SignInFailedEvent(
        authMethod: _authMethodFromIdToken(idToken),
        failureCode: FailureCodeValues.unknown,
      ));
      emit(AuthenticationUnauthenticated(message: result.error));
    }
  }

  static String _authMethodFromIdToken(String token) {
    // Firebase ID tokens from Google have 'google.com' in the token's iss claim.
    // We can't decode JWT here without a package, so use length heuristic.
    // This is analytics-only — not a security boundary.
    return 'social';
  }

  Future<void> _onBrowseAsGuest(
      AuthBrowseAsGuest event, Emitter<AuthenticationState> emit) async {
    _trackEvent(const GuestModeSelectedEvent());
    _notify(AuthStatus.guest);
    emit(AuthenticationGuest());
  }

  Future<void> _onCheckSession(
      AuthCheckSession event, Emitter<AuthenticationState> emit) async {
    // No Loading state — passive session restore should be silent.
    // Only user-initiated actions (login, logout) emit Loading.
    try {
      // STITCH-C20-POST-003: capture generation before async gap so concurrent
      // logout (which advances the generation) invalidates this in-flight check.
      final capturedGen = dpLocator<SessionGenerationCoordinator>().current;
      final session = await SessionService.getSession();
      if (!dpLocator<SessionGenerationCoordinator>().isValid(capturedGen)) {
        // A logout fired concurrently — discard this stale session check.
        return;
      }
      if (session != null && session.token.isNotEmpty) {
        _notifyFcmLogin(session.customerID);
        _setAnalyticsUserContext(session.customerID); // STITCH WARN-01
        // STITCH B2: load payment context BEFORE emitting so the BlocListener
        // in home_screen.dart can call consume() and see the value.
        // If emit() fires first, the async gap lets the listener run before
        // setPending(), meaning consume() always returns null.
        try {
          final ctx = await dpLocator<DraftRepository>()
              .loadPaymentContext(session.customerID);
          if (ctx != null) {
            dpLocator<PendingPaymentService>().setPending(ctx);
          }
        } catch (_) {}
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
    _trackEvent(const LoggedOutEvent(trigger: 'user_action'));
    emit(AuthenticationLoading());
    // C20 LEAKSHIELD: capture UID before session is deleted so
    // DraftRepository/OperationJournal clears fire with a valid key.
    var logoutUid = '';
    try {
      final session = await SessionService.getSession();
      logoutUid = session?.customerID ?? '';
    } catch (_) {}
    try {
      await repo.logout();
    } catch (_) {
      // Logout is best-effort; always clear local state.
    }
    await SessionService.deleteSession();
    // Set guest status immediately after session deletion so that any 401 fired
    // by subsequent cleanup API calls (e.g. FCM token deactivation) does NOT
    // trigger onUnauthorized → AuthStatus.expired, which would show "Session
    // expired" UI during a voluntary logout.
    _notify(AuthStatus.guest);
    // End the FIREBASE session too, not just the Servana one.
    //
    // Nothing in this app signed out of Firebase, so FirebaseAuth.currentUser
    // survived a logout. That was a latent leak on shared devices; it became a
    // live cross-user path once the API client began preferring the Firebase
    // token — customer A signs in with Google, logs out, customer B signs in
    // with email and password, and B's requests would carry A's credential.
    //
    // Best-effort: a failure here must not block a logout the customer asked
    // for. The API client independently refuses a Firebase token whose subject
    // does not match the active session, so this is one of two defences.
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    // LEAKSHIELD LEAK H-1: purge Hive registration box so the next user cannot
    // see Customer A's PII pre-populated in the registration form.
    try {
      if (Hive.isBoxOpen(Boxes.registration)) {
        await Hive.box(Boxes.registration).close();
      }
      await Hive.deleteBoxFromDisk(Boxes.registration);
    } catch (_) {}
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
      LiveRegionManager.clearCache();
      dpLocator<SupportController>().resetPrivateData();
      dpLocator<SupportCreateController>().resetPrivateData();
      dpLocator<SupportTicketController>().resetPrivateData();
      dpLocator<SupportDraftRepository>().clearAllDrafts().ignore();
      // A threat detected during one customer's session must not be attributed
      // to the next person who signs in on this device.
      dpLocator<ThreatDetectionProvider>().reset();
      // LAUNCHBANNER+ §25: cancel any pending campaign presentation and clear
      // the session flag. Persisted frequency history is account-scoped and
      // deliberately survives, so a permanent dismissal cannot be reset by
      // signing out and back in.
      dpLocator<HomeCampaignController>().resetSessionState();
      dpLocator<ReviewFormController>().resetPrivateData();
      dpLocator<ReviewDetailController>().resetPrivateData();
    } catch (_) {}
    // C20 Recovery layer — clear all UID-scoped state to prevent cross-account leakage.
    // LEAK M-1: clearAll() fallback covers the empty-UID case (session error at logout).
    try {
      dpLocator<PendingPaymentService>().clear();
      if (logoutUid.isNotEmpty) {
        dpLocator<DraftRepository>().clearAllForAccount(logoutUid).ignore();
        dpLocator<OperationJournal>().clearForAccount(logoutUid).ignore();
      } else {
        dpLocator<DraftRepository>().clearAll().ignore();
        dpLocator<OperationJournal>().clearAll().ignore();
      }
      dpLocator<SessionGenerationCoordinator>().advance();
    } catch (_) {}
    // FCM + notification cleanup (non-blocking; deactivates device token).
    try {
      dpLocator<NotificationsController>().clearOnLogout();
      await dpLocator<FcmCoordinator>().deactivateOnLogout();
    } catch (_) {}
    // C21: clear analytics identity and experiment context on logout.
    try {
      await dpLocator<AnalyticsCoordinator>().clearUserContext();
      dpLocator<ExperimentCoordinator>().clearOnLogout();
      await dpLocator<CrashlyticsService>().clearUserIdentifier();
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
      // REPEAT FAIL-03: log FCM registration errors instead of silently swallowing them.
      dpLocator<FcmCoordinator>().registerForAccount(uid).catchError((e) {
        debugPrint('[AuthBloc] FCM registration: ${e.runtimeType}');
      });
      dpLocator<MessagingStore>().initForSession().ignore();
    } catch (_) {}
  }

  // ── C21 Analytics helpers ──────────────────────────────────────────────────

  void _trackEvent(event) {
    try {
      dpLocator<AnalyticsCoordinator>().track(event).ignore();
    } catch (_) {}
  }

  void _setAnalyticsUserContext(String rawCustomerId) {
    try {
      final analyticsId = AnalyticsUserContext.deriveAnalyticsId(rawCustomerId);
      final ctx = AnalyticsUserContext(
        analyticsId: analyticsId,
        accountState: 'authenticated',
        lifecycleStage: 'active',
        profileCompletionBand: '0',
        hasCompletedBooking: false,
      );
      dpLocator<AnalyticsCoordinator>().setUserContext(ctx).ignore();
      dpLocator<CrashlyticsService>().setUserIdentifier(analyticsId).ignore();
      dpLocator<CrashlyticsService>().setKeys({
        'account_state': 'authenticated',
        'session_state': 'active',
      }).ignore();
    } catch (_) {}
  }

  static String _mapLoginError(String? error) {
    if (error == null || error.isEmpty) return FailureCodeValues.unknown;
    final e = error.toLowerCase();
    if (e.contains('invalid') && e.contains('credential')) {
      return FailureCodeValues.invalidCredentials;
    }
    if (e.contains('disabled')) return FailureCodeValues.accountDisabled;
    if (e.contains('network') || e.contains('socket')) {
      return FailureCodeValues.networkError;
    }
    if (e.contains('timeout')) return FailureCodeValues.timeout;
    return FailureCodeValues.unknown;
  }
}
