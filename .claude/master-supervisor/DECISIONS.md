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

---

DECISION: Treat TAB 11 as payments/checkout, chosen by the user rather than derived.
CONTEXT: A fresh session picked up from state.json, which carries `currentTabIndex: 11` but no title. The Master Command text lived in the previous session's prompt and is not stored in the repo; `TAB01_CONVERGENCE_RISK_MATRIX.md` Â§3 says outright that its sequencing is *"recorded as a finding of TAB 01, not as a plan."*
OPTIONS: (a) infer the subject from the remaining domains and proceed; (b) ask, with an evidence-based recommendation; (c) stop and do nothing.
SELECTED: (b).
WHY: Guessing wrong does not produce merely imperfect work â€” it fills TAB 11's slot with another tab's content and records a false claim in `completedTabs`, which the next session reads as ground truth. That is the narrow case where proceeding under an assumption makes the work useless if the assumption is wrong. The recommendation was payments: it is the next step in the booking journey after TAB 10's actions, it is the only untouched customer money surface, and R-06 was already recorded against it.
EVIDENCE: `contract.ts` domain census â€” `finance` has 3 customer-facing entries and no capability; `reviews` is a recorded backend gap (R-11, 5 of 9 legacy calls `KEEP`); `conversations` already has a capability blocked on a semantic decision (R-10).
PRIMARY SOURCES: backend contract; TAB 01 risk matrix.
LOCAL IMPACT: `state.json` now carries a `tabTitleProvenance` field so a future session knows TAB 11's title was user-supplied and that TAB 12's must be asked for too.
PRODUCTION IMPACT: none.
DATE: 2026-08-16

---

DECISION: Name the capability `bookingPayments`, not `finance` or `payments`.
CONTEXT: The three customer endpoints live in the backend's `finance` domain.
OPTIONS: (a) `finance`; (b) `payments`; (c) `bookingPayments`.
SELECTED: (c).
WHY: The existing rule â€” a value named for a domain claims the domain migrated â€” already rules out (a) and (b), but `finance` fails a second test that is worth writing down separately: the domain contains provider earnings, payouts and admin reconciliation, which a CUSTOMER app may never call at all. A capability can be dishonest not only by claiming an unfinished migration but by claiming a surface this client will never have. All three canonical calls are booking-scoped, so the name says so.
EVIDENCE: `contract.ts` `domain: 'finance'` â€” 7 entries, of which 3 are `/bookings/:bookingId/*` and 4 are `/provider/earnings/*` and `/admin/finance/*`.
PRIMARY SOURCES: backend contract.
LOCAL IMPACT: `canonical_availability_test.dart` gained a guard rejecting `finance`, `payments`, `earnings` and `payouts` as capability names.
PRODUCTION IMPACT: none; the capability is off.
DATE: 2026-08-16

---

DECISION: Send an EMPTY body on the canonical payment intent.
CONTEXT: `PaymentIntentRequest` has one optional property, `returnOrigin`.
OPTIONS: (a) send the app's deep-link origin; (b) send a configured origin from AppConfig; (c) send nothing.
SELECTED: (c).
WHY: The field is *"matched against a SERVER-SIDE allowlist. Never used as a URL â€” a caller-supplied return target would let a payer be returned to another application."* A mobile client has no origin worth nominating, and (a) or (b) would be the client expressing a preference about where a payer is returned to, which is precisely the decision the allowlist exists to take out of a caller's hands. An empty request is the shape that cannot be wrong.
EVIDENCE: `openapi.ts:1052-1063` (`PaymentIntentRequest`); `contract.ts:3236-3239` (the return-origin note).
PRIMARY SOURCES: backend schema and contract.
LOCAL IMPACT: asserted by test â€” the POST body is empty and the query string carries nothing.
PRODUCTION IMPACT: none.
DATE: 2026-08-16

---

