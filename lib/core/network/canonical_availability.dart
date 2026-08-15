/// The gate that decides whether a canonical `/api/v1` data source may be used.
///
/// ## Why this exists at all
///
/// TAB 01 established, from the backend's own git objects, that the entire
/// `/api/v1` namespace is absent from `servana_api`'s `origin/main`:
/// `src/api/v1/contract.ts` is not on the pushed branch and
/// `origin/main:src/app.ts` mounts zero v1 routers. The backend's generated
/// parity matrix states it plainly — *"0 cells on canonical … the v1 namespace
/// is mounted, tested and documented, and it is unpushed"*.
///
/// So the canonical client in this repository is real, tested and **must not
/// carry production traffic yet**. This gate is what makes that a property of
/// the build rather than a promise in a document.
///
/// ## Deny by default, and only a build flag can change it
///
/// [enabled] is `false` unless the build is compiled with
/// `--dart-define=CANONICAL_V1_ENABLED=true`. Two things it deliberately is
/// NOT:
///
///  - **Not a runtime probe.** The app never asks the server "do you have v1?"
///    and then switches. A 404 from a legacy-only backend and a 404 from a
///    deployed v1 backend for a genuinely missing resource are the same status,
///    and guessing between them would route real customers onto an endpoint
///    that does not exist.
///  - **Not remote-configurable.** Nothing on the network may turn this on.
///    A flag that a server can flip is a flag an attacker can flip.
///
/// ## Per capability, not all-or-nothing
///
/// v1 will not arrive in one deploy, and the domains are not equally ready —
/// TAB 01 found reviews and notifications have only *partial* canonical
/// surfaces, and booking creation has no canonical endpoint at all. A single
/// global boolean would force the app to migrate a domain whose canonical
/// surface is incomplete, producing the `⚠ mixed` state the backend's own
/// parity matrix warns about. So a capability is enabled individually, and
/// [V1Capability] only lists domains whose canonical surface is complete
/// enough to be switched as a unit.
library;

/// Domains that can be switched from legacy to canonical independently.
///
/// A domain appears here only if EVERY call the app makes for it has a
/// canonical successor. That is why booking, review and support are absent:
///
///  - **bookings** — `POST /api/bookings` is classified `KEEP` with no
///    canonical successor and none planned, so a "migrated" booking domain
///    would still create bookings on a legacy route.
///  - **reviews** — 4 of 9 calls have successors; read, edit, delete,
///    list-mine and report do not.
///  - **support** — the v1 relative is booking-scoped only and is explicitly
///    documented as narrower, not equivalent.
///
/// Adding a value here is a claim that the domain is complete. It should be
/// accompanied by evidence in the migration manifest.
enum V1Capability {
  /// `GET /api/v1/catalog*` — the full canonical catalog tree.
  catalog,

  /// `GET /api/v1/notifications`, `…/unread-count`, `PATCH …/:key/read`,
  /// `POST …/read-all`, `POST|DELETE /api/v1/me/devices`.
  ///
  /// Note: legacy `DELETE /api/user/notifications/:key` has NO canonical
  /// successor. The notifications repository keeps that one call on the
  /// compatibility source even when this capability is enabled — see
  /// `NotificationsRepository`.
  notifications,

  /// `GET|PATCH /api/v1/customer/profile`, `/api/v1/customer/addresses*`.
  customerProfile,

  /// `GET /api/v1/me` plus the verification and password-reset endpoints:
  /// `POST /api/v1/auth/verify-email`, `…/verify-mobile`,
  /// `…/resend-verification`, `…/forgot-password`, `…/reset-password`,
  /// `…/logout`.
  ///
  /// Deliberately named `identity` and NOT `auth`. Sign-in is excluded: the
  /// customer app authenticates through
  /// `POST /api/auth/customer-firebase-login`, which the backend's migration
  /// matrix classifies `ROLE_SPECIFIC` and explicitly does **not** collapse
  /// into `POST /api/v1/auth/login` — its link-collision contract is a 200
  /// carrying `status: "failed"`, and changing that shape is a client release.
  /// Account creation is excluded for the same kind of reason: it goes through
  /// the multi-step registration form and a different payload.
  ///
  /// So enabling this capability migrates identity reads and verification, and
  /// leaves sign-in and registration on the compatibility path by design.
  identity,

  /// `GET|POST /api/v1/conversations*`.
  conversations,

  /// `GET /api/v1/search` — the first server-side catalog search.
  ///
  /// A unit because the compatibility source satisfies the same interface and
  /// returns the same `SearchResults`. Enabling it moves matching from
  /// `String.contains` over a downloaded catalog to the backend's term
  /// expansion and scoring, which is what makes aliases work at all — `aircon`
  /// and `air conditioning` resolve to the same Services with the same ids.
  ///
  /// The screen is unaffected either way: both transports emit qualified refs
  /// (`service:180`) and both feed the same card view model.
  search,

  /// `GET /api/v1/home` and `GET /api/v1/home/sections` — the Home composition.
  ///
  /// Safe to define as a unit because the compatibility source already
  /// satisfies the same interface: enabling this swaps several assembled calls
  /// for one composed fetch, and disabling it swaps back, with no screen
  /// learning which answered. The sections the legacy transport cannot produce
  /// are reported absent rather than failed, so neither direction of the flip
  /// invents content or a retry affordance.
  home,
}

class CanonicalAvailability {
  const CanonicalAvailability({
    bool? enabled,
    Set<V1Capability>? capabilities,
  })  : _enabledOverride = enabled,
        _capabilitiesOverride = capabilities;

  final bool? _enabledOverride;
  final Set<V1Capability>? _capabilitiesOverride;

  /// Master build-time switch. False in every build that does not pass the
  /// define — which is every production build today.
  static const bool buildEnabled =
      bool.fromEnvironment('CANONICAL_V1_ENABLED', defaultValue: false);

  /// Comma-separated capability names, e.g.
  /// `--dart-define=CANONICAL_V1_CAPABILITIES=catalog,notifications`.
  ///
  /// Empty means "none", not "all". An operator who enables the master switch
  /// and forgets the list gets no traffic moved, which is the safe direction.
  static const String buildCapabilities =
      String.fromEnvironment('CANONICAL_V1_CAPABILITIES', defaultValue: '');

  bool get enabled => _enabledOverride ?? buildEnabled;

  Set<V1Capability> get capabilities =>
      _capabilitiesOverride ?? _parse(buildCapabilities);

  /// The single question every repository asks.
  ///
  /// Both conditions must hold: the master switch AND the specific capability.
  bool isAvailable(V1Capability capability) =>
      enabled && capabilities.contains(capability);

  /// True when no canonical traffic can flow at all — the state of every
  /// shipped build today. Surfaced so diagnostics can say so out loud rather
  /// than letting a reader infer it from silence.
  bool get isFullyLegacy => !enabled || capabilities.isEmpty;

  static Set<V1Capability> _parse(String raw) {
    if (raw.trim().isEmpty) return const <V1Capability>{};
    final out = <V1Capability>{};
    for (final part in raw.split(',')) {
      final name = part.trim();
      if (name.isEmpty) continue;
      for (final c in V1Capability.values) {
        // Unrecognised names are ignored rather than throwing: a typo in a
        // build define must not crash the app at startup, and ignoring it
        // fails toward legacy, which is the safe side.
        if (c.name == name) out.add(c);
      }
    }
    return out;
  }

  @override
  String toString() => 'CanonicalAvailability(enabled: $enabled, '
      'capabilities: ${capabilities.map((c) => c.name).join(',')})';
}
