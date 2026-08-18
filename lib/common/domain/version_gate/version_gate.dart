/// The minimum-version gate (TAB 15).
///
/// ## Why this exists
///
/// Ninety-four legacy routes are classified `ALIAS_TEMPORARILY` and production
/// already emits `Deprecation: true` on them. When those aliases are retired,
/// every installed build that has not migrated simply breaks — and until this
/// gate existed there was no way to tell those builds to upgrade, and no way to
/// find out how many there were.
///
/// It is also the honest answer to the build-time capability flags. Canonical
/// traffic is enabled at compile time and deliberately cannot be turned off
/// remotely, because a flag a server can flip is a flag an attacker can flip.
/// The only way to retire a bad wave fleet-wide is therefore to require an
/// upgrade, which is what this makes possible at all.
///
/// ## What it is not
///
/// It gates on VERSION and nothing else. No feature may be enabled or disabled
/// through this channel — the gate may block the app, it may never silently
/// change its behaviour. That boundary is why the decision is a three-value
/// enum and not a bag of flags.
///
/// This library is deliberately pure: no Firebase, no Flutter, no I/O. The
/// policy is the part that must be certain, so it is the part that is trivially
/// testable.
library;

/// What the app should do about the build the customer is running.
enum VersionGateDecision {
  /// Current enough. Proceed silently.
  allowed,

  /// Below the recommended build. A dismissible prompt, frequency-capped.
  recommendUpdate,

  /// Below the minimum supported build. A blocking screen with no dismissal.
  blocked,
}

/// The remote schema, versioned so an older build reading a newer config
/// degrades predictably instead of guessing.
///
/// Not annotated `@immutable`: that lives in `package:meta`, which this project
/// only has transitively, and this library is deliberately import-free so the
/// policy can be tested without a Flutter binding. Every field is `final`.
class VersionGateConfig {
  const VersionGateConfig({
    required this.schemaVersion,
    required this.minimumSupportedBuild,
    required this.recommendedBuild,
    required this.message,
    required this.androidStoreUrl,
    required this.iosStoreUrl,
  });

  /// The schema this app understands. A config declaring a HIGHER version is
  /// ignored entirely rather than partially applied — see [fromMap].
  static const supportedSchemaVersion = 1;

  final int schemaVersion;

  /// Builds strictly below this are blocked.
  final int minimumSupportedBuild;

  /// Builds strictly below this get a dismissible prompt.
  final int recommendedBuild;

  /// Shown on the blocking screen. Must say why.
  final String message;

  final String androidStoreUrl;
  final String iosStoreUrl;

  /// Parses a Remote Config payload. Returns null for anything it cannot fully
  /// trust, because a half-understood gate is worse than none: this gate can
  /// lock a customer out of the app, so ambiguity must resolve to "do nothing".
  static VersionGateConfig? fromMap(Map<String, Object?> raw) {
    final schema = _asInt(raw['schema_version']);
    if (schema == null || schema < 1) return null;

    // A newer schema may mean these keys have changed meaning. Refusing to act
    // is the only safe reading — the alternative is an old build enforcing a
    // rule it has misunderstood, and the customer cannot argue with a blocking
    // screen.
    if (schema > supportedSchemaVersion) return null;

    final minimum = _asInt(raw['minimum_supported_build']);
    if (minimum == null || minimum < 0) return null;

    final recommended = _asInt(raw['recommended_build']) ?? minimum;

    // A recommended build below the minimum is incoherent. Clamp rather than
    // reject: the minimum is the safety-critical half and must still apply.
    final coherentRecommended = recommended < minimum ? minimum : recommended;

    return VersionGateConfig(
      schemaVersion: schema,
      minimumSupportedBuild: minimum,
      recommendedBuild: coherentRecommended,
      message: (raw['message'] as String?)?.trim().isNotEmpty == true
          ? (raw['message'] as String).trim()
          : _defaultMessage,
      androidStoreUrl: (raw['android_store_url'] as String?) ?? '',
      iosStoreUrl: (raw['ios_store_url'] as String?) ?? '',
    );
  }

  static const _defaultMessage =
      'This version of Servana is no longer supported. '
      'Please update to continue booking services.';

  Map<String, Object?> toMap() => <String, Object?>{
        'schema_version': schemaVersion,
        'minimum_supported_build': minimumSupportedBuild,
        'recommended_build': recommendedBuild,
        'message': message,
        'android_store_url': androidStoreUrl,
        'ios_store_url': iosStoreUrl,
      };

  static int? _asInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is VersionGateConfig &&
      other.schemaVersion == schemaVersion &&
      other.minimumSupportedBuild == minimumSupportedBuild &&
      other.recommendedBuild == recommendedBuild &&
      other.message == message &&
      other.androidStoreUrl == androidStoreUrl &&
      other.iosStoreUrl == iosStoreUrl;

  @override
  int get hashCode => Object.hash(schemaVersion, minimumSupportedBuild,
      recommendedBuild, message, androidStoreUrl, iosStoreUrl);
}

/// The decision itself.
abstract final class VersionGate {
  /// Evaluates the gate.
  ///
  /// [config] is null when Remote Config has never been fetched successfully
  /// AND nothing was cached. That resolves to [VersionGateDecision.allowed] —
  /// **fail open**. A gate that blocks the application because the network is
  /// unavailable is worse than the problem it solves: it turns every airport,
  /// every dead spot and every Firebase outage into a total outage of an app
  /// that would otherwise work offline.
  ///
  /// Fail-open applies to NEVER-FETCHED, not to previously-fetched. A cached
  /// minimum is still enforced offline, because it was genuinely published and
  /// nothing has withdrawn it — see `VersionGateRepository`.
  static VersionGateDecision evaluate({
    required int currentBuild,
    required VersionGateConfig? config,
  }) {
    if (config == null) return VersionGateDecision.allowed;

    // A build number we could not read is not evidence of an old build.
    if (currentBuild <= 0) return VersionGateDecision.allowed;

    if (currentBuild < config.minimumSupportedBuild) {
      return VersionGateDecision.blocked;
    }
    if (currentBuild < config.recommendedBuild) {
      return VersionGateDecision.recommendUpdate;
    }
    return VersionGateDecision.allowed;
  }
}
