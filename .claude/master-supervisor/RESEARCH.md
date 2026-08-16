# Research log

## Method note

Every TAB 05 question was answerable from **primary source read directly** —
the backend's own TypeScript in `servana_api-main`. No web research was
performed, because none would have improved correctness: the authority for
"what does `GET /api/v1/home` return" is that repository's source, not any
external document. The Master Command's own rule applies — do not infer
availability or shape from prose.

## Sources read (2026-08-16)

| Question | Source | Finding |
| --- | --- | --- |
| Does `/api/v1/home` exist, and what does it return? | `servana_api-main/src/api/v1/contract.ts:1997-2048` (`home.feed`) | Exists, `status: implemented`, `responseSchema: HomeFeed`, auth `authenticated`, optional `sections` comma-separated query param. Unknown names ignored, never refused. |
| What is the `HomeFeed` shape? | `src/services/home/homeService.ts:301-310`, `:409-417` | `{ sections: Array<SectionEnvelope>, meta: {requested, unavailable, personalized, generatedAt} }` — an **array**, not a map. This is defect 1. |
| What is a section envelope? | `homeService.ts:312-326` | `{type, status: 'ok'|'unavailable', items, reason, ttlSeconds}`. `status` is `unavailable` only when `reason === 'UNAVAILABLE'`. |
| What do the `reason` values mean? | `homeService.ts:320-324`, `:335-375` | `EMPTY`, `REQUIRES_AUTH`, `NOT_CONFIGURED`, `UNAVAILABLE`, null. The source states the intent: *"EMPTY and UNAVAILABLE are different facts a client should render differently — collapsing them shows 'no recent services' to somebody who has ten."* |
| Is `/api/v1/home/sections` a per-section content fetch? | `contract.ts:2049-2067`, `homeService.ts:420-434` | **No.** It is the section registry — `describeSections`, returning type/audience/failureMode/ownedBy/referenceId/ttlSeconds. Contract notes: *"METADATA, not content — it names no account and no resource."* Takes no parameter. This is defect 2. |
| What are the declared section names? | `src/services/home/homePolicy.ts:101-108` (`SECTION_TYPES`) | Seven: `categories`, `featuredServices`, `popularServices`, `recentServices`, `activeBooking`, `notificationSummary`, `banners`. Note `banners`, not `promotions`. |
| What happens to an unrecognised requested section name? | `homeService.ts:389-395` | Filtered out by `isSectionType`; if the filtered list is empty it falls back to **all** sections. So a wrong name widens rather than narrows — the reason `requestName` exists. |
| Does the backend own promotions? | `homeService.ts:362-366` | No, and deliberately: `banners` returns `NOT_CONFIGURED` because *"there is no promotions source, and the command forbids the homepage owning promotion truth — so inventing one here would be the violation rather than the fix."* |
| Is `/api/v1` deployed? | `git rev-list --count origin/main..HEAD` in `servana_api-main` → **51** | Unpushed. Confirms the TAB 01 finding is still true at 2026-08-16. This is why every canonical source stays gated. |

## Standing conclusion

The canonical Home client is correct against the backend's source and is
unreachable in any shipped build. Both facts are load-bearing and both are
asserted by tests rather than asserted in prose.

## Sources read for TAB 10 (2026-08-16)

Same method as TAB 05: every question was answerable from the backend's own
TypeScript, read directly. No web research, because the authority for "what
does `POST /api/v1/bookings/:id/cancel` accept" is that repository's source.

