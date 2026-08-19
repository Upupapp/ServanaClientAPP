# Matrix 1 — Client surface inventory

**Servana Client Mobile Backend Convergence V1 · TAB 01**

| | |
| --- | --- |
| Client repo | `servana_client-main`, branch `main`, HEAD `ce02830` |
| Client version | `1.0.0+38` (`pubspec.yaml`); Play serves `+37` |
| Backend evidence repo | `servana_api-main`, branch `main`, HEAD `36ca152`, **51 commits ahead of `origin/main`** |
| Base URL | `https://api.servana.com.ph` (`lib/common/config/app_config.dart:38`) |
| Method | Static read of both trees. No network call was made to any environment. |

This matrix is the *client half* of TAB 01: every screen, route, outbound call,
DTO and cache the customer app owns. The backend half is
[TAB01_BACKEND_DELTA_MATRIX.md](TAB01_BACKEND_DELTA_MATRIX.md); the judgement
half is [TAB01_CONVERGENCE_RISK_MATRIX.md](TAB01_CONVERGENCE_RISK_MATRIX.md).

---

## 1. Counts

| Surface | Count | Source |
| --- | ---: | --- |
| Dart files under `lib/` | 498 | `find lib -name '*.dart'` |
| Test files under `test/` | 110 | `find test -name '*.dart'` |
| `*Screen` classes | 67 | class scan of `lib/` |
| `GoRoute` entries in the router | 64 | `lib/common/presentation/routes/main_router.dart` |
| Declarations on `ServanaApiClient` | 82 | `lib/common/data/backend/servana_api_client.dart` |
| …public | 78 | 4 are private helpers |
| Public methods that name an endpoint | 76 | excludes the `getBookingDetail` delegator and the `_TimeoutClient.send` override |
| **Distinct legacy endpoints called** (verb + path) | **76** | 77 endpoint-bearing methods, de-duplicated: `getUserProfile` and `loadProfile` share `GET /api/user/profile`, and the private `_exchangeRefreshToken` adds `POST /api/auth/refresh` |
| …public methods with **no production caller** | 13 | call-graph scan of `lib/` |
| `/api/v1` endpoints called | **0** | `grep -rn 'api/v1' lib test` → no match |
| Hive boxes | 4 | `session`, `servana_onboarding`, `catalog_cache_v2`, `registration` |
| Secure-storage caches | 3 | draft, operation journal, pending payment |

**The single most important number here is zero.** The client has no reference
to the canonical `/api/v1` namespace anywhere in `lib/` or `test/`. Convergence
V1 starts from a client that is 100 % on legacy routes.

---

## 2. Screens → routes

64 mounted routes over 67 screen classes. Three screen classes are mounted by a
parent rather than by their own `GoRoute` (`CategoryScreen`,
`SubcategoryScreen`, `ServiceDetailScreen` are reached through the four
`CatalogRoutes` paths), and several placeholder screens share one file.

### 2.1 Landing / auth

| Screen | Route path | Route name | File |
| --- | --- | --- | --- |
| `SplashScreen` | `/splash` | `Splash` | `modules/landing/presentation/screens/splash_screen.dart` |
| `WelcomeScreen` | `/welcome` | `Welcome` | `modules/landing/presentation/screens/welcome_screen.dart` |
| `AuthenticationScreen` | `Authenticate` | `Authenticate` | `modules/authentication/presentation/screens/authentication_screen.dart` |
| `AuthenticationGateScreen` | `/auth-gate` | `AuthGate` | `common/presentation/screens/authentication_gate_screen.dart` |
| `CreateAccountScreen` | `/CreateAccount` | `CreateAccount` | `modules/registration/presentation/screens/create_account_screen.dart` |
| `EmailVerificationScreen` | `/signup/verify-email` | `SignupEmailVerification` | `modules/profile/presentation/screens/email_verification_screen.dart` |
| `ProtectScreen` | — (not mounted) | — | `modules/landing/presentation/screens/protect_screen.dart` |
| `AccountPendingForApprovalScreen` | — (not mounted) | — | `modules/registration/presentation/screens/account_pending_for_approval.dart` |

### 2.2 Home / discovery / catalog

