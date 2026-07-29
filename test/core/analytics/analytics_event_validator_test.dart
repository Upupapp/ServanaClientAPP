import 'package:flutter_test/flutter_test.dart';
import 'package:client/core/analytics/data/analytics_event_validator.dart';
import 'package:client/core/analytics/events/auth_events.dart';
import 'package:client/core/analytics/events/booking_events.dart';
import 'package:client/core/analytics/events/payment_events.dart';
import 'package:client/core/analytics/events/search_events.dart';
import 'package:client/core/analytics/domain/analytics_event.dart';
import 'package:client/core/analytics/domain/analytics_consent.dart';

void main() {
  const validator = AnalyticsEventValidator();

  group('AnalyticsEventValidator — event name format', () {
    test('valid lower_snake_case names pass', () {
      for (final event in _allRealEvents()) {
        final result = validator.validate(event);
        expect(result.isValid, true, reason: '${event.eventName} should be valid');
      }
    });

    test('event name with uppercase fails', () {
      final event = _NamedEvent('BookingStarted', {});
      final result = validator.validate(event);
      expect(result.isValid, false);
      expect(result.result, ValidationResult.invalidName);
    });

    test('event name with spaces fails', () {
      final event = _NamedEvent('booking started', {});
      final result = validator.validate(event);
      expect(result.isValid, false);
    });

    test('event name with hyphens fails', () {
      final event = _NamedEvent('booking-started', {});
      final result = validator.validate(event);
      expect(result.isValid, false);
    });

    test('event name starting with number fails', () {
      final event = _NamedEvent('1booking', {});
      final result = validator.validate(event);
      expect(result.isValid, false);
    });

    test('event name over 40 chars fails', () {
      final event = _NamedEvent('a' * 41, {});
      final result = validator.validate(event);
      expect(result.isValid, false);
    });

    test('empty event name fails', () {
      final event = _NamedEvent('', {});
      final result = validator.validate(event);
      expect(result.isValid, false);
    });

    test('single char event name passes', () {
      final event = _NamedEvent('a', {});
      final result = validator.validate(event);
      expect(result.isValid, true);
    });

    test('exactly 40 char name passes', () {
      final event = _NamedEvent('a' * 40, {});
      final result = validator.validate(event);
      expect(result.isValid, true);
    });
  });

  group('AnalyticsEventValidator — property key format', () {
    test('valid property keys pass', () {
      final event = _NamedEvent('test_event', {
        'auth_method': 'email',
        'failure_code': 'network_error',
        'step_number': 2,
      });
      final result = validator.validate(event);
      expect(result.isValid, true);
    });

    test('property key with uppercase fails', () {
      final event = _NamedEvent('test_event', {'authMethod': 'email'});
      final result = validator.validate(event);
      expect(result.isValid, false);
      expect(result.result, ValidationResult.missingRequiredProperty);
    });

    test('property key with hyphen fails', () {
      final event = _NamedEvent('test_event', {'auth-method': 'email'});
      final result = validator.validate(event);
      expect(result.isValid, false);
    });
  });

  group('AnalyticsEventValidator — all production events pass', () {
    test('all auth events have valid names', () {
      final events = [
        const SignInStartedEvent(authMethod: 'email'),
        const SignInSucceededEvent(authMethod: 'email'),
        const SignInFailedEvent(authMethod: 'email', failureCode: 'network_error'),
        const GuestModeSelectedEvent(),
        const LoggedOutEvent(trigger: 'user_action'),
        const RegistrationStartedEvent(entrySource: 'welcome'),
        const RegistrationStepCompletedEvent(step: 1),
        const RegistrationSucceededEvent(),
        const RegistrationFailedEvent(failureCode: 'network_error'),
      ];
      for (final e in events) {
        expect(validator.validate(e).isValid, true, reason: e.eventName);
      }
    });

    test('all booking events have valid names', () {
      final events = [
        const BookingStartedEvent(serviceCategory: 'aircon', entrySource: 'home'),
        const BookingSubmittedEvent(serviceCategory: 'aircon'),
        const BookingCreatedEvent(serviceCategory: 'aircon'),
        const BookingFailedEvent(serviceCategory: 'aircon', failureCode: 'network_error'),
        const BookingAbandonedEvent(serviceCategory: 'aircon', step: 'address'),
      ];
      for (final e in events) {
        expect(validator.validate(e).isValid, true, reason: e.eventName);
      }
    });

    test('all payment events have valid names', () {
      final events = [
        const PaymentMethodSelectedEvent(paymentMethod: 'gcash'),
        const CheckoutOpenedEvent(checkoutProvider: 'paymongo', amountBand: '501-1000'),
        const CheckoutReturnedEvent(paymentStatus: 'pending'),
        const PaymentSucceededObservedEvent(paymentMethod: 'gcash', amountBand: '501-1000'),
        const PaymentFailedEvent(paymentMethod: 'gcash', failureCode: 'payment_declined'),
      ];
      for (final e in events) {
        expect(validator.validate(e).isValid, true, reason: e.eventName);
      }
    });

    test('all search events have valid names', () {
      final events = [
        const SearchOpenedEvent(entrySource: 'home'),
        const SearchSubmittedEvent(queryLengthBucket: '<10', queryTokenCountBucket: '1'),
        const SearchResultsLoadedEvent(resultCountBucket: '1-10', latencyBucket: '<500ms'),
        const SearchZeroResultsEvent(queryLengthBucket: '<10'),
        const SearchFailedEvent(failureCode: 'network_error'),
      ];
      for (final e in events) {
        expect(validator.validate(e).isValid, true, reason: e.eventName);
      }
    });

    test('screen_view event passes', () {
      const event = ScreenViewEvent(screenName: 'home', previousScreen: 'splash');
      expect(validator.validate(event).isValid, true);
    });
  });
}

List<AnalyticsEvent> _allRealEvents() => [
  const SignInStartedEvent(authMethod: 'email'),
  const SignInSucceededEvent(authMethod: 'email'),
  const SignInFailedEvent(authMethod: 'email', failureCode: 'network_error'),
  const GuestModeSelectedEvent(),
  const LoggedOutEvent(trigger: 'user_action'),
  const BookingStartedEvent(serviceCategory: 'aircon', entrySource: 'home'),
  const BookingCreatedEvent(serviceCategory: 'aircon'),
  const BookingFailedEvent(serviceCategory: 'aircon', failureCode: 'network_error'),
  const PaymentMethodSelectedEvent(paymentMethod: 'gcash'),
  const CheckoutOpenedEvent(checkoutProvider: 'paymongo', amountBand: '501-1000'),
  const SearchOpenedEvent(entrySource: 'home'),
  const SearchSubmittedEvent(queryLengthBucket: '<10', queryTokenCountBucket: '1'),
  const ScreenViewEvent(screenName: 'home'),
];

final class _NamedEvent extends AnalyticsEvent {
  _NamedEvent(this._name, this._props);
  final String _name;
  final Map<String, Object?> _props;
  @override String get eventName => _name;
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties => _props;
}