DECISION: Do not model `earning`, `payout`, `provider` or `servana` on BookingPayment.
CONTEXT: `GET â€¦/payment` is field-scoped by the caller's seat and can carry all four.
OPTIONS: (a) model everything the schema declares; (b) model only the customer's fields.
SELECTED: (b).
WHY: A field a customer app cannot receive is a field it must not have a parser for. The parser would be the thing that made a disclosure bug invisible: if the backend ever leaked the provider share to a customer token, a client with no field for it produces nothing, and a client with a field for it produces a number on a screen. The backend's own design intent is that *"the provider is shown the gross their share is a percentage of and never the customer refund position"* â€” this is the client half of the same rule.
EVIDENCE: `openapi.ts:1080-1144` (`BookingPayment`, with `ADMIN only` and `PROVIDER only` annotations per field); `contract.ts:3267-3271`.
PRIMARY SOURCES: backend schema.
LOCAL IMPACT: `BookingPayment` carries state, captured, method, paidAt, breakdown and refund. Nothing else.
PRODUCTION IMPACT: none.
DATE: 2026-08-16

---

DECISION: No idempotency keys on any payment operation.
CONTEXT: TAB 10 established key-per-intent bookkeeping for booking actions one tab earlier.
OPTIONS: (a) reuse the TAB 10 pattern for consistency; (b) send keys only on checkout; (c) send none.
SELECTED: (c).
WHY: Consistency would be the wrong reason. None of the three lists `IDEMPOTENCY_KEY_INVALID` or `IDEMPOTENCY_KEY_REUSED` among its errors, which is the backend saying it does not read one â€” and each has a stronger guard already. Checkout is protected by an advisory transaction lock plus a processor `Idempotency-Key` derived from the payment row and its attempt counter, which lives INSIDE the processor call where a client key could not reach. Refund is bounded by `captured - alreadyRefunded` and a customer repeat returns the same open review row. Adding key plumbing would advertise a protection that is not the one operating.
EVIDENCE: `contract.ts:3209-3213` (checkout replayGuard), `:3281-3285` (refund replayGuard), and the `errors` arrays of all three entries.
PRIMARY SOURCES: backend contract.
LOCAL IMPACT: `PaymentsRepository` has no `_intentKeys` map, unlike `BookingLifecycleRepository`. `PaymentIntent.reused` is the observable half instead.
PRODUCTION IMPACT: none.
DATE: 2026-08-16

---

DECISION: A customer refund result must never read as money having moved.
CONTEXT: `RefundResult.outcome` is `requested`, `issued` or `pending_processor`.
OPTIONS: (a) treat any 2xx as a refund; (b) expose the raw outcome string and let callers compare; (c) model the distinction on the type.
SELECTED: (c) â€” `isRequestOnly` and `isMoneyMoving`.
WHY: (a) is the damaging error: a customer told "Refunded" waits for money that is not coming until an admin approves the review row. (b) leaves every future call site to remember a string comparison. The customer path *"writes exactly one record and calls no processor"*, and the type should make that hard to misread rather than merely documented.
EVIDENCE: `bookingPaymentService.ts:331-351` (the customer branch opening a review and returning `outcome: 'requested'`); `openapi.ts:1164-1187` (`RefundResult`); `contract.ts:3309-3312`.
PRIMARY SOURCES: backend service source.
LOCAL IMPACT: no refund UI was built, partly for this reason â€” the copy needs a decision this tab did not have.
PRODUCTION IMPACT: none; refunds are unreachable on the legacy transport.
DATE: 2026-08-16

---