| Screen | Route path | Route name | File |
| --- | --- | --- | --- |
| `HomeScreen` | `/HomeScreen` | `HomeScreen` | `modules/homepage/presentation/screens/home_screen.dart` |
| `SearchScreen` | `SearchScreen` | `SearchScreen` | `modules/homepage/presentation/screens/search_screen.dart` |
| `CategoryExperienceScreen` | `CategoryRoutes.aircon` / `.beautyWellness` / `.hairNails` / `.massage`, plus `category/:categoryKey` | same | `modules/categories/presentation/screens/category_experience_screen.dart` |
| `CatalogBrowseScreen` | `catalog` | `CatalogBrowse` | `modules/catalog/presentation/screens/catalog_browse_screen.dart` |
| `CategoryScreen` | `catalog/category/:categoryId` | `CatalogCategory` | `modules/catalog/presentation/screens/category_screen.dart` |
| `SubcategoryScreen` | `catalog/subcategory/:subcategoryId` | `CatalogSubcategory` | `modules/catalog/presentation/screens/subcategory_screen.dart` |
| `ServiceDetailScreen` | `service/:serviceId` | `CatalogService` | `modules/catalog/presentation/screens/service_detail_screen.dart` |
| `CatalogUnavailableScreen` | — (rendered on catalog load failure) | — | `modules/catalog/presentation/screens/catalog_unavailable_screen.dart` |
| `MerchantMenuScreen` | `MerchantMenuScreen.route` | same | `modules/merchant_menu/presentation/screens/merchant_menu_screen.dart` |
| `StoreItemsScreen` | `StoreItemsScreen.route` | same | `modules/store_items/presentation/screens/store_items_screen.dart` |
| `ServiceCategoryListScreen` | — (widget-level) | — | `common/presentation/widgets/service_category_list_screen.dart` |

### 2.3 Booking funnels

Two parallel funnels — aircon and beauty/wellness — plus a shared OTP and
payment leg.

| Screen | Route path | File |
| --- | --- | --- |
| `AirconOptionsScreen` | `AirconOptions` | `modules/aircon_booking/presentation/screens/aircon_options_screen.dart` |
| `AirconCheckoutScreen` | `AirconCheckout` | `modules/aircon_booking/presentation/screens/aircon_checkout_screen.dart` |
| `AirconConfirmationScreen` | `AirconConfirmation` | `modules/aircon_booking/presentation/screens/aircon_confirmation_screen.dart` |
| `BwOptionsScreen` | `BwOptions` | `modules/bw_booking/presentation/screens/bw_options_screen.dart` |
| `BwAddOnsScreen` | `BwAddOns` | `modules/bw_booking/presentation/screens/bw_addons_screen.dart` |
| `BwBranchSlotScreen` | `BwBranchSlot` | `modules/bw_booking/presentation/screens/bw_branch_slot_screen.dart` |
| `BwCheckoutScreen` | `BwCheckout` | `modules/bw_booking/presentation/screens/bw_checkout_screen.dart` |
| `BwConfirmationScreen` | `BwConfirmation` | `modules/bw_booking/presentation/screens/bw_confirmation_screen.dart` |
| `BookingOtpScreen` | `BookingOtp` | `common/presentation/screens/booking_otp_screen.dart` |
| `PaymentWebViewScreen` | `PaymentWebView` | `common/presentation/screens/payment_webview_screen.dart` |
| `SelectPaymentMethodScreen` | `SelectPaymentMethodScreen.route` | `modules/job_order/presentation/screens/select_payment_method_screen.dart` |
| `JobOrderScreen` | `JobOrderScreen/:id/:name` | `modules/job_order/presentation/screens/job_order_screen.dart` |
| `JobOrderSummaryScreen` | `JobOrderSummaryScreen.route` | `modules/job_order/presentation/screens/job_order_summary_screen.dart` |
| `AddAdditionalItemMenuScreen` | `AddAdditionalItemMenuScreen.route` | `modules/job_order/presentation/screens/add_additional_item_menu_screen.dart` |
| `ItemOptionMenuScreen` (×2 files) | `ItemOptionMenuScreen.route` | `modules/job_order/…`, `modules/merchant_menu/…` |
| `CheckoutJobOrderScreen`, `CashPaymentScreen`, `QRPaymentScreen` | — (not mounted) | `modules/job_order/presentation/screens/` |

