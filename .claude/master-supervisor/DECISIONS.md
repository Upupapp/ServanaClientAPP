# Material decisions

---

DECISION: Treat `servana_client-mobile` as the Master Command's repository.
CONTEXT: The Master Command locks the path to `C:\Users\paulg\OneDrive\Desktop\servana_client-main`, which does not exist. The user supplied `servana_client-mobile`.
OPTIONS: (a) stop and ask; (b) use the user's path if evidence confirms identity; (c) search for another candidate.
SELECTED: (b).
WHY: `git remote -v` gives `https://github.com/Upupapp/ServanaClientAPP.git` — the exact repository the Master Command names as its GitHub reference. Same project, different local folder name. The user also stated the path explicitly.
EVIDENCE: `git remote -v`; `pubspec.yaml` `name: client`, `version: 1.0.0+40`, matching the observed baseline in the command.
PRIMARY SOURCES: n/a.
LOCAL IMPACT: none beyond path binding.
PRODUCTION IMPACT: none.
DATE: 2026-08-16

---

DECISION: Fix `HomeComposition.fromJson` to read the array-of-envelopes body.
CONTEXT: The uncommitted parser expected `sections` to be a map keyed by section type.
OPTIONS: (a) keep the map assumption and ask the backend to change; (b) parse the array the backend actually returns; (c) accept both.
SELECTED: (c) — array primary, map retained.
WHY: The backend is the source of truth and its shape is fixed in `homeService.composeHome`. The map form is still needed because the compatibility source assembles its own composition that way and both feed one constructor. Keeping both costs one branch.
EVIDENCE: `servana_api-main/src/services/home/homeService.ts:301-310` (`HomeFeed.sections: Array<SectionEnvelope>`), `:409-417` (the returned object).
PRIMARY SOURCES: backend source, read directly.
LOCAL IMPACT: Without this, `isUsable` is false for every canonical response — a blank Home.
BACKWARD COMPATIBILITY: map form retained, so the compatibility source is unaffected.
PRODUCTION IMPACT: none today; the canonical path is gated off.
DATE: 2026-08-16

---

DECISION: Fetch one section by narrowing `/api/v1/home`, not by calling `/api/v1/home/sections`.
CONTEXT: The uncommitted canonical source called the registry route with a `section` query param, expecting content.
OPTIONS: (a) keep it and hope the registry returns content; (b) use the documented `sections` query on the composition endpoint; (c) drop per-section retry entirely.
SELECTED: (b).
WHY: `/home/sections` is `describeSections` — a metadata registry that names no account and no resource and takes no parameter. Calling it for content is fabricating server behaviour, which the Master Command forbids outright. The composition endpoint has a documented `sections` query param for exactly this.
EVIDENCE: `contract.ts:2050-2067` (`home.sections`, `responseSchema: HomeSectionRegistry`, notes: *"METADATA, not content"*); `contract.ts:2007-2017` (the `sections` query param on `home.feed`); `homeService.ts:428-434` (`describeSections` returns only type/audience/failureMode/ownedBy/referenceId/ttlSeconds).
PRIMARY SOURCES: backend contract and service source.
LOCAL IMPACT: inline section retry now works instead of returning registry metadata.
PRODUCTION IMPACT: none today; gated off.
DATE: 2026-08-16

---

DECISION: Request the promotions section as `banners`.
CONTEXT: The client enum names it `promotions`; the backend registry names it `banners`.
OPTIONS: (a) rename the enum; (b) send the backend spelling only when requesting; (c) ignore it.
SELECTED: (b) — added `HomeSectionType.requestName`.
WHY: (c) is actively harmful. `composeHome` filters requested names through `isSectionType` and, if nothing survives, falls back to **every** section — so requesting `promotions` would silently widen the response to the whole page instead of narrowing it. (a) would churn the client vocabulary for a wire detail. Reading already accepts both spellings.
EVIDENCE: `homeService.ts:389-395` (`.filter(isSectionType)` then `sections.length ? sections : [...SECTION_TYPE_NAMES]`); `homePolicy.ts` `SECTION_TYPES` key `banners`.
PRIMARY SOURCES: backend service source.
LOCAL IMPACT: a narrowed request is honoured as narrow.
PRODUCTION IMPACT: none today.
DATE: 2026-08-16

