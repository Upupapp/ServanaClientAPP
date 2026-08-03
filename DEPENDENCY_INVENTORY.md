# Dependency Inventory — Servana Client v1.0.0+35

Generated: 2026-07-30 | Commit: 1eb2faa

## Runtime Dependencies

| Package | Version | Purpose | Status |
|---|---|---|---|
| firebase_core | ^3.4.1 | Firebase init | Active |
| firebase_auth | ^5.3.1 | Authentication | Active |
| firebase_analytics | ^11.3.2 | Event tracking | Active |
| firebase_crashlytics | ^4.1.1 | Crash reporting | Active |
| firebase_messaging | ^15.1.0 | Push notifications (FCM) | Active |
| firebase_performance | ^0.10.0 | Perf monitoring | Active |
| google_sign_in | ^6.2.1 | Google OAuth | Active |
| flutter_facebook_auth | ^7.1.1 | Facebook OAuth | Active |
| go_router | ^14.2.7 | Navigation | Active |
| mobx | ^2.3.3+2 | State management | Active |
| flutter_mobx | ^2.2.1+1 | MobX Flutter bindings | Active |
| bloc | ^8.1.3 | BLoC state management | Active |
| flutter_bloc | ^8.1.4 | BLoC Flutter bindings | Active |
| get_it | ^7.6.7 | Service locator | Active |
| socket_io_client | ^2.0.3+1 | Real-time messaging | Active |
| hive | ^2.2.3 | Local key-value store | Active |
| hive_flutter | ^1.1.0 | Hive Flutter | Active |
| flutter_secure_storage | ^9.0.0 | Encrypted local storage | Active |
| shared_preferences | ^2.3.2 | Non-sensitive preferences | Active |
| google_maps_flutter | ^2.6.0 | Maps and location | Active — key must be injected via CI |
| geolocator | ^10.1.1 | Device location | Active |
| geocoding | ^3.0.0 | Address geocoding | Active |
| location | ^7.0.1 | Location permissions | Active |
| http | ^1.6.0 | REST API calls | Active |
| image_picker | ^1.0.7 | Camera/gallery | Active |
| image_cropper | ^8.0.2 | Image crop | Active |
| file_picker | ^8.1.2 | File selection | Active |
| webview_flutter | ^4.13.1 | Payment webview | Active |
| url_launcher | ^6.2.5 | External URLs | Active |
| qr_flutter | ^4.1.0 | QR code display | Active |
| package_info_plus | ^8.0.0 | App version info | Active |
| freerasp | ^6.4.0 | Runtime app self-protection (RASP) | Active — TalsecSecurity |
| in_app_update | ^4.2.2 | Play Store in-app updates | Active |
| flutter_animate | ^4.5.0 | Animations | Active |
| intl | ^0.19.0 | i18n / date/number formatting | Active |
| provider | ^6.1.1 | ChangeNotifier bindings | Active |
| equatable | ^2.0.5 | Value equality | Active |
| json_annotation | ^4.8.1 | JSON serialization | Active |
| freezed_annotation | ^2.4.1 | Immutable models | Active |
| toastification | ^2.3.0 | Toast notifications | Active |
| pinput | ^5.0.0 | OTP input | Active |
| pull_to_refresh | ^2.0.0 | Pull-to-refresh | Active |
| flutter_spinkit | ^5.2.1 | Loading indicators | Active |
| flutter_svg | ^2.0.9 | SVG rendering | Active |
| material_dialogs | ^1.1.4 | Dialog helpers | Active |
| awesome_dialog | ^3.2.1 | Alert dialogs | Active |
| quickalert | ^1.1.0 | Quick alerts | Active |
| loader_overlay | ^4.0.2 | Loading overlay | Active |
| flutter_switch | ^0.3.2 | Toggle switch | Active |
| flutter_slidable | ^3.1.0 | Swipeable list rows | Active |
| dropdown_button2 | ^2.3.9 | Dropdown widget | Active |
| flutter_typeahead | ^5.2.0 | Type-ahead search | Active |
| currency_text_input_formatter | ^2.2.3 | Currency formatting | Active |
| number_text_input_formatter | ^1.0.0+8 | Number formatting | Active |
| intl_phone_field | ^3.2.0 | Phone number input | Active |
| phone_numbers_parser | ^9.0.0 | Phone number parsing | Active |
| email_validator_flutter | ^1.0.0 | Email validation | Active |
| location_picker_flutter_map | ^3.0.1 | Map location picker | Active |
| u_credit_card | ^1.1.0 | Credit card display | Active |
| gap | ^3.0.1 | Spacing widget | Active |
| blur | ^4.0.0 | Blur effects | Active |
| dotted_line | ^3.2.2 | Dotted divider | Active |
| ticket_clippers | ^0.0.5 | Ticket-shape clipper | Active |
| input_quantity | ^2.3.2 | Quantity input | Active |
| fraction | ^5.0.2 | Fraction arithmetic | Active |
| easy_stepper | ^0.8.5+1 | Step progress | Active |
| another_stepper | ^1.2.2 | Stepper widget | Active |
| overlay_tooltip | ^0.2.3 | Onboarding tooltips | Active |
| configurable_expansion_tile_null_safety | ^3.3.2 | Expansion tile | Active |

## Dev Dependencies

| Package | Version | Purpose |
|---|---|---|
| flutter_lints | ^4.0.0 | Lint rules |
| mocktail | ^1.0.4 | Test mocking |
| freezed | ^2.4.7 | Code generation |
| build_runner | ^2.4.8 | Code generation runner |
| hive_generator | ^2.0.1 | Hive type adapters |
| mobx_codegen | ^2.6.1 | MobX store generation |
| flutter_launcher_icons | ^0.14.3 | App icon generation |

## Key Observations

- `freerasp` (TalsecSecurity) provides RASP: jailbreak/root detection, debugger detection, emulator detection, and reverse-engineering protection. Requires native dependency in `android/app/build.gradle`.
- `in_app_update` enables Google Play in-app update prompts. Works only in Play Store builds with version checks.
- All Firebase SDK packages are from Google's official FlutterFire umbrella — no third-party Firebase wrappers.
- No abandoned or unmaintained packages identified.
- `flutter_facebook_auth ^7.1.1` — Facebook SDK carries known tracking implications; declared in Privacy Policy required.

## Vulnerability Status

No known critical vulnerabilities identified in pinned versions as of 2026-07-30. Run `flutter pub outdated` before each release to check for security updates. For Firebase SDKs, monitor Firebase Release Notes.
