/// The single authority for session token material.
///
/// ## The gap this closes
///
/// TAB 03 introduced [SecureSessionStore] but never gave it a production write
/// path: tokens kept being persisted inside the `UserSession` Hive record, and
/// the secure store was only ever cleared. So "centralize token persistence"
/// was true of the code that existed and false of the code that ran. This is
/// the write path, plus the one-time migration that moves existing customers
/// across without signing anyone out.
///
/// ## Expand → migrate → contract
///
///  - **Expand** (TAB 03): [SecureSessionStore] exists alongside the Hive
///    record.
///  - **Migrate** (here): the first [read] on a device that still has a Hive
///    token copies it into secure storage, VERIFIES the copy, and only then
///    strips the token fields from the Hive record. Steady-state writes go to
///    secure storage only.
///  - **Contract** (later): once no device reports a legacy fallback, the
///    `token`/`refreshToken` fields can be removed from `UserSession`
///    altogether. Not done here — the Hive adapter is a persisted schema and
///    dropping fields from it is its own migration.
///
/// ## Failing safe
///
/// If the secure write fails or cannot be read back, the legacy token is left
/// **exactly as it was** and the caller still receives working credentials.
/// The alternative — strip first, then discover the write failed — signs the
/// customer out and loses a refresh token that cannot be regenerated on this
/// device for email/password sessions.
///
/// ## Never logged
///
/// No path here writes token material to a log, an exception message or
/// `toString()`. A failure is reported as a boolean or a thrown error carrying
/// no secret. This matters more than usual because migration failures are
/// exactly the situation somebody would be tempted to debug by printing.
library;

import 'package:client/common/domain/helpers/session_service.dart';
import 'package:client/core/session/secure_session_store.dart';

/// Token material for one session.
class SessionTokens {
  const SessionTokens({
    this.accessToken = '',
    this.refreshToken,
    this.subject = '',
  });

  final String accessToken;
  final String? refreshToken;

  /// The server's uid for this session. Used to detect an account switch, and
  /// never used to authorize anything — authorization follows the token the
  /// server issued, not a value this device stored.
  final String subject;

  bool get isEmpty => accessToken.isEmpty;
  bool get isNotEmpty => !isEmpty;

  static const SessionTokens none = SessionTokens();

  /// Deliberately free of token material.
  @override
  String toString() =>
      'SessionTokens(subject: $subject, hasAccess: ${accessToken.isNotEmpty}, '
      'hasRefresh: ${(refreshToken ?? '').isNotEmpty})';
}

/// The legacy Hive-backed location, behind an interface so the migration is
/// testable without a Hive box.
abstract interface class LegacyTokenAccess {
  /// Token material still held in the legacy record, or null when there is
  /// none.
  Future<SessionTokens?> readLegacyTokens();

  /// Removes ONLY the token fields, preserving every other session field.
  ///
  /// The Hive record still carries display name, email, mobile and customer id,
  /// which ~20 call sites read. Deleting the record would sign the customer out
  /// of screens that have nothing to do with credentials.
  Future<void> stripLegacyTokens();
}

/// Default implementation over [SessionService].
class HiveLegacyTokenAccess implements LegacyTokenAccess {
  const HiveLegacyTokenAccess();

  @override
  Future<SessionTokens?> readLegacyTokens() async {
    final session = await SessionService.getSession();
    if (session == null) return null;
    final access = session.token;
    final refresh = session.refreshToken ?? '';
    if (access.isEmpty && refresh.isEmpty) return null;
    return SessionTokens(
      accessToken: access,
      refreshToken: refresh.isEmpty ? null : refresh,
      subject: session.customerID,
    );
  }

  @override
  Future<void> stripLegacyTokens() async {
    final session = await SessionService.getSession();
    if (session == null) return;
    if (session.token.isEmpty && (session.refreshToken ?? '').isEmpty) return;
    await SessionService.saveSession(
      session.copyWith(token: '', refreshToken: null),
    );
  }
}

class SessionTokenStore {
  SessionTokenStore({
    SecureSessionStore? secure,
    LegacyTokenAccess? legacy,
  })  : _secure = secure ?? SecureSessionStore(),
        _legacy = legacy ?? const HiveLegacyTokenAccess();

  final SecureSessionStore _secure;
  final LegacyTokenAccess _legacy;