| Question | Source | Finding |
| --- | --- | --- |
| Which lifecycle actions exist canonically? | `contract.ts:2355` (cancel), `:2746` (otp.request), `:2783` (otp.verify), `:2828` (otp.status), `:2853` (reschedule), `:2894` (reschedule.history), `:2703` (tracking) | All seven `status: 'implemented'`. Confirms the TAB 09 note that TAB 10 had real endpoints to migrate onto. |
| What header carries idempotency on v1? | `api/v1/envelope.ts:171`, `:186-201` | **`idempotency-key`**, and `readIdempotencyKey` consults no other name. Shape `^[A-Za-z0-9_.:-]{8,128}$`, and a malformed key throws rather than being ignored â€” *"silently ignoring a bad key is worse than rejecting it, because the caller believes it is protected against a retry and is not."* The client was sending `X-Idempotency-Key`. **This is the tab's first defect.** |
| Who reads `X-Idempotency-Key` then? | `controllers/bookingController.ts:42-58` | The legacy `POST /api/bookings` only. `ServanaApiClient` correctly keeps sending it there; `V1ApiClient` was sending it nowhere useful. |
| Which actions actually take a key? | `contract.ts` `replayGuard` fields | cancel and otp.verify: *"An Idempotency-Key replays the original result."* otp.request: **no** â€” its guard is the resend cooldown and the issue ceiling. reschedule: **no** â€” its guard is `schedule IS NOT DISTINCT FROM <expected>`, refusing a repeat with `BOOKING_SCHEDULE_CHANGED`. Neither lists the idempotency error codes, which is the backend saying the same thing. |
| What status does each booking refusal carry? | `api/v1/errors.ts:59-137` | `BOOKING_OTP_INVALID` and `BOOKING_WORKER_CODE_INVALID` are **403**, alongside `BOOKING_ACCESS_DENIED` and `BOOKING_OTP_ACTOR_NOT_PERMITTED`. The first two mean "wrong code", the second two mean "not yours". Status-driven mapping rendered all four as ForbiddenFailure. **The tab's second defect.** |
| Does the backend own the OTP policy? | `contract.ts:2847-2850` | Yes, and states the intent: `otp.status` exists *"so a client renders 'resend in 42s' and '2 attempts left' from the backend rather than from its own copy of the policy â€” the same argument availableActions makes for buttons."* The client had exactly such a copy: `_resendCooldownSeconds = 60`. |
| Is the OTP code ever in a response? | `openapi.ts:462-476` | Never. *"The code itself is NEVER in this response, in any field, for any actor."* `present: bool` is the most a client may know. |
| What are the reschedule reasons and who owns the policy? | `experiencePolicy.ts:434-472`, `:488-535` | `RESCHEDULE_REASONS` is a closed 6-value list. `CUSTOMER_RESCHEDULE_NOTICE_HOURS = 24`, but `noticeHours = actor === 'admin' ? 0 : 24` â€” so a client copy would apply one actor's rule to the other. `RESCHEDULE_REQUIRES_PROVIDER_ACCEPTANCE` is `false` today, which is why `PENDING_PROVIDER` is modelled rather than collapsed. |
| Is reschedule a state-machine transition? | `bookingRescheduleService.ts`, `canonicalState.ts:136+` | **No.** It goes through its own service, governed by `RESCHEDULABLE_STATES`. So it can never appear in `availableActions`, and a client looking for it there would offer it never. |
| What can a CUSTOMER do, per the machine? | `canonicalState.ts:136-290`, `projections.ts:165-172` | `confirmOtp` and `cancel`. Generated by `allowedActions(state, 'customer')` from the same `TRANSITIONS` table the executor enforces â€” the thing `BookingActionResolver` was independently reimplementing. |
| What does the canonical tracking route return? | `openapi.ts:390-448`, `bookingTrackingService.ts:139-195` | `{bookingId, state, steps, assignedProvider:{assigned, location}, visibility:{visibility, reason, trackableStates, windowClosesAt}, policy}`. Four withholding reasons. Visibility is evaluated **before** the position is read and re-evaluated after, and *"a withheld position is a 200 with visibility.reason, never a 403."* |
| Why is the legacy position route a problem? | `contract.ts:2726-2733` | It *"answers in EVERY state â€” a customer could watch their provider on a booking cancelled last week."* The client cannot close that: it can decline to draw a pin, but the coordinates have already reached the device. |
| Does the canonical tracking payload carry an ETA? | `openapi.ts:390-448` | No. The legacy stitcher derives one from booking columns this route does not return, so the canonical source reports `eta: null` rather than inventing one. Recorded as an open gap. |
| Is `/api/v1` deployed yet? | `git rev-list --count origin/main..HEAD` in `servana_api-main` â†’ **51** | Still unpushed at 2026-08-16. Every capability stays gated. |

## Standing conclusion, updated

TAB 10 differs from every tab before it in one way that mattered throughout:
its calls mutate. That turned two latent client defects into blockers â€” a
header nothing read, and a 403 mapping that told a customer who mistyped a
digit that the booking was not theirs â€” and it is why the tab spent its first
work on the transport rather than on the endpoints it was named for.

The recurring find was not a missing endpoint. It was the client holding a copy
of a rule the server owns: a cooldown, a cancellability set, a failure message
written for a gap that had closed, and a whole state machine with no callers.
Each copy was silently wrong in the same direction â€” toward offering the
customer something the server would refuse.

## Sources read for TAB 11 (2026-08-16)

