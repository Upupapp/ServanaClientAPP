import '../domain/analytics_consent.dart';
import '../domain/analytics_event.dart';
import '../domain/analytics_property.dart';

// NOTE: No profile values (name, email, phone, address) in any event.

final class ProfileOpenedEvent extends AnalyticsEvent {
  const ProfileOpenedEvent({required this.completionBand});
  final String completionBand;
  @override
  String get eventName => 'profile_opened';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties =>
      {AnalyticsKeys.profileCompletionBand: completionBand};
}

final class ProfileEditStartedEvent extends AnalyticsEvent {
  const ProfileEditStartedEvent({required this.fieldCategory});
  final String fieldCategory; // 'basic_info' | 'contact' | 'photo' | 'address'
  @override
  String get eventName => 'profile_edit_started';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties =>
      {AnalyticsKeys.fieldCategory: fieldCategory};
}

final class ProfileUpdateSucceededEvent extends AnalyticsEvent {
  const ProfileUpdateSucceededEvent({required this.fieldCategory});
  final String fieldCategory;
  @override
  String get eventName => 'profile_update_succeeded';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties =>
      {AnalyticsKeys.fieldCategory: fieldCategory};
}

final class ProfileUpdateFailedEvent extends AnalyticsEvent {
  const ProfileUpdateFailedEvent(
      {required this.fieldCategory, required this.failureCode});
  final String fieldCategory;
  final String failureCode;
  @override
  String get eventName => 'profile_update_failed';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties => {
        AnalyticsKeys.fieldCategory: fieldCategory,
        AnalyticsKeys.failureCode: failureCode,
      };
}

final class ProfilePhotoStartedEvent extends AnalyticsEvent {
  const ProfilePhotoStartedEvent();
  @override
  String get eventName => 'profile_photo_started';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties => {};
}

final class ProfilePhotoSucceededEvent extends AnalyticsEvent {
  const ProfilePhotoSucceededEvent();
  @override
  String get eventName => 'profile_photo_succeeded';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties => {};
}

final class ContactVerificationStartedEvent extends AnalyticsEvent {
  const ContactVerificationStartedEvent({required this.verificationType});
  final String verificationType; // 'email' | 'phone'
  @override
  String get eventName => 'contact_verification_started';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties =>
      {AnalyticsKeys.verificationType: verificationType};
}

final class ContactVerificationSucceededEvent extends AnalyticsEvent {
  const ContactVerificationSucceededEvent({required this.verificationType});
  final String verificationType;
  @override
  String get eventName => 'contact_verification_succeeded';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  String? get dedupKey => 'contact_verify:$verificationType';
  @override
  Map<String, Object?> get properties =>
      {AnalyticsKeys.verificationType: verificationType};
}

final class AddressCreatedEvent extends AnalyticsEvent {
  const AddressCreatedEvent({required this.addressSource});
  final String addressSource; // 'map_picker' | 'manual' | 'search'
  @override
  String get eventName => 'address_created';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties =>
      {AnalyticsKeys.addressSource: addressSource};
}

final class AddressSetPrimaryEvent extends AnalyticsEvent {
  const AddressSetPrimaryEvent();
  @override
  String get eventName => 'address_set_primary';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties => {};
}

final class AddressDeletedEvent extends AnalyticsEvent {
  const AddressDeletedEvent();
  @override
  String get eventName => 'address_deleted';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties => {};
}
