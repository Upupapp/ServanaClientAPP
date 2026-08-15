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
