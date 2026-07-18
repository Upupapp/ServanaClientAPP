// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bw_booking_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$BwBookingStore on _BwBookingStore, Store {
  Computed<List<Map<String, dynamic>>>? _$bookableOptionsComputed;

  @override
  List<Map<String, dynamic>> get bookableOptions =>
      (_$bookableOptionsComputed ??= Computed<List<Map<String, dynamic>>>(
              () => super.bookableOptions,
              name: '_BwBookingStore.bookableOptions'))
          .value;
  Computed<double>? _$estimatedTotalComputed;

  @override
  double get estimatedTotal =>
      (_$estimatedTotalComputed ??= Computed<double>(() => super.estimatedTotal,
              name: '_BwBookingStore.estimatedTotal'))
          .value;

  late final _$isLoadingAtom =
      Atom(name: '_BwBookingStore.isLoading', context: context);

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
      Atom(name: '_BwBookingStore.errorMessage', context: context);

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

  late final _$selectedServiceIdAtom =
      Atom(name: '_BwBookingStore.selectedServiceId', context: context);

  @override
  int? get selectedServiceId {
    _$selectedServiceIdAtom.reportRead();
    return super.selectedServiceId;
  }

  @override
  set selectedServiceId(int? value) {
    _$selectedServiceIdAtom.reportWrite(value, super.selectedServiceId, () {
      super.selectedServiceId = value;
    });
  }

  late final _$optionsWithAddonsAtom =
      Atom(name: '_BwBookingStore.optionsWithAddons', context: context);

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

  late final _$branchesAtom =
      Atom(name: '_BwBookingStore.branches', context: context);

  @override
  ObservableList<Map<String, dynamic>> get branches {
    _$branchesAtom.reportRead();
    return super.branches;
  }

  @override
  set branches(ObservableList<Map<String, dynamic>> value) {
    _$branchesAtom.reportWrite(value, super.branches, () {
      super.branches = value;
    });
  }

  late final _$slotsAtom =
      Atom(name: '_BwBookingStore.slots', context: context);

  @override
  ObservableList<Map<String, dynamic>> get slots {
    _$slotsAtom.reportRead();
    return super.slots;
  }

  @override
  set slots(ObservableList<Map<String, dynamic>> value) {
    _$slotsAtom.reportWrite(value, super.slots, () {
      super.slots = value;
    });
  }

  late final _$savedAddressesAtom =
      Atom(name: '_BwBookingStore.savedAddresses', context: context);

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
      Atom(name: '_BwBookingStore.selectedOption', context: context);

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

  late final _$selectedAddonIdsAtom =
      Atom(name: '_BwBookingStore.selectedAddonIds', context: context);

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

  late final _$selectedBranchAtom =
      Atom(name: '_BwBookingStore.selectedBranch', context: context);

  @override
  Map<String, dynamic>? get selectedBranch {
    _$selectedBranchAtom.reportRead();
    return super.selectedBranch;
  }

  @override
  set selectedBranch(Map<String, dynamic>? value) {
    _$selectedBranchAtom.reportWrite(value, super.selectedBranch, () {
      super.selectedBranch = value;
    });
  }

  late final _$selectedDateAtom =
      Atom(name: '_BwBookingStore.selectedDate', context: context);

  @override
  DateTime? get selectedDate {
    _$selectedDateAtom.reportRead();
    return super.selectedDate;
  }

  @override
  set selectedDate(DateTime? value) {
    _$selectedDateAtom.reportWrite(value, super.selectedDate, () {
      super.selectedDate = value;
    });
  }

  late final _$selectedSlotAtom =
      Atom(name: '_BwBookingStore.selectedSlot', context: context);

  @override
  Map<String, dynamic>? get selectedSlot {
    _$selectedSlotAtom.reportRead();
    return super.selectedSlot;
  }

  @override
  set selectedSlot(Map<String, dynamic>? value) {
    _$selectedSlotAtom.reportWrite(value, super.selectedSlot, () {
      super.selectedSlot = value;
    });
  }

  late final _$selectedAddressAtom =
      Atom(name: '_BwBookingStore.selectedAddress', context: context);

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

  late final _$paymentMethodAtom =
      Atom(name: '_BwBookingStore.paymentMethod', context: context);

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

  late final _$bookingResultAtom =
      Atom(name: '_BwBookingStore.bookingResult', context: context);

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
      Atom(name: '_BwBookingStore.createdBookingId', context: context);

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
      Atom(name: '_BwBookingStore.workerCode', context: context);

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
      Atom(name: '_BwBookingStore.paymongoCheckoutUrl', context: context);

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

  late final _$loadOptionsWithAddonsAsyncAction =
      AsyncAction('_BwBookingStore.loadOptionsWithAddons', context: context);

  @override
  Future<void> loadOptionsWithAddons({required int serviceId}) {
    return _$loadOptionsWithAddonsAsyncAction
        .run(() => super.loadOptionsWithAddons(serviceId: serviceId));
  }

  late final _$loadBranchesAsyncAction =
      AsyncAction('_BwBookingStore.loadBranches', context: context);

  @override
  Future<void> loadBranches({required int serviceId}) {
    return _$loadBranchesAsyncAction
        .run(() => super.loadBranches(serviceId: serviceId));
  }

  late final _$loadSlotsAsyncAction =
      AsyncAction('_BwBookingStore.loadSlots', context: context);

  @override
  Future<void> loadSlots() {
    return _$loadSlotsAsyncAction.run(() => super.loadSlots());
  }

  late final _$loadSavedAddressesAsyncAction =
      AsyncAction('_BwBookingStore.loadSavedAddresses', context: context);

  @override
  Future<void> loadSavedAddresses() {
    return _$loadSavedAddressesAsyncAction
        .run(() => super.loadSavedAddresses());
  }

  late final _$createBookingAsyncAction =
      AsyncAction('_BwBookingStore.createBooking', context: context);

  @override
  Future<void> createBooking() {
    return _$createBookingAsyncAction.run(() => super.createBooking());
  }

  late final _$verifyPaymentStatusAsyncAction =
      AsyncAction('_BwBookingStore.verifyPaymentStatus', context: context);

  @override
  Future<bool> verifyPaymentStatus() {
    return _$verifyPaymentStatusAsyncAction
        .run(() => super.verifyPaymentStatus());
  }

  late final _$createPaymongoSessionAsyncAction =
      AsyncAction('_BwBookingStore.createPaymongoSession', context: context);

  @override
  Future<void> createPaymongoSession() {
    return _$createPaymongoSessionAsyncAction
        .run(() => super.createPaymongoSession());
  }

  late final _$_BwBookingStoreActionController =
      ActionController(name: '_BwBookingStore', context: context);

  @override
  void reset() {
    final _$actionInfo = _$_BwBookingStoreActionController.startAction(
        name: '_BwBookingStore.reset');
    try {
      return super.reset();
    } finally {
      _$_BwBookingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void ensureOptionsLoaded({required int serviceId}) {
    final _$actionInfo = _$_BwBookingStoreActionController.startAction(
        name: '_BwBookingStore.ensureOptionsLoaded');
    try {
      return super.ensureOptionsLoaded(serviceId: serviceId);
    } finally {
      _$_BwBookingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void selectOption(Map<String, dynamic> option) {
    final _$actionInfo = _$_BwBookingStoreActionController.startAction(
        name: '_BwBookingStore.selectOption');
    try {
      return super.selectOption(option);
    } finally {
      _$_BwBookingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleAddon(int addonId) {
    final _$actionInfo = _$_BwBookingStoreActionController.startAction(
        name: '_BwBookingStore.toggleAddon');
    try {
      return super.toggleAddon(addonId);
    } finally {
      _$_BwBookingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void selectBranch(Map<String, dynamic> branch) {
    final _$actionInfo = _$_BwBookingStoreActionController.startAction(
        name: '_BwBookingStore.selectBranch');
    try {
      return super.selectBranch(branch);
    } finally {
      _$_BwBookingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setDate(DateTime date) {
    final _$actionInfo = _$_BwBookingStoreActionController.startAction(
        name: '_BwBookingStore.setDate');
    try {
      return super.setDate(date);
    } finally {
      _$_BwBookingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void selectSlot(Map<String, dynamic> slot) {
    final _$actionInfo = _$_BwBookingStoreActionController.startAction(
        name: '_BwBookingStore.selectSlot');
    try {
      return super.selectSlot(slot);
    } finally {
      _$_BwBookingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void selectAddress(Map<String, dynamic> address) {
    final _$actionInfo = _$_BwBookingStoreActionController.startAction(
        name: '_BwBookingStore.selectAddress');
    try {
      return super.selectAddress(address);
    } finally {
      _$_BwBookingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setPaymentMethod(String method) {
    final _$actionInfo = _$_BwBookingStoreActionController.startAction(
        name: '_BwBookingStore.setPaymentMethod');
    try {
      return super.setPaymentMethod(method);
    } finally {
      _$_BwBookingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
isLoading: ${isLoading},
errorMessage: ${errorMessage},
selectedServiceId: ${selectedServiceId},
optionsWithAddons: ${optionsWithAddons},
branches: ${branches},
slots: ${slots},
savedAddresses: ${savedAddresses},
selectedOption: ${selectedOption},
selectedAddonIds: ${selectedAddonIds},
selectedBranch: ${selectedBranch},
selectedDate: ${selectedDate},
selectedSlot: ${selectedSlot},
selectedAddress: ${selectedAddress},
paymentMethod: ${paymentMethod},
bookingResult: ${bookingResult},
createdBookingId: ${createdBookingId},
workerCode: ${workerCode},
paymongoCheckoutUrl: ${paymongoCheckoutUrl},
bookableOptions: ${bookableOptions},
estimatedTotal: ${estimatedTotal}
    ''';
  }
}