| Question | Source | Finding |
| --- | --- | --- |
| What is TAB 11? | `state.json`, `TAB01_CONVERGENCE_RISK_MATRIX.md:71-88`, repo-wide grep | **Not recoverable from the repo.** `state.json` carries the index and no title; the risk matrix says its sequencing is *"recorded as a finding of TAB 01, not as a plan."* The subject was chosen by the user from an evidence-based shortlist. Recorded in `state.json.tabTitleProvenance` so the next session asks rather than guesses. |
| What is left to migrate? | `contract.ts` domain census | `finance` 7 entries (3 customer-facing), `booking-experiences` 4 remaining, `reviews` 6 (backend gap R-11), `conversations` 6 (capability exists, blocked on R-10), `account` 19 (partly done in TAB 03). |
| Which finance endpoints may a customer call? | `contract.ts:3202`, `:3242`, `:3274` | Three, all booking-scoped: `payments.intent`, `payments.get`, `refunds.create`. The other four are provider earnings, payouts and admin reconciliation. This is why the capability is `bookingPayments` and not `finance`. |
| Does a legacy payment-state route exist? | `contract.ts:3254-3264` (`bookings.payments.get` legacy array) | **No.** Its only legacy entry is `GET /api/admin/finance/ledger/booking/:id`, classified `ROLE_SPECIFIC` â€” the admin revenue-recognition view, *"a different question â€¦ carries its own permission."* Confirms TAB 01's R-06 is still true. |
| Does a legacy customer refund route exist? | `contract.ts:3297-3307` | **No.** The one legacy entry is `POST /api/admin/finance/refunds`, and the note says this canonical entry *"adds the customer-initiated path, which had no route at all."* |
| What does the checkout replay guard actually do? | `contract.ts:3209-3213` | An advisory transaction lock on the booking, reuse of a live session for the same return origin, and a processor `Idempotency-Key` derived from the payment row and its attempt counter. *"A replay returns the SAME checkout URL rather than creating a second payable session."* The client key would be redundant â€” the protection is inside the processor call. |
| Should the client send `returnOrigin`? | `openapi.ts:1052-1063`, `contract.ts:3236-3239` | No. *"Matched against a SERVER-SIDE allowlist. Never used as a URL."* A stored session encodes the URLs it was built with, so handing one back to a caller resolving to another origin would return the payer to a different application. |
| How many payment states are there? | `openapi.ts:1089-1093` | Six: PENDING, PAID, FAILED, REJECTED, REFUNDING, REFUNDED. `PaymentStatusParser` knew three. `state` is *"Settlement truth. SEPARATE from the booking lifecycle state."* |
| Which refund triggers may a CUSTOMER cite? | `financePolicy.ts:592-638` (`REFUND_TRIGGERS[â€¦].initiators`) | Four: `CUSTOMER_CANCELLED`, `PROVIDER_CANCELLED`, `SERVICE_NOT_DELIVERED`, `DUPLICATE_PAYMENT`. Admin-only: `ADMIN_CANCELLED`, `DISPUTE_UPHELD`, `ADMIN_DISCRETION`. A trigger whose initiators exclude the actor is refused with `OUTCOME_NOT_REFUNDABLE`. |
| What happens when a customer requests a refund? | `bookingPaymentService.ts:331-351` | A review row is opened and **no processor is called**. `outcome: 'requested'`. Money moves only on an admin decision. |
| How is a double refund prevented? | `financePolicy.ts:684-721` (`evaluateRefundEligibility`) | `maxRefundable = max(0, captured - refunded)`, so a second full refund computes a ceiling of zero and is refused by arithmetic. Also refuses a provider outright, and refuses `REFUNDING`/`REFUNDED`/uncaptured states. All server-side; nothing mirrored. |
| Do the finance error codes need a mapper override? | `errors.ts:158-179` | **No** â€” checked before touching the mapper, and the status-driven classification is correct for all ten. Pinned by test rather than left as a silent absence, because the TAB 10 OTP codes looked equally fine until their statuses were read. |
| How many client copies of the payment calls exist? | grep over `lib/` | Four `createPaymongoSession` call sites and three `isPaid` implementations. `booking_detail_screen.dart:990` unwrapped the envelope but read only the root key for the URL â€” a live defect on one of four paths. |

## Standing conclusion, updated

TAB 10's recurring find was the client holding a copy of a server RULE. TAB 11's
is the client holding a copy of itself: the same seven-call-site duplication
TAB 08 removed from booking creation, still present in the payment layer, and
already diverged badly enough to have produced a real defect on one path.

The other half is what the legacy transport simply cannot do. Two of the three
canonical operations have no predecessor at all, so `bookingPayments` is the
first capability whose flip does not merely move traffic â€” it adds a question
the app could not ask and an action it could not take. `hasPaymentDetail` and
`canOfferRefund` exist so a caller can tell which world it is in, rather than
rendering an unknowable zero as a price.

## Sources read for TAB 12 (2026-08-16)

