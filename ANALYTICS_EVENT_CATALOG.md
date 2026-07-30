# Analytics Event Catalog — Servana Customer App

Generated from `lib/core/analytics/events/` · C21 ANALYTICSCORE+ · 120 events

**Consent categories**: `essential` (always fires) · `analytics` (requires explicit user opt-in per PDPA/GDPR)

---

## Auth & Session (15 events)

| Event name | Class | Consent | dedup | Properties |
|---|---|---|---|---|
| `app_opened` | `AppOpenedEvent` | analytics | `app_opened:{launchType}` | `launch_type` |
| `session_restored` | `SessionRestoredEvent` | analytics | — | `has_session` |
| `auth_entry_viewed` | `AuthEntryViewedEvent` | analytics | — | `entry_source` |
| `sign_in_started` | `SignInStartedEvent` | analytics | — | `auth_method` |
| `sign_in_succeeded` | `SignInSucceededEvent` | analytics | `sign_in_succeeded:{authMethod}` | `auth_method` |
| `sign_in_failed` | `SignInFailedEvent` | analytics | — | `auth_method`, `failure_code` |
| `registration_started` | `RegistrationStartedEvent` | analytics | — | `entry_source` |
| `registration_step_completed` | `RegistrationStepCompletedEvent` | analytics | — | `step_number` |
| `registration_succeeded` | `RegistrationSucceededEvent` | analytics | `registration_succeeded` | — |
| `registration_failed` | `RegistrationFailedEvent` | analytics | — | `failure_code` |
| `otp_requested` | `OtpRequestedEvent` | analytics | — | `otp_context` |
| `otp_verified` | `OtpVerifiedEvent` | analytics | — | `otp_context` |
| `otp_failed` | `OtpFailedEvent` | analytics | — | `otp_context`, `failure_code` |
| `guest_mode_selected` | `GuestModeSelectedEvent` | analytics | — | — |
| `logged_out` | `LoggedOutEvent` | analytics | — | `logout_trigger` |

---

## Home & Onboarding (10 events)

| Event name | Class | Consent | dedup | Properties |
|---|---|---|---|---|
| `home_viewed` | `HomeViewedEvent` | analytics | `home_viewed` | `account_state` |
| `home_search_selected` | `HomeSearchSelectedEvent` | analytics | — | — |
| `home_category_selected` | `HomeCategorySelectedEvent` | analytics | — | `category_key` |
| `home_service_selected` | `HomeServiceSelectedEvent` | analytics | — | `service_category`, `surface` |
| `home_active_booking_selected` | `HomeActiveBookingSelectedEvent` | analytics | — | `booking_status_category` |
| `home_promotion_selected` | `HomePromotionSelectedEvent` | analytics | — | `promotion_category` |
| `onboarding_started` | `OnboardingStartedEvent` | analytics | — | `entry_source` |
| `onboarding_card_viewed` | `OnboardingCardViewedEvent` | analytics | — | `card_key`, `step_number` |
| `onboarding_skipped` | `OnboardingSkippedEvent` | analytics | — | `step_number` |
| `onboarding_completed` | `OnboardingCompletedEvent` | analytics | `onboarding_completed` | — |

---

## Search (8 events)

| Event name | Class | Consent | dedup | Properties |
|---|---|---|---|---|
| `search_opened` | `SearchOpenedEvent` | analytics | — | `entry_source` |
| `search_submitted` | `SearchSubmittedEvent` | analytics | — | `query_length_bucket`, `query_token_count_bucket`, `category_key`?, `sort_key`?, `filter_count` |
| `search_results_loaded` | `SearchResultsLoadedEvent` | analytics | — | `result_count_bucket`, `latency_bucket` |
| `search_zero_results` | `SearchZeroResultsEvent` | analytics | — | `query_length_bucket` |
| `search_result_selected` | `SearchResultSelectedEvent` | analytics | — | `service_category`, `position_bucket` |
| `search_suggestion_selected` | `SearchSuggestionSelectedEvent` | analytics | — | — |
| `search_filter_applied` | `SearchFilterAppliedEvent` | analytics | — | `filter_count`, `category_key`? |
| `search_failed` | `SearchFailedEvent` | analytics | — | `failure_code` |

---

## Categories & Booking (20 events)

