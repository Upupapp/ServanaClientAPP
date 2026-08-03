# Analytics Property Enums — Servana Customer App

All property keys are declared as constants in `lib/core/analytics/domain/analytics_property.dart`.
**Never** use raw string literals in event property maps — always use `AnalyticsKeys.*`.

---

## AnalyticsKeys — Property Key Registry

### Context (auto-attached by AnalyticsContextProvider)
| Constant | Value | Description |
|---|---|---|
| `schemaVersion` | `schema_version` | Pinned at 1; bump on breaking schema changes |
| `platform` | `platform` | `android` or `ios` |
| `appVersion` | `app_version` | Semantic version |
| `buildNumber` | `build_number` | Build number |
| `environment` | `environment` | `production` / `staging` / `dev` |
| `sessionId` | `session_id` | Anonymised per-session id |

### Navigation
| Constant | Value | Description |
|---|---|---|
| `screenName` | `screen_name` | Route name |
| `screenClass` | `screen_class` | Widget class name |
| `previousScreen` | `previous_screen` | Last screen |
| `entrySource` | `entry_source` | See `EntrySourceValues` |
| `launchType` | `launch_type` | `cold_start` / `warm_start` / `deep_link` |
| `navigationType` | `navigation_type` | — |
| `deepLinkType` | `deep_link_type` | — |

### Auth
| Constant | Value | Description |
|---|---|---|
| `authMethod` | `auth_method` | See `AuthMethodValues` |
| `identifierType` | `identifier_type` | reserved: `email` / `phone` |
| `hasSession` | `has_session` | Boolean |
| `otpContext` | `otp_context` | `booking` / `registration` / `email_verify` |
| `logoutTrigger` | `logout_trigger` | `user_action` / `session_expired` / `account_switch` |
| `step` | `step` | Step name string |
| `stepNumber` | `step_number` | Int |
| `failureCode` | `failure_code` | See `FailureCodeValues` |

### Onboarding
| Constant | Value | Description |
|---|---|---|
| `cardKey` | `card_key` | Onboarding card identifier |
| `completionBand` | `completion_band` | Profile completion band |

### Category
| Constant | Value | Description |
|---|---|---|
| `categoryKey` | `category_key` | Service category identifier |

### Search
| Constant | Value | Description |
|---|---|---|
| `queryLengthBucket` | `query_length_bucket` | Bucketed query character count |
| `queryTokenCountBucket` | `query_token_count_bucket` | Bucketed word count |
| `filterCount` | `filter_count` | Number of active filters |
| `resultCountBucket` | `result_count_bucket` | See `CountBucketValues` |
| `latencyBucket` | `latency_bucket` | See `LatencyBucketValues` |
| `sortKey` | `sort_key` | Sort mode identifier |

### Service / Booking
| Constant | Value | Description |
|---|---|---|
| `serviceCategory` | `service_category` | Service domain (e.g. `aircon`, `bw`) |
| `optionType` | `option_type` | Booking option type |
| `addonCount` | `addon_count` | Int |
| `availabilityResult` | `availability_result` | `available` / `unavailable` |
| `coverageResult` | `coverage_result` | — |
| `surface` | `surface` | UI surface (e.g. `home_featured`) |
| `positionBucket` | `position_bucket` | Result position bucket |
| `recommendationType` | `recommendation_type` | — |
| `addressSource` | `address_source` | `map_picker` / `manual` / `search` |
| `scheduleType` | `schedule_type` | `now` / `scheduled` |
| `quoteResult` | `quote_result` | `success` / `error` |
| `bookingStatusCategory` | `booking_status_category` | See `BookingStatusCategoryValues` |

### Payment
| Constant | Value | Description |
|---|---|---|
| `paymentMethod` | `payment_method` | See `PaymentMethodValues` |
| `paymentStatus` | `payment_status` | `pending` / `success` / `failed` / `refunded` |
| `currency` | `currency` | ISO 4217 code |
| `amountBand` | `amount_band` | See `AmountBandValues` |
| `checkoutProvider` | `checkout_provider` | `paymongo` etc. |

