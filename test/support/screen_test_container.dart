/// A dependency container for rendering whole screens in a widget test.
///
/// ## The problem this solves
///
/// Sixty screens, and the viewport matrix could only reach four of them — the
/// ones that construct without touching `dpLocator`. Everything with a
/// controller behind it threw `GetIt: Object/factory with type X is not
/// registered` before it drew a single pixel, so the screens most likely to
/// overflow were exactly the ones no test could build.
///
/// ## Real objects over hand-written fakes, wherever possible
///
/// Each controller here is the REAL class, constructed over a repository whose
/// HTTP client answers an empty envelope. A hand-written fake would satisfy
/// the screen's expectations by construction and could not disagree with it —
/// the same failure that let five wrong request bodies survive 1901 passing
/// tests. A real controller over a dead network produces the empty and error
/// states a real screen actually meets.
///
/// One exception: **analytics**. The real coordinator needs a live Firebase
/// app, and a screen's tracking calls are not what a layout test is about.
///
/// ## Scope, stated rather than implied
///
/// This covers the types the screens in `screen_viewport_matrix_test.dart`
/// resolve. It is not the whole injector and does not pretend to be. A screen
/// whose dependency is missing fails with GetIt's own message naming the type,
/// which is the right outcome — it says exactly what to add here.
///
/// Screens that reach Firebase directly (notification permissions) or that
/// need a live MobX store graph (Home, the booking flows) are **not** covered
/// and are listed in the matrix as such rather than being quietly omitted.
library;

import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/services/auth_state_service.dart';
import 'package:client/core/analytics/application/analytics_coordinator.dart';
import 'package:client/modules/catalog/data/catalog_compatibility_data_source.dart';
import 'package:client/modules/catalog/data/catalog_repository.dart';
import 'package:client/modules/review/application/review_detail_controller.dart';
import 'package:client/modules/review/application/review_form_controller.dart';
import 'package:client/modules/review/data/reviews_compatibility_data_source.dart';
import 'package:client/modules/review/data/reviews_repository.dart';
import 'package:client/modules/search/application/search_controller.dart';
import 'package:client/modules/search/data/search_compatibility_data_source.dart';
import 'package:client/modules/search/data/search_repository.dart';
import 'package:client/modules/settings/application/settings_controller.dart';
import 'package:client/modules/support/application/support_controller.dart';
import 'package:client/modules/support/application/support_create_controller.dart';
import 'package:client/modules/support/data/support_draft_repository.dart';
import 'package:client/modules/support/data/support_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:client/common/data/repositories/address_repository.dart';
import 'package:client/modules/profile/application/address_controller.dart';
import 'package:client/modules/profile/application/profile_controller.dart';
import 'package:client/modules/profile/data/profile_repository.dart';
import 'package:client/common/data/backend/mock_backend.dart';
import 'package:client/modules/authentication/domain/authentication_repo.dart';
import 'package:client/modules/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:client/modules/homepage/data/repositories/home_repo.dart.dart';
import 'package:client/modules/homepage/presentation/stores/hompage_store.dart';
import 'package:client/common/services/location_service.dart';
import 'package:client/common/domain/booking/booking_draft_service.dart';
import 'package:client/modules/aircon_booking/data/aircon_booking_store.dart';
import 'package:client/modules/bw_booking/data/bw_booking_store.dart';
import 'package:client/modules/job_order/domain/repositories/jo_repo.dart';
import 'package:client/modules/job_order/presentation/blocs/job_order_bloc.dart';
import 'package:client/core/analytics/application/consent_gate_service.dart';
// NB: there are TWO classes named StoreItemsReporsitory. This is the one
// main_injector and StoreItemsBloc use; the merchant_menu copy is dead.
import 'package:client/modules/store_items/domain/repositories/store_items_repo.dart';
import 'package:client/modules/store_items/domain/use_cases/get_store_items_use_case.dart';
import 'package:client/modules/store_items/presentation/bloc/store_items_bloc.dart';
import 'package:client/modules/catalog/application/catalog_controller.dart';
import 'package:client/modules/catalog/application/service_detail_controller.dart';
import 'package:client/core/network/canonical_availability.dart';
import 'package:client/core/network/compat/canonical_router.dart';
import 'package:client/core/network/v1_api_client.dart';
import 'package:client/modules/authentication/data/identity_canonical_data_source.dart';
import 'package:client/modules/authentication/data/identity_compatibility_data_source.dart';
import 'package:client/modules/authentication/data/identity_repository.dart';
import 'package:client/modules/registration/domain/repositories/registration_repository.dart';
import 'package:client/modules/registration/domain/use_cases/load_registration_from_local.dart';
import 'package:client/modules/registration/domain/use_cases/save_registration_to_local.dart';
import 'package:client/modules/registration/domain/use_cases/validate_registration_step1.dart';
import 'package:client/modules/registration/presentation/bloc/registration_bloc.dart';
import 'package:client/common/domain/use_cases/get_barangays_in_city_use_case.dart';
import 'package:client/common/domain/use_cases/get_provinces_use_case.dart';
import 'package:client/common/domain/use_cases/get_cities_in_region_use_case.dart';
import 'package:client/modules/notifications/application/notification_permission_coordinator.dart';

