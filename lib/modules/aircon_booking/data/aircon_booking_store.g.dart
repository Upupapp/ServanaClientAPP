// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'aircon_booking_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$AirconBookingStore on _AirconBookingStore, Store {
  Computed<List<Map<String, dynamic>>>? _$bookableOptionsComputed;

  @override
  List<Map<String, dynamic>> get bookableOptions =>
      (_$bookableOptionsComputed ??= Computed<List<Map<String, dynamic>>>(
              () => super.bookableOptions,
              name: '_AirconBookingStore.bookableOptions'))
          .value;

  late final _$isLoadingAtom =
      Atom(name: '_AirconBookingStore.isLoading', context: context);

  @override
  bool get isLoading {
    _$isLoadingAtom.reportRead();
    return super.isLoading;
  }

  @override
  set isLoading(bool value) {
    _$isLoadingAtom.reportWrite(value, super.isLoading, () {
      super.isLoading = value;
    });
  }

  late final _$errorMessageAtom =
      Atom(name: '_AirconBookingStore.errorMessage', context: context);

  @override
  String? get errorMessage {
    _$errorMessageAtom.reportRead();
    return super.errorMessage;
  }

  @override
  set errorMessage(String? value) {
    _$errorMessageAtom.reportWrite(value, super.errorMessage, () {
      super.errorMessage = value;
    });
  }

  late final _$servicesAtom =
      Atom(name: '_AirconBookingStore.services', context: context);

  @override
  ObservableList<Map<String, dynamic>> get services {
    _$servicesAtom.reportRead();
    return super.services;
  }

  @override
  set services(ObservableList<Map<String, dynamic>> value) {
    _$servicesAtom.reportWrite(value, super.services, () {
      super.services = value;
    });
  }

  late final _$level2ServicesAtom =
      Atom(name: '_AirconBookingStore.level2Services', context: context);

  @override
  ObservableList<Map<String, dynamic>> get level2Services {
    _$level2ServicesAtom.reportRead();
    return super.level2Services;
  }

  @override
  set level2Services(ObservableList<Map<String, dynamic>> value) {
    _$level2ServicesAtom.reportWrite(value, super.level2Services, () {
      super.level2Services = value;
    });
  }

  late final _$optionsWithAddonsAtom =
      Atom(name: '_AirconBookingStore.optionsWithAddons', context: context);

  @override
  ObservableList<Map<String, dynamic>> get optionsWithAddons {
    _$optionsWithAddonsAtom.reportRead();
    return super.optionsWithAddons;
  }

  @override
  set optionsWithAddons(ObservableList<Map<String, dynamic>> value) {
    _$optionsWithAddonsAtom.reportWrite(value, super.optionsWithAddons, () {
      super.optionsWithAddons = value;
    });
  }

  late final _$savedAddressesAtom =
      Atom(name: '_AirconBookingStore.savedAddresses', context: context);

  @override
  ObservableList<Map<String, dynamic>> get savedAddresses {
    _$savedAddressesAtom.reportRead();
    return super.savedAddresses;
  }

  @override
  set savedAddresses(ObservableList<Map<String, dynamic>> value) {
    _$savedAddressesAtom.reportWrite(value, super.savedAddresses, () {
      super.savedAddresses = value;
    });
  }

  late final _$selectedOptionAtom =
      Atom(name: '_AirconBookingStore.selectedOption', context: context);

  @override
  Map<String, dynamic>? get selectedOption {
    _$selectedOptionAtom.reportRead();
    return super.selectedOption;
  }

  @override
  set selectedOption(Map<String, dynamic>? value) {
    _$selectedOptionAtom.reportWrite(value, super.selectedOption, () {
      super.selectedOption = value;
    });
  }

  late final _$selectedHpKeyAtom =
      Atom(name: '_AirconBookingStore.selectedHpKey', context: context);

  @override
  String? get selectedHpKey {
    _$selectedHpKeyAtom.reportRead();
    return super.selectedHpKey;
  }

  @override
  set selectedHpKey(String? value) {
    _$selectedHpKeyAtom.reportWrite(value, super.selectedHpKey, () {
      super.selectedHpKey = value;
    });
  }

  late final _$selectedHeightKeyAtom =
      Atom(name: '_AirconBookingStore.selectedHeightKey', context: context);

  @override
  String? get selectedHeightKey {
    _$selectedHeightKeyAtom.reportRead();
    return super.selectedHeightKey;
  }

  @override
  set selectedHeightKey(String? value) {
    _$selectedHeightKeyAtom.reportWrite(value, super.selectedHeightKey, () {
      super.selectedHeightKey = value;
    });
  }

  late final _$selectedDistanceKeyAtom =
      Atom(name: '_AirconBookingStore.selectedDistanceKey', context: context);

  @override
  String? get selectedDistanceKey {
    _$selectedDistanceKeyAtom.reportRead();
    return super.selectedDistanceKey;
  }

  @override
  set selectedDistanceKey(String? value) {
    _$selectedDistanceKeyAtom.reportWrite(value, super.selectedDistanceKey, () {
      super.selectedDistanceKey = value;
    });
  }

  late final _$selectedAddonIdsAtom =
      Atom(name: '_AirconBookingStore.selectedAddonIds', context: context);

  @override
  ObservableList<int> get selectedAddonIds {
    _$selectedAddonIdsAtom.reportRead();
    return super.selectedAddonIds;
  }

  @override
  set selectedAddonIds(ObservableList<int> value) {
    _$selectedAddonIdsAtom.reportWrite(value, super.selectedAddonIds, () {
      super.selectedAddonIds = value;
    });
  }

  late final _$selectedAddressAtom =
      Atom(name: '_AirconBookingStore.selectedAddress', context: context);

  @override
  Map<String, dynamic>? get selectedAddress {
    _$selectedAddressAtom.reportRead();
    return super.selectedAddress;
  }

  @override
  set selectedAddress(Map<String, dynamic>? value) {
    _$selectedAddressAtom.reportWrite(value, super.selectedAddress, () {
      super.selectedAddress = value;
    });
  }

  late final _$selectedScheduleAtom =
      Atom(name: '_AirconBookingStore.selectedSchedule', context: context);

  @override
  DateTime? get selectedSchedule {
    _$selectedScheduleAtom.reportRead();
    return super.selectedSchedule;
  }

  @override
  set selectedSchedule(DateTime? value) {
    _$selectedScheduleAtom.reportWrite(value, super.selectedSchedule, () {
      super.selectedSchedule = value;
    });
  }

  late final _$paymentMethodAtom =
      Atom(name: '_AirconBookingStore.paymentMethod', context: context);

  @override
  String get paymentMethod {
    _$paymentMethodAtom.reportRead();
    return super.paymentMethod;
  }

  @override
  set paymentMethod(String value) {
    _$paymentMethodAtom.reportWrite(value, super.paymentMethod, () {
      super.paymentMethod = value;
    });
  }

  late final _$quoteResultAtom =
      Atom(name: '_AirconBookingStore.quoteResult', context: context);

  @override
  Map<String, dynamic>? get quoteResult {
    _$quoteResultAtom.reportRead();
    return super.quoteResult;
  }

  @override
  set quoteResult(Map<String, dynamic>? value) {
    _$quoteResultAtom.reportWrite(value, super.quoteResult, () {
      super.quoteResult = value;
    });
  }

  late final _$quotedTotalAtom =
      Atom(name: '_AirconBookingStore.quotedTotal', context: context);

  @override
  double get quotedTotal {
    _$quotedTotalAtom.reportRead();
    return super.quotedTotal;
  }

  @override
  set quotedTotal(double value) {
    _$quotedTotalAtom.reportWrite(value, super.quotedTotal, () {
      super.quotedTotal = value;
    });
  }

  late final _$bookingResultAtom =
      Atom(name: '_AirconBookingStore.bookingResult', context: context);

  @override
  Map<String, dynamic>? get bookingResult {
    _$bookingResultAtom.reportRead();
    return super.bookingResult;
  }

  @override
  set bookingResult(Map<String, dynamic>? value) {
    _$bookingResultAtom.reportWrite(value, super.bookingResult, () {
      super.bookingResult = value;
    });
  }

  late final _$createdBookingIdAtom =
      Atom(name: '_AirconBookingStore.createdBookingId', context: context);

  @override
  int? get createdBookingId {
    _$createdBookingIdAtom.reportRead();
    return super.createdBookingId;
  }

  @override
  set createdBookingId(int? value) {
    _$createdBookingIdAtom.reportWrite(value, super.createdBookingId, () {
      super.createdBookingId = value;
    });
  }

  late final _$workerCodeAtom =
      Atom(name: '_AirconBookingStore.workerCode', context: context);

  @override
  String? get workerCode {
    _$workerCodeAtom.reportRead();
    return super.workerCode;
  }

  @override
  set workerCode(String? value) {
    _$workerCodeAtom.reportWrite(value, super.workerCode, () {
      super.workerCode = value;
    });
  }

  late final _$paymongoCheckoutUrlAtom =
      Atom(name: '_AirconBookingStore.paymongoCheckoutUrl', context: context);

  @override
  String? get paymongoCheckoutUrl {
    _$paymongoCheckoutUrlAtom.reportRead();
    return super.paymongoCheckoutUrl;
  }

  @override
  set paymongoCheckoutUrl(String? value) {
    _$paymongoCheckoutUrlAtom.reportWrite(value, super.paymongoCheckoutUrl, () {
      super.paymongoCheckoutUrl = value;
    });
  }

  late final _$loadServicesAsyncAction =
      AsyncAction('_AirconBookingStore.loadServices', context: context);

  @override
  Future<void> loadServices() {
    return _$loadServicesAsyncAction.run(() => super.loadServices());
  }

  late final _$loadLevel2ServicesAsyncAction =
      AsyncAction('_AirconBookingStore.loadLevel2Services', context: context);

  @override
  Future<void> loadLevel2Services({int serviceId = 1}) {
    return _$loadLevel2ServicesAsyncAction
        .run(() => super.loadLevel2Services(serviceId: serviceId));
  }

  late final _$loadOptionsWithAddonsAsyncAction = AsyncAction(
      '_AirconBookingStore.loadOptionsWithAddons',
      context: context);

  @override
  Future<void> loadOptionsWithAddons({int serviceId = 1}) {
    return _$loadOptionsWithAddonsAsyncAction
        .run(() => super.loadOptionsWithAddons(serviceId: serviceId));
  }

  late final _$loadSavedAddressesAsyncAction =
      AsyncAction('_AirconBookingStore.loadSavedAddresses', context: context);

  @override
  Future<void> loadSavedAddresses() {
    return _$loadSavedAddressesAsyncAction
        .run(() => super.loadSavedAddresses());
  }

  late final _$getQuoteAsyncAction =
      AsyncAction('_AirconBookingStore.getQuote', context: context);

  @override
  Future<void> getQuote() {
    return _$getQuoteAsyncAction.run(() => super.getQuote());
  }

  late final _$createBookingAsyncAction =
      AsyncAction('_AirconBookingStore.createBooking', context: context);

  @override
  Future<void> createBooking() {
    return _$createBookingAsyncAction.run(() => super.createBooking());
  }

  late final _$createPaymongoSessionAsyncAction = AsyncAction(
      '_AirconBookingStore.createPaymongoSession',
      context: context);

  @override
  Future<void> createPaymongoSession() {
    return _$createPaymongoSessionAsyncAction
        .run(() => super.createPaymongoSession());
  }

  late final _$verifyPaymentStatusAsyncAction =
      AsyncAction('_AirconBookingStore.verifyPaymentStatus', context: context);

  @override
  Future<bool> verifyPaymentStatus() {
    return _$verifyPaymentStatusAsyncAction
        .run(() => super.verifyPaymentStatus());
  }

  late final _$getBookingTrackingAsyncAction =
      AsyncAction('_AirconBookingStore.getBookingTracking', context: context);

  @override
  Future<Map<String, dynamic>?> getBookingTracking() {
    return _$getBookingTrackingAsyncAction
        .run(() => super.getBookingTracking());
  }

  late final _$_AirconBookingStoreActionController =
      ActionController(name: '_AirconBookingStore', context: context);

  @override
  void reset() {
    final _$actionInfo = _$_AirconBookingStoreActionController.startAction(
        name: '_AirconBookingStore.reset');
    try {
      return super.reset();
    } finally {
      _$_AirconBookingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearSelectionOnly() {
    final _$actionInfo = _$_AirconBookingStoreActionController.startAction(
        name: '_AirconBookingStore.clearSelectionOnly');
    try {
      return super.clearSelectionOnly();
    } finally {
      _$_AirconBookingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void ensureOptionsLoaded({int serviceId = 1}) {
    final _$actionInfo = _$_AirconBookingStoreActionController.startAction(
        name: '_AirconBookingStore.ensureOptionsLoaded');
    try {
      return super.ensureOptionsLoaded(serviceId: serviceId);
    } finally {
      _$_AirconBookingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _invalidateQuote() {
    final _$actionInfo = _$_AirconBookingStoreActionController.startAction(
        name: '_AirconBookingStore._invalidateQuote');
    try {
      return super._invalidateQuote();
    } finally {
      _$_AirconBookingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void selectOption(Map<String, dynamic> option) {
    final _$actionInfo = _$_AirconBookingStoreActionController.startAction(
        name: '_AirconBookingStore.selectOption');
    try {
      return super.selectOption(option);
    } finally {
      _$_AirconBookingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setHpKey(String key) {
    final _$actionInfo = _$_AirconBookingStoreActionController.startAction(
        name: '_AirconBookingStore.setHpKey');
    try {
      return super.setHpKey(key);
    } finally {
      _$_AirconBookingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setHeightKey(String key) {
    final _$actionInfo = _$_AirconBookingStoreActionController.startAction(
        name: '_AirconBookingStore.setHeightKey');
    try {
      return super.setHeightKey(key);
    } finally {
      _$_AirconBookingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setDistanceKey(String key) {
    final _$actionInfo = _$_AirconBookingStoreActionController.startAction(
        name: '_AirconBookingStore.setDistanceKey');
    try {
      return super.setDistanceKey(key);
    } finally {
      _$_AirconBookingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleAddon(int addonId) {
    final _$actionInfo = _$_AirconBookingStoreActionController.startAction(
        name: '_AirconBookingStore.toggleAddon');
    try {
      return super.toggleAddon(addonId);
    } finally {
      _$_AirconBookingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void selectAddress(Map<String, dynamic> address) {
    final _$actionInfo = _$_AirconBookingStoreActionController.startAction(
        name: '_AirconBookingStore.selectAddress');
    try {
      return super.selectAddress(address);
    } finally {
      _$_AirconBookingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setSchedule(DateTime dt) {
    final _$actionInfo = _$_AirconBookingStoreActionController.startAction(
        name: '_AirconBookingStore.setSchedule');
    try {
      return super.setSchedule(dt);
    } finally {
      _$_AirconBookingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setPaymentMethod(String method) {
    final _$actionInfo = _$_AirconBookingStoreActionController.startAction(
        name: '_AirconBookingStore.setPaymentMethod');
    try {
      return super.setPaymentMethod(method);
    } finally {
      _$_AirconBookingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
isLoading: ${isLoading},
errorMessage: ${errorMessage},
services: ${services},
level2Services: ${level2Services},
optionsWithAddons: ${optionsWithAddons},
savedAddresses: ${savedAddresses},
selectedOption: ${selectedOption},
selectedHpKey: ${selectedHpKey},
selectedHeightKey: ${selectedHeightKey},
selectedDistanceKey: ${selectedDistanceKey},
selectedAddonIds: ${selectedAddonIds},
selectedAddress: ${selectedAddress},
selectedSchedule: ${selectedSchedule},
paymentMethod: ${paymentMethod},
quoteResult: ${quoteResult},
quotedTotal: ${quotedTotal},
bookingResult: ${bookingResult},
createdBookingId: ${createdBookingId},
workerCode: ${workerCode},
paymongoCheckoutUrl: ${paymongoCheckoutUrl},
bookableOptions: ${bookableOptions}
    ''';
  }
}
