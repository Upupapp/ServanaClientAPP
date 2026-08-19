import 'package:client/common/injectors/main_injector.dart';
import 'package:client/core/analytics/application/analytics_coordinator.dart';
import 'package:client/core/analytics/events/auth_events.dart';
import 'package:client/modules/registration/domain/repositories/registration_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/common/constants/defaults.dart';
import 'package:client/common/data/models/address_data_model.dart';
import 'package:client/common/data/models/barangay.dart';
import 'package:client/common/data/models/city.dart';
import 'package:client/common/data/models/province.dart';
import 'package:client/common/data/resources/data_state.dart';
import 'package:client/common/domain/use_cases/get_barangays_in_city_use_case.dart';
import 'package:client/common/domain/use_cases/get_cities_in_region_use_case.dart';
import 'package:client/common/domain/use_cases/get_provinces_use_case.dart';
import 'package:client/modules/registration/data/models/reg_form_error_model.dart';
import 'package:client/modules/registration/data/models/registration_form_model.dart';

import 'package:client/modules/registration/data/resources/form_state.dart'
    // ignore: library_prefixes
    as regFormSt;
import 'package:client/modules/registration/domain/use_cases/load_registration_from_local.dart';
import 'package:client/modules/registration/domain/use_cases/save_registration_to_local.dart';
import 'package:client/modules/registration/domain/use_cases/validate_registration_step1.dart';
import 'package:client/modules/registration/presentation/bloc/registration_events.dart';
import 'package:client/modules/registration/presentation/bloc/registration_states.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:client/common/services/error_message_mapper.dart';

class RegistrationBloc extends Bloc<RegistrationEvent, RegistrationState> {
  final SaveRegistrationToLocalUseCase saveRegistrationToLocalUseCase;
  final LoadRegistrationFromLocalUseCase loadRegistrationFromLocal;
  final ValidateRegistrationFormUseCase validateRegistrationFormUseCase;
  final RegistrationRepository repo;
  final GetBarangaysInCityUseCase getBarangaysInCityUseCase;
  final GetProvincesUseCase getProvincesUseCase;
  final GetCitiesInregionUseCase getCitiesInregionUseCase;

  RegistrationFormModel registration = const RegistrationFormModel();
  List<ProvinceModel> provinces = [];
  List<CityModel> cities = [];
  List<BarangayModel> barangays = [];

  final provinceDropdownKey = GlobalKey<FormFieldState>();
  final cityDropdownKey = GlobalKey<FormFieldState>();
  final barangayDropdownKey = GlobalKey<FormFieldState>();

  bool isToolTipShown = false;

  bool isPassVisible = false;
  bool isConfirmPassVisible = false;

  void _track(dynamic event) {
    try {
      dpLocator<AnalyticsCoordinator>().track(event).ignore();
    } catch (_) {}
  }

  RegistrationBloc({
    required this.saveRegistrationToLocalUseCase,
    required this.loadRegistrationFromLocal,
    required this.validateRegistrationFormUseCase,
    required this.repo,
    required this.getBarangaysInCityUseCase,
    required this.getProvincesUseCase,
    required this.getCitiesInregionUseCase,
  }) : super(const RegistrationInitialState()) {
    on<RegistrationEvent>((event, emit) async {
      switch (event) {
        case LoadCachedRegistrationForm():
          await onLoadCachedRegistrationForm(event, emit);
          break;
        case SubmitRegistrationForm():
          await onSubmitRegistrationForm(event, emit);
          break;
        case SaveRegistrationFormToCache():
          await onSaveRegistrationFormToCache(event, emit);
          break;
        case ValidateRegistrationForm():
          // await onValidateRegistrationForm(event, emit);
          break;
        case PickedListPicture():
          await onPickedListPicture(event, emit);
        case ValidationReset():
          await onValidationReset(event, emit);
        case PickedBannerPicture():
          await onPickedBannerPicture(event, emit);
        case PickedMapLocation():
          await onPickedMapLocation(event, emit);
        case InitializeRegistrationForm():
          await onInitializeRegistrationForm(event, emit);
        case BarangaySelectedRegistrationForm():
          // TODO: Handle this case.
          break;
        case CitySelectedRegistrationForm():
          await onCitySelectedRegistrationForm(event, emit);
          break;
        case PickedCOR():
          await onPickedCOR(event, emit);
        case PickedPermit():
          await onPickedPermit(event, emit);
        case PickedBIR2302():
          await onPickedBIR2302(event, emit);
        case PickedBankCert():
          await onPickedBankCert(event, emit);
        case PickedAccountHolderIdFront():
          await onPickedAccountHolderIdFront(event, emit);
        case PickedAccountHolderIdBack():
          await onPickedAccountHolderIdBack(event, emit);
        case PickedAuthorizedPersonIdFront():
          await onPickedAuthorizedPersonIdFront(event, emit);
        case PickedAuthorizedPersonIdBack():
          await onPickedAuthorizedPersonIdBack(event, emit);
        case PassVisibilityToggled():
          onPassVisibilityToggled(event, emit);
        case ConfirmPassVisibilityToggled():
          onConfirmPassVisibilityToggled(event, emit);
        case ProvinceSelectedRegistrationForm():
          await onProvinceSelectedRegistrationForm(event, emit);
        case ResendVerificationEmail():
          await onResendVerificationEmail(event, emit);
      }
    });
  }

