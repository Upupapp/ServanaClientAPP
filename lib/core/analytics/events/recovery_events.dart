import '../domain/analytics_consent.dart';
import '../domain/analytics_event.dart';
import '../domain/analytics_property.dart';

// NOTE: No draft content, resource identifiers, or operation payloads.

final class RecoveryOfflineShownEvent extends AnalyticsEvent {
  const RecoveryOfflineShownEvent();
  @override String get eventName => 'recovery_offline_shown';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties => {};
}

final class RecoveryConnectionRestoredEvent extends AnalyticsEvent {
  const RecoveryConnectionRestoredEvent();
  @override String get eventName => 'recovery_connection_restored';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties => {};
}

final class RecoveryManualRetryEvent extends AnalyticsEvent {
  const RecoveryManualRetryEvent({required this.operationType});
  final String operationType;
  @override String get eventName => 'recovery_manual_retry';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties =>
      {AnalyticsKeys.operationType: operationType};
}

final class RecoveryAutomaticRetryEvent extends AnalyticsEvent {
  const RecoveryAutomaticRetryEvent(
      {required this.operationType, required this.retryCountBucket});
  final String operationType;
  final String retryCountBucket;
  @override String get eventName => 'recovery_automatic_retry';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties => {
        AnalyticsKeys.operationType: operationType,
        AnalyticsKeys.retryCountBucket: retryCountBucket,
      };
}

final class RecoveryOperationReconciledEvent extends AnalyticsEvent {
  const RecoveryOperationReconciledEvent({required this.operationType});
  final String operationType;
  @override String get eventName => 'recovery_operation_reconciled';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties =>
      {AnalyticsKeys.operationType: operationType};
}

final class RecoveryOperationFailedEvent extends AnalyticsEvent {
  const RecoveryOperationFailedEvent(
      {required this.operationType, required this.failureCategory});
  final String operationType;
  final String failureCategory;
  @override String get eventName => 'recovery_operation_failed';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties => {
        AnalyticsKeys.operationType: operationType,
        AnalyticsKeys.failureCategory: failureCategory,
      };
}

final class RecoveryPaymentReconciledEvent extends AnalyticsEvent {
  const RecoveryPaymentReconciledEvent({required this.recoveryResult});
  final String recoveryResult;
  @override String get eventName => 'recovery_payment_reconciled';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties =>
      {AnalyticsKeys.recoveryResult: recoveryResult};
}

final class RecoverySocketReconnectedEvent extends AnalyticsEvent {
  const RecoverySocketReconnectedEvent();
  @override String get eventName => 'recovery_socket_reconnected';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties => {};
}