### 2.4 Post-booking

| Screen | Route path | File |
| --- | --- | --- |
| `BookingsScreen` | `/Bookings` | `modules/bookings/presentation/screens/bookings_screen.dart` |
| `BookingDetailScreen` | `/bookings/:bookingId` **and** `/booking/:id` | `modules/bookings/presentation/screens/booking_detail_screen.dart` |
| `BookingCalendarScreen` | `/Calendar` | `modules/bookings/presentation/screens/booking_calendar_screen.dart` |
| `LiveTrackingScreen` | `/bookings/:bookingId/track` | `modules/tracking/presentation/screens/live_tracking_screen.dart` |
| `BookingChatScreen` | `/bookings/:bookingId/messages` **and** `/BookingChat/:jobOrderId` | `modules/messaging/presentation/screens/booking_chat_screen.dart` |
| `MessagesInboxScreen` | `/Messages` | `modules/messaging/presentation/screens/messages_inbox_screen.dart` |
| `ReviewFormScreen` | `/review/new` | `modules/review/presentation/screens/review_form_screen.dart` |
| `ReviewDetailScreen` | `/review/detail` | `modules/review/presentation/screens/review_detail_screen.dart` |

Two screens are reachable by two paths each (`BookingDetailScreen`,
`BookingChatScreen`). That is deliberate — notification deep links use the
singular form — and is recorded here because a convergence change that
renumbers booking ids has to update both.

### 2.5 Account, settings, support

| Screen | Route path | File |
| --- | --- | --- |
| `ProfileScreen` | `/Profile` | `modules/profile/presentation/screens/profile_screen.dart` |
| `ProfileEditScreen` | `/settings/profile-edit` | `modules/settings/presentation/screens/profile_edit_screen.dart` |
| `SettingsScreen` | `/Settings` | `common/presentation/screens/drawer_placeholder_screens.dart` |
| `SecurityScreen` | `/settings/security` | `modules/settings/presentation/screens/security_screen.dart` |
| `AppearanceScreen` | `/settings/appearance` | `modules/settings/presentation/screens/appearance_screen.dart` |
| `PermissionsScreen` | `/settings/permissions` | `modules/settings/presentation/screens/permissions_screen.dart` |
| `PrivacyLegalScreen` | `/settings/privacy` | `modules/settings/presentation/screens/privacy_legal_screen.dart` |
| `AboutScreen` | `/settings/about` | `modules/settings/presentation/screens/about_screen.dart` |
| `LanguageScreen` | `/Language` | `common/presentation/screens/drawer_placeholder_screens.dart` |
| `SavedAddressesScreen` | `/SavedAddresses` | `common/presentation/screens/drawer_placeholder_screens.dart` |
| `AddressFormScreen` | — (pushed by parent) | `common/presentation/screens/address_form_screen.dart` |
| `FavouritesScreen` | `/Favourites` | `common/presentation/screens/drawer_placeholder_screens.dart` |
| `RewardsScreen` | `/Rewards` | `common/presentation/screens/drawer_placeholder_screens.dart` |
| `NotificationsScreen` | `/Notifications` | `common/presentation/screens/notifications_screen.dart` |
| `HelpSupportScreen` | `/HelpSupport` | `common/presentation/screens/drawer_placeholder_screens.dart` |
| `SupportHomeScreen` | `/support` | `modules/support/presentation/screens/support_home_screen.dart` |
| `SupportTicketsScreen` | `/support/tickets` | `modules/support/presentation/screens/support_tickets_screen.dart` |
| `SupportTicketDetailScreen` | `/support/tickets/:ticketKey` | `modules/support/presentation/screens/support_ticket_detail_screen.dart` |
| `CreateSupportTicketScreen` | `/support/new` | `modules/support/presentation/screens/create_support_ticket_screen.dart` |
| `SafetySupportScreen` | `/support/safety` | `modules/support/presentation/screens/safety_support_screen.dart` |
| `HelpCenterScreen` | `/support/help` | `modules/support/presentation/screens/help_center_screen.dart` |

---

## 3. Outbound calls → owning module

Derived by resolving every `ServanaApiClient` method to its call sites.
`*** none ***` means the method is compiled into the app and no production code
path reaches it.

