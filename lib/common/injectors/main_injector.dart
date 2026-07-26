import 'package:client/modules/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:client/modules/homepage/presentation/stores/hompage_store.dart';
import 'package:client/modules/job_order/presentation/blocs/job_order_bloc.dart';
import 'package:client/modules/messaging/domain/repositories/messaging_repository.dart';
import 'package:client/modules/messaging/presentation/bloc/messaging_bloc.dart';
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
import 'package:client/modules/search/application/search_controller.dart';
import 'package:client/modules/search/data/search_repository.dart';
import 'package:client/modules/settings/application/settings_controller.dart';

final dpLocator = GetIt.instance;

void initInjector(AppConfig config) {
  dpLocator.registerSingleton<AppConfig>(config);

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
    () => ServanaApiClient(baseUrl: config.baseUrl),
  );

  // Backend
  dpLocator.registerLazySingleton<Backend>(
    () => config.mockBackend
        ? MockBackend()
        : HttpBackend(baseUrl: config.baseUrl),
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
  dpLocator
      .registerLazySingleton(() => MessagingRepository(backend: dpLocator()));
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
  dpLocator.registerFactory(() => MessagingBloc(repo: dpLocator()));
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
    () => SearchRepository(api: dpLocator()),
  );
  dpLocator.registerLazySingleton(
    () => SearchController(repository: dpLocator()),
  );
}
