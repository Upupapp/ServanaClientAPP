import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The customer app must not carry privileged endpoints, and must not grow
/// silent dead API surface.
///
/// ## What this guards, and why it is not hypothetical
///
/// A sweep on 2026-08-22 found **11 of 82** public methods on
/// `ServanaApiClient` with zero references anywhere in `lib/` or `test/`. Five
/// of them were not customer operations at all:
///
///   * `approveGcashPayment`  -> `POST /api/:bookingId/approve`
///   * `approveCashPayment`   -> `POST /api/:bookingId/mark-cash-paid`
///   * `createGeoCoverage`    -> `POST /api/services/:id/coverage-geo`
///   * `createBranchSlot`     -> `POST /api/branches/slots`
///   * `getRegisteredUsers`   -> `GET  /api/user/registereduser`
///
/// Approving a payment, configuring service coverage, creating branch capacity
/// and listing registered users are provider or administrative capabilities.
/// Nothing in a customer build should be able to reach them, and shipping the
/// call sites also ships the endpoint paths to anyone who unpacks the binary.
/// They were deleted; this test is what stops them coming back in a merge.
///
/// ## Why the remaining six are pinned rather than deleted
///
/// The other six ARE legitimate customer operations that simply have no caller
/// today — `submitGcashProof` in particular looks like a half-finished payment
/// path, and deleting a half-finished feature is a different decision from
/// deleting a privileged one. So they are listed here with a reason each. The
/// list is a ratchet: adding to it requires writing down why, and removing a
/// method from the client is what shrinks it.
void main() {
  final client = File('lib/common/data/backend/servana_api_client.dart')
      .readAsStringSync();

  group('customer app API surface', () {
    /// Paths that are privileged **however they are reached**. Matched on the
    /// path rather than the Dart name, so a rename cannot smuggle one back.
    const forbiddenAnyVerb = <String, String>{
      '/approve': 'approving a payment is a provider/admin capability',
      '/mark-cash-paid': 'marking cash paid is a provider/admin capability',
      'registereduser': 'listing registered users is an admin capability',
    };

    /// Paths where only the WRITE is privileged. Reading service coverage and
    /// reading a branch's slots are ordinary customer operations on the booking
    /// path — coverage-geo is read live through `HttpBackend` today — so the
    /// rule has to be about the verb, not the path. A blanket path ban here
    /// would forbid the customer journey it is meant to protect.
    const forbiddenWriteOnly = <String, String>{
      'coverage-geo':
          'service coverage is CONFIGURED by admin; reading it is fine',
      'branches/slots':
          'branch capacity is CREATED by admin; reading it is fine',
    };

    test('carries no privileged endpoint paths', () {
      final offenders = <String>[];

      forbiddenAnyVerb.forEach((path, why) {
        if (client.contains(path)) offenders.add('$path — $why');
      });

      // Split into method blocks so a verb can be attributed to a path.
      final blocks = client.split(RegExp(r'\n  (?=(?:static )?Future<)'));
      for (final b in blocks) {
        final writes = RegExp(r'_client\.(post|put|patch)\(').hasMatch(b);
        if (!writes) continue;
        forbiddenWriteOnly.forEach((path, why) {
          if (b.contains(path)) offenders.add('write to $path — $why');
        });
      }

      expect(
        offenders,
        isEmpty,
        reason: 'privileged endpoints found in the customer API client:\n'
            '${offenders.join('\n')}',
      );
    });

    test('the block split actually produced method blocks', () {
      final blocks = client.split(RegExp(r'\n  (?=(?:static )?Future<)'));
      expect(blocks.length, greaterThan(50),
          reason: 'block split produced ${blocks.length} — the verb-aware '
              'check above proved nothing');
    });

    test('the forbidden-path scan can actually see this file', () {
      // The floor that stops "no offenders" from silently meaning "no matches".
      // A previous guard in this repository passed because its pattern matched
      // nothing at all, and it kept passing when the defect was put back.
      expect(client.length, greaterThan(10000),
          reason:
              'the client source did not load — the scan above proved nothing');
      expect(client.contains("_uri('/api/"), isTrue,
          reason: 'no endpoint literals found — the scan above proved nothing');
    });

    test('every unreferenced public method is one we have accepted', () {
      /// Unwired today, deliberately kept, with the reason.
      const acceptedUnwired = <String, String>{
        'submitGcashProof': 'half-finished customer payment-proof path; '
            'deleting it would discard partial work, not dead weight',
        'getGeoCoverage': 'read-only coverage lookup; serviceability is served '
            'by CatalogRepository.serviceability today',
        'getAddressById': 'superseded by the all-addresses read, kept for a '
            'single-address fetch a detail screen may still need',
        'getUserProfile': 'superseded by the canonical profile read',
        'listFullCatalog': 'superseded by the canonical catalog reads',
        'resendVerification': 'duplicate of Backend.resendVerificationEmail, '
            'which is the live path',
      };

      // Public Future-returning methods declared at class-member indent.
      final declared = RegExp(
              r'^  (?:static\s+)?Future<.*>\s+([a-zA-Z0-9_]+)\(',
              multiLine: true)
          .allMatches(client)
          .map((m) => m.group(1)!)
          .where((n) => !n.startsWith('_'))
          .toSet();

      expect(declared.length, greaterThan(50),
          reason:
              'method scan found ${declared.length} methods — it is broken');

      // Every reference anywhere else in lib/ and test/.
      final referenced = <String>{};
      for (final dir in ['lib', 'test']) {
        for (final f in Directory(dir)
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
          if (f.path.endsWith('servana_api_client.dart')) continue;
          final src = f.readAsStringSync();
          for (final name in declared) {
            if (referenced.contains(name)) continue;
            if (RegExp('\\b$name\\b').hasMatch(src)) referenced.add(name);
          }
        }
      }

      expect(referenced.length, greaterThan(30),
          reason: 'reference scan found ${referenced.length} — it is broken');

      final unwired = declared.difference(referenced).toList()..sort();
      final unexplained =
          unwired.where((n) => !acceptedUnwired.containsKey(n)).toList();

      expect(
        unexplained,
        isEmpty,
        reason: 'new dead API surface with no stated reason: $unexplained\n'
            'Either wire it, delete it, or add it to acceptedUnwired with why.',
      );
    });
  });
}