| API method | Legacy endpoint | Called from |
| --- | --- | --- |
| `firebaseLogin` | `POST /api/auth/customer-firebase-login` | `common/domain/auth/auth_token_exchanger.dart` |
| `_exchangeRefreshToken` | `POST /api/auth/refresh` | internal to the client (401 recovery) |
| `logout` | `POST /api/auth/logout` | `http_backend`, `modules/authentication/domain/authentication_repo.dart`, `…/bloc/authentication_bloc.dart` |
| `signup` | `POST /api/auth/signup` | *** none *** |
| `signin` | `POST /api/auth/signin` | *** none *** |
| `resendVerification` | `GET /api/auth/resendverification` | *** none *** |
| `verifyEmailOtp` | `POST /api/auth/verify-email-otp` | `modules/profile/data/profile_repository.dart`, `…/screens/email_verification_screen.dart` |
| `resendEmailOtp` | `POST /api/auth/resend-email-otp` | `modules/profile/data/profile_repository.dart` |
| `loadProfile` | `GET /api/user/profile` | profile controller/repository, email verification, profile screen, profile edit |
| `getUserProfile` | `GET /api/user/profile` | *** none *** |
| `updateProfile` | `PUT /api/user/updateprofile` | profile controller/repository, `modules/settings/…/profile_edit_screen.dart` |
| `getRegisteredUsers` | `GET /api/user/registereduser` | *** none *** |
| `getAllUserAddresses` | `GET /api/user/alluseraddresses` | `address_repository`, drawer screens, both booking stores |
| `addUserAddress` | `POST /api/user/adduseraddress` | `address_repository`, drawer screens |
| `makeAddressPrimary` | `PUT /api/user/makeaddressprimary` | `http_backend`, `modules/profile/application/address_controller.dart` |
| `deleteAddress` | `DELETE /api/user/deleteaddress` | drawer screens, `address_controller` |
| `getAddressById` | `GET /api/user/getaddressbyid` | *** none *** |
| `listServices` | `GET /api/services` | `modules/aircon_booking/data/aircon_booking_store.dart` |
| `listLevel2Services` | `GET /api/services/:id/level2` | `aircon_booking_store` |
| `listOptionsWithAddons` | `GET /api/services/:id/options-with-addons` | both booking stores, `modules/categories/data/category_experience_repository.dart` |
| `listFullCatalog` | `GET /api/services/full` | *** none *** |
| `getCanonicalCatalog` | `GET /api/catalog` | `modules/catalog/data/catalog_repository.dart` |
| `getCanonicalCatalogSummary` | `GET /api/catalog/summary` | `catalog_repository` |
| `getCanonicalService` | `GET /api/catalog/services/:id` | `catalog_repository` |
| `getBeautyAndWellnessBranches` | `GET /api/services/:id/branches` | `bw_booking_store` |
| `getBranchSlots` | `GET /api/branches/:id/slots` | `bw_booking_store` |
| `createBranchSlot` | `POST /api/branches/slots` | *** none *** |
| `getGeoCoverage` / `createGeoCoverage` | `GET`/`POST /api/services/:id/coverage-geo` | *** none *** |
| `getAirconQuote` | `POST /api/quote` | `aircon_booking_store` |
| `createBooking` | `POST /api/bookings?userId=` | both booking stores and both checkout screens |
| `getUserBookings` | `GET /api/users/:userId/bookings` | `http_backend`, `modules/bookings/data/booking_repository.dart` |
| `getBooking` / `getBookingDetail` | `GET /api/:id` | payment webview, assignment polling, both stores, booking detail, tracking |
| `getBookingTimeline` | `GET /api/:id/timeline` | `booking_repository` |
| `getBookingTracking` | `GET /api/:id/tracking` | `aircon_booking_store` |
| `cancelBooking` | `POST /api/bookings/:id/cancel` | `booking_repository`, `…/widgets/booking_cancellation_sheet.dart` |
| `confirmOtp` | `POST /api/:id/confirm-otp` | `common/presentation/screens/booking_otp_screen.dart` |
| `resendOtp` | `POST /api/:id/resend-otp` | `booking_otp_screen` |
| `getBookingProvider` | `GET /api/booking/:id/provider` | `common/services/assignment_polling_service.dart`, booking detail |
| `getBookingProviderLocation` | `GET /api/booking/:id/provider-location` | `modules/tracking/data/tracking_data_source.dart` |
| `createPaymongoSession` | `POST /api/:id/paymongo/create` | both stores, both confirmation screens, booking detail |
| `submitGcashProof` | `POST /api/:id/gcash-submit` | *** none *** |
| `approveGcashPayment` | `POST /api/:id/approve` | *** none *** |
| `approveCashPayment` | `POST /api/:id/mark-cash-paid` | *** none *** |
| `registerFcmToken` / `clearFcmToken` | `POST`/`DELETE /api/user/fcm-token` | `modules/notifications/application/fcm_coordinator.dart`, notifications data layer |
| `listNotifications` | `GET /api/user/notifications` | notifications remote data source + repository |
| `getNotificationsUnreadCount` | `GET /api/user/notifications/unread-count` | notifications remote data source |
| `markNotificationRead` | `PATCH /api/user/notifications/:key/read` | notifications remote data source |
| `markAllNotificationsRead` | `POST /api/user/notifications/mark-all-read` | notifications remote data source |
| `deleteNotification` | `DELETE /api/user/notifications/:key` | notifications remote data source |
| `getBookingConversation` | `GET /api/bookings/:id/conversation` | `modules/messaging/domain/repositories/messaging_repository.dart` |
| `listConversations` | `GET /api/chat/conversations` | messaging repository + store |
| `getMessages` / `sendChatMessage` | `GET`/`POST /api/chat/conversations/:id/messages` | messaging repository + store |
| `markConversationRead` | `POST /api/chat/conversations/:id/read` | messaging repository |
| `reportChatMessage` | `POST /api/chat/conversations/:id/messages/:msgId/report` | messaging repository |
| `listSupportTickets` … `reopenSupportTicket` (7 methods) | `/api/support/tickets*` | `modules/support/data/support_repository.dart` |
| `getSupportUnreadCount` | `GET /api/support/unread-count` | `support_repository` |
| `getSupportEmergencyConfig` | `GET /api/support/safety/emergency-config` | `support_repository` |
| `listSafetyIncidents` / `submitSafetyIncident` | `GET`/`POST /api/support/safety/incidents` | `support_repository`, `safety_support_screen` |
| `getReviewEligibility` | `GET /api/bookings/:id/review-eligibility` | `modules/review/data/reviews_repository.dart` |
| `createReview` / `getReviewByBooking` | `POST`/`GET /api/bookings/:id/reviews` | reviews repository, review form controller |
| `getReviewById` / `editReview` / `deleteReview` | `/api/reviews/:reviewId` | reviews repository, review detail controller |
| `listMyReviews` | `GET /api/reviews/me` | reviews repository |
| `reportReview` | `POST /api/reviews/:reviewId/report` | reviews repository, review detail controller/screen |
| `getProviderAggregate` | `GET /api/providers/:uid/rating` | reviews repository |