DECISION: Model an unrecognised payment state as `unknown`, not as `pending`.
CONTEXT: `PaymentStatusParser` knew three states and treated everything else as neither paid nor payable.
OPTIONS: (a) default an unknown wire value to PENDING; (b) default to a distinct `unknown`.
SELECTED: (b).
WHY: PENDING is the one state that INVITES a payment. Defaulting an unrecognised value to it means a build that has not learned a new backend state offers "Pay now" for a booking the server may consider settled â€” a double charge produced by a client being out of date. `unknown.invitesPayment` is false, so the safe direction is the default. The same reasoning excluded `REJECTED`: a declined GCash proof needs support, not another attempt, and the intent would be refused with `PAYMENT_STATE_CONFLICT`.
EVIDENCE: `openapi.ts:1089-1093` (the six-value enum); `errors.ts:163` (`PAYMENT_STATE_CONFLICT: 409`).
PRIMARY SOURCES: backend schema and errors.
LOCAL IMPACT: `PaymentState` has seven values, six from the wire plus `unknown`.
PRODUCTION IMPACT: none today â€” the legacy vocabulary maps onto the same enum, including the `PAYMENT_` prefixed forms.
DATE: 2026-08-16

---

DECISION: Report the legacy breakdown as UNKNOWN rather than as zero.
CONTEXT: The compatibility source has no payment endpoint and so no price breakdown.
OPTIONS: (a) return a zeroed breakdown; (b) make `breakdown` nullable; (c) return a zeroed breakdown plus an `isBackendDerived` flag.
SELECTED: (c).
WHY: (b) would force every caller to null-check a field that is non-null on the transport anyone actually wants. (a) alone is the trap â€” a screen rendering `gross` would show a customer â‚±0.00 for a booking they are about to pay for. The flag separates "this transport cannot tell you" from "the amount is nothing", and `PaymentsRepository.hasPaymentDetail` surfaces the same fact before a caller has fetched anything.
EVIDENCE: TAB 01 R-06; the absence of any legacy payment route in `contract.ts`'s `finance` legacy arrays.
PRIMARY SOURCES: TAB 01 delta matrix; backend contract.
LOCAL IMPACT: asserted by test â€” `grossMinor` is null and `refund` is null on the legacy path.
PRODUCTION IMPACT: none; no screen renders the breakdown yet.
DATE: 2026-08-16

---

DECISION: Take the four remaining `booking-experiences` entries as TAB 12.
CONTEXT: The user said "go" after being told TAB 12's subject needed their input. Two candidates had been offered: the leftover `booking-experiences` entries, or `conversations`.
OPTIONS: (a) ask again; (b) take booking-experiences; (c) take conversations.
SELECTED: (b).
WHY: Asking twice in a row after an explicit "go" ignores the instruction. Between the two candidates only one can proceed without the user: `conversations` is blocked on the R-10 semantic decision â€” v1 replaces lazy conversation creation with an explicit POST and SC-038 records the current behaviour as a defect â€” and that is a product call, not a technical one. `booking-experiences` needs nothing from anybody and completes a domain TAB 10 half-finished.
EVIDENCE: `contract.ts` â€” `booking-experiences` has 10 entries, TAB 10 took 6; TAB 01 R-10 on conversations.
PRIMARY SOURCES: backend contract; TAB 01 risk matrix.
LOCAL IMPACT: `state.json.tabTitleProvenance` now records that TAB 11's title was the user's and TAB 12's was mine.
PRODUCTION IMPACT: none.
DATE: 2026-08-16

---

DECISION: Give `additionalWork.create` no method AND no capability flag.
CONTEXT: Every previous absence in this work was reported through a `supportsâ€¦` flag so a UI could ask before offering.
OPTIONS: (a) a `supportsRaisingChangeOrders` flag, false on both transports; (b) a method that throws; (c) absent from the interface entirely.
SELECTED: (c).
WHY: The flag pattern exists for a transport gap â€” something legacy lacks that canonical has, which will become true when v1 deploys. This is not that. `bookings.additionalWork.create` is `auth: 'provider'`, `customerMobile: 'n/a'`, and the write requires an IN_PROGRESS assignment row the customer does not have. It will never be true for this client. A flag would advertise a capability that is permanently false, and the next person to see it would reasonably wonder what deploy turns it on.
EVIDENCE: `contract.ts:2914-2952` â€” `auth: 'provider'`, `callers.customerMobile: 'n/a'`, `PROVIDER_ROLE_REQUIRED` in the error list, and the replayGuard requiring an IN_PROGRESS assignment under FOR UPDATE.
PRIMARY SOURCES: backend contract.
LOCAL IMPACT: a test pins the interface at four members so a fifth is a visible decision.
PRODUCTION IMPACT: none.
DATE: 2026-08-16