  /// In-memory cache.
  ///
  /// [read] sits on the path of EVERY authenticated request. Secure storage is
  /// a platform channel to a system service; hitting it per request would add
  /// a hop to every call the app makes. The cache is dropped on write, clear
  /// and account switch, so it cannot outlive the credentials it holds.
  SessionTokens? _cached;

  /// True when the last [read] had to fall back to the legacy record.
  ///
  /// This is the signal the contract phase needs: when no device reports it,
  /// the `token` fields can be removed from `UserSession`. Exposed as a plain
  /// flag rather than reported anywhere automatically — shipping a telemetry
  /// event for it is a separate, consented decision.
  bool get didFallBackToLegacy => _didFallBackToLegacy;
  bool _didFallBackToLegacy = false;

  /// Current token material, migrating a legacy record on first sight.
  Future<SessionTokens> read() async {
    final cached = _cached;
    if (cached != null) return cached;

    final access = await _secure.readAccessToken();
    if (access != null && access.isNotEmpty) {
      final tokens = SessionTokens(
        accessToken: access,
        refreshToken: await _secure.readRefreshToken(),
        subject: await _secure.readSubject() ?? '',
      );
      _cached = tokens;
      return tokens;
    }

    // Nothing in secure storage. Either this is a signed-out device, or it is
    // a device that signed in before the secure store existed.
    final legacy = await _legacy.readLegacyTokens();
    if (legacy == null || legacy.isEmpty) {
      _cached = SessionTokens.none;
      return SessionTokens.none;
    }

    _didFallBackToLegacy = true;
    final migrated = await _migrate(legacy);
    _cached = migrated;
    return migrated;
  }

  /// Copies [legacy] into secure storage, verifies it, then strips the legacy
  /// copy. Returns working credentials either way.
  Future<SessionTokens> _migrate(SessionTokens legacy) async {
    try {
      await _secure.save(
        accessToken: legacy.accessToken,
        refreshToken: legacy.refreshToken,
        subject: legacy.subject,
      );
    } catch (_) {
      // Write failed. The legacy record is untouched and still authoritative,
      // so the customer stays signed in and the migration retries next launch.
      // The error is swallowed rather than logged because anything derived
      // from it could carry the value we are trying to protect.
      return legacy;
    }

    // Verify by reading BACK, not by trusting the write. A secure store that
    // silently drops a write — which is exactly what a corrupt keystore does —
    // would otherwise pass the write step and then lose the credential when we
    // strip the legacy copy.
    final readBack = await _secure.readAccessToken();
    if (readBack != legacy.accessToken) {
      return legacy;
    }

    try {
      await _legacy.stripLegacyTokens();
    } catch (_) {
      // The secure copy is confirmed good, so the customer is fine. A stale
      // legacy copy is a privacy wart, not a functional break, and it will be
      // stripped on a later launch.
    }
    return legacy;
  }

  /// Persists new token material. Secure storage only.
  ///
  /// Also strips any legacy copy, so a device that signs in again after the
  /// migration cannot resurrect a token in Hive.
  ///
  /// Returns false when the secure write failed, so the caller can decide
  /// whether the sign-in it just completed can be trusted.
  Future<bool> write({
    required String accessToken,
    String? refreshToken,
    required String subject,
  }) async {
    try {
      await _secure.save(
        accessToken: accessToken,
        refreshToken: refreshToken,
        subject: subject,
      );
    } catch (_) {
      _cached = null;
      return false;
    }
    _cached = SessionTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      subject: subject,
    );
    // Best-effort: the secure copy is authoritative from here.
    try {
      await _legacy.stripLegacyTokens();
    } catch (_) {}
    return true;
  }

  /// Clears BOTH locations. Used by logout, revoke and account switch.
  Future<void> clear() async {
    _cached = null;
    _didFallBackToLegacy = false;
    await _secure.clear();
    try {
      await _legacy.stripLegacyTokens();
    } catch (_) {}
  }

  /// True when credentials are held for somebody other than [subject].
  ///
  /// Used at sign-in to detect an account SWITCH on a device that never signed
  /// out — the previous customer's cached drafts and inbox have to be cleared,
  /// or they leak into the new session. Returns false when nothing is held,
  /// because a first sign-in is not a switch.
  Future<bool> isDifferentSubjectFrom(String subject) async {
    final tokens = await read();
    if (tokens.isEmpty) return false;
    final held = tokens.subject;
    return held.isNotEmpty && held != subject;
  }

  /// Drops the in-memory copy without touching storage.
  void invalidateCache() => _cached = null;
}