  Future<void> onPassVisibilityToggled(
      PassVisibilityToggled event, Emitter<RegistrationState> emit) async {
    isPassVisible = !isPassVisible;
    emit(RegistrationLoadedState(
      registration: registration,
    ));
  }

  Future<void> onConfirmPassVisibilityToggled(
      ConfirmPassVisibilityToggled event,
      Emitter<RegistrationState> emit) async {
    isConfirmPassVisible = !isConfirmPassVisible;
    emit(RegistrationLoadedState(
      registration: registration,
    ));
  }

  Future<void> onPickedAuthorizedPersonIdFront(
      PickedAuthorizedPersonIdFront event,
      Emitter<RegistrationState> emit) async {
    registration =
        registration.copyWith(authorizedPersonelIdFrontFile: event.picture);
    emit(RegistrationLoadedState(
      registration: registration,
    ));
  }

  Future<void> onPickedAuthorizedPersonIdBack(
      PickedAuthorizedPersonIdBack event,
      Emitter<RegistrationState> emit) async {
    registration =
        registration.copyWith(authorizedPersonelIdBackFile: event.picture);
    emit(RegistrationLoadedState(
      registration: registration,
    ));
  }

  Future<void> onPickedBankCert(
      PickedBankCert event, Emitter<RegistrationState> emit) async {
    registration = registration.copyWith(bankCertificateFile: event.file);
    emit(RegistrationLoadedState(
      registration: registration,
    ));
  }

  Future<void> onPickedAccountHolderIdFront(
      PickedAccountHolderIdFront event, Emitter<RegistrationState> emit) async {
    registration =
        registration.copyWith(bankAccountHolderIdFrontFile: event.picture);
    emit(RegistrationLoadedState(
      registration: registration,
    ));
  }

  Future<void> onPickedAccountHolderIdBack(
      PickedAccountHolderIdBack event, Emitter<RegistrationState> emit) async {
    registration =
        registration.copyWith(bankAccountHolderIdBackFile: event.picture);
    emit(RegistrationLoadedState(
      registration: registration,
    ));
  }

  Future<void> onPickedCOR(
      PickedCOR event, Emitter<RegistrationState> emit) async {
    registration =
        registration.copyWith(certificateOfRegistrationFile: event.file);
    emit(RegistrationLoadedState(
      registration: registration,
    ));
  }

  Future<void> onPickedPermit(
      PickedPermit event, Emitter<RegistrationState> emit) async {
    registration = registration.copyWith(businessPermitFile: event.file);
    emit(RegistrationLoadedState(
      registration: registration,
    ));
  }

  Future<void> onPickedBIR2302(
      PickedBIR2302 event, Emitter<RegistrationState> emit) async {
    registration = registration.copyWith(bir2303File: event.file);
    emit(RegistrationLoadedState(
      registration: registration,
    ));
  }

  Future<void> onProvinceSelectedRegistrationForm(
      ProvinceSelectedRegistrationForm event,
      Emitter<RegistrationState> emit) async {
    provinceDropdownKey.currentState?.reset();
    barangayDropdownKey.currentState?.reset();
    cityDropdownKey.currentState?.reset();
    emit(const RegistrationLoadingState());
    var province =
        provinces.firstWhere((element) => event.key.contains(element.name));

    registration = registration.copyWith(
        city: null, barangay: null, province: province.name);

    emit(
      RegistrationLoadedState(registration: registration),
    );

    var cityRes = await getCitiesInregionUseCase.call(params: province.code);
    cities.clear();
    cities.addAll(cityRes);

    var barangayRes = await getBarangaysInCityUseCase.call(
        params: DefaultValues.defaultCityCode);
    barangays.clear();
    barangays.addAll(barangayRes);

    emit(
      RegistrationInitialState(registration: registration),
    );
  }

  Future<void> onCitySelectedRegistrationForm(
      CitySelectedRegistrationForm event,
      Emitter<RegistrationState> emit) async {
    barangayDropdownKey.currentState?.reset();
    emit(const RegistrationLoadingState());
    var city = cities.firstWhere((element) => event.key.contains(element.name));

    registration = registration.copyWith(
      city: city.name,
      barangay: null,
    );

    emit(
      RegistrationLoadedState(registration: registration),
    );

    var barangayRes = await getBarangaysInCityUseCase.call(params: city.code);
    barangays.clear();
    barangays.addAll(barangayRes);

    emit(
      RegistrationInitialState(registration: registration),
    );
  }