### Messaging
| Constant | Value | Description |
|---|---|---|
| `conversationType` | `conversation_type` | — |
| `contentType` | `content_type` | `text` / `attachment` |

### Notifications
| Constant | Value | Description |
|---|---|---|
| `notificationType` | `notification_type` | See `NotificationTypeValues` |
| `routeKey` | `route_key` | GoRouter destination key |
| `appState` | `app_state` | `foreground` / `background` / `terminated` |
| `permissionState` | `permission_state` | — |
| `deliveryChannel` | `delivery_channel` | — |

### Tracking
| Constant | Value | Description |
|---|---|---|
| `trackingStatusCategory` | `tracking_status_category` | — |
| `freshnessCategory` | `freshness_category` | `live` / `stale` etc. |
| `connectionState` | `connection_state` | reserved: future use |

### Profile
| Constant | Value | Description |
|---|---|---|
| `fieldCategory` | `field_category` | `basic_info` / `contact` / `photo` / `address` |
| `verificationType` | `verification_type` | `email` / `phone` |
| `profileCompletionBand` | `profile_completion_band` | — |

### Support
| Constant | Value | Description |
|---|---|---|
| `supportCategory` | `support_category` | See `SupportCategoryValues` |

### Review
| Constant | Value | Description |
|---|---|---|
| `ratingBucket` | `rating_bucket` | `1` through `5` |
| `hasPublicComment` | `has_public_comment` | Boolean |
| `hasPrivateFeedback` | `has_private_feedback` | Boolean |

### Safety
| Constant | Value | Description |
|---|---|---|
| `safetyPath` | `safety_path` | — |
| `severity` | `severity` | — |

### Recovery
| Constant | Value | Description |
|---|---|---|
| `operationType` | `operation_type` | See `RecoveryOperationValues` |
| `recoveryResult` | `recovery_result` | — |
| `retryCountBucket` | `retry_count_bucket` | See `CountBucketValues` |
| `failureCategory` | `failure_category` | — |

### Experiments
| Constant | Value | Description |
|---|---|---|
| `experimentKey` | `experiment_key` | Experiment identifier |
| `variantKey` | `variant_key` | Variant name |
| `assignmentId` | `assignment_id` | — |
| `flagKey` | `flag_key` | Feature flag key |
| `resolvedValue` | `resolved_value` | — |
| `evaluationSource` | `evaluation_source` | — |

### Lifecycle
| Constant | Value | Description |
|---|---|---|
| `accountState` | `account_state` | `authenticated` / `guest` |
| `lifecycleStage` | `lifecycle_stage` | `active` / `inactive` |
| `hasCompletedBooking` | `has_completed_booking` | Boolean |

### Attribution
| Constant | Value | Description |
|---|---|---|
| `utmSource` | `utm_source` | — |
| `utmMedium` | `utm_medium` | — |
| `utmCampaign` | `utm_campaign` | — |
| `referralCategory` | `referral_category` | — |

### Generic
| Constant | Value | Description |
|---|---|---|
| `result` | `result` | See `ResultValues` |
| `modelVersion` | `model_version` | — |
| `promotionCategory` | `promotion_category` | — |
| `featureKey` | `feature_key` | — |
| `errorCategory` | `error_category` | — |
| `appLanguage` | `app_language` | — |
| `deviceLocale` | `device_locale` | — |

---

## Enum Value Sets

### AuthMethodValues
| Constant | Value |
|---|---|
| `email` | `email` |
| `google` | `google` |
| `facebook` | `facebook` |
| `sessionRestore` | `session_restore` |

