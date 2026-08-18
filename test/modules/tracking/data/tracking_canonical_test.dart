/// TAB 10 — tracking, and the privacy boundary it moves server-side.
///
/// The legacy position route *"answers in EVERY state — a customer could watch
/// their provider on a booking cancelled last week"*. The canonical route
/// applies the state and time-window rules before reading a position at all,
/// and reports a withheld one as a 200 with `visibility.reason` rather than a
/// 403, because the caller IS entitled to the booking.
///
/// What is asserted here is that the client stops flattening that verdict.
library;

import 'dart:convert';

import 'package:client/common/domain/booking/booking_status.dart';
import 'package:client/core/network/canonical_availability.dart';
import 'package:client/core/network/compat/canonical_router.dart';
import 'package:client/core/network/v1_api_client.dart';
import 'package:client/modules/tracking/data/tracking_canonical_data_source.dart';
import 'package:client/modules/tracking/data/tracking_repository.dart';
import 'package:client/modules/tracking/data/tracking_snapshot_source.dart';
import 'package:client/modules/tracking/domain/booking_tracking_state.dart';
import 'package:client/modules/tracking/domain/tracking_visibility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

TrackingCanonicalDataSource sourceReturning(Map<String, dynamic> data) {
  final api = V1ApiClient(
    baseUrl: 'https://api.example.test',
    httpClient: MockClient((_) async => http.Response(
          jsonEncode(<String, dynamic>{'data': data}),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        )),
  );
  return TrackingCanonicalDataSource(api);
}

Map<String, dynamic> position() => <String, dynamic>{
      'loc': <String, dynamic>{
        'type': 'Point',
        'coordinates': <double>[121.0244, 14.5547],
      },
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };

class _StubSource implements TrackingSnapshotSource {
  _StubSource(this.label);
  final String label;
  @override
  Future<BookingTrackingState> snapshot({
    required String bookingId,
    String? knownWorkerUid,
    String? seedName,
    String? seedPhone,
    double? seedLatitude,
    double? seedLongitude,
    String? seedAddress,
  }) async =>
      BookingTrackingState(
        bookingId: label,
        bookingStatus: BookingStatus.enRoute,
        serviceAddress: '',
        serviceLatitude: 0,
        serviceLongitude: 0,
      );
}