---

DECISION: Do NOT mirror the dispute categories; read them from the response.
CONTEXT: TAB 10 mirrored `RESCHEDULE_REASONS` and TAB 11 mirrored the customer subset of `REFUND_TRIGGERS`, both because a picker must be populated before any request exists.
OPTIONS: (a) mirror `DISPUTE_CATEGORIES` as a Dart enum for consistency with the two previous tabs; (b) consume the server's list.
SELECTED: (b) â€” `DisputeCategory` is an extension type over a String.
WHY: Consistency would be the wrong reason. The justification for mirroring was that no endpoint hands the list over first, and here one does: `bookings.disputes.list` returns `categories` OUTSIDE any branch, so it arrives even for a booking with zero disputes. The one call a screen makes to show escalations also supplies the vocabulary. The backend additionally describes its list as *"a superset of the provider-facing categories"* â€” a set expected to grow â€” so a closed client enum would drop a new category silently and turn each backend addition into a client release.
EVIDENCE: `domains/bookingExperiences.ts:493-501` (`categories: DISPUTE_CATEGORIES` unconditional in the `ok()` call); `experiencePolicy.ts:656-671` (nine categories, documented as a growing superset).
PRIMARY SOURCES: backend route and policy source.
LOCAL IMPACT: an unrecognised category still renders, humanised from its wire name, rather than being dropped.
PRODUCTION IMPACT: none; disputes are unreachable on legacy.
DATE: 2026-08-16

---

DECISION: `BookingDispute` carries no `reason` field.
CONTEXT: The customer writes `reason` when opening a dispute.
OPTIONS: (a) model it so the author can see what they submitted; (b) omit it from the read model, keep it outbound-only on the draft.
SELECTED: (b).
WHY: `reason`, `assigned_team` and `actor_uid` are withheld from EVERY caller â€” *"free text one party typed about another, internal routing, and a person."* Including the author. A field for it would be a parser waiting for a disclosure bug, and a screen rendering it after submission would be showing its own local copy while implying the platform echoes it back. If the author needs to see what they wrote, that is a local draft concern and must be presented as one.
EVIDENCE: `openapi.ts:648-671` (`BookingDispute`, with the withholding note); `contract.ts:3044-3047`.
PRIMARY SOURCES: backend schema and contract.
LOCAL IMPACT: `DisputeDraft.reason` is outbound only; `stateSnapshot` is an opaque map for the same reason â€” evidence, not a view model.
PRODUCTION IMPACT: none.
DATE: 2026-08-16

---

DECISION: Two capabilities over one repository.
CONTEXT: Change orders and disputes share a backend domain and a client module.
OPTIONS: (a) one `bookingExperiences` capability; (b) `bookingAdditionalWork` + `bookingDisputes`.
SELECTED: (b).
WHY: (a) would also claim the six entries TAB 10 already routes under `bookingTracking` and `bookingLifecycle`, so the name would be false on arrival. Beyond naming, the two halves are not comparable: the change-order read has a live legacy relative doing identical work, so flipping it changes a URL; disputes have no customer route at all, so flipping that turns on a feature. Same argument that separated `bookingReads` from `bookingLifecycle`.
EVIDENCE: `contract.ts` â€” 10 `booking-experiences` entries across what are now four client capabilities.
PRIMARY SOURCES: backend contract.
LOCAL IMPACT: `BookingExperiencesRepository._sourceFor(capability)` routes per call rather than holding one `_source` getter â€” the first repository in this work that needed it.
PRODUCTION IMPACT: none; both off.
DATE: 2026-08-16

