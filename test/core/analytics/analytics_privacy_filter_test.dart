import 'package:flutter_test/flutter_test.dart';
import 'package:client/core/analytics/data/analytics_privacy_filter.dart';
import 'package:client/core/analytics/domain/analytics_consent.dart';
import 'package:client/core/analytics/domain/analytics_event.dart';
import 'package:client/core/analytics/events/auth_events.dart';
import 'package:client/core/analytics/events/booking_events.dart';
import 'package:client/core/analytics/events/message_events.dart';
import 'package:client/core/analytics/events/review_events.dart';
import 'package:client/core/analytics/events/support_events.dart';

// Concrete test-double event for injecting arbitrary properties.
final class _FakeEvent extends AnalyticsEvent {
  const _FakeEvent(this._props);
  final Map<String, Object?> _props;
  @override
  String get eventName => 'test_event';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties => _props;
}

void main() {
  const filter = AnalyticsPrivacyFilter();

  group('AnalyticsPrivacyFilter — banned keys', () {
    test('drops email property', () {
      const fake =
          _FakeEvent({'email': 'user@test.com', 'auth_method': 'email'});
      final (:clean, :violations) = filter.filter(fake);
      expect(clean.containsKey('email'), false);
      expect(clean['auth_method'], 'email');
      expect(violations.any((v) => v.contains('BANNED:email')), true);
    });

    test('drops mobile property', () {
      const fake =
          _FakeEvent({'mobile': '09171234567', 'auth_method': 'email'});
      final (:clean, :violations) = filter.filter(fake);
      expect(clean.containsKey('mobile'), false);
      expect(violations.any((v) => v.contains('BANNED:mobile')), true);
    });

    test('drops coordinates — lat/lon', () {
      const fake =
          _FakeEvent({'lat': 14.5, 'lon': 121.0, 'service_category': 'aircon'});
      final (:clean, :violations) = filter.filter(fake);
      expect(clean.containsKey('lat'), false);
      expect(clean.containsKey('lon'), false);
      expect(clean['service_category'], 'aircon');
    });

    test('drops token property', () {
      const fake = _FakeEvent({'token': 'eyJhbGciOiJSUzI1NiJ9.payload.sig'});
      final (:clean, :violations) = filter.filter(fake);
      expect(clean.containsKey('token'), false);
    });

    test('drops checkout_url', () {
      const fake =
          _FakeEvent({'checkout_url': 'https://checkout.paymongo.com/pay/x'});
      final (:clean, :violations) = filter.filter(fake);
      expect(clean.containsKey('checkout_url'), false);
    });

    test('drops message_body', () {
      const fake =
          _FakeEvent({'message_body': 'Hello provider please call me'});
      final (:clean, :violations) = filter.filter(fake);
      expect(clean.containsKey('message_body'), false);
    });

    test('drops review_text', () {
      const fake = _FakeEvent({'review_text': 'Excellent service!'});
      final (:clean, :violations) = filter.filter(fake);
      expect(clean.containsKey('review_text'), false);
    });

    test('drops customer_id', () {
      const fake =
          _FakeEvent({'customer_id': 'cust-uuid-123', 'auth_method': 'google'});
      final (:clean, :violations) = filter.filter(fake);
      expect(clean.containsKey('customer_id'), false);
      expect(clean['auth_method'], 'google');
    });

    test('drops booking_id', () {
      const fake = _FakeEvent(
          {'booking_id': 'booking-123', 'service_category': 'aircon'});
      final (:clean, :violations) = filter.filter(fake);
      expect(clean.containsKey('booking_id'), false);
    });

    test('drops support description', () {
      const fake = _FakeEvent({'support_description': 'My booking went wrong'});
      final (:clean, :violations) = filter.filter(fake);
      expect(clean.containsKey('support_description'), false);
    });
  });

  group('AnalyticsPrivacyFilter — PII value detection', () {
    test('drops string value containing email address', () {
      const fake = _FakeEvent({'auth_method': 'user@example.com'});
      final (:clean, :violations) = filter.filter(fake);
      expect(clean.containsKey('auth_method'), false);
      expect(violations.any((v) => v.contains('PII_VALUE')), true);
    });

    test('drops string value containing PH phone number', () {
      const fake = _FakeEvent({'auth_method': '09181234567'});
      final (:clean, :violations) = filter.filter(fake);
      expect(clean.containsKey('auth_method'), false);
    });

    test('drops oversized string (>200 chars, likely free text)', () {
      final fake = _FakeEvent({'result': 'x' * 201});
      final (:clean, :violations) = filter.filter(fake);
      expect(clean.containsKey('result'), false);
    });
  });

  group('AnalyticsPrivacyFilter — allowlist enforcement', () {
    test('passes allowed properties through', () {
      const fake = _FakeEvent({
        'auth_method': 'email',
        'failure_code': 'invalid_credentials',
        'entry_source': 'home',
      });
      final (:clean, :violations) = filter.filter(fake);
      expect(clean['auth_method'], 'email');
      expect(clean['failure_code'], 'invalid_credentials');
      expect(clean['entry_source'], 'home');
      expect(violations.where((v) => v.startsWith('BANNED')), isEmpty);
    });

    test('strips unknown (unlisted) keys', () {
      const fake = _FakeEvent({
        'auth_method': 'email',
        'completely_new_key': 'some_value',
      });
      final (:clean, :violations) = filter.filter(fake);
      expect(clean['auth_method'], 'email');
      expect(clean.containsKey('completely_new_key'), false);
      expect(violations.any((v) => v.startsWith('UNLISTED')), true);
    });

    test('empty event passes through cleanly', () {
      const fake = _FakeEvent({});
      final (:clean, :violations) = filter.filter(fake);
      expect(clean, isEmpty);
      expect(violations, isEmpty);
    });
  });

  group('AnalyticsPrivacyFilter — real event types', () {
    test('SignInStartedEvent passes', () {
      const event = SignInStartedEvent(authMethod: 'email');
      final (:clean, :violations) = filter.filter(event);
      expect(clean['auth_method'], 'email');
      expect(violations.where((v) => v.startsWith('BANNED')), isEmpty);
    });

    test('BookingStartedEvent passes', () {
      const event = BookingStartedEvent(
        serviceCategory: 'aircon',
        entrySource: 'home',
      );
      final (:clean, :violations) = filter.filter(event);
      expect(clean['service_category'], 'aircon');
      expect(clean['entry_source'], 'home');
      expect(violations.where((v) => v.startsWith('BANNED')), isEmpty);
    });

    test('MessageSendStartedEvent passes (no body)', () {
      const event = MessageSendStartedEvent(contentType: 'text');
      final (:clean, :violations) = filter.filter(event);
      expect(clean['content_type'], 'text');
      expect(violations.where((v) => v.startsWith('BANNED')), isEmpty);
    });

    test('ReviewSubmittedEvent passes (no text)', () {
      const event = ReviewSubmittedEvent(
        ratingBucket: '5',
        serviceCategory: 'aircon',
        hasPublicComment: true,
        hasPrivateFeedback: false,
      );
      final (:clean, :violations) = filter.filter(event);
      expect(clean['rating_bucket'], '5');
      expect(clean['has_public_comment'], true);
      expect(violations.where((v) => v.startsWith('BANNED')), isEmpty);
    });

    test('SupportTicketSubmittedEvent passes (no description)', () {
      const event =
          SupportTicketSubmittedEvent(supportCategory: 'booking_issue');
      final (:clean, :violations) = filter.filter(event);
      expect(clean['support_category'], 'booking_issue');
      expect(violations.where((v) => v.startsWith('BANNED')), isEmpty);
    });
  });
}