---

DECISION: Do not route banners/campaigns through the Home composition.
CONTEXT: TAB 05 asks Home to consume a composition endpoint while preserving banner and campaign design.
OPTIONS: (a) wire `promotions` to `HomePromotionRepository` through the composition; (b) leave banners on the existing Remote Config pipeline and report the section absent.
SELECTED: (b).
WHY: The banners are typed `HomePromotion`/`HomeCampaign` objects with slots, motion presets, themes, audiences, impression caps and a Remote Config kill switch, feeding purpose-built widgets. Flattening them into `Map<String, dynamic>` rows to pass through a generic transport would degrade protected creative for no gain — the composition would just hand them back to the same widgets. The backend independently reaches the same conclusion: it declares `banners` and permanently returns `NOT_CONFIGURED` because it has no promotions source and refuses to invent one. So neither side owns promotion truth, which is what the no-duplicate-truth rule wants.
EVIDENCE: `homeService.ts:362-366` (banners returns `NOT_CONFIGURED` with the comment that inventing a source *"would be the violation rather than the fix"*); `home_promotion_repository.dart`; `home_campaign_state.dart`.
PRIMARY SOURCES: backend service source.
LOCAL IMPACT: banner design and kill switch untouched.
PRODUCTION IMPACT: none.
DATE: 2026-08-16

---

DECISION: Give the compatibility source only a `categories` loader.
CONTEXT: Seven declared sections; the legacy transport can produce few of them honestly.
OPTIONS: (a) assemble every section from whatever legacy calls exist; (b) load only what has a real legacy source and report the rest absent.
SELECTED: (b).
WHY: `featured/popular/recentServices` have no legacy endpoint at all. `notificationSummary` already has exactly one owner in `NotificationsController`; assembling a second unread count here would be a duplicate truth and the two would drift. `activeBooking` would mean re-deriving booking state in the client. Absent is the honest answer and produces no retry affordance for something that cannot be retried.
EVIDENCE: TAB 01 delta matrix; `notifications_repository.dart:80` (`fetchUnreadCount`).
PRIMARY SOURCES: n/a — repository evidence.
LOCAL IMPACT: Home renders from `categories`, which is the one required section.
PRODUCTION IMPACT: none.
DATE: 2026-08-16

---

DECISION: Fix the canonical idempotency header before writing any TAB 10 action.
CONTEXT: `V1ApiClient` sent `X-Idempotency-Key`. Canonical routes read `Idempotency-Key`.
OPTIONS: (a) send both names; (b) send the canonical name only; (c) leave it and note the gap.
SELECTED: (b).
WHY: (c) was not available â€” TAB 10's entire scope is mutations, and every one of them relies on the header. (a) looks safe and is not: the legacy spelling is read by exactly one route, `POST /api/bookings`, which `V1ApiClient` never calls, so sending it would be cargo. The real hazard was silent: `V1ApiClient` permits a retry of a mutation *only* when a key was supplied, so it would have retried a cancel believing it was protected while the server saw two unrelated requests.
EVIDENCE: `servana_api-main/src/api/v1/envelope.ts:171` (`IDEMPOTENCY_HEADER = 'idempotency-key'`), `:186-201` (`readIdempotencyKey` consults that name only, and validates the 8-128 character shape); `src/controllers/bookingController.ts:54` (the legacy route reading `X-Idempotency-Key`).
PRIMARY SOURCES: backend source, read directly.
LOCAL IMPACT: two existing tests in `v1_api_client_test.dart` were asserting the defect and were corrected.
PRODUCTION IMPACT: none today; no canonical mutation is reachable.
DATE: 2026-08-16

---

