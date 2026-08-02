/// SC-185 — the app's public legal links must point at pages that exist.
///
/// Every legal URL in the app was wrong: it linked to `servana.com.ph/privacy`
/// and `/terms`, which return 404. The real pages are
/// `www.servana.com.ph/privacy-policy` and `/terms-and-conditions`.
///
/// Nothing caught it because `launchUrl` to a 404 is not an error. The browser
/// opens, the page says "not found", and the app never learns. A customer
/// tapping "Privacy Policy" during sign-up hit a dead end — and a reachable
/// privacy policy is mandatory for Play review.
///
/// These are offline assertions on purpose. A test that hits the network would
/// fail in CI whenever the marketing site is slow, and a legal-link test that
/// cries wolf is one people learn to ignore.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:client/common/constants/servana_urls.dart';

void main() {
  group('canonical URLs', () {
    test('point at the paths that actually exist', () {
      expect(ServanaUrls.privacyPolicy,
          'https://www.servana.com.ph/privacy-policy');
      expect(ServanaUrls.termsAndConditions,
          'https://www.servana.com.ph/terms-and-conditions');
    });

    test('cancellation and refunds resolve to the T&C', () {
      // There is no standalone page for either; section 8 of the T&C is
      // "Cancellations and Refunds". Inventing /cancellation and /refunds is
      // what produced two of the four 404s.
      expect(ServanaUrls.cancellationPolicy, ServanaUrls.termsAndConditions);
      expect(ServanaUrls.refundPolicy, ServanaUrls.termsAndConditions);
    });

    test('use the www host, which is where the apex redirects', () {
      for (final url in ServanaUrls.all) {
        expect(url, startsWith('https://www.servana.com.ph'), reason: url);
      }
    });

    test('none of the dead paths survive', () {
      for (final dead in const [
        '/privacy',
        '/terms',
        '/cancellation',
        '/refunds',
      ]) {
        for (final url in ServanaUrls.all) {
          expect(url.endsWith(dead), isFalse, reason: '$url ends with $dead');
        }
      }
    });
  });

  group('no file re-introduces a hard-coded legal URL', () {
    test('every legal link goes through ServanaUrls', () {
      // The original bug was 13 literals across 5 files. One centralised
      // definition is the fix; this stops the next one drifting back.
      final offenders = <String>[];
      final dir = Directory('lib');
      for (final f in dir.listSync(recursive: true).whereType<File>()) {
        if (!f.path.endsWith('.dart')) continue;
        if (f.path.endsWith('servana_urls.dart')) continue;
        final lines = f.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (!line.contains('servana.com.ph')) continue;
          // Legitimate non-marketing hosts: the API, the payment webview
          // allow-list, the support mailto, and plain display text.
          final isEmail = RegExp(r'[\w.+-]+@servana\.com\.ph').hasMatch(line);
          if (line.contains('api.servana.com.ph') || // API host
              line.contains('app.servana.com.ph') || // payment allow-list
              line.contains('mailto:') ||
              isEmail || // support@, privacy@, etc.
              line.contains("'servana.com.ph'")) {
            // display text
            continue;
          }
          offenders.add('${f.path}:${i + 1}  ${line.trim()}');
        }
      }
      expect(offenders, isEmpty,
          reason: 'hard-coded marketing URLs found:\n${offenders.join('\n')}');
    });
  });
}
