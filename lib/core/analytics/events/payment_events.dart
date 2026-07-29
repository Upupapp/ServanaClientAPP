import '../domain/analytics_consent.dart';
import '../domain/analytics_event.dart';
import '../domain/analytics_property.dart';

// CLIENT_INTERACTION: customer chose a method
final class PaymentMethodSelectedEvent extends AnalyticsEvent {
  const PaymentMethodSelectedEvent({required this.paymentMethod});
  final String paymentMethod;
  @override String get eventName => 'payment_method_selected';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties =>
      {AnalyticsKeys.paymentMethod: paymentMethod};
}

// CLIENT_INTERACTION: checkout webview opened
final class CheckoutOpenedEvent extends AnalyticsEvent {
  const CheckoutOpenedEvent(
      {required this.checkoutProvider, required this.amountBand});
  final String checkoutProvider;
  final String amountBand;
  @override String get eventName => 'checkout_opened';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties => {
        AnalyticsKeys.checkoutProvider: checkoutProvider,
        AnalyticsKeys.amountBand: amountBand,
      };
}

// CLIENT_OBSERVATION: user returned from checkout
final class CheckoutReturnedEvent extends AnalyticsEvent {
  const CheckoutReturnedEvent({required this.paymentStatus});
  final String paymentStatus;
  @override String get eventName => 'checkout_returned';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties =>
      {AnalyticsKeys.paymentStatus: paymentStatus};
}

// CLIENT_OBSERVATION: payment status polling result shown to user.
// NOTE: Never treat this as financial truth — backend events are authoritative.
final class PaymentStatusCheckedEvent extends AnalyticsEvent {
  const PaymentStatusCheckedEvent({required this.paymentStatus});
  final String paymentStatus;
  @override String get eventName => 'payment_status_checked';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties =>
      {AnalyticsKeys.paymentStatus: paymentStatus};
}

// CLIENT_OBSERVATION: success screen was shown.
// Financial confirmation must come from backend payment_captured event.
final class PaymentSucceededObservedEvent extends AnalyticsEvent {
  const PaymentSucceededObservedEvent(
      {required this.paymentMethod, required this.amountBand});
  final String paymentMethod;
  final String amountBand;
  @override String get eventName => 'payment_succeeded_observed';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override String? get dedupKey => 'payment_succeeded';
  @override Map<String, Object?> get properties => {
        AnalyticsKeys.paymentMethod: paymentMethod,
        AnalyticsKeys.amountBand: amountBand,
      };
}

final class PaymentFailedEvent extends AnalyticsEvent {
  const PaymentFailedEvent(
      {required this.paymentMethod, required this.failureCode});
  final String paymentMethod;
  final String failureCode;
  @override String get eventName => 'payment_failed';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties => {
        AnalyticsKeys.paymentMethod: paymentMethod,
        AnalyticsKeys.failureCode: failureCode,
      };
}

final class PaymentRetrySelectedEvent extends AnalyticsEvent {
  const PaymentRetrySelectedEvent({required this.paymentMethod});
  final String paymentMethod;
  @override String get eventName => 'payment_retry_selected';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties =>
      {AnalyticsKeys.paymentMethod: paymentMethod};
}

final class RefundStatusViewedEvent extends AnalyticsEvent {
  const RefundStatusViewedEvent({required this.paymentStatus});
  final String paymentStatus;
  @override String get eventName => 'refund_status_viewed';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties =>
      {AnalyticsKeys.paymentStatus: paymentStatus};
}