| Question | Source | Finding |
| --- | --- | --- |
| What is left in `booking-experiences`? | `contract.ts` â€” 10 entries at 2703â€“3048 | TAB 10 took 6 (tracking, 3Ã— otp, reschedule, reschedule.history). Four remain: `additionalWork.create`, `additionalWork.list`, `disputes.open`, `disputes.list`. |
| May a CUSTOMER raise a change order? | `contract.ts:2914-2952` | **No.** `auth: 'provider'`, `callers.customerMobile: 'n/a'`, `PROVIDER_ROLE_REQUIRED` among its errors, and the replayGuard *"requires an IN_PROGRESS assignment row held under FOR UPDATE"*. This is an authorization fact, not a transport gap â€” hence no method and no flag on the customer interface. |
| Does the change-order READ have a legacy relative? | `contract.ts:2966-2975` | Yes â€” `GET /api/additional/booking/:bookingId`, `ALIAS_TEMPORARILY`, *"already booking-scoped and already the same service. The canonical path differs only in living under the booking it belongs to."* The client had never called it. |
| Does the client have any change-order surface? | grep over `lib/` | No. `AddAdditionalItemMenuScreen` matches on the name but belongs to the MerchantMenu subtree â€” it takes `merchantId`, uses `MerchantService` and the `store_items` bloc, and is unrelated to `booking_additional_requests`. Narrows the standing MerchantMenu retirement finding. |
| Does a customer have any legacy dispute route? | `contract.ts:3001-3020` | **No.** `POST /api/admin/bookings/:id/escalate` is admin-only and *"does not record a category, the opening role or the state snapshot Â§66 requires"*; `GET /api/provider/bookings/:id/dispute-status` is provider-facing. Neither is reachable with a customer token. |
| Where do dispute categories come from? | `domains/bookingExperiences.ts:493-501` | The route returns `categories: DISPUTE_CATEGORIES` **outside any branch** â€” so they arrive even for a booking with zero disputes. The client does not need to mirror them, unlike TAB 10's reschedule reasons and TAB 11's refund triggers. |
| Is the category list expected to grow? | `experiencePolicy.ts:656-671` | Nine values today, documented as *"a superset of `PROVIDER_DISPUTE_CATEGORIES`, which must remain a subset"*. A closed client enum would drop a new one silently â€” hence an extension type over String. |
| What is never projected on a dispute? | `openapi.ts:648-671`, `contract.ts:3044-3047` | `reason`, `assigned_team`, `actor_uid` â€” *"free text one party typed about another, internal routing, and a person."* Withheld from EVERY caller, including the author of the reason. `openedByYou` is the only caller-dependent field. |
| How is a duplicate dispute prevented? | `contract.ts:2987-2990` | A partial unique index plus the policy check: *"two simultaneous reports produce one record and one BOOKING_DISPUTE_ALREADY_OPEN, not two disputes."* Stronger than a client idempotency key, and neither idempotency error code is listed. |
| From which states may a dispute be opened? | `experiencePolicy.ts:688-697` (`DISPUTABLE_STATES`) | ACCEPTED, EN_ROUTE, ARRIVED, IN_PROGRESS, COMPLETED, CANCELLED, DISPUTED. *"A booking nobody has committed to has nothing to dispute."* Server-side; not mirrored. |
| When does a change order carry an approved amount? | `additional.service.ts:354-370` | `CASE WHEN status IN ('WAITING_FOR_PAYMENT','WAITING_WORKER_APPROVAL','ACCEPTED','IN_PROGRESS','PROCEEDING','COMPLETED') THEN total_amount ELSE NULL`. So a `PENDING_ADMIN_APPROVAL` request has a price and no approved amount â€” mirrored to *explain* the null, pinned by test against this set. |
| What shape are the change-order rows? | same | Raw Postgres columns, snake_case, with Postgres' native timestamp rendering. Both spellings parsed; timestamps through the shared `parseBackendTimestamp`. |

## Standing conclusion, updated

TAB 12 completed the `booking-experiences` domain and, in doing so, produced
the taxonomy the earlier tabs had been building toward without naming: there
are **three** kinds of absence, and they need three different treatments.
Legacy-lacks-it gets a `supportsâ€¦` flag. Canonical-lacks-it gets a per-call
escape to the compatibility source. **This-actor-may-never-call-it** gets
nothing at all â€” no method, no flag â€” because a flag implies a deploy that
would turn it on, and none will.

It also produced the first case where the backend serves its own vocabulary.
TABs 10 and 11 both mirrored a closed list because no endpoint offered one
before the request; disputes hand the categories over on the same read that
shows the escalations. Consuming that rather than mirroring it is the
difference between a backend addition being a deploy and being a client
release.

And one thing genuinely shipped: change orders are readable on the legacy
transport today, because the route was always live and the app had simply never
called it. Every prior tab's user-visible work was a correction; this one added
a capability with no deploy behind it.
