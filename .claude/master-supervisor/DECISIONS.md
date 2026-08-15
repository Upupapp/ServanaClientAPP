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