### FailureCodeValues
| Constant | Value |
|---|---|
| `invalidCredentials` | `invalid_credentials` |
| `invalidOtp` | `invalid_otp` |
| `expiredOtp` | `expired_otp` |
| `rateLimited` | `rate_limited` |
| `networkError` | `network_error` |
| `accountDisabled` | `account_disabled` |
| `notFound` | `not_found` |
| `conflict` | `conflict` |
| `forbidden` | `forbidden` |
| `validation` | `validation` |
| `timeout` | `timeout` |
| `backendUnavailable` | `backend_unavailable` |
| `paymentDeclined` | `payment_declined` |
| `resourceChanged` | `resource_changed` |
| `unknown` | `unknown` |

### ResultValues
| Constant | Value |
|---|---|
| `success` | `success` |
| `failure` | `failure` |
| `cancelled` | `cancelled` |
| `timeout` | `timeout` |
| `skipped` | `skipped` |
| `notEligible` | `not_eligible` |
| `duplicate` | `duplicate` |

### EntrySourceValues
| Constant | Value |
|---|---|
| `home` | `home` |
| `search` | `search` |
| `category` | `category` |
| `notification` | `notification` |
| `deepLink` | `deep_link` |
| `bookingDetail` | `booking_detail` |
| `profilePrompt` | `profile_prompt` |
| `quickBook` | `quick_book` |
| `rebooking` | `rebooking` |
| `direct` | `direct` |
| `unknown` | `unknown` |

### BookingStatusCategoryValues
| Constant | Value |
|---|---|
| `actionRequired` | `action_required` |
| `upcoming` | `upcoming` |
| `active` | `active` |
| `completed` | `completed` |
| `cancelled` | `cancelled` |
| `pending` | `pending` |

### PaymentMethodValues
| Constant | Value |
|---|---|
| `card` | `card` |
| `eWallet` | `e_wallet` |
| `gcash` | `gcash` |
| `maya` | `maya` |
| `grabPay` | `grab_pay` |
| `paymongo` | `paymongo` |
| `unknown` | `unknown` |

### NotificationTypeValues
| Constant | Value |
|---|---|
| `bookingUpdate` | `booking_update` |
| `paymentUpdate` | `payment_update` |
| `messageNew` | `message_new` |
| `assignmentUpdate` | `assignment_update` |
| `supportUpdate` | `support_update` |
| `systemUpdate` | `system_update` |
| `promotion` | `promotion` |
| `unknown` | `unknown` |

### SupportCategoryValues
| Constant | Value |
|---|---|
| `bookingIssue` | `booking_issue` |
| `paymentIssue` | `payment_issue` |
| `providerIssue` | `provider_issue` |
| `serviceQuality` | `service_quality` |
| `accountIssue` | `account_issue` |
| `refundRequest` | `refund_request` |
| `safety` | `safety` |
| `other` | `other` |

### RecoveryOperationValues
| Constant | Value |
|---|---|
| `booking` | `booking` |
| `payment` | `payment` |
| `message` | `message` |
| `upload` | `upload` |
| `profile` | `profile` |
| `unknown` | `unknown` |

### AmountBandValues
| Band | PHP Range |
|---|---|
| `0` | ₱0 |
| `1-500` | ₱1–₱500 |
| `501-1000` | ₱501–₱1,000 |
| `1001-2000` | ₱1,001–₱2,000 |
| `2001-5000` | ₱2,001–₱5,000 |
| `5001+` | ₱5,001+ |

### CountBucketValues
| Bucket | Range |
|---|---|
| `0` | 0 |
| `1` | 1 |
| `2-3` | 2–3 |
| `4-5` | 4–5 |
| `6-10` | 6–10 |
| `11+` | 11 or more |

### LatencyBucketValues
| Bucket | Range |
|---|---|
| `<500ms` | Under 500ms |
| `500-999ms` | 500–999ms |
| `1-2s` | 1,000–1,999ms |
| `2-5s` | 2,000–4,999ms |
| `5s+` | 5,000ms or more |
