/// The Home screen as a composition of independently-resolvable sections.
///
/// ## The guarantee this type exists to make
///
/// **One optional section failing must never blank Home.** Today Home is built
/// from serial calls on a single store, where `loadBookings()` throwing takes
/// the whole screen with it — the customer loses the category grid, the
/// banners and the search bar because their booking list was unavailable.
///
/// Modelling each section as its own outcome makes that structurally
/// impossible rather than carefully avoided: a failure is a value inside one
/// section, not an exception that unwinds the composition. A caller cannot
/// accidentally propagate it, because there is nothing to propagate.
///
/// ## Required vs optional
///
/// Exactly one section is required — [HomeSectionType.categories] — because a
/// Home with no way to browse services is not a degraded Home, it is a broken
/// one. Everything else is optional by construction, and
/// [HomeComposition.isUsable] says so.
///
/// ## Canonical ids in actions
///
/// Section actions carry canonical ids (`services.id`, `categories.id`,
/// `bookings.id`). They are read from the payload and never derived — the same
/// rule TAB 04 applied to `canonicalServiceId`, for the same reason: an id that
/// happens to match today is not an id that will match after the next admin
/// creates a row.
library;

import 'package:client/core/network/api_failure.dart';

/// Stable section identities, matching the canonical composition contract.
///
/// The wire name is explicit rather than derived from the enum name, so a Dart
/// rename cannot silently stop matching a backend key.
enum HomeSectionType {
  categories('categories'),
  featuredServices('featuredServices'),
  popularServices('popularServices'),
  recentServices('recentServices'),
  activeBooking('activeBooking'),
  promotions('promotions'),
  notificationSummary('notificationSummary');

  const HomeSectionType(this.wireName);

  final String wireName;

  /// The name to put in `?sections=`.
  ///
  /// The backend's registry calls this section `banners`; this enum calls it
  /// `promotions`. That only matters when *asking*: `composeHome` filters the
  /// requested list through `isSectionType` and, if nothing survives, falls
  /// back to **every** section. So requesting `promotions` would not narrow the
  /// response — it would silently widen it to the whole page. Reading is
  /// unaffected, because [fromWire] already accepts both spellings.
  String get requestName =>
      this == HomeSectionType.promotions ? 'banners' : wireName;

  /// Home is not meaningful without a way to browse. Everything else may fail
  /// and Home still renders.
  bool get isRequired => this == HomeSectionType.categories;

  static HomeSectionType? fromWire(String? raw) {
    if (raw == null) return null;
    for (final type in HomeSectionType.values) {
      if (type.wireName == raw) return type;
      // Banners and promotions are the same section under two names in the
      // contract's wording; accept both rather than dropping the section.
      if (type == HomeSectionType.promotions && raw == 'banners') return type;
    }
    return null;
  }
}

/// How a section's content was obtained, so the UI can say so honestly.
enum HomeSectionOrigin {
  /// Fetched this load.
  live,

  /// Served from cache because the network failed or was skipped. The content
  /// was real when it was fetched — never a placeholder (§50).
  cached,
}

/// One section's outcome. Loaded, failed, or simply not offered.
sealed class HomeSection {
  const HomeSection(this.type);

  final HomeSectionType type;

  bool get isLoaded => this is HomeSectionLoaded;
  bool get isFailed => this is HomeSectionFailed;
}

/// Content, and where it came from.
class HomeSectionLoaded extends HomeSection {
  const HomeSectionLoaded(
    super.type, {
    required this.items,
    this.origin = HomeSectionOrigin.live,
  });

  /// Already-mapped rows. The composition layer does not interpret them; each
  /// consuming widget knows its own shape.
  final List<Map<String, dynamic>> items;

  final HomeSectionOrigin origin;

  bool get isStale => origin == HomeSectionOrigin.cached;
  bool get isEmpty => items.isEmpty;
}

/// This section could not be produced. Carries a typed failure so the UI can
/// distinguish "you are offline, retry" from "this is gone".
class HomeSectionFailed extends HomeSection {
  const HomeSectionFailed(super.type, this.failure);

  final ApiFailure failure;

  /// Whether offering a retry affordance makes sense.
  bool get isRetryable => failure.isRetryable;

  /// True when the request never reached the server, which is the state worth
  /// naming as "offline" rather than "something went wrong".
  bool get isOffline =>
      failure is RetryableFailure && (failure as RetryableFailure).isTransport;
}

/// The backend did not offer this section for this customer. Distinct from
/// failed on purpose: a guest has no `activeBooking`, and rendering a retry
/// button for it would be nonsense.
class HomeSectionAbsent extends HomeSection {
  const HomeSectionAbsent(super.type);
}

/// Home, as a whole.
class HomeComposition {
  const HomeComposition({required this.sections, this.fetchedAt});

  final Map<HomeSectionType, HomeSection> sections;
  final DateTime? fetchedAt;

  static const HomeComposition empty =
      HomeComposition(sections: <HomeSectionType, HomeSection>{});

  HomeSection sectionOf(HomeSectionType type) =>
      sections[type] ?? HomeSectionAbsent(type);

  /// Rows for [type], or empty. The accessor most widgets want — a failed or
  /// absent section reads as "nothing to show here", never as a throw.
  List<Map<String, dynamic>> itemsOf(HomeSectionType type) {
    final section = sections[type];
    return section is HomeSectionLoaded
        ? section.items
        : const <Map<String, dynamic>>[];
  }

  /// Sections that failed. Drives a single inline retry affordance rather than
  /// one per section shouting at the customer.
  List<HomeSectionFailed> get failures =>
      sections.values.whereType<HomeSectionFailed>().toList(growable: false);

