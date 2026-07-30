import '../domain/analytics_consent.dart';
import '../domain/analytics_event.dart';
import '../domain/analytics_property.dart';

final class AppOpenedEvent extends AnalyticsEvent {
  const AppOpenedEvent({required this.launchType});
  final String launchType; // 'cold_start' | 'warm_start' | 'deep_link'
  @override String get eventName => 'app_opened';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override String? get dedupKey => 'app_opened:$launchType';
  @override Map<String, Object?> get properties =>
      {AnalyticsKeys.launchType: launchType};
}

final class SessionRestoredEvent extends AnalyticsEvent {
  const SessionRestoredEvent({required this.hasSession});
  final bool hasSession;
  @override String get eventName => 'session_restored';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties => {AnalyticsKeys.hasSession: hasSession};
}

final class AuthEntryViewedEvent extends AnalyticsEvent {
  const AuthEntryViewedEvent({required this.entrySource});
  final String entrySource;
  @override String get eventName => 'auth_entry_viewed';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties =>
      {AnalyticsKeys.entrySource: entrySource};
}

final class SignInStartedEvent extends AnalyticsEvent {
  const SignInStartedEvent({required this.authMethod});
  final String authMethod;
  @override String get eventName => 'sign_in_started';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties =>
      {AnalyticsKeys.authMethod: authMethod};
}

final class SignInSucceededEvent extends AnalyticsEvent {
  const SignInSucceededEvent({required this.authMethod});
  final String authMethod;
  @override String get eventName => 'sign_in_succeeded';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override String? get dedupKey => 'sign_in_succeeded:$authMethod';
  @override Map<String, Object?> get properties =>
      {AnalyticsKeys.authMethod: authMethod};
}

final class SignInFailedEvent extends AnalyticsEvent {
  const SignInFailedEvent(
      {required this.authMethod, required this.failureCode});
  final String authMethod;
  final String failureCode;
  @override String get eventName => 'sign_in_failed';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties => {
        AnalyticsKeys.authMethod: authMethod,
        AnalyticsKeys.failureCode: failureCode,
      };
}

final class RegistrationStartedEvent extends AnalyticsEvent {
  const RegistrationStartedEvent({required this.entrySource});
  final String entrySource;
  @override String get eventName => 'registration_started';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties =>
      {AnalyticsKeys.entrySource: entrySource};
}

final class RegistrationStepCompletedEvent extends AnalyticsEvent {
  const RegistrationStepCompletedEvent({required this.step});
  final int step;
  @override String get eventName => 'registration_step_completed';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties =>
      {AnalyticsKeys.stepNumber: step};
}

final class RegistrationSucceededEvent extends AnalyticsEvent {
  const RegistrationSucceededEvent();
  @override String get eventName => 'registration_succeeded';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override String? get dedupKey => 'registration_succeeded';
  @override Map<String, Object?> get properties => {};
}

final class RegistrationFailedEvent extends AnalyticsEvent {
  const RegistrationFailedEvent({required this.failureCode});
  final String failureCode;
  @override String get eventName => 'registration_failed';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties =>
      {AnalyticsKeys.failureCode: failureCode};
}

final class OtpRequestedEvent extends AnalyticsEvent {
  const OtpRequestedEvent({required this.context});
  final String context; // 'booking' | 'registration' | 'email_verify'
  @override String get eventName => 'otp_requested';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties => {AnalyticsKeys.otpContext: context};
}

final class OtpVerifiedEvent extends AnalyticsEvent {
  const OtpVerifiedEvent({required this.context});
  final String context;
  @override String get eventName => 'otp_verified';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties => {AnalyticsKeys.otpContext: context};
}

final class OtpFailedEvent extends AnalyticsEvent {
  const OtpFailedEvent(
      {required this.context, required this.failureCode});
  final String context;
  final String failureCode;
  @override String get eventName => 'otp_failed';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties => {
        AnalyticsKeys.otpContext: context,
        AnalyticsKeys.failureCode: failureCode,
      };
}

final class GuestModeSelectedEvent extends AnalyticsEvent {
  const GuestModeSelectedEvent();
  @override String get eventName => 'guest_mode_selected';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties => {};
}

final class LoggedOutEvent extends AnalyticsEvent {
  const LoggedOutEvent({required this.trigger});
  final String trigger; // 'user_action' | 'session_expired' | 'account_switch'
  @override String get eventName => 'logged_out';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties => {AnalyticsKeys.logoutTrigger: trigger};
}
