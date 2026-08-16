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