  Future<void> onInitializeRegistrationForm(
      InitializeRegistrationForm event, Emitter<RegistrationState> emit) async {
    _track(const RegistrationStartedEvent(entrySource: 'registration_screen'));
    emit(const RegistrationLoadingState());
    var barangayRes = await getBarangaysInCityUseCase.call(
        params: DefaultValues.defaultRegionCode);
    barangays.clear();
    barangays.addAll(barangayRes);
    var cityRes = await getCitiesInregionUseCase.call(
        params: DefaultValues.defaultCityCode);
    cities.clear;
    cities.addAll(cityRes);
    var provinceRes = await getProvincesUseCase.call();
    provinces.clear;
    provinces.addAll(provinceRes);

    var dataState = await loadRegistrationFromLocal.call();

    if (dataState.data != null) {
      registration = dataState.data!;

      if (registration.businessLocationCoordinates != null) {
        var address = AddressDataModel(
          barangay: registration.barangay,
          city: registration.city,
          country: registration.country,
          locationCoordinates: registration.businessLocationCoordinates,
          province: registration.province,
          postalCode: registration.postalCode,
          streetAddress: registration.streetAddress,
        );
        await loadLocalityDropdown(address);
      }

      emit(
        RegistrationLoadedFromCacheState(registration: registration),
      );
    } else {
      emit(
        RegistrationInitialState(registration: registration),
      );
    }
  }

  Future<void> onValidationReset(
      ValidationReset event, Emitter<RegistrationState> emit) async {
    if (event.errorModel != null) {
      regFormSt.FormState formState = regFormSt.FormInvalid(event.errorModel!);
      emit(
        RegistrationValidationResetState(
            registration: registration, formState: formState),
      );
    } else {
      emit(
        RegistrationInitialState(registration: registration),
      );
    }
  }

  Future<void> onPickedMapLocation(
      PickedMapLocation event, Emitter<RegistrationState> emit) async {
    provinceDropdownKey.currentState?.reset();
    barangayDropdownKey.currentState?.reset();
    cityDropdownKey.currentState?.reset();
    var address = event.addressDataModel;

    await loadLocalityDropdown(address);

    registration = registration.copyWith(
      city: address.city,
      barangay: address.barangay,
      streetAddress: address.streetAddress,
      businessLocationCoordinates: address.locationCoordinates,
      postalCode: address.postalCode,
      province: address.province,
    );

    emit(RegistrationLoadedState(
      registration: registration,
    ));
  }

  Future<void> loadLocalityDropdown(AddressDataModel address) async {
    var provinces = await getProvincesUseCase.call();
    var province = provinces
        .firstWhereOrNull((element) => element.name == address.province);
    var cityRes = await getCitiesInregionUseCase.call(
        params: province?.code ?? DefaultValues.defaultRegionCode);
    cities.clear();
    cities.addAll(cityRes);
    var city =
        cities.firstWhereOrNull((element) => element.name == address.city);
    var barRes = await getBarangaysInCityUseCase.call(
        params: city?.code ?? DefaultValues.defaultCityCode);
    barangays.clear();
    barangays.addAll(barRes);

    /// check if barangay exist in list, otherwise will add in list
    var isInBarangayList = barangays
        .where((element) => element.name == address.barangay)
        .isNotEmpty;

    if (address.barangay != null && !isInBarangayList) {
      barangays.add(
        BarangayModel(
            code: '000000',
            name: address.barangay!,
            provinceCode: '000000',
            cityCode: '000000',
            regionCode: '000000'),
      );
    }

    /// check if city exist in list, otherwise will add in list
    var isInCityList =
        cities.where((element) => element.name == address.city).isNotEmpty;

    if (address.city != null && !isInCityList) {
      cities.add(
        CityModel(
          code: '000000',
          name: address.city!,
          provinceCode: '000000',
          psgc: '000000',
          region: '000000',
        ),
      );
    }

    /// check if province exist in list, otherwise will add in list
    var isInProvinceList = provinces
        .where((element) => element.name == address.province)
        .isNotEmpty;

    if (address.province != null && !isInProvinceList) {
      provinces.add(
        ProvinceModel(
          code: '000000',
          name: address.province!,
          psgc: '000000',
          regionCode: '000000',
        ),
      );
    }
  }

  Future<void> onPickedListPicture(
      PickedListPicture event, Emitter<RegistrationState> emit) async {
    registration = registration.copyWith(listPicture: event.picture);
    emit(RegistrationLoadedState(
      registration: registration,
    ));
  }