| Event name | Class | Consent | dedup | Properties |
|---|---|---|---|---|
| `category_reveal_shown` | `CategoryRevealShownEvent` | analytics | `category_reveal:{categoryKey}` | `category_key` |
| `category_viewed` | `CategoryViewedEvent` | analytics | — | `category_key`, `entry_source` |
| `service_viewed` | `ServiceViewedEvent` | analytics | — | `service_category`, `entry_source` |
| `service_availability_checked` | `ServiceAvailabilityCheckedEvent` | analytics | — | `service_category`, `availability_result` |
| `booking_started` | `BookingStartedEvent` | analytics | — | `service_category`, `entry_source` |
| `booking_option_confirmed` | `BookingOptionConfirmedEvent` | analytics | — | `service_category`, `option_type` |
| `booking_addons_confirmed` | `BookingAddonsConfirmedEvent` | analytics | — | `service_category`, `addon_count` |
| `booking_address_selected` | `BookingAddressSelectedEvent` | analytics | — | `address_source`, `service_category` |
| `booking_schedule_selected` | `BookingScheduleSelectedEvent` | analytics | — | `service_category`, `schedule_type` |
| `booking_quote_requested` | `BookingQuoteRequestedEvent` | analytics | — | `service_category` |
| `booking_quote_loaded` | `BookingQuoteLoadedEvent` | analytics | — | `service_category`, `quote_result`, `amount_band`, `latency_bucket` |
| `booking_summary_viewed` | `BookingSummaryViewedEvent` | analytics | — | `service_category` |
| `booking_submitted` | `BookingSubmittedEvent` | analytics | — | `service_category` |
| `booking_created` | `BookingCreatedEvent` | analytics | `booking_created:{serviceCategory}` | `service_category`, `payment_method`?, `amount_band`? |
| `booking_failed` | `BookingFailedEvent` | analytics | — | `service_category`, `failure_code` |
| `booking_abandoned` | `BookingAbandonedEvent` | analytics | — | `service_category`, `step` |
| `booking_detail_viewed` | `BookingDetailViewedEvent` | analytics | — | `booking_status_category` |
| `booking_cancel_started` | `BookingCancelStartedEvent` | analytics | — | `booking_status_category` |
| `booking_cancel_succeeded` | `BookingCancelSucceededEvent` | analytics | — | — |
| `booking_repeat_started` | `BookingRepeatStartedEvent` | analytics | — | `service_category` |

---

## Payment (8 events)

| Event name | Class | Consent | dedup | Properties |
|---|---|---|---|---|
| `payment_method_selected` | `PaymentMethodSelectedEvent` | analytics | — | `payment_method` |
| `checkout_opened` | `CheckoutOpenedEvent` | analytics | — | `checkout_provider`, `amount_band` |
| `checkout_returned` | `CheckoutReturnedEvent` | analytics | — | `payment_status` |
| `payment_status_checked` | `PaymentStatusCheckedEvent` | analytics | — | `payment_status` |
| `payment_succeeded_observed` | `PaymentSucceededObservedEvent` | analytics | `payment_succeeded` | `payment_method`, `amount_band` |
| `payment_failed` | `PaymentFailedEvent` | analytics | — | `payment_method`, `failure_code` |
| `payment_retry_selected` | `PaymentRetrySelectedEvent` | analytics | — | `payment_method` |
| `refund_status_viewed` | `RefundStatusViewedEvent` | analytics | — | `payment_status` |

---

## Messaging (7 events)

| Event name | Class | Consent | dedup | Properties |
|---|---|---|---|---|
| `messages_opened` | `MessagesOpenedEvent` | analytics | `messages_opened` | — |
| `conversation_opened` | `ConversationOpenedEvent` | analytics | — | `booking_status_category`, `entry_source` |
| `message_send_started` | `MessageSendStartedEvent` | analytics | — | `content_type` |
| `message_send_succeeded` | `MessageSendSucceededEvent` | analytics | — | `content_type` |
| `message_send_failed` | `MessageSendFailedEvent` | analytics | — | `content_type`, `failure_code` |
| `message_retry_selected` | `MessageRetrySelectedEvent` | analytics | — | — |
| `conversation_marked_read` | `ConversationMarkedReadEvent` | analytics | — | — |

---

## Tracking (7 events)

| Event name | Class | Consent | dedup | Properties |
|---|---|---|---|---|
| `tracking_opened` | `TrackingOpenedEvent` | analytics | — | `tracking_status_category`, `entry_source` |
| `tracking_snapshot_loaded` | `TrackingSnapshotLoadedEvent` | analytics | — | `freshness_category`, `tracking_status_category` |
| `tracking_live_connected` | `TrackingLiveConnectedEvent` | analytics | — | — |
| `tracking_reconnecting` | `TrackingReconnectingEvent` | analytics | — | — |
| `tracking_stale_state_shown` | `TrackingStaleStateShownEvent` | analytics | — | `freshness_category` |
| `tracking_message_selected` | `TrackingMessageSelectedEvent` | analytics | — | — |
| `tracking_support_selected` | `TrackingSupportSelectedEvent` | analytics | — | — |

---

## Profile (11 events)

