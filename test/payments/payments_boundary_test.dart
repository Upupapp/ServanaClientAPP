/// TAB 11 — payments, refunds, and the four copies that became one.
///
/// The claims this tab makes are asserted here rather than described: that no
/// shipped build can reach the canonical transport, that the legacy transport
/// reports what it cannot know as unknown rather than as zero, and that a
/// customer refund REQUEST is never presented as money having moved.
library;

import 'dart:convert';

import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/core/network/canonical_availability.dart';
import 'package:client/core/network/compat/canonical_router.dart';
import 'package:client/core/network/v1_api_client.dart';
import 'package:client/modules/payments/data/payments_canonical_data_source.dart';
import 'package:client/modules/payments/data/payments_compatibility_data_source.dart';
import 'package:client/modules/payments/data/payments_data_source.dart';
import 'package:client/modules/payments/data/payments_repository.dart';
import 'package:client/modules/payments/domain/booking_payment.dart';
import 'package:client/modules/payments/domain/payment_intent.dart';
import 'package:client/modules/payments/domain/refund.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// ── Doubles ──────────────────────────────────────────────────────────────────

class _Recorder {
  final List<http.BaseRequest> requests = <http.BaseRequest>[];
  final List<String> bodies = <String>[];
}

({PaymentsCanonicalDataSource source, _Recorder recorder}) canonical(
  Object body, {
  int status = 200,
}) {
  final recorder = _Recorder();
  final api = V1ApiClient(
    baseUrl: 'https://api.example.test',
    httpClient: MockClient((request) async {
      recorder.requests.add(request);
      recorder.bodies.add(request.body);
      return http.Response(jsonEncode(body), status,
          headers: <String, String>{'content-type': 'application/json'});
    }),
  );
  return (source: PaymentsCanonicalDataSource(api), recorder: recorder);
}

class _FakeLegacyApi extends Fake implements ServanaApiClient {
  Map<String, dynamic> checkoutResponse = <String, dynamic>{};
  Map<String, dynamic> bookingResponse = <String, dynamic>{};
  int checkoutCalls = 0;
  int bookingCalls = 0;

  @override
  Future<Map<String, dynamic>> createPaymongoSession({
    required int bookingId,
  }) async {
    checkoutCalls++;
    return checkoutResponse;
  }

  @override
  Future<Map<String, dynamic>> getBooking(int bookingId) async {
    bookingCalls++;
    return bookingResponse;
  }
}