---

DECISION: Build TAB 13 without waiting for the R-10 product decision — then discover there was none to make.
CONTEXT: I told the user conversations was "genuinely blocked" on whether the app should stop creating conversations on read. They said "go".
OPTIONS: (a) ask a third time; (b) build both transports and record the decision as required-before-flip; (c) pick a different tab.
SELECTED: (b), and the premise then collapsed.
WHY: Even before measuring, the decision governed the FLIP and not the build — the capability is gated off, and preserving legacy behaviour on the legacy path is the standing rule regardless. So the tab was buildable either way. Measuring the backend then showed the decision does not exist at all: the legacy GET creates nothing. I overstated the blocker to the user and corrected it in the same turn.
EVIDENCE: `src/chat/chat.controller.ts:52-83` — `getBookingConversation` calls `getExistingConversation` and 404s, with a comment naming this client's 404-to-null mapping as the contract it was written against.
PRIMARY SOURCES: backend controller source, read directly.
LOCAL IMPACT: the §3.1 blocker "and a semantic decision" is withdrawn in the manifest; `conversations` is now blocked on the v1 deploy alone.
PRODUCTION IMPACT: none.
DATE: 2026-08-16

---

DECISION: Map `CONVERSATION_NOT_AVAILABLE` to null; do NOT map `CONVERSATION_ACCESS_DENIED`.
CONTEXT: The canonical resolve is a POST that can be refused for two different reasons; the legacy resolve 404s for one of them.
OPTIONS: (a) map every failure to null so the screen never errors; (b) map neither and let the screen handle both; (c) map only the "not yet" refusal.
SELECTED: (c).
WHY: (a) would tell somebody probing another customer's booking that it merely has no chat yet — an authorization refusal flattened into an empty state. (b) would turn a working quiet empty state into an error banner the moment the capability flips, for the ordinary case of a booking whose provider is not yet confirmed. The two codes exist separately precisely so a client can tell them apart, and `mayOpenConversation` is what produces the first: support may open a thread on an unassigned booking, the parties may not.
EVIDENCE: `contract.ts:2101-2104` (both codes on `conversations.create`); `errors.ts:198,204` (403 and 409); `messagingPolicy.ts:767` (`mayOpenConversation`); `chat.controller.ts:52-83` (the legacy 404).
PRIMARY SOURCES: backend contract, errors and policy source.
LOCAL IMPACT: both directions asserted by test.
PRODUCTION IMPACT: none; the canonical path is unreachable.
DATE: 2026-08-16

---

DECISION: Keep `reportMessage` on the compatibility source in every configuration.
CONTEXT: The `conversations` domain has six canonical entries and the client calls a seventh thing.
OPTIONS: (a) put report on the interface and throw from the canonical source; (b) call compatibility directly from the repository.
SELECTED: (b).
WHY: The precedent is `NotificationsRepository.dismiss` for `DELETE /api/user/notifications/:key`, and the reasoning transfers exactly: the canonical implementation must not invent an endpoint that does not exist, and must not throw at runtime on a button the customer can see. This is the second kind of absence in the taxonomy TAB 12 named — canonical lacks what legacy has — and it already had a treatment.
EVIDENCE: `contract.ts` conversations domain — create, list, get, messages.list, messages.create, read. No report, edit or delete.
PRIMARY SOURCES: backend contract.
LOCAL IMPACT: `MessagingRepository` retains a `ServanaApiClient` field for this one call; a test asserts reporting reaches legacy with the capability ON.
PRODUCTION IMPACT: none.
DATE: 2026-08-16

---

