// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tracking_controller.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$TrackingController on _TrackingController, Store {
  late final _$trackingStateAtom =
      Atom(name: '_TrackingController.trackingState', context: context);

  @override
  BookingTrackingState? get trackingState {
    _$trackingStateAtom.reportRead();
    return super.trackingState;
  }

  @override
  set trackingState(BookingTrackingState? value) {
    _$trackingStateAtom.reportWrite(value, super.trackingState, () {
      super.trackingState = value;
    });
  }

  late final _$isLoadingAtom =
      Atom(name: '_TrackingController.isLoading', context: context);

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

  late final _$isPollingAtom =
      Atom(name: '_TrackingController.isPolling', context: context);

  @override
  bool get isPolling {
    _$isPollingAtom.reportRead();
    return super.isPolling;
  }

  @override
  set isPolling(bool value) {
    _$isPollingAtom.reportWrite(value, super.isPolling, () {
      super.isPolling = value;
    });
  }

  late final _$errorAtom =
      Atom(name: '_TrackingController.error', context: context);

  @override
  String? get error {
    _$errorAtom.reportRead();
    return super.error;
  }

  @override
  set error(String? value) {
    _$errorAtom.reportWrite(value, super.error, () {
      super.error = value;
    });
  }

  late final _$startTrackingAsyncAction =
      AsyncAction('_TrackingController.startTracking', context: context);

  @override
  Future<void> startTracking(
      {required String bookingId,
      String? workerUid,
      String? workerName,
      String? workerPhone,
      double? serviceLatitude,
      double? serviceLongitude,
      String? serviceAddress}) {
    return _$startTrackingAsyncAction.run(() => super.startTracking(
        bookingId: bookingId,
        workerUid: workerUid,
        workerName: workerName,
        workerPhone: workerPhone,
        serviceLatitude: serviceLatitude,
        serviceLongitude: serviceLongitude,
        serviceAddress: serviceAddress));
  }

  late final _$refreshAsyncAction =
      AsyncAction('_TrackingController.refresh', context: context);

  @override
  Future<void> refresh() {
    return _$refreshAsyncAction.run(() => super.refresh());
  }

  late final _$_TrackingControllerActionController =
      ActionController(name: '_TrackingController', context: context);

  @override
  void stopTracking() {
    final _$actionInfo = _$_TrackingControllerActionController.startAction(
        name: '_TrackingController.stopTracking');
    try {
      return super.stopTracking();
    } finally {
      _$_TrackingControllerActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
trackingState: ${trackingState},
isLoading: ${isLoading},
isPolling: ${isPolling},
error: ${error}
    ''';
  }
}