DECISION: Two capabilities for TAB 10, not one, and neither folded into `bookingReads`.
CONTEXT: Cancel, reschedule and the OTP ceremony are actions; tracking is a read.
OPTIONS: (a) one `bookingActions` covering all five; (b) widen `bookingReads` to include tracking and add one action value; (c) `bookingLifecycle` + `bookingTracking`, separate from `bookingReads`.
SELECTED: (c).
WHY: The three have different blast radii and an operator should be able to take them in order of risk. A read from the wrong transport shows stale data; an action changes a customer's booking; tracking moves a *privacy* boundary â€” the legacy position route answers in every state, and the canonical one applies state and time-window rules. Folding tracking into `bookingReads` would have made enabling a read migration silently change who can see a provider's location.
EVIDENCE: `contract.ts:2703-2744` (tracking, with the two ALIAS_TEMPORARILY legacy routes and the note that the position route "answers in EVERY state"); `contract.ts:2355-2390`, `:2746-2892` (the five actions, all `implemented`).
PRIMARY SOURCES: backend contract, read directly.
LOCAL IMPACT: `canonical_availability_test.dart` gained a guard asserting the three are independently switchable.
PRODUCTION IMPACT: none; both off.
DATE: 2026-08-16

---

DECISION: The OTP screen stops holding its own resend cooldown.
CONTEXT: `BookingOtpScreen` held `_resendCooldownSeconds = 60` and counted it down locally.
OPTIONS: (a) keep it and add the backend numbers alongside; (b) read the backend state and fall back to the constant only on legacy; (c) delete the constant outright.
SELECTED: (b).
WHY: (c) would leave the legacy path with no cooldown at all, and the legacy resend route has no cooldown of its own â€” the client timer is the only thing standing between a customer and an unlimited rotation oracle. (a) keeps two numbers that can disagree. The chosen split names the constant as a *client assumption* (`BookingOtpState.local`, `isBackendDerived: false`) rather than letting it pass for policy, and the canonical path never consults it.
EVIDENCE: `contract.ts:2828-2851` (`bookings.otp.status`, whose stated purpose is *"so a client renders 'resend in 42s' and '2 attempts left' from the backend rather than from its own copy of the policy"*); `contract.ts:2746-2781` (the resend cooldown and issue ceiling the legacy route does not have).
PRIMARY SOURCES: backend contract.
LOCAL IMPACT: the local timer also stopped resetting on dispose in the canonical case, which was granting resends the server then refused.
PRODUCTION IMPACT: unchanged on legacy â€” still 60 seconds.
DATE: 2026-08-16

---

