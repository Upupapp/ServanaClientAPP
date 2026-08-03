import '../domain/analytics_event.dart';

enum ValidationResult {
  valid,
  invalidName,
  missingRequiredProperty,
  unknownConsentCategory
}

final class EventValidationOutcome {
  const EventValidationOutcome(this.result, {this.reason = ''});
  final ValidationResult result;
  final String reason;
  bool get isValid => result == ValidationResult.valid;
}

final class AnalyticsEventValidator {
  const AnalyticsEventValidator();

  // Event names must be lower_snake_case, 1–40 chars.
  static final _namePattern = RegExp(r'^[a-z][a-z0-9_]{0,39}$');

  EventValidationOutcome validate(AnalyticsEvent event) {
    final name = event.eventName;
    if (!_namePattern.hasMatch(name)) {
      return EventValidationOutcome(
        ValidationResult.invalidName,
        reason: 'Event name "$name" must be lower_snake_case, max 40 chars',
      );
    }
    // Property keys must also be lower_snake_case
    for (final key in event.properties.keys) {
      if (!_namePattern.hasMatch(key)) {
        return EventValidationOutcome(
          ValidationResult.missingRequiredProperty,
          reason: 'Property key "$key" has invalid format in event "$name"',
        );
      }
    }
    return const EventValidationOutcome(ValidationResult.valid);
  }
}