### 3.1 The 13 public methods with no production caller

`signup`, `signin`, `resendVerification`, `getUserProfile`,
`getRegisteredUsers`, `getAddressById`, `listFullCatalog`, `createBranchSlot`,
`getGeoCoverage`, `createGeoCoverage`, `submitGcashProof`,
`approveGcashPayment`, `approveCashPayment`.

The private `_exchangeRefreshToken` also has no direct caller in `lib/`; it is
reachable only through the 401 path inside the client itself, so it is counted
separately rather than as dead surface.

Three of those are the manual-payment family — `gcash-submit`, `approve`,
`mark-cash-paid`. The customer app carries the code to approve its own payment
and never calls it. That is not an authorization hole (the backend guards those
routes), but it is dead weight that a convergence pass should not port to v1.

---

## 4. DTOs

42 hand-written files declare `fromJson`. Freezed generates a further 20-odd
`.g.dart`/`.freezed.dart` pairs from them, which are excluded here because they
are derived, not authored.

| Cluster | DTOs | Location |
| --- | --- | --- |
| Identity / session | `UserSession`, `RegistrationFormModel` | `common/data/models/`, `modules/registration/data/models/` |
| Customer profile | `CustomerProfile`, `CustomerAddress` | `modules/profile/domain/` |
| Address & geo | `AddressDataModel`, `UserAddressModel`, `LocationCoordinatesModel`, `ServiceCoverageGeo`, `Province`, `City`, `Barangay` | `common/data/models/` |
| Legacy catalog | `MerchantModel`, `MerchantLight`, `MerchantCategory`, `MerchantService`, `MerchantServiceLight`, `MerchantServiceOption` | `common/data/models/` |
| Canonical catalog (V2) | `Catalog`, `Category`, `Subcategory`, `Service` | `modules/catalog/domain/catalog_models.dart` |
| Booking | `CustomerBooking`, `BookingStatus`, `BookingPriceQuote`, `BookingDraft`, `JobOrder`, `JobOrderItem`, `JobOrderDetails` | `common/domain/booking/`, `common/data/models/`, `modules/job_order/data/models/` |
| Tracking | `GeoPositionSnapshot` | `modules/tracking/domain/` |
| Messaging | `Conversation`, `Message`, `MessageAttachmentModel` (+ two mappers) | `modules/messaging/data/` |
| Notifications | notification models | `modules/notifications/data/` |
| Support | `SupportDraft` + ticket models | `modules/support/domain/`, `…/data/` |
| Reviews | review models | `modules/review/data/` |
| Search / home | `SearchServiceResult`, `HomeCampaignState` | `modules/homepage/` |
| Recovery | `PendingPaymentContext`, operation-journal entries | `core/recovery/` |

