import 'package:client/core/analytics/application/analytics_coordinator.dart';
import 'package:client/core/analytics/application/consent_gate_service.dart';
import 'package:client/core/analytics/application/experiment_coordinator.dart';
import 'package:client/core/analytics/data/firebase_analytics_service.dart';
import 'package:client/core/observability/crashlytics_service.dart';
import 'package:client/core/observability/performance_service.dart';
import 'package:client/core/recovery/app_lifecycle_coordinator.dart';
import 'package:client/core/recovery/connectivity_monitor.dart';
import 'package:client/core/recovery/draft_repository.dart';
import 'package:client/core/recovery/operation_journal.dart';
import 'package:client/core/recovery/pending_payment_service.dart';
import 'package:client/core/recovery/session_generation_coordinator.dart';
import 'package:client/modules/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:client/modules/tracking/application/tracking_controller.dart';
import 'package:client/modules/tracking/data/tracking_data_source.dart';
import 'package:client/modules/tracking/data/tracking_repository.dart';
import 'package:client/modules/homepage/presentation/stores/hompage_store.dart';
import 'package:client/modules/job_order/presentation/blocs/job_order_bloc.dart';
import 'package:client/modules/messaging/data/services/chat_socket_service.dart';
import 'package:client/modules/bookings/data/booking_repository.dart';
import 'package:client/modules/messaging/domain/repositories/messaging_repository.dart';
import 'package:client/modules/messaging/presentation/stores/messaging_store.dart';
import 'package:client/modules/registration/domain/use_cases/load_registration_from_local.dart';
import 'package:client/modules/registration/domain/use_cases/save_registration_to_local.dart';
import 'package:client/modules/registration/domain/use_cases/validate_registration_step1.dart';
import 'package:client/modules/registration/presentation/bloc/registration_bloc.dart';
import 'package:client/modules/store_items/domain/use_cases/get_store_items_use_case.dart';
import 'package:client/modules/store_items/domain/use_cases/get_store_options_use_case.dart';
import 'package:client/modules/store_items/presentation/bloc/store_items_bloc.dart';
import 'package:client/modules/store_items/presentation/bloc/store_options_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:client/common/domain/use_cases/get_barangays_in_city_use_case.dart';
import 'package:client/common/domain/use_cases/get_cities_in_region_use_case.dart';
import 'package:client/common/domain/use_cases/get_provinces_use_case.dart';
import 'package:client/common/config/app_config.dart';
import 'package:client/common/data/backend/backend.dart';
import 'package:client/common/data/backend/http_backend.dart';
import 'package:client/common/data/backend/mock_backend.dart';
import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/common/data/repositories/address_repository.dart';
import 'package:client/common/domain/booking/booking_draft_service.dart';
import 'package:client/common/domain/helpers/session_service.dart';
import 'package:client/common/services/auth_state_service.dart';
import 'package:client/modules/aircon_booking/data/aircon_booking_store.dart';
import 'package:client/modules/bw_booking/data/bw_booking_store.dart';
import 'package:client/common/services/location_service.dart';
import 'package:client/modules/authentication/domain/authentication_repo.dart';
import 'package:client/modules/homepage/data/repositories/home_repo.dart.dart';
import 'package:client/modules/job_order/domain/repositories/jo_repo.dart';
import 'package:client/modules/registration/domain/repositories/registration_repository.dart';
import 'package:client/modules/store_items/domain/repositories/store_items_repo.dart';
import 'package:client/modules/store_items/domain/repositories/store_options_repo.dart';
import 'package:client/modules/categories/data/category_experience_repository.dart';
import 'package:client/modules/notifications/application/fcm_coordinator.dart';
import 'package:client/modules/notifications/application/notification_navigation_coordinator.dart';
import 'package:client/modules/notifications/application/notification_permission_coordinator.dart';
import 'package:client/modules/notifications/application/notifications_controller.dart';
import 'package:client/modules/notifications/data/notifications_local_data_source.dart';
import 'package:client/modules/notifications/data/notifications_remote_data_source.dart';
import 'package:client/modules/notifications/data/notifications_repository.dart';
import 'package:client/modules/search/application/search_controller.dart';
import 'package:client/modules/search/data/search_repository.dart';
import 'package:client/modules/profile/application/address_controller.dart';
import 'package:client/modules/profile/application/profile_controller.dart';
import 'package:client/modules/profile/data/profile_repository.dart';
import 'package:client/modules/settings/application/settings_controller.dart';
import 'package:client/modules/review/application/review_detail_controller.dart';
import 'package:client/modules/review/application/review_form_controller.dart';
import 'package:client/modules/review/data/reviews_repository.dart';
import 'package:client/modules/support/application/support_controller.dart';
import 'package:client/modules/support/application/support_create_controller.dart';
import 'package:client/modules/support/application/support_ticket_controller.dart';
import 'package:client/modules/support/data/support_draft_repository.dart';
import 'package:client/modules/support/data/support_repository.dart';
import 'package:client/common/services/threat_detection/provider/threat_detection_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final dpLocator = GetIt.instance;