void main() {
  group('reachability', () {
    test('a default build tracks over the legacy pair', () async {
      const repo = TrackingRepository(
        compatibility: _NeverCalled(),
      );
      expect(repo.isCanonical, isFalse);
    });

    test('bookingTracking is its own switch', () async {
      // Tracking is a read, so it could have been folded into bookingReads.
      // It is not, because what enabling it changes is a privacy boundary
      // rather than a data source — an operator should be able to decide that
      // separately.
      final repo = TrackingRepository(
        compatibility: _StubSource('legacy'),
        canonical: _StubSource('canonical'),
        router: const CanonicalRouter(
          availability: CanonicalAvailability(
            enabled: true,
            capabilities: <V1Capability>{V1Capability.bookingReads},
          ),
        ),
      );
      final state = await repo.fetchSnapshot(bookingId: '42');
      expect(state.bookingId, 'legacy');
      expect(repo.isCanonical, isFalse);
    });

    test('with its own capability on, the canonical source answers', () async {
      final repo = TrackingRepository(
        compatibility: _StubSource('legacy'),
        canonical: _StubSource('canonical'),
        router: const CanonicalRouter(
          availability: CanonicalAvailability(
            enabled: true,
            capabilities: <V1Capability>{V1Capability.bookingTracking},
          ),
        ),
      );
      final state = await repo.fetchSnapshot(bookingId: '42');
      expect(state.bookingId, 'canonical');
      expect(repo.isCanonical, isTrue);
    });
  });

  group('a withheld position keeps its reason', () {
    test('VISIBLE puts the position on the map', () async {
      final state = await sourceReturning(<String, dynamic>{
        'bookingId': 42,
        'state': 'EN_ROUTE',
        'steps': <dynamic>[],
        'assignedProvider': <String, dynamic>{
          'assigned': true,
          'location': position(),
        },
        'visibility': <String, dynamic>{
          'visibility': 'VISIBLE',
          'reason': null,
        },
      }).snapshot(bookingId: '42');

      expect(state.providerLocation, isNotNull);
      expect(state.visibility.isVisible, isTrue);
      expect(state.visibility.isBackendDerived, isTrue);
      expect(state.bookingStatus, BookingStatus.enRoute);
    });

    test('each withholding reason survives to the screen', () async {
      // Four different facts. The legacy stitcher rendered all four as a blank
      // map, so a customer whose provider is out of signal and one whose
      // booking has no provider saw the same thing.
      const cases = <String, TrackingWithheldReason>{
        'NO_ASSIGNMENT': TrackingWithheldReason.noAssignment,
        'STATE_NOT_TRACKABLE': TrackingWithheldReason.stateNotTrackable,
        'WINDOW_EXPIRED': TrackingWithheldReason.windowExpired,
        'NO_POSITION_REPORTED': TrackingWithheldReason.noPositionReported,
      };

      for (final entry in cases.entries) {
        final state = await sourceReturning(<String, dynamic>{
          'bookingId': 42,
          'state': 'ASSIGNED',
          'assignedProvider': <String, dynamic>{
            'assigned': true,
            'location': null,
          },
          'visibility': <String, dynamic>{
            'visibility': 'WITHHELD',
            'reason': entry.key,
          },
        }).snapshot(bookingId: '42');

        expect(state.visibility.reason, entry.value, reason: entry.key);
        expect(state.visibility.isExplainedWithholding, isTrue);
        expect(state.providerLocation, isNull);
        // Every reason says something the customer can act on or wait for.
        expect(entry.value.customerMessage, isNotEmpty);
      }

      // And no two of them say the same thing.
      final messages =
          TrackingWithheldReason.values.map((r) => r.customerMessage).toSet();
      expect(messages.length, TrackingWithheldReason.values.length);
    });

    test('a WITHHELD verdict drops the position even if one is attached',
        () async {
      // The backend already nulls it. This is the client refusing to draw a pin
      // on the strength of coordinates the verdict said to hide — the failure
      // mode a server regression would otherwise produce silently.
      final state = await sourceReturning(<String, dynamic>{
        'bookingId': 42,
        'state': 'CANCELLED',
        'assignedProvider': <String, dynamic>{
          'assigned': true,
          'location': position(),
        },
        'visibility': <String, dynamic>{
          'visibility': 'WITHHELD',
          'reason': 'STATE_NOT_TRACKABLE',
        },
      }).snapshot(bookingId: '42');

      expect(state.providerLocation, isNull);
    });

    test('an unparseable verdict withholds rather than reveals', () async {
      // Deny by default. A parser that defaulted to VISIBLE would put a
      // position on screen on the strength of a value it did not understand.
      final state = await sourceReturning(<String, dynamic>{
        'bookingId': 42,
        'state': 'EN_ROUTE',
        'assignedProvider': <String, dynamic>{
          'assigned': true,
          'location': position(),
        },
        'visibility': <String, dynamic>{'visibility': 'SOMETHING_NEW'},
      }).snapshot(bookingId: '42');

      expect(state.visibility.isVisible, isFalse);
      expect(state.providerLocation, isNull);
    });

    test('a payload with no verdict at all withholds', () async {
      final state = await sourceReturning(<String, dynamic>{
        'bookingId': 42,
        'state': 'EN_ROUTE',
        'assignedProvider': <String, dynamic>{
          'assigned': true,
          'location': position(),
        },
      }).snapshot(bookingId: '42');

      expect(state.visibility.isVisible, isFalse);
      expect(state.providerLocation, isNull);
    });
  });

  group('the legacy transport labels its guess as a guess', () {
    test('an inferred verdict is not presented as the backend’s', () {
      const state = BookingTrackingState(
        bookingId: '42',
        bookingStatus: BookingStatus.enRoute,
        serviceAddress: '',
        serviceLatitude: 0,
        serviceLongitude: 0,
      );

      // No position and no verdict: the honest reading is "not reported", and
      // it must not claim to be the server's answer, because the legacy route
      // cannot distinguish that from "wrong state" or "window closed".
      expect(state.visibility.isVisible, isFalse);
      expect(
          state.visibility.reason, TrackingWithheldReason.noPositionReported);
      expect(state.visibility.isBackendDerived, isFalse);
    });
  });
}

/// A compatibility source that fails the test if it is ever asked for a frame.
class _NeverCalled implements TrackingSnapshotSource {
  const _NeverCalled();
  @override
  Future<BookingTrackingState> snapshot({
    required String bookingId,
    String? knownWorkerUid,
    String? seedName,
    String? seedPhone,
    double? seedLatitude,
    double? seedLongitude,
    String? seedAddress,
  }) async =>
      throw StateError('not expected in this test');
}
