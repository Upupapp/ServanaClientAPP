/// Test doubles for the booking submission ceremony.
///
/// The API double extends the real `ServanaApiClient` and overrides only
/// `createBooking`, so a signature change to that method breaks compilation
/// here rather than letting the double drift into testing a shape the client no
/// longer sends.
library;

import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/core/recovery/operation_journal.dart';
import 'package:flutter_test/flutter_test.dart';

/// One recorded call to `createBooking`.
class RecordedBookingCall {
  const RecordedBookingCall({
    required this.userId,
    required this.payload,
    required this.idempotencyKey,
  });

  final String userId;
  final Map<String, dynamic> payload;
  final String? idempotencyKey;
}

class FakeBookingApi extends ServanaApiClient {
  FakeBookingApi({this.throws, this.onCall, this.response})
      : super(baseUrl: 'http://fake.test');

  /// Thrown instead of answering, to exercise the failure path.
  final Object? throws;

  /// Run at the moment of the call — used to assert what has already happened
  /// by the time the request goes out.
  final void Function()? onCall;

  final Map<String, dynamic>? response;

  final List<RecordedBookingCall> calls = <RecordedBookingCall>[];

  @override
  Future<Map<String, dynamic>> createBooking({
    required String userId,
    required Map<String, dynamic> payload,
    String? idempotencyKey,
  }) async {
    onCall?.call();
    calls.add(RecordedBookingCall(
      userId: userId,
      payload: payload,
      idempotencyKey: idempotencyKey,
    ));
    if (throws != null) throw throws!;
    return response ??
        <String, dynamic>{'bookingId': 4242, 'workerCode': 'W-1'};
  }
}

class FakeJournal extends Fake implements OperationJournal {
  final List<JournaledOperation> recorded = <JournaledOperation>[];
  final List<String> resolved = <String>[];

  @override
  Future<void> record(JournaledOperation op) async => recorded.add(op);

  @override
  Future<void> resolveIdempotencyKey(
    String uid, {
    required String type,
    required String idempotencyKey,
  }) async =>
      resolved.add(idempotencyKey);
}
