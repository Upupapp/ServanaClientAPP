// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hompage_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$HomeStore on _HomeStore, Store {
  late final _$isLoadingAtom =
      Atom(name: '_HomeStore.isLoading', context: context);

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

  late final _$sessionAtom = Atom(name: '_HomeStore.session', context: context);

  @override
  UserSession? get session {
    _$sessionAtom.reportRead();
    return super.session;
  }

  @override
  set session(UserSession? value) {
    _$sessionAtom.reportWrite(value, super.session, () {
      super.session = value;
    });
  }

  late final _$currentLocationAtom =
      Atom(name: '_HomeStore.currentLocation', context: context);

  @override
  LatLng? get currentLocation {
    _$currentLocationAtom.reportRead();
    return super.currentLocation;
  }

  @override
  set currentLocation(LatLng? value) {
    _$currentLocationAtom.reportWrite(value, super.currentLocation, () {
      super.currentLocation = value;
    });
  }

  late final _$merchantsAtom =
      Atom(name: '_HomeStore.merchants', context: context);

  @override
  ObservableList<MerchantLight> get merchants {
    _$merchantsAtom.reportRead();
    return super.merchants;
  }

  @override
  set merchants(ObservableList<MerchantLight> value) {
    _$merchantsAtom.reportWrite(value, super.merchants, () {
      super.merchants = value;
    });
  }

  late final _$searchResultsAtom =
      Atom(name: '_HomeStore.searchResults', context: context);

  @override
  ObservableList<SearchServiceResult> get searchResults {
    _$searchResultsAtom.reportRead();
    return super.searchResults;
  }

  @override
  set searchResults(ObservableList<SearchServiceResult> value) {
    _$searchResultsAtom.reportWrite(value, super.searchResults, () {
      super.searchResults = value;
    });
  }

  late final _$bookingsAtom =
      Atom(name: '_HomeStore.bookings', context: context);

  @override
  ObservableList<JobOrder> get bookings {
    _$bookingsAtom.reportRead();
    return super.bookings;
  }

  @override
  set bookings(ObservableList<JobOrder> value) {
    _$bookingsAtom.reportWrite(value, super.bookings, () {
      super.bookings = value;
    });
  }

  late final _$loadnearbyMerchantsAsyncAction =
      AsyncAction('_HomeStore.loadnearbyMerchants', context: context);

  @override
  Future<void> loadnearbyMerchants() {
    return _$loadnearbyMerchantsAsyncAction
        .run(() => super.loadnearbyMerchants());
  }

  late final _$loadBookingsAsyncAction =
      AsyncAction('_HomeStore.loadBookings', context: context);

  @override
  Future<void> loadBookings() {
    return _$loadBookingsAsyncAction.run(() => super.loadBookings());
  }

  late final _$searchServiceAsyncAction =
      AsyncAction('_HomeStore.searchService', context: context);

  @override
  Future<void> searchService(String keyword) {
    return _$searchServiceAsyncAction.run(() => super.searchService(keyword));
  }

  late final _$_HomeStoreActionController =
      ActionController(name: '_HomeStore', context: context);

  @override
  void resetPrivateData() {
    final _$actionInfo = _$_HomeStoreActionController.startAction(
        name: '_HomeStore.resetPrivateData');
    try {
      return super.resetPrivateData();
    } finally {
      _$_HomeStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void addBooking(JobOrder booking) {
    final _$actionInfo =
        _$_HomeStoreActionController.startAction(name: '_HomeStore.addBooking');
    try {
      return super.addBooking(booking);
    } finally {
      _$_HomeStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
isLoading: ${isLoading},
session: ${session},
currentLocation: ${currentLocation},
merchants: ${merchants},
searchResults: ${searchResults},
bookings: ${bookings}
    ''';
  }
}