Two catalog DTO families coexist — the legacy `Merchant*` set and the canonical
`Catalog`/`Category`/`Subcategory`/`Service` set introduced by `d6d32bd`. That
duplication is expected mid-migration and is tracked as risk **R-07**.

---

## 5. Caches and client-held state

| Store | Key / box | Contents | Invalidation | Source |
| --- | --- | --- | --- | --- |
| Hive | `session` | `UserSession` (token, uid, role) | cleared on logout / 401 | `common/domain/helpers/session_service.dart:11` |
| Hive | `catalog_cache_v2` | full canonical catalog JSON | 6 h TTL **and** backend `lastUpdatedAt` revalidation; box name carries the version so an incompatible cache is never opened | `modules/catalog/data/catalog_cache.dart:47` |
| Hive | `servana_onboarding` | onboarding progress flags | manual | `common/services/onboarding_state_service.dart:15` |
| Hive | `registration` | in-progress registration form | on submit | `common/constants/boxes.dart:2` |
| Secure storage | booking draft | `BookingDraft` + idempotency key | on booking confirmed | `core/recovery/draft_repository.dart` |
| Secure storage | pending payment | `PendingPaymentContext` | 2 h hard expiry | `core/recovery/draft_repository.dart:23` |
| Secure storage | operation journal | retryable mutations | on drain | `core/recovery/operation_journal.dart` |
| SharedPreferences | `search_recent_terms` | recent search strings | manual clear | `modules/search/data/search_local_data_source.dart:4` |
| SharedPreferences | settings, analytics consent, campaign state | local prefs | manual | `modules/settings/data/`, `core/analytics/`, `modules/homepage/data/` |
| In-memory | `CatalogRepository._memory` | last catalog | process lifetime | `modules/catalog/data/catalog_repository.dart` |

`catalog_cache_v2` is the only cache whose contents come from an endpoint that
does not exist on the pushed backend branch. That interaction is risk **R-01**.

---

## 6. Transport and auth posture

- One low-level client, `ServanaApiClient`, wraps every REST call.
  30 s timeout, `Bearer` token resolved **per request** via an injected
  `tokenProvider` so Firebase can refresh a near-expiry ID token
  (`servana_api_client.dart:34-79`).
- A parallel `HttpBackend` implements the older `Backend` interface and
  duplicates six endpoints (`signin`, `signup`, `resendverification`,
  `adduseraddress`, `services`, `coverage-geo`). Convergence has to retire one
  of the two paths rather than migrate both — risk **R-08**.
- `MockBackend` (1 389 lines) serves the whole `Backend` interface when
  `MOCK_BACKEND=true`. It is build-time gated and never reachable in a release
  build.
- Any 401 fires `onUnauthorized`, which clears the session.
