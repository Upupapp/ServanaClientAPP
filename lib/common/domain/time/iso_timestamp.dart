/// Centralised timestamp parsing for backend payloads.
///
/// Servana emits two shapes and the difference is not cosmetic.
///
/// The canonical catalog surfaces (`/api/catalog/*`, `/api/admin/catalog/*`)
/// normalise to ISO 8601 with a UTC designator:
///
/// ```text
/// 2026-08-11T11:03:23.421Z
/// ```
///
/// Legacy surfaces still emit Postgres' native rendering, and measured on
/// production today `/api/services/:id/options-with-addons` returns BOTH in the
/// same object — `createdAt` ISO, `updatedAt` raw:
///
/// ```text
/// 2026-07-15 02:51:24.993763+00
/// ```
///
/// That second form has two deviations from ISO: a space where ISO wants `T`,
/// and a two-digit offset where ISO wants ±HH:MM.
///
/// **Dart tolerates both.** Verified against this SDK:
///
/// ```text
/// DateTime.parse('2026-07-15 02:51:24.993763+00')
///   => 2026-07-15T02:51:24.993763Z
/// ```
///
/// This is worth stating explicitly because the backend's equivalent helper
/// exists for the opposite reason: JavaScript's `new Date()` REJECTS the bare
/// `+00`, so a Node fix that repairs only the space returns `NaN`. That
/// asymmetry makes it tempting to assume the Dart side has the same hole. It
/// does not, and `catalog_contract_test.dart` pins the SDK's actual behaviour
/// so this claim is checked rather than believed.
///
/// The repair below is therefore defence in depth, not the load-bearing path —
/// it covers a future SDK tightening its parser or a surface emitting a form
/// Dart has not seen. What IS load-bearing is that this function never throws:
/// callers get null and a catalog row with an unreadable timestamp still
/// renders, because the value is cache metadata the customer never sees.
///
/// Every catalog timestamp goes through here. Do not call `DateTime.parse`
/// directly on a backend value and do not hand-slice the string; a substring is
/// how a timezone silently becomes wrong.
library;

/// Parses a backend timestamp, returning `null` rather than throwing.
///
/// Null is the honest answer for an absent or unparseable timestamp: a catalog
/// row with a broken `updatedAt` must still render, because the timestamp is
/// cache metadata and never something the customer reads.
DateTime? parseBackendTimestamp(Object? raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;

  final text = raw.toString().trim();
  if (text.isEmpty) return null;

  // Fast path: already ISO.
  final direct = DateTime.tryParse(text);
  if (direct != null) return direct.toUtc();

  // Repair both Postgres deviations together. Either alone still fails.
  var candidate = text.replaceFirst(' ', 'T');
  candidate = candidate.replaceFirstMapped(
    RegExp(r'([+-]\d{2})$'),
    (m) => '${m[1]}:00',
  );

  return DateTime.tryParse(candidate)?.toUtc();
}

/// Serialises for the cache, so a round trip cannot change the instant.
String? formatBackendTimestamp(DateTime? value) =>
    value?.toUtc().toIso8601String();