/// Analytics that records nothing and reaches nothing.
///
/// `noSuchMethod` covers the rest of the surface so this does not have to be
/// rewritten every time the real coordinator gains a method — a layout test
/// has no opinion about any of them.
class NoOpAnalyticsCoordinator implements AnalyticsCoordinator {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

/// Answers every request with an empty success envelope.
///
/// Not an error and not a hang. A screen rendering its EMPTY state is the case
/// worth measuring; a thrown transport error would send half of them down an
/// error path instead of drawing their content, and a hang would time the test
/// out with nothing learned.
http.Client emptyBackend() => MockClient(
      (_) async => http.Response(
        '{"success":true,"status":"success","data":[]}',
        200,
        headers: <String, String>{'content-type': 'application/json'},
      ),
    );

/// Registers everything the covered screens resolve.
///
/// Call from `setUp`, and pair with [resetScreenDependencies] in `tearDown`.
/// GetIt is global: a registration that leaks between tests makes one test's
/// state another test's starting point.
Future<void> registerScreenDependencies() async {
  // Several controllers read preferences on construction or first build.
  SharedPreferences.setMockInitialValues(<String, Object>{});

  await resetScreenDependencies();

  final api = ServanaApiClient(
    baseUrl: 'https://api.example.test',
    client: emptyBackend(),
  );

  dpLocator.registerSingleton<ServanaApiClient>(api);
  dpLocator.registerSingleton<AnalyticsCoordinator>(NoOpAnalyticsCoordinator());
  dpLocator.registerSingleton<AuthStateService>(AuthStateService());
  dpLocator.registerSingleton<SettingsController>(SettingsController());

  // Saved addresses. Registered because SavedAddressesScreen resolves it on
  // build, and without it the screen cannot be rendered at any viewport.
  final addressRepository = AddressRepository(api: api);
  dpLocator.registerSingleton<AddressRepository>(addressRepository);
  final addressController =
      AddressController(repository: addressRepository, api: api);
  dpLocator.registerSingleton<AddressController>(addressController);

  // Profile. ProfileScreen resolves both of these on build.
  final profileRepository = ProfileRepository(api: api);
  dpLocator.registerSingleton<ProfileRepository>(profileRepository);
  dpLocator.registerSingleton<ProfileController>(
    ProfileController(
      repository: profileRepository,
      addressController: addressController,
    ),
  );

  // ── Support ───────────────────────────────────────────────────────────────
  final support = SupportRepository(api: api);
  dpLocator.registerSingleton<SupportRepository>(support);
  final supportController = SupportController(repository: support);
  dpLocator.registerSingleton<SupportController>(supportController);
  dpLocator.registerSingleton<SupportCreateController>(
    SupportCreateController(
      repository: support,
      draftRepository: SupportDraftRepository(),
      supportController: supportController,
    ),
  );

  // ── Reviews ───────────────────────────────────────────────────────────────
  final reviews = ReviewsRepository(
    api: api,
    compatibility: ReviewsCompatibilityDataSource(api),
  );
  dpLocator.registerSingleton<ReviewsRepository>(reviews);
  dpLocator.registerSingleton<ReviewFormController>(
    ReviewFormController(repository: reviews),
  );
  dpLocator.registerSingleton<ReviewDetailController>(
    ReviewDetailController(repository: reviews),
  );

  // ── The shell's own store ─────────────────────────────────────────────────
  // BookingsScreen, BookingCalendarScreen and MessagesInboxScreen all resolve
  // HomeStore. It was named as out of scope because it is MobX; in practice
  // it needs only a repository and a location service, both of which compose
  // from the MockBackend already used here.
  final locationService = LocationService();
  dpLocator.registerSingleton<LocationService>(locationService);
  dpLocator.registerSingleton<HomeStore>(
    HomeStore(
      repo: HomeRepository(
        backend: MockBackend(),
        locationService: locationService,
      ),
      locationSerive: locationService,
    ),
  );

  // WelcomeScreen gates on this; it takes nothing.
  dpLocator.registerSingleton<ConsentGateService>(ConsentGateService());

  // ── The booking flows ─────────────────────────────────────────────────────
  // The largest uncovered block, and the one nearest the money. Both stores
  // take only the api client; the draft service takes nothing.
  dpLocator.registerSingleton<BookingDraftService>(BookingDraftService());
  dpLocator.registerSingleton<AirconBookingStore>(AirconBookingStore(api: api));
  dpLocator.registerSingleton<BwBookingStore>(BwBookingStore(api: api));

  // ── Identity and registration ─────────────────────────────────────────────
  // The canonical side is constructed but never chosen: CanonicalAvailability
  // defaults to disabled, which is exactly what every shipped build does. The
  // router therefore always answers with the compatibility source here, the
  // same transport a real customer is on.
  dpLocator.registerSingleton<IdentityRepository>(
    IdentityRepository(
      compatibility: IdentityCompatibilityDataSource(api),
      canonical: IdentityCanonicalDataSource(
        V1ApiClient(
          baseUrl: 'https://example.invalid',
          httpClient: emptyBackend(),
        ),
      ),
      router: const CanonicalRouter(availability: CanonicalAvailability()),
    ),
  );
  dpLocator.registerFactory<RegistrationBloc>(
    () => RegistrationBloc(
      saveRegistrationToLocalUseCase: SaveRegistrationToLocalUseCase(),
      loadRegistrationFromLocal: LoadRegistrationFromLocalUseCase(),
      validateRegistrationFormUseCase: ValidateRegistrationFormUseCase(),
      repo: RegistrationRepository(backend: MockBackend()),
      getBarangaysInCityUseCase: GetBarangaysInCityUseCase(),
      getProvincesUseCase: GetProvincesUseCase(),
      getCitiesInregionUseCase: GetCitiesInregionUseCase(),
    ),
  );

  // PermissionsScreen resolves this; it takes nothing.
  dpLocator.registerSingleton<NotificationPermissionCoordinator>(
    NotificationPermissionCoordinator(),
  );

  // ── Catalog and search ────────────────────────────────────────────────────
  final catalog = CatalogRepository(
    api: api,
    compatibility: CatalogCompatibilityDataSource(api),
  );
  dpLocator.registerSingleton<CatalogRepository>(catalog);
  dpLocator.registerSingleton<CatalogController>(CatalogController(catalog));
  dpLocator.registerSingleton<ServiceDetailController>(
    ServiceDetailController(catalog),
  );
  dpLocator.registerSingleton<SearchController>(
    SearchController(
      repository: SearchRepository(
        compatibility: SearchCompatibilityDataSource(catalog: catalog),
      ),
    ),
  );
}

/// An [AuthenticationBloc] for the screens that sit under one.
///
/// Five screens build a `BlocBuilder<AuthenticationBloc, ...>` — profile,
/// authentication, splash, welcome and bookings. Without a provider above them
/// the build throws `ProviderNotFoundException`, and the three errors that
/// follow are consequences of that first one: the error box lands where a
/// sliver was expected, and the framework then trips two assertions tearing the
/// broken tree down. One missing provider, four exceptions.
///
/// The social sign-in dependencies are left at their defaults. They are
/// constructed but never invoked here, which is what makes that safe.
AuthenticationBloc buildTestAuthenticationBloc() => AuthenticationBloc(
      repo: AuthenticationRepository(backend: MockBackend()),
    );

/// A [StoreItemsBloc] for the merchant screens, which build under one.
StoreItemsBloc buildTestStoreItemsBloc() {
  final repo = StoreItemsReporsitory(backend: MockBackend());
  return StoreItemsBloc(
    getStoreItemsUseCase: GetStoreItemsUseCase(storeItemsRepo: repo),
    storeItemsRepo: repo,
  );
}

/// A [JobOrderBloc] for SelectPaymentMethodScreen, which builds under one.
///
/// Takes only a repository, which takes only a Backend — the same MockBackend
/// every other graph here composes from.
JobOrderBloc buildTestJobOrderBloc() =>
    JobOrderBloc(repo: JonOrderRepository(backend: MockBackend()));

/// Clears the container between tests.
Future<void> resetScreenDependencies() => dpLocator.reset();