| Event name | Class | Consent | dedup | Properties |
|---|---|---|---|---|
| `profile_opened` | `ProfileOpenedEvent` | analytics | — | `profile_completion_band` |
| `profile_edit_started` | `ProfileEditStartedEvent` | analytics | — | `field_category` |
| `profile_update_succeeded` | `ProfileUpdateSucceededEvent` | analytics | — | `field_category` |
| `profile_update_failed` | `ProfileUpdateFailedEvent` | analytics | — | `field_category`, `failure_code` |
| `profile_photo_started` | `ProfilePhotoStartedEvent` | analytics | — | — |
| `profile_photo_succeeded` | `ProfilePhotoSucceededEvent` | analytics | — | — |
| `contact_verification_started` | `ContactVerificationStartedEvent` | analytics | — | `verification_type` |
| `contact_verification_succeeded` | `ContactVerificationSucceededEvent` | analytics | `contact_verify:{verificationType}` | `verification_type` |
| `address_created` | `AddressCreatedEvent` | analytics | — | `address_source` |
| `address_set_primary` | `AddressSetPrimaryEvent` | analytics | — | — |
| `address_deleted` | `AddressDeletedEvent` | analytics | — | — |

---

## Notifications (8 events)

| Event name | Class | Consent | dedup | Properties |
|---|---|---|---|---|
| `notification_permission_prompt_shown` | `NotificationPermissionPromptShownEvent` | analytics | `notif_perm_prompt` | — |
| `notification_permission_granted` | `NotificationPermissionGrantedEvent` | analytics | `notif_perm_granted` | — |
| `notification_permission_denied` | `NotificationPermissionDeniedEvent` | analytics | `notif_perm_denied` | — |
| `notification_received_foreground` | `NotificationReceivedForegroundEvent` | analytics | — | `notification_type` |
| `notification_opened` | `NotificationOpenedEvent` | analytics | — | `notification_type`, `app_state`, `route_key`? |
| `notification_deep_link_succeeded` | `NotificationDeepLinkSucceededEvent` | analytics | — | `route_key` |
| `notification_deep_link_failed` | `NotificationDeepLinkFailedEvent` | analytics | — | `route_key`, `failure_code` |
| `notification_marked_read` | `NotificationMarkedReadEvent` | analytics | — | `notification_type` |

---

## Support & Safety (12 events)

| Event name | Class | Consent | dedup | Properties |
|---|---|---|---|---|
| `support_opened` | `SupportOpenedEvent` | analytics | — | `entry_source` |
| `support_category_selected` | `SupportCategorySelectedEvent` | analytics | — | `support_category` |
| `support_ticket_started` | `SupportTicketStartedEvent` | analytics | — | `support_category` |
| `support_ticket_submitted` | `SupportTicketSubmittedEvent` | analytics | — | `support_category` |
| `support_ticket_failed` | `SupportTicketFailedEvent` | analytics | — | `support_category`, `failure_code` |
| `support_ticket_opened` | `SupportTicketOpenedEvent` | analytics | — | `support_category` |
| `support_reply_succeeded` | `SupportReplySucceededEvent` | analytics | — | — |
| `support_ticket_closed` | `SupportTicketClosedEvent` | analytics | — | — |
| `support_ticket_reopened` | `SupportTicketReopenedEvent` | analytics | — | — |
| `safety_entry_opened` | `SafetyEntryOpenedEvent` | **essential** | — | — |
| `safety_submission_attempted` | `SafetySubmissionAttemptedEvent` | **essential** | — | — |
| `safety_submission_succeeded` | `SafetySubmissionSucceededEvent` | **essential** | `safety_submission_succeeded` | — |

---

## Recovery (8 events)

| Event name | Class | Consent | dedup | Properties |
|---|---|---|---|---|
| `recovery_offline_shown` | `RecoveryOfflineShownEvent` | analytics | — | — |
| `recovery_connection_restored` | `RecoveryConnectionRestoredEvent` | analytics | `recovery_online` | — |
| `recovery_manual_retry` | `RecoveryManualRetryEvent` | analytics | — | `operation_type` |
| `recovery_automatic_retry` | `RecoveryAutomaticRetryEvent` | analytics | — | `operation_type`, `retry_count_bucket` |
| `recovery_operation_reconciled` | `RecoveryOperationReconciledEvent` | analytics | — | `operation_type` |
| `recovery_operation_failed` | `RecoveryOperationFailedEvent` | analytics | — | `operation_type`, `failure_category` |
| `recovery_payment_reconciled` | `RecoveryPaymentReconciledEvent` | analytics | — | `recovery_result` |
| `recovery_socket_reconnected` | `RecoverySocketReconnectedEvent` | analytics | `recovery_socket_reconnected` | — |

---

## Context Properties (auto-attached to every event)

These are set by `AnalyticsContextProvider` and do not need to be declared per-event:

| Key | Description |
|---|---|
| `schema_version` | Pinned at `1` — bumped on breaking schema changes |
| `platform` | `android` \| `ios` |
| `app_version` | Semantic version string (e.g. `1.4.2`) |
| `build_number` | Build number integer as string |
| `environment` | `production` \| `staging` \| `dev` |
| `session_id` | Anonymised per-session identifier |

---

## Privacy Rules

- No event contains raw PII (name, email, phone, address, coordinates, message body, review text).
- `payment_succeeded_observed` is a **client observation** — do not use as financial truth; backend event is authoritative.
- Safety events (`essential`) bypass the analytics consent gate by design.
- Analytics events (all others) are **dark** on first app install until the user grants analytics consent via a consent dialog.