  /// True when at least one section failed because the device is offline.
  bool get hasOfflineFailure => failures.any((f) => f.isOffline);

  /// True when any section is being served from cache.
  bool get hasStaleContent => sections.values
      .whereType<HomeSectionLoaded>()
      .any((section) => section.isStale);

  /// **Home renders.**
  ///
  /// True unless the one required section is unavailable. This is the
  /// acceptance gate in code: any number of optional sections may fail and
  /// Home is still usable.
  bool get isUsable {
    final required = sections[HomeSectionType.categories];
    return required is HomeSectionLoaded && required.items.isNotEmpty;
  }

  /// True when nothing at all could be produced — the only state that warrants
  /// a full-screen error.
  bool get isBlank => sections.values.every((s) => s is! HomeSectionLoaded);

  HomeComposition mergeSection(HomeSection section) => HomeComposition(
        sections: <HomeSectionType, HomeSection>{
          ...sections,
          section.type: section,
        },
        fetchedAt: fetchedAt,
      );

  /// Parses the canonical composition body.
  ///
  /// ## The shape this actually has to read
  ///
  /// `GET /api/v1/home` returns `sections` as an **array of envelopes**, not a
  /// map keyed by type — `homeService.composeHome` builds
  /// `[{type, status, items, reason, ttlSeconds}, …]` alongside a `meta` block.
  /// An earlier draft of this parser assumed the map form, fell through to the
  /// root keys, matched neither `sections` nor `meta`, and produced an empty
  /// composition — which [isUsable] reads as a blank Home. The array form is
  /// therefore the primary path and is covered by a test.
  ///
  /// The map form is still accepted because the compatibility source assembles
  /// its own composition that way, and both feed this one constructor.
  ///
  /// Unknown section keys are ignored rather than rejected: the backend's
  /// section registry is append-only by design, and refusing a whole payload
  /// over an unrecognised key would blank a Home that is otherwise fine.
  factory HomeComposition.fromJson(Map<String, dynamic> json) {
    final sections = <HomeSectionType, HomeSection>{};
    final node = json['sections'];

    if (node is List) {
      for (final entry in node) {
        if (entry is! Map) continue;
        final envelope = Map<String, dynamic>.from(entry);
        final type = HomeSectionType.fromWire(envelope['type'] as String?);
        if (type == null) continue;
        sections[type] = _fromEnvelope(type, envelope);
      }
    } else {
      // The assembled form: a map keyed by type, or the keys at the root.
      final source = node is Map ? Map<String, dynamic>.from(node) : json;
      source.forEach((key, value) {
        final type = HomeSectionType.fromWire(key);
        if (type == null) return;
        sections[type] = _sectionFrom(type, value);
      });
    }

    return HomeComposition(
      sections: sections,
      fetchedAt: DateTime.now().toUtc(),
    );
  }

  /// One canonical section envelope.
  ///
  /// The backend draws a deliberate distinction the UI must not collapse:
  /// *"an empty recents list is a new customer, an unavailable one is a backend
  /// that failed"*. So `reason` decides the outcome type, not just the copy:
  ///
  ///  - `UNAVAILABLE` (the only value carrying `status: unavailable`) — the
  ///    section genuinely failed server-side. **Failed**, and retryable.
  ///  - `NOT_CONFIGURED` — the backend does not offer this section at all.
  ///    `banners` is permanently in this state: there is no promotions source
  ///    and the backend refuses to invent one. **Absent** — a retry button for
  ///    something that does not exist is noise.
  ///  - `REQUIRES_AUTH` — a personal section for a signed-out customer. Not an
  ///    error, just a Home without personalization. **Absent**.
  ///  - `EMPTY` / null — a real answer that happens to have no rows.
  ///    **Loaded**, so "no recent services" renders instead of a retry.
  static HomeSection _fromEnvelope(
    HomeSectionType type,
    Map<String, dynamic> envelope,
  ) {
    final reason = envelope['reason'] as String?;
    final status = envelope['status'] as String?;

    if (reason == 'UNAVAILABLE' || status == 'unavailable') {
      return HomeSectionFailed(
        type,
        RetryableFailure(
          safeMessage: 'This section could not be loaded.',
          code: 'SECTION_UNAVAILABLE',
          debugDetail: 'home section ${type.wireName} reported unavailable',
        ),
      );
    }
    if (reason == 'NOT_CONFIGURED' || reason == 'REQUIRES_AUTH') {
      return HomeSectionAbsent(type);
    }

    final items = envelope['items'];
    return HomeSectionLoaded(
      type,
      items: items is List ? _rows(items) : const <Map<String, dynamic>>[],
    );
  }

  static HomeSection _sectionFrom(HomeSectionType type, Object? value) {
    if (value == null) return HomeSectionAbsent(type);

    // A section may arrive as a bare list, or as an object wrapping `items`.
    if (value is List) {
      return HomeSectionLoaded(type, items: _rows(value));
    }
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      final items = map['items'] ?? map['data'] ?? map['results'];
      if (items is List) {
        return HomeSectionLoaded(type, items: _rows(items));
      }
      // A single-object section — activeBooking and notificationSummary are
      // both scalars in the contract. Wrapped so every consumer reads a list.
      return HomeSectionLoaded(type, items: <Map<String, dynamic>>[map]);
    }
    return HomeSectionAbsent(type);
  }

  static List<Map<String, dynamic>> _rows(List<dynamic> raw) => raw
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList(growable: false);
}