  Future<void> onPickedBannerPicture(
      PickedBannerPicture event, Emitter<RegistrationState> emit) async {
    registration = registration.copyWith(bannerPicture: event.picture);
    emit(RegistrationLoadedState(
      registration: registration,
    ));
  }

  Future<void> onSubmitRegistrationForm(
      SubmitRegistrationForm event, Emitter<RegistrationState> emit) async {
    regFormSt.FormState formState =
        const regFormSt.FormInvalid(RegFormErrorModel());
    emit(const RegistrationLoadingState());
    switch (event.step) {
      case 1:
        formState = await validateRegistrationFormUseCase.call(
            params: event.registration);
        break;
    }

    switch (formState) {
      case regFormSt.FormValid():
        try {
          final res = await repo.submitRegistration(registration: registration);

          if (res.isSuccess) {
            _track(const RegistrationSucceededEvent());
            emit(RegistrationSubmittedState(
                registration: event.registration, formState: formState));
            await saveRegistrationToLocalUseCase.call(
                params: event.registration);
          } else {
            _track(const RegistrationFailedEvent(failureCode: 'api_error'));
            emit(RegistrationSubmittedFailedState(
              registration: event.registration,
              formState: formState,
              // Was `res.message ?? 'Error occurred'` — the raw backend
              // string, straight onto the screen. ErrorMessageMapper exists
              // to stop exactly that and had no caller.
              error: ErrorMessageMapper.forRegistration(
                res.message,
                statusCode: res.statusCode,
              ),
            ));
          }
        } catch (e) {
          _track(const RegistrationFailedEvent(failureCode: 'exception'));
          emit(RegistrationSubmittedFailedState(
            registration: event.registration,
            formState: formState,
            // An exception here is ours, not the customer's. Its toString()
            // is a developer artefact and must not be shown.
            error: ErrorMessageMapper.forServerError(),
          ));
        }
        break;
      case regFormSt.FormInvalid():
        emit(
          RegistrationValidationFailedState(
            registration: event.registration,
            formState: formState,
          ),
        );
        break;
    }
  }

  // Future<void> onValidateRegistrationForm(
  //     ValidateRegistrationForm event, Emitter<RegistrationState> emit) async {
  //   var formState =
  //       await validateRegistrationFormUseCase.call(params: event.registration);

  //   switch (formState) {
  //     case FormValid():
  //       emit(RegistrationFormValidState(
  //           registration: event.registration, formState: formState));
  //       break;
  //     case FormInvalid():
  //       emit(
  //         RegistrationValidationFailedState(
  //           registration: event.registration,
  //           formState: formState,
  //         ),
  //       );
  //       break;
  //     // TODO: Handle this case.
  //   }
  // }

  Future<void> onSaveRegistrationFormToCache(SaveRegistrationFormToCache event,
      Emitter<RegistrationState> emit) async {
    regFormSt.FormState formState =
        const regFormSt.FormInvalid(RegFormErrorModel());
    emit(const RegistrationLoadingState());
    switch (event.step) {
      case 1:
        formState = await validateRegistrationFormUseCase.call(
            params: event.registration);
        break;

      default:
        formState = const regFormSt.FormValid();
    }

    switch (formState) {
      case regFormSt.FormValid():
        await saveRegistrationToLocalUseCase.call(params: event.registration);
        emit(const RegistrationSavedToCacheState());
        break;
      case regFormSt.FormInvalid():
        emit(
          RegistrationValidationFailedState(
            registration: event.registration,
            formState: formState,
          ),
        );
        break;
    }
  }

  Future<void> onLoadCachedRegistrationForm(
      LoadCachedRegistrationForm event, Emitter<RegistrationState> emit) async {
    var dataState = await loadRegistrationFromLocal.call();

    switch (dataState) {
      case DataSuccess():
        if (dataState.data != null) {
          registration = dataState.data!;

          emit(RegistrationLoadedFromCacheState(registration: dataState.data!));
        }
      case DataFailed():
        emit(
          RegistrationLoadedFromCacheFailedState(
            error: dataState.error?.toString() ??
                "Failed to save to local storage. Please check you permissions.",
          ),
        );
    }
  }

  Future<void> onResendVerificationEmail(
      ResendVerificationEmail event, Emitter<RegistrationState> emit) async {
    emit(const ResendVerificationLoadingState());
    try {
      final res = await repo.resendVerificationEmail(email: event.email);
      if (res.isSuccess) {
        emit(ResendVerificationSuccessState(
            message: res.message ?? 'Verification email sent.'));
      } else {
        emit(ResendVerificationFailedState(
            error: res.message ?? 'Failed to resend verification email.'));
      }
    } catch (e) {
      emit(ResendVerificationFailedState(error: e.toString()));
    }
  }
}