DECISION: Mirror the reschedule reason vocabulary, mirror none of the policy.
CONTEXT: A reason must be pickable before any request exists, so the list has to be client-side.
OPTIONS: (a) mirror reasons and the notice window so the UI can pre-validate; (b) mirror the reasons only; (c) mirror nothing and send free text.
SELECTED: (b).
WHY: (c) fails â€” a `reasonCode` outside the standardized list is refused with `BOOKING_RESCHEDULE_REASON_INVALID`. (a) is the trap: the 24-hour window applies to a *customer* and not to an admin, the lead bound and the provider-calendar check are server state the client cannot see, and each refusal already carries the rule that refused plus `verdict.noticeHours`. Mirroring the vocabulary is safe specifically because `RESCHEDULE_REASONS` is closed and append-only â€” a value can be added but never redefined.
EVIDENCE: `services/booking/experiencePolicy.ts:463-472` (`RESCHEDULE_REASONS`), `:434` (`RESCHEDULE_REQUIRES_PROVIDER_ACCEPTANCE = false`), `:437` (`CUSTOMER_RESCHEDULE_NOTICE_HOURS = 24`), `:523` (an admin's notice window is zero); `bookingRescheduleService.ts:263-277` (refusals carrying `reasons` and `reschedulableStates`).
PRIMARY SOURCES: backend service source.
LOCAL IMPACT: `RescheduleReason.customerChoices` omits `PROVIDER_SUPPLY` and `OPERATIONAL` â€” valid on the endpoint, but an admin's vocabulary, and offering them invites a customer to attribute the move to their provider in a kept record.
PRODUCTION IMPACT: none; the sheet is unreachable while the legacy transport answers.
DATE: 2026-08-16

---

DECISION: Gate the reschedule entry point on the TRANSPORT, not on booking state.
CONTEXT: The client had no reschedule surface at all; the canonical endpoint exists and the legacy one is admin-only.
OPTIONS: (a) show the button whenever the booking looks reschedulable and let the request fail; (b) show it only when the active transport has the endpoint; (c) ship the transport and no UI.
SELECTED: (b).
WHY: (a) makes the customer discover the missing capability by being refused, and a client-side state check would have been the fourth copy of a server rule in that file's vicinity. (c) leaves the tab's headline item undelivered when the endpoint genuinely exists. `supportsReschedule` answers a question the client can answer honestly â€” does this transport have the route â€” and leaves *whether this booking may move* to the backend.
EVIDENCE: `contract.ts:2875-2885` (the only legacy reschedule is admin-only); `contract.ts:2886` (`callers.customerMobile: 'planned'`).
PRIMARY SOURCES: backend contract.
LOCAL IMPACT: `canOfferReschedule` is false on every shipped build, so no button appears today.
PRODUCTION IMPACT: none.
DATE: 2026-08-16

---

DECISION: An EMPTY `availableActions` from the backend wins over the local resolver.
CONTEXT: `BookingActionResolver` is a client-side state machine with zero production callers; the backend generates `availableActions` from `TRANSITIONS`.
OPTIONS: (a) merge the two lists; (b) prefer the backend list when non-empty; (c) prefer the backend list whenever the field was present at all, empty included.
SELECTED: (c).
WHY: (b) is the trap, and it is easy to write by accident. An empty list means the machine permits nothing â€” a terminal or disputed booking â€” and treating empty as "the server said nothing" reinstates the client's own machine at exactly the moment the server said to offer no buttons. (a) can only ever add actions the server did not permit.
EVIDENCE: `services/booking/projections.ts:165-172` (`toCustomerProjection`); `canonicalState.ts:446-451` (`allowedActions` generated from `TRANSITIONS`).
PRIMARY SOURCES: backend service source.
LOCAL IMPACT: the resolver becomes the labelled fallback (`isBackendDerived: false`) rather than a rival source of truth. It is no longer dead code.
PRODUCTION IMPACT: none today â€” nothing fetches `availableActions` yet, recorded as an open finding.
DATE: 2026-08-16

---

DECISION: A tracking verdict the client cannot parse WITHHOLDS.
CONTEXT: `TrackingVisibility.fromApiMap` has to handle an unrecognised or absent verdict.
OPTIONS: (a) default to visible and let the presence of coordinates decide; (b) default to withheld.
SELECTED: (b), and additionally drop an attached position whenever the verdict is not VISIBLE.
WHY: (a) would put a provider's live position on screen on the strength of a value the client did not understand. The backend already nulls the position on a withheld verdict, so the extra drop is belt-and-braces â€” but it is the difference between a server regression leaking coordinates silently and it leaking nothing. The legacy route this replaces "answers in EVERY state".
EVIDENCE: `openapi.ts:390-448` (`BookingTracking`, the `visibility.reason` enum, and *"Present ONLY when visibility is VISIBLE"*); `contract.ts:2726-2733`; `bookingTrackingService.ts:175-187` (visibility evaluated BEFORE the position is read, and re-evaluated after).
PRIMARY SOURCES: backend service and schema source.
LOCAL IMPACT: `BookingTrackingState.visibility` is never null to a caller â€” an inferred verdict is supplied on legacy and flagged `isBackendDerived: false`.
PRODUCTION IMPACT: none; the legacy stitch behaves as before, with the guess now labelled.
DATE: 2026-08-16

---

DECISION: Do NOT pass `expectedState` on cancel from the booking detail screen.
CONTEXT: The sheet accepts it and the canonical route honours it.
OPTIONS: (a) pass `_bookingStatus`; (b) pass nothing and record the gap.
SELECTED: (b).
WHY: `_bookingStatus` is the LEGACY status string. Its vocabulary includes `CONFIRMED` and `PAID`, which are not canonical states at all. Sending one would not add a concurrency guard â€” it would manufacture a `BOOKING_STATE_CONFLICT` on a booking that is perfectly cancellable, turning a safety feature into an outage. Closing it needs the canonical state on the READ path, which is a booking-read concern rather than an action one.
EVIDENCE: `canonicalState.ts:48-70` (`BOOKING_STATES` â€” eleven values, none of them `CONFIRMED` or `PAID`); `booking_detail_screen.dart` `_isCancellable` switching on the legacy vocabulary.
PRIMARY SOURCES: backend source and local code.
LOCAL IMPACT: recorded in `TAB10_CERTIFICATION.md` Â§10 and in `state.json` openFindings.
PRODUCTION IMPACT: none.
DATE: 2026-08-16