void initInjector(AppConfig config) {
  dpLocator.registerSingleton<AppConfig>(config);

  // ── C24 Security / Threat Detection ──────────────────────────────────────
  dpLocator.registerLazySingleton(() => ThreatDetectionProvider());

  // ── C21 Analytics & Observability ────────────────────────────────────────
  dpLocator.registerLazySingleton(() => FirebaseAnalyticsService());
  dpLocator.registerLazySingleton(
    () => AnalyticsCoordinator(service: dpLocator()),
  );
  dpLocator.registerLazySingleton(
    () => ExperimentCoordinator(analytics: dpLocator()),
  );
  dpLocator.registerLazySingleton(() => CrashlyticsService());
  dpLocator.registerLazySingleton(() => PerformanceService());
  // C24: Consent gate — singleton so dialog fires exactly once per install.
  dpLocator.registerLazySingleton(() => ConsentGateService());

  // ── Encrypted storage — registered early so recovery layer can inject it ──
  dpLocator.registerLazySingleton(
    () => const FlutterSecureStorage(),
  );

  // ── C20 Recovery layer ────────────────────────────────────────────────────
  dpLocator.registerLazySingleton(() => ConnectivityMonitor());
  dpLocator.registerLazySingleton(() => SessionGenerationCoordinator());
  dpLocator.registerLazySingleton(
    () => DraftRepository(storage: dpLocator()),
  );
  dpLocator.registerLazySingleton(
    () => OperationJournal(storage: dpLocator()),
  );
  dpLocator.registerLazySingleton(() => PendingPaymentService());
  dpLocator.registerLazySingleton(
    () => AppLifecycleCoordinator(
      connectivity: dpLocator(),
      // STITCH-C20-POST-002: refresh messaging state after app returns to
      // foreground — socket may have missed messages while backgrounded.
      // STITCH WARN-02: guard with auth state so unauthenticated resume
      // does not attempt to open a session-scoped socket.
      onResume: () {
        try {
          if (dpLocator<AuthStateService>().isAuthenticated) {
            dpLocator<MessagingStore>().initForSession().ignore();
          }
        } catch (_) {}
      },
    ),
  );

  // Auth state notifier — router and BLoC share this singleton.
  dpLocator.registerLazySingleton(() => AuthStateService());

  // Booking draft — lives in memory, cleared on logout / booking submit.
  dpLocator.registerLazySingleton(() => BookingDraftService());

  // Address repository — shared by both checkout screens.
  dpLocator.registerLazySingleton(
    () => AddressRepository(api: dpLocator()),
  );

  // SDK-ish services
  dpLocator.registerLazySingleton(() => LocationService());

  // Low-level HTTP client for Servana REST API (raw JSON).
  dpLocator.registerLazySingleton(
    () => ServanaApiClient(
      baseUrl: config.baseUrl,
      // STITCH B1: force session expiry on any 401 so the router redirects to login.
      onUnauthorized: () {
        try {
          dpLocator<AuthStateService>().update(AuthStatus.expired);
          SessionService.deleteSession().ignore();
        } catch (_) {}
      },
    ),
  );

  // Backend
  dpLocator.registerLazySingleton<Backend>(
    () => config.mockBackend
        ? MockBackend()
        : HttpBackend(baseUrl: config.baseUrl, apiClient: dpLocator()),
  );

  // Repositories
  dpLocator.registerLazySingleton(
      () => AuthenticationRepository(backend: dpLocator()));
  dpLocator.registerLazySingleton(
      () => RegistrationRepository(backend: dpLocator()));
  dpLocator.registerLazySingleton(
    () => HomeRepository(
      backend: dpLocator(),
      locationService: dpLocator(),
    ),
  );
  dpLocator
      .registerLazySingleton(() => JonOrderRepository(backend: dpLocator()));
  dpLocator.registerLazySingleton(
    () => BookingRepository(dpLocator()),
  );
  dpLocator.registerLazySingleton(
    () => MessagingRepository(api: dpLocator()),
  );
  dpLocator.registerLazySingleton(
    () => ChatSocketService(baseUrl: config.baseUrl),
  );
  dpLocator.registerLazySingleton(
    () => MessagingStore(
      repository: dpLocator(),
      socketService: dpLocator(),
    ),
  );
  dpLocator
      .registerLazySingleton(() => StoreItemsReporsitory(backend: dpLocator()));
  dpLocator.registerLazySingleton(
      () => StoreOptionsRepository(backend: dpLocator()));

  // BLoCs / Stores
  dpLocator.registerFactory(() => AuthenticationBloc(repo: dpLocator()));
  dpLocator.registerFactory(
      () => StoreOptionsBloc(getStoreOptionsUseCase: dpLocator()));
  dpLocator.registerFactory(() => StoreItemsBloc(
      getStoreItemsUseCase: dpLocator(), storeItemsRepo: dpLocator()));

  dpLocator.registerFactory(() => JobOrderBloc(repo: dpLocator()));
  dpLocator.registerFactory(
    () => RegistrationBloc(
      saveRegistrationToLocalUseCase: dpLocator(),
      loadRegistrationFromLocal: dpLocator(),
      validateRegistrationFormUseCase: dpLocator(),
      repo: dpLocator(),
      getBarangaysInCityUseCase: dpLocator(),
      getProvincesUseCase: dpLocator(),
      getCitiesInregionUseCase: dpLocator(),
    ),
  );

  dpLocator.registerLazySingleton(
    () => HomeStore(
      repo: dpLocator(),
      locationSerive: dpLocator(),
    ),
  );

  dpLocator.registerLazySingleton(
    () => AirconBookingStore(api: dpLocator()),
  );

  dpLocator.registerLazySingleton(
    () => BwBookingStore(api: dpLocator()),
  );

  dpLocator.registerLazySingleton(
    () => CategoryExperienceRepository(dpLocator()),
  );
  dpLocator.registerLazySingleton(
      () => GetStoreOptionsUseCase(storeOptionsRepository: dpLocator()));
  dpLocator.registerLazySingleton(
      () => GetStoreItemsUseCase(storeItemsRepo: dpLocator()));
  dpLocator.registerLazySingleton(() => SaveRegistrationToLocalUseCase());
  dpLocator.registerLazySingleton(() => LoadRegistrationFromLocalUseCase());
  dpLocator.registerLazySingleton(() => ValidateRegistrationFormUseCase());
  dpLocator.registerLazySingleton(() => GetBarangaysInCityUseCase());
  dpLocator.registerLazySingleton(() => GetProvincesUseCase());
  dpLocator.registerLazySingleton(() => GetCitiesInregionUseCase());

  // dpLocator.registerLazySingleton(() => AuthenticateUserUsecase());

  dpLocator.registerLazySingleton(() => SettingsController());

  dpLocator.registerLazySingleton(
    () => ProfileRepository(api: dpLocator()),
  );
  dpLocator.registerLazySingleton(
    () => AddressController(repository: dpLocator(), api: dpLocator()),
  );
  dpLocator.registerLazySingleton(
    () => ProfileController(
      repository: dpLocator(),
      addressController: dpLocator(),
    ),
  );

  dpLocator.registerLazySingleton(
    () => SearchRepository(api: dpLocator()),
  );
  dpLocator.registerLazySingleton(
    () => SearchController(repository: dpLocator()),
  );

  // Notifications
  dpLocator.registerLazySingleton(
    () => NotificationsRemoteDataSource(dpLocator()),
  );
  dpLocator.registerLazySingleton(
    () => NotificationsLocalDataSource(),
  );
  dpLocator.registerLazySingleton(
    () => NotificationsRepository(
      remote: dpLocator(),
      local: dpLocator(),
    ),
  );
  dpLocator.registerLazySingleton(
    () => NotificationsController(repository: dpLocator()),
  );
  dpLocator.registerLazySingleton(
    () => NotificationPermissionCoordinator(),
  );
  dpLocator.registerLazySingleton(
    () => NotificationNavigationCoordinator(),
  );
  dpLocator.registerLazySingleton(
    () => FcmCoordinator(
      repository: dpLocator(),
      notificationsController: dpLocator(),
      secureStorage: dpLocator(),
    ),
  );

  // ── Tracking (C16 LIVETRACK+) ─────────────────────────────────────────────
  dpLocator.registerLazySingleton(
    () => TrackingDataSource(dpLocator()),
  );
  dpLocator.registerLazySingleton(
    () => TrackingRepository(dpLocator()),
  );
  // Factory so each LiveTrackingScreen gets its own controller instance.
  dpLocator.registerFactory(
    () => TrackingController(repository: dpLocator()),
  );

  // ── Support (C18 SUPPORTCORE+) ────────────────────────────────────────────
  dpLocator.registerLazySingleton(
    () => SupportRepository(api: dpLocator()),
  );
  dpLocator.registerLazySingleton(
    () => SupportDraftRepository(),
  );
  dpLocator.registerLazySingleton(
    () => SupportController(repository: dpLocator()),
  );
  dpLocator.registerLazySingleton(
    () => SupportTicketController(
      repository: dpLocator(),
      supportController: dpLocator(),
    ),
  );
  dpLocator.registerLazySingleton(
    () => SupportCreateController(
      repository: dpLocator(),
      draftRepository: dpLocator(),
      supportController: dpLocator(),
    ),
  );

  // ── Reviews (C19 REVIEWCORE+) ─────────────────────────────────────────────
  dpLocator.registerLazySingleton(
    () => ReviewsRepository(api: dpLocator()),
  );
  dpLocator.registerLazySingleton(
    () => ReviewFormController(repository: dpLocator()),
  );
  dpLocator.registerLazySingleton(
    () => ReviewDetailController(repository: dpLocator()),
  );
}
