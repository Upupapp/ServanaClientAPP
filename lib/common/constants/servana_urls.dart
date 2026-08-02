/// Canonical public Servana URLs (SC-185).
///
/// These were previously written as string literals at 13 call sites across 5
/// files, and every one of them was wrong: the app linked to
/// `servana.com.ph/privacy` and `/terms`, which return 404. The real pages are
/// `www.servana.com.ph/privacy-policy` and `/terms-and-conditions`.
///
/// Nothing caught it because a `launchUrl` to a 404 is not an error — the
/// browser opens, the page says "not found", and the app is none the wiser.
/// A customer tapping "Privacy Policy" during sign-up got a dead end, and a
/// reachable privacy policy is mandatory for Play review.
///
/// Centralised so the next site change is one edit rather than thirteen, and
/// so a test can assert every URL still resolves.
abstract final class ServanaUrls {
  /// Marketing site root. The apex redirects to `www`, so `www` is canonical.
  static const String home = 'https://www.servana.com.ph';

  static const String privacyPolicy = '$home/privacy-policy';

  static const String termsAndConditions = '$home/terms-and-conditions';

  /// Cancellation terms live in section 8 of the T&C, "Cancellations and
  /// Refunds". There is no standalone page, and pointing at an invented
  /// `/cancellation` path is what produced the 404 this replaces.
  static const String cancellationPolicy = termsAndConditions;

  /// Refund terms share section 8 with cancellations.
  static const String refundPolicy = termsAndConditions;

  /// Every externally-linked URL, for the reachability test.
  static const List<String> all = <String>[
    home,
    privacyPolicy,
    termsAndConditions,
  ];
}