DECISION: Send no `Idempotency-Key` header on `sendMessage`.
CONTEXT: TAB 10 established header-based idempotency for booking actions.
OPTIONS: (a) send a header as well as `clientMsgId`; (b) send `clientMsgId` only.
SELECTED: (b).
WHY: `clientMsgId` IS the idempotency mechanism for a message, and it is a message field rather than a transport concern — the contract names a malformed one `MESSAGE_IDEMPOTENCY_KEY_INVALID` rather than the generic `IDEMPOTENCY_KEY_INVALID`, which is the backend saying the two are different mechanisms. A header would be a second, unread key.
EVIDENCE: `contract.ts:2268` (`MESSAGE_IDEMPOTENCY_KEY_INVALID` on `conversations.messages.create`); `domains/conversations.ts:96` (`CLIENT_MSG_ID_INVALID` mapped to it).
PRIMARY SOURCES: backend contract and domain source.
LOCAL IMPACT: asserted by test, because the habit from three tabs ago would make a header look correct.
PRODUCTION IMPACT: none.
DATE: 2026-08-16

---

DECISION: Re-measure R-11 before committing TAB 14 to reviews.
CONTEXT: TAB 13 had just withdrawn R-10 as stale after eleven tabs of planning around it.
OPTIONS: (a) inherit R-11 and pick a different tab; (b) measure it first.
SELECTED: (b).
WHY: The lesson from TAB 13 is worthless if the next tab inherits the next finding. Measuring cost two greps.
EVIDENCE: `contract.ts` reviews and booking-review entries against the nine methods on `reviews_repository.dart`. Four have successors: eligibility and getByBooking (both to `bookings.review.get`), createReview, getProviderAggregate. Five do not: getById, editReview, deleteReview, listMyReviews, reportReview.
PRIMARY SOURCES: backend contract; local repository.
LOCAL IMPACT: **R-11 HOLDS exactly.** Unlike R-10. Recorded so the next reader knows both were checked and only one was stale.
PRODUCTION IMPACT: none.
DATE: 2026-08-16

---

DECISION: Name two slices rather than declining a capability entirely.
CONTEXT: R-11's remedy in the manifest was "do not define a `reviews` capability".
OPTIONS: (a) keep declining, leave reviews unmigrated; (b) `bookingReview` plus `providerReputation`.
SELECTED: (b).
WHY: R-11's conclusion was right and its remedy predated the slice rule. "The domain cannot be named" and "nothing here can migrate" are different claims, and TAB 09 established the difference when it named `bookingReads` in a domain whose create has no successor. Two slices rather than one because they answer different questions on different screens, and the read-only one should be movable first.
EVIDENCE: `contract.ts:1248-1387` — `reviews.provider.rating` is read from a provider profile; `bookings.review.*` is booking-scoped.
PRIMARY SOURCES: backend contract.
LOCAL IMPACT: the TAB 10 allow-list guard FAILED on first run because `bookingReview` was not in it — the guard working as designed.
PRODUCTION IMPACT: none.
DATE: 2026-08-16

---

DECISION: Fold eligibility into one method, and let an existing review win.
CONTEXT: The canonical read returns `ReviewOrEligibility`; the legacy transport has two separate routes.
OPTIONS: (a) keep two methods and add a third folded one; (b) one method, folded on both transports.
SELECTED: (b).
WHY: The contract names the second call as the defect — "asking twice means a screen that offers a form the next call refuses" — and the client's version is worse than the race the backend describes. The two calls are made by TWO CONTROLLERS AND NEITHER MAKES BOTH: `ReviewFormController` asks eligibility and never looks for a review, so it could open a form on an already-reviewed booking. Folding on both transports means both controllers get the same answer. An existing review wins because that is how the backend resolves it, and because the alternative offers a form the create refuses.
EVIDENCE: `contract.ts:1352-1387` (`ReviewOrEligibility`, and the note folding in the eligibility route); `review_form_controller.dart:61`; `review_detail_controller.dart:33`.
PRIMARY SOURCES: backend contract; local controllers.
LOCAL IMPACT: `getEligibility` is retained and now synthesises `ALREADY_REVIEWED`; neither controller was touched.
PRODUCTION IMPACT: an improvement ships on legacy — the form no longer opens on an already-reviewed booking.
DATE: 2026-08-16
