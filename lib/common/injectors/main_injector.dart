import 'package:firebase_auth/firebase_auth.dart';

import 'package:client/core/analytics/application/analytics_coordinator.dart';
import 'package:client/core/analytics/application/consent_gate_service.dart';
import 'package:client/modules/homepage/presentation/controllers/home_campaign_controller.dart';
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
import 'package:client/modules/bookings/data/bookings_canonical_data_source.dart';
import 'package:client/modules/bookings/data/bookings_compatibility_data_source.dart';
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
import 'package:client/modules/catalog/application/catalog_controller.dart';
import 'package:client/modules/catalog/application/service_detail_controller.dart';
import 'package:client/modules/catalog/data/catalog_canonical_data_source.dart';
import 'package:client/modules/catalog/data/catalog_repository.dart';
import 'package:client/modules/homepage/data/home_composition_canonical_data_source.dart';
import 'package:client/modules/homepage/data/home_composition_compatibility_data_source.dart';
import 'package:client/modules/homepage/data/home_composition_repository.dart';
import 'package:client/modules/homepage/domain/home_composition.dart';
import 'package:client/common/data/booking/booking_submission_service.dart';
import 'package:client/modules/search/data/search_canonical_data_source.dart';
import 'package:client/modules/search/data/search_compatibility_data_source.dart';
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
import 'package:client/core/network/canonical_availability.dart';
import 'package:client/core/network/compat/canonical_router.dart';
import 'package:client/core/network/v1_api_client.dart';
import 'package:client/core/session/secure_session_store.dart';
import 'package:client/core/session/session_cleanup_service.dart';
import 'package:client/core/session/session_token_store.dart';
import 'package:client/modules/authentication/data/identity_canonical_data_source.dart';
import 'package:client/modules/authentication/data/identity_compatibility_data_source.dart';
import 'package:client/modules/authentication/data/identity_repository.dart';
import 'package:client/modules/notifications/data/notifications_canonical_data_source.dart';
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

  // LAUNCHBANNER+ §26: a singleton, so "once per app session" survives Home
  // being rebuilt. A controller owned by the widget would reset its session
  // flag on every reconstruction and the campaign could reappear.
  dpLocator.registerLazySingleton(() => HomeCampaignController());

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
  // TAB 08 — one booking-create ceremony for every category flow. The
  // customer id is resolved from the session here, never handed in by a
  // screen; the legacy route still takes it as `?userId=`, which is the
  // endpoint's gap and not the caller's to fix.
  dpLocator.registerLazySingleton(
    () => BookingSubmissionService(
      api: dpLocator(),
      journal: dpLocator(),
      customerId: () async =>
          (await SessionService.getSession())?.customerID,
    ),
  );

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
      // The backend verifies a Firebase ID token, which lives one hour. The
      // session token is written once at sign-in and never renewed, so every
      // authenticated call used to start 401ing an hour in — and onUnauthorized
      // below would then sign the customer out mid-journey.
      //
      // getIdToken() returns the cached token and only performs a network
      // refresh when it is expired or nearly so, so this is cheap per request.
      tokenProvider: () async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return null;
        return user.getIdToken();
      },
      // STITCH B1: force session expiry on any 401 so the router redirects to login.
      onUnauthorized: () {
        try {
          dpLocator<AuthStateService>().update(AuthStatus.expired);
          SessionService.deleteSession().ignore();
        } catch (_) {}
      },
    ),
  );

  // Canonical /api/v1 transport.
  //
  // Registered unconditionally so it is constructible and testable, and gated
  // by CanonicalAvailability so it carries no traffic. The gate is deny-by-
  // default and can only be opened by a build define — never by the network.
  // /api/v1 is absent from the backend's origin/main, so no shipped build
  // enables it. See docs/convergence-v1/TAB02_MIGRATION_MANIFEST.md.
  dpLocator.registerLazySingleton(() => const CanonicalAvailability());
  dpLocator.registerLazySingleton(
    () => CanonicalRouter(availability: dpLocator()),
  );
  dpLocator.registerLazySingleton(
    () => V1ApiClient(
      // Same environment switch as every other call. No literal host.
      baseUrl: config.baseUrl,
      tokenProvider: () async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return null;
        return user.getIdToken();
      },
      // A 401 must mean the same thing on both transports, or the two would
      // disagree about whether the session is alive.
      onUnauthorized: () {
        try {
          dpLocator<AuthStateService>().update(AuthStatus.expired);
          SessionService.deleteSession().ignore();
        } catch (_) {}
      },
    ),
  );

  // Session hardening (TAB 03).
  //
  // SecureSessionStore is additive: it keeps credentials in flutter_secure_storage
  // with their own lifetime, alongside the existing Hive-backed SessionService
  // rather than replacing it. Rewriting the read path would break every
  // signed-in customer on the installed base, which still runs 1.0.0+37.
  dpLocator.registerLazySingleton(() => SecureSessionStore());
  // The one authority for token material: secure storage, with a verified
  // one-time migration of any legacy Hive token. Registered as a singleton so
  // the in-memory cache is shared rather than re-read per consumer.
  dpLocator.registerLazySingleton(() => SessionTokenStore(secure: dpLocator()));
  dpLocator.registerLazySingleton(() => const SessionCleanupService());

  // Identity: canonical /api/v1/me + verification, gated OFF; legacy otherwise.
  dpLocator.registerLazySingleton(
    () => IdentityCompatibilityDataSource(dpLocator()),
  );
  dpLocator.registerLazySingleton(
    () => IdentityCanonicalDataSource(dpLocator()),
  );
  dpLocator.registerLazySingleton(
    () => IdentityRepository(
      compatibility: dpLocator<IdentityCompatibilityDataSource>(),
      canonical: dpLocator<IdentityCanonicalDataSource>(),
      router: dpLocator(),
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
    // Both transports constructed; the router decides. With the bookings
    // capability unset — every build today — the legacy source answers.
    // READS only: there is no canonical booking create, and cancel is a
    // state-changing action that belongs to TAB 10.
    () => BookingRepository(
      dpLocator(),
      compatibility: BookingsCompatibilityDataSource(dpLocator()),
      canonical: BookingsCanonicalDataSource(dpLocator()),
      router: dpLocator(),
    ),
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

  // ── Canonical Catalog V2 ──────────────────────────────────────────────────
  //
  // The repository and the browse controller are singletons because the whole
  // hierarchy arrives in one fetch and is then shared by every catalog screen —
  // a per-screen instance would refetch on each push and defeat the single-read
  // design (§92).
  //
  // ServiceDetailController is a FACTORY. It holds the selected add-ons for one
  // Service, so sharing it would carry a previous Service's configuration onto
  // the next one.
  dpLocator.registerLazySingleton(
    // Both sources constructed; the router decides. With the catalog
    // capability unset — every build today — the compatibility source answers
    // and the canonical box is never written.
    () => CatalogRepository(
      api: dpLocator(),
      canonical: CatalogCanonicalDataSource(dpLocator()),
      router: dpLocator(),
    ),
  );
  dpLocator.registerLazySingleton(
    () => CatalogController(dpLocator()),
  );

  // ── Home composition (TAB 05) ──────────────────────────────────────────────
  //
  // Both transports are constructed and the router decides, exactly as catalog
  // and notifications do. With the `home` capability unset — every build today
  // — the compatibility source answers, so this registration moves no traffic.
  //
  // Only `categories` has a loader, and that is deliberate rather than
  // unfinished:
  //
  //  - featured/popular/recentServices have NO legacy endpoint. Reported
  //    absent, not failed: there is nothing to retry until /api/v1/home ships.
  //  - promotions/banners stays with HomeCampaignController, HomePromotionRepository
  //    and its Remote Config kill switch. The backend reports this section
  //    NOT_CONFIGURED on purpose — it has no promotions source and declines to
  //    invent one — so routing banners through the composition would move
  //    protected campaign creatives behind a transport that cannot serve them.
  //  - notificationSummary already has one owner in NotificationsController.
  //    A second unread count assembled here would be a duplicate truth.
  //
  // `categories` reads the canonical Catalog V2 hierarchy, so Home and the
  // catalog cannot disagree about what exists.
  dpLocator.registerLazySingleton(
    () => HomeCompositionRepository(
      compatibility: HomeCompositionCompatibilityDataSource(
        loaders: <HomeSectionType, HomeSectionLoader>{
          HomeSectionType.categories: () async {
            final categories = await dpLocator<CatalogRepository>().categories();
            return categories
                .map((c) => <String, dynamic>{
                      'id': c.id,
                      'name': c.name,
                      'slug': c.slug,
                      'displayOrder': c.displayOrder,
                      'description': c.description,
                      'imageUrl': c.imageUrl,
                      'subcategoryCount': c.subcategoryCount,
                      'serviceCount': c.serviceCount,
                    })
                .toList(growable: false);
          },
        },
      ),
      canonical: HomeCompositionCanonicalDataSource(dpLocator()),
      router: dpLocator(),
    ),
  );
  dpLocator.registerFactory(
    () => ServiceDetailController(dpLocator()),
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
    // Both transports constructed; the router decides. With the search
    // capability unset — every build today — the on-device index answers, and
    // `/api/v1/search` is never called.
    () => SearchRepository(
      compatibility: SearchCompatibilityDataSource(catalog: dpLocator()),
      canonical: SearchCanonicalDataSource(dpLocator()),
      router: dpLocator(),
    ),
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
    () => NotificationsCanonicalDataSource(dpLocator()),
  );
  // Both sources are constructed; the router decides which one answers. With
  // CANONICAL_V1_ENABLED unset — every build today — that is always the legacy
  // source, so this registration changes no runtime behaviour.
  dpLocator.registerLazySingleton(
    () => NotificationsRepository(
      remote: dpLocator(),
      local: dpLocator(),
      canonical: dpLocator<NotificationsCanonicalDataSource>(),
      router: dpLocator(),
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