void main() {
  // ── The gate ───────────────────────────────────────────────────────────────

  group('reachability', () {
    test('a default build routes payments at the legacy transport', () {
      final repo = PaymentsRepository(
        compatibility: PaymentsCompatibilityDataSource(_FakeLegacyApi()),
        canonical: canonical(const <String, dynamic>{}).source,
        router: const CanonicalRouter(availability: CanonicalAvailability()),
      );

      expect(repo.isCanonical, isFalse);
      expect(repo.canOfferRefund, isFalse);
      expect(repo.hasPaymentDetail, isFalse);
    });

    test('the booking capabilities do not enable payments', () {
      // Four booking-shaped capabilities now exist. Payments must not ride in
      // on any of them: enabling booking READS must not start posting to a
      // finance endpoint over an undeployed namespace.
      for (final other in <V1Capability>[
        V1Capability.bookingReads,
        V1Capability.bookingLifecycle,
        V1Capability.bookingTracking,
      ]) {
        final repo = PaymentsRepository(
          compatibility: PaymentsCompatibilityDataSource(_FakeLegacyApi()),
          canonical: canonical(const <String, dynamic>{}).source,
          router: CanonicalRouter(
            availability: CanonicalAvailability(
              enabled: true,
              capabilities: <V1Capability>{other},
            ),
          ),
        );
        expect(repo.isCanonical, isFalse, reason: other.name);
      }
    });

    test('a half-wired injector falls back rather than routing at nothing', () {
      const repo = PaymentsRepository(
        compatibility: _NeverCalled(),
        router: CanonicalRouter(
          availability: CanonicalAvailability(
            enabled: true,
            capabilities: <V1Capability>{V1Capability.bookingPayments},
          ),
        ),
      );
      expect(repo.isCanonical, isFalse);
    });
  });

  // ── Checkout ───────────────────────────────────────────────────────────────

  group('starting a checkout', () {
    test('the canonical request carries no body at all', () async {
      // PaymentIntentRequest's one property is `returnOrigin`, and it is
      // "matched against a SERVER-SIDE allowlist. Never used as a URL — a
      // caller-supplied return target would let a payer be returned to another
      // application." A mobile client has no origin to nominate, and the
      // request that cannot be wrong is the empty one.
      final c = canonical(<String, dynamic>{
        'data': <String, dynamic>{
          'bookingId': 42,
          'checkoutUrl': 'https://checkout.paymongo.com/abc',
          'reused': false,
        },
      });

      final intent = await c.source.startCheckout('42');

      expect(c.recorder.requests.single.method, 'POST');
      expect(c.recorder.requests.single.url.path,
          '/api/v1/bookings/42/payment-intents');
      expect(c.recorder.bodies.single, isEmpty);
      expect(c.recorder.requests.single.url.queryParameters, isEmpty);

      expect(intent.checkoutUrl, 'https://checkout.paymongo.com/abc');
      expect(intent.isUsable, isTrue);
      expect(intent.reused, isFalse);
    });

    test('a resumed session is reported as reused', () async {
      // The app already depends on this behaviour — both booking stores persist
      // the checkout URL for crash recovery and call the endpoint again on
      // retry — but had no way to observe it. A regression here would hand a
      // customer two payable sessions for one booking.
      final c = canonical(<String, dynamic>{
        'data': <String, dynamic>{
          'bookingId': 42,
          'checkoutUrl': 'https://checkout.paymongo.com/abc',
          'reused': true,
        },
      });

      final intent = await c.source.startCheckout('42');
      expect(intent.reused, isTrue);
    });

    test('the legacy transport reads both URL spellings', () async {
      // The four call sites did not agree about this. Two read `data ?? root`
      // then checked both `checkoutUrl` and `checkout_url`; the inline block in
      // BookingDetailScreen unwrapped the envelope but only ever looked at the
      // root key, so a wrapped response the stores handled would have failed
      // there with "Payment session could not be started".
      final wrapped = _FakeLegacyApi()
        ..checkoutResponse = <String, dynamic>{
          'data': <String, dynamic>{'checkout_url': 'https://checkout.paymongo.com/x'},
        };
      final rooted = _FakeLegacyApi()
        ..checkoutResponse = <String, dynamic>{
          'checkoutUrl': 'https://checkout.paymongo.com/y',
        };

      expect(
        (await PaymentsCompatibilityDataSource(wrapped).startCheckout('42'))
            .checkoutUrl,
        'https://checkout.paymongo.com/x',
      );
      expect(
        (await PaymentsCompatibilityDataSource(rooted).startCheckout('42'))
            .checkoutUrl,
        'https://checkout.paymongo.com/y',
      );
    });

    test('a success with no URL is not usable', () async {
      // The backend can return success without a URL on a partial session
      // failure. Both stores already handled it; the check now lives once, on
      // the model, so the confirmation screen shows Retry rather than an
      // indefinite spinner.
      final api = _FakeLegacyApi()
        ..checkoutResponse = <String, dynamic>{'success': true};

      final intent =
          await PaymentsCompatibilityDataSource(api).startCheckout('42');
      expect(intent.isUsable, isFalse);
    });

    test('reused is false on legacy because it is unknowable, not because it '
        'is known false', () async {
      final api = _FakeLegacyApi()
        ..checkoutResponse = <String, dynamic>{
          'checkoutUrl': 'https://checkout.paymongo.com/z',
        };
      final intent =
          await PaymentsCompatibilityDataSource(api).startCheckout('42');

      expect(intent.reused, isFalse);
      // The flag a caller must consult before believing it.
      expect(PaymentsCompatibilityDataSource(api).hasPaymentEndpoint, isFalse);
    });
  });

  // ── Reading payment state ──────────────────────────────────────────────────

  group('payment state', () {
    test('canonical asks the payment endpoint and gets the breakdown',
        () async {
      final c = canonical(<String, dynamic>{
        'data': <String, dynamic>{
          'bookingId': 42,
          'currency': 'PHP',
          'state': 'PAID',
          'captured': true,
          'method': 'gcash',
          'paidAt': '2026-08-16T09:00:00.000Z',
          'breakdown': <String, dynamic>{
            'gross': 1500.0,
            'grossMinor': 150000,
            'basePrice': 1200.0,
            'additionalWork': 300.0,
          },
          'refund': <String, dynamic>{
            'refundedAmount': 0,
            'refundable': 1500.0,
            'refundableMinor': 150000,
          },
        },
      });

      final payment = await c.source.payment('42');

      expect(c.recorder.requests.single.method, 'GET');
      expect(c.recorder.requests.single.url.path, '/api/v1/bookings/42/payment');
      expect(payment.state, PaymentState.paid);
      expect(payment.isPaid, isTrue);
      expect(payment.captured, isTrue);
      expect(payment.breakdown.gross, 1500.0);
      expect(payment.breakdown.grossMinor, 150000);
      expect(payment.refund?.refundable, 1500.0);
      expect(payment.isBackendDerived, isTrue);
    });

    test('the legacy transport re-reads the whole booking — R-06', () async {
      // Not a defect this tab could fix. There is no legacy payment endpoint,
      // so the only way to learn the state is to fetch the booking. What
      // changed is that it happens once, behind a name, instead of in three
      // places with three fallback chains.
      final api = _FakeLegacyApi()
        ..bookingResponse = <String, dynamic>{
          'booking': <String, dynamic>{'paymentStatus': 'PAID'},
        };

      final payment =
          await PaymentsCompatibilityDataSource(api).payment('42');

      expect(api.bookingCalls, 1);
      expect(payment.isPaid, isTrue);
    });

    test('legacy reports the breakdown as unknown, not as zero pesos', () {
      // The distinction that keeps a screen honest. `gross: 0` here means "this
      // transport cannot tell you", and `isBackendDerived: false` is how a
      // caller knows not to render it as a price.
      final payment = BookingPayment.fromBookingMap(
        <String, dynamic>{'paymentStatus': 'PAID'},
        bookingId: '42',
      );

      expect(payment.isBackendDerived, isFalse);
      expect(payment.refund, isNull);
      expect(payment.breakdown.grossMinor, isNull);
    });

    test('all three legacy status keys are read', () async {
      // Inherited from PaymentStatusParser; each branch exists because a route
      // was observed returning that shape.
      for (final booking in <Map<String, dynamic>>[
        <String, dynamic>{'paymentStatus': 'PAID'},
        <String, dynamic>{'payment_status': 'PAID'},
        <String, dynamic>{
          'payment': <String, dynamic>{'status': 'PAID'},
        },
      ]) {
        expect(
          BookingPayment.fromBookingMap(booking, bookingId: '42').isPaid,
          isTrue,
          reason: '$booking',
        );
      }
    });

    test('the legacy PAYMENT_ prefixed vocabulary still maps', () {
      expect(PaymentState.fromWire('PAYMENT_PAID'), PaymentState.paid);
      expect(PaymentState.fromWire('PAYMENT_FAILED'), PaymentState.failed);
    });

    test('an unrecognised state is unknown, NOT pending', () {
      // The trap. PaymentStatusParser had three states and treated everything
      // else as neither paid nor payable; a state it did not know would have
      // silently disabled every affordance. `unknown` is distinct so a caller
      // can tell "we do not recognise this" from "awaiting payment", and
      // crucially it does not invite a second payment.
      final state = PaymentState.fromWire('SOMETHING_NEW');
      expect(state, PaymentState.unknown);
      expect(state.invitesPayment, isFalse);
      expect(state.isSettled, isFalse);
    });

    test('only PENDING and FAILED invite a payment', () {
      // REJECTED is excluded deliberately: a rejected GCash proof needs
      // support, not another attempt, and the backend would refuse the intent
      // with PAYMENT_STATE_CONFLICT.
      expect(PaymentState.pending.invitesPayment, isTrue);
      expect(PaymentState.failed.invitesPayment, isTrue);
      for (final s in <PaymentState>[
        PaymentState.paid,
        PaymentState.rejected,
        PaymentState.refunding,
        PaymentState.refunded,
        PaymentState.unknown,
      ]) {
        expect(s.invitesPayment, isFalse, reason: s.name);
      }
    });

    test('a refunded booking is not a paid one', () {
      // Settlement truth is SEPARATE from lifecycle truth, and REFUNDED is not
      // PAID. `hasMoneyMoved` covers the three states a refund conversation can
      // apply to without conflating any of them with settled.
      expect(PaymentState.refunded.isSettled, isFalse);
      expect(PaymentState.refunded.hasMoneyMoved, isTrue);
      expect(PaymentState.refunding.hasMoneyMoved, isTrue);
      expect(PaymentState.pending.hasMoneyMoved, isFalse);
    });
  });

  // ── Refunds ────────────────────────────────────────────────────────────────

  group('refunds', () {
    test('the legacy transport has no refund route at all', () async {
      // Not "awkward" — absent. The canonical entry "adds the
      // customer-initiated path, which had no route at all".
      final repo = PaymentsRepository(
        compatibility: PaymentsCompatibilityDataSource(_FakeLegacyApi()),
      );

      expect(repo.canOfferRefund, isFalse);
      await expectLater(
        repo.requestRefund(
          bookingId: '42',
          request: const RefundRequest(trigger: RefundTrigger.customerCancelled),
        ),
        throwsA(isA<UnsupportedPaymentAction>()),
      );
    });

    test('a customer request is NOT money moving', () async {
      // The single most damaging thing this surface could get wrong. A
      // successful customer call opens a review row and calls no processor;
      // wording it as a completed refund makes the customer wait for money
      // that is not coming until an admin approves it.
      final c = canonical(<String, dynamic>{
        'data': <String, dynamic>{
          'bookingId': 42,
          'outcome': 'requested',
          'trigger': 'CUSTOMER_CANCELLED',
          'amount': 1500.0,
          'amountMinor': 150000,
          'currency': 'PHP',
          'reference': 'SRV-REF-42',
          'refundReviewId': 7,
          'reversesProviderEarning': true,
        },
      });

      final result = await c.source.requestRefund(
        bookingId: '42',
        request: const RefundRequest(trigger: RefundTrigger.customerCancelled),
      );

      expect(result.isRequestOnly, isTrue);
      expect(result.isMoneyMoving, isFalse);
      expect(result.refundReviewId, 7);
      // A Servana handle support can discuss — never the processor's id.
      expect(result.reference, 'SRV-REF-42');
    });

    test('an issued refund IS money moving', () {
      final issued = RefundResult.fromApiMap(
        <String, dynamic>{'outcome': 'issued', 'amount': 100},
        bookingId: '42',
      );
      expect(issued.isMoneyMoving, isTrue);

      final pending = RefundResult.fromApiMap(
        <String, dynamic>{'outcome': 'pending_processor', 'amount': 100},
        bookingId: '42',
      );
      expect(pending.isMoneyMoving, isTrue);
      expect(pending.isPendingProcessor, isTrue);
    });

    test('omitting the amount asks for the whole refundable balance',
        () async {
      // The ceiling is captured-minus-refunded, computed server-side. A client
      // that names a figure can only ever name a stale one, so the default is
      // to name none.
      final c = canonical(<String, dynamic>{
        'data': <String, dynamic>{
          'bookingId': 42,
          'outcome': 'requested',
          'amount': 1500.0,
          'currency': 'PHP',
        },
      });

      await c.source.requestRefund(
        bookingId: '42',
        request: const RefundRequest(trigger: RefundTrigger.duplicatePayment),
      );

      final body = jsonDecode(c.recorder.bodies.single) as Map<String, dynamic>;
      expect(body['trigger'], 'DUPLICATE_PAYMENT');
      expect(body.containsKey('amount'), isFalse);
    });

    test('the customer trigger list matches the backend initiators', () {
      // REFUND_TRIGGERS[…].initiators includes 'customer' for exactly these
      // four. Offering an admin-only trigger would produce
      // REFUND_OUTCOME_NOT_REFUNDABLE — a refusal the customer can do nothing
      // about, on a screen about their money.
      final offered =
          RefundTrigger.customerChoices.map((t) => t.wireName).toSet();
      expect(offered, <String>{
        'CUSTOMER_CANCELLED',
        'PROVIDER_CANCELLED',
        'SERVICE_NOT_DELIVERED',
        'DUPLICATE_PAYMENT',
      });

      for (final adminOnly in <String>[
        'ADMIN_CANCELLED',
        'DISPUTE_UPHELD',
        'ADMIN_DISCRETION',
      ]) {
        expect(offered, isNot(contains(adminOnly)));
        // Still parseable, because an admin may have issued one and the
        // customer is now reading the result.
        expect(RefundTrigger.fromWire(adminOnly), isNotNull);
      }
    });

    test('every modelled trigger is one the backend knows', () {
      const backend = <String>{
        'CUSTOMER_CANCELLED', 'PROVIDER_CANCELLED', 'ADMIN_CANCELLED',
        'DISPUTE_UPHELD', 'SERVICE_NOT_DELIVERED', 'DUPLICATE_PAYMENT',
        'ADMIN_DISCRETION',
      };
      for (final t in RefundTrigger.values) {
        expect(backend, contains(t.wireName));
      }
    });
  });

  // ── The narrow question ────────────────────────────────────────────────────

  group('isPaid', () {
    test('answers from whichever transport is active', () async {
      final legacy = _FakeLegacyApi()
        ..bookingResponse = <String, dynamic>{
          'booking': <String, dynamic>{'paymentStatus': 'PENDING'},
        };
      final repo = PaymentsRepository(
        compatibility: PaymentsCompatibilityDataSource(legacy),
      );

      expect(await repo.isPaid('42'), isFalse);

      legacy.bookingResponse = <String, dynamic>{
        'booking': <String, dynamic>{'paymentStatus': 'PAID'},
      };
      expect(await repo.isPaid('42'), isTrue);
    });
  });
}

/// A compatibility source that fails the test if it is ever asked anything.
class _NeverCalled implements PaymentsDataSource {
  const _NeverCalled();

  @override
  bool get supportsRefunds => false;

  @override
  bool get hasPaymentEndpoint => false;

  @override
  Future<PaymentIntent> startCheckout(String bookingId) =>
      throw StateError('not expected in this test');

  @override
  Future<BookingPayment> payment(String bookingId) =>
      throw StateError('not expected in this test');

  @override
  Future<RefundResult> requestRefund({
    required String bookingId,
    required RefundRequest request,
  }) =>
      throw StateError('not expected in this test');
}
