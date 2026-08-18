/// Turns an external URL into a destination inside the app (TAB 14).
///
/// ## Why this is pure
///
/// A deep link is UNTRUSTED INPUT arriving from a mail client, a push payload
/// or a shared message. The rules that decide what it may reach are the part
/// that must be certain, so they live here with no Flutter, no router and no
/// I/O, and the widget layer only carries out what this returns.
///
/// ## What a link may never do
///
/// It may not trigger a mutation. Every destination below is a READ — a
/// booking, a conversation, a notification list, a service page. Nothing
/// cancels, confirms, pays or deletes, because a URL that mutates is a URL that
/// mutates when a mail client prefetches it.
///
/// It may not carry a credential. `password-reset` deliberately resolves to the
/// reset SCREEN and drops any token in the URL rather than forwarding it,
/// because a one-time code in a path or query is written to the nginx access
/// log on every request and survives in browser history and referrer headers.
/// The screen asks the customer to enter the code they were emailed.
///
/// ## Every segment is percent-encoded
///
/// Identifiers reach the router from links and cached payloads, and a segment
/// containing `/` or `?` silently retargets the request — `/bookings/1%2F..%2Fadmin`
/// is a different route than it appears. The v1 endpoint builder already
/// encodes; this must match, or the two disagree about what an id is.
library;

import 'package:client/common/constants/servana_urls.dart';
import 'package:client/common/domain/auth/auth_return_intent.dart';

/// Where a link resolved to, and what has to be true to go there.
class DeepLinkTarget {
  const DeepLinkTarget({
    required this.location,
    required this.requiresAuth,
    this.returnIntent,
  });

  /// A GoRouter location, already encoded.
  final String location;

  /// Whether the customer must be signed in first. When true and they are not,
  /// the caller holds [returnIntent], authenticates, and continues — dropping
  /// them on Home after sign-in loses the intent that brought them.
  final bool requiresAuth;

  /// Validated against [AuthReturnIntent]'s own allow-list, so a link cannot
  /// become an open redirect.
  final AuthReturnIntent? returnIntent;

  @override
  bool operator ==(Object other) =>
      other is DeepLinkTarget &&
      other.location == location &&
      other.requiresAuth == requiresAuth;

  @override
  int get hashCode => Object.hash(location, requiresAuth);

  @override
  String toString() => 'DeepLinkTarget($location, auth=$requiresAuth)';
}

abstract final class DeepLinkResolver {
  /// Hosts this app will accept links from. Anything else is refused outright:
  /// an allow-list is the only thing standing between a Universal Link handler
  /// and an attacker-chosen host.
  ///
  /// Defined once in [ServanaUrls.deepLinkHosts], because the intent filters,
  /// the association file and this check must name the same set.
  static const allowedHosts = ServanaUrls.deepLinkHosts;

  /// The link path prefixes this app claims. Kept in one place because the
  /// Android intent filters, the AASA paths and this table must agree — three
  /// copies of a path list is three chances to disagree.
  static const claimedPrefixes = <String>[
    '/bookings',
    '/conversations',
    '/notifications',
    '/services',
    '/reset-password',
  ];

  /// Resolves [uri]. Returns null when the link is not one this app claims,
  /// which the caller must treat as "open in the browser", never as "open Home".
  static DeepLinkTarget? resolve(Uri uri) {
    if (uri.scheme != 'https') return null;
    if (!allowedHosts.contains(uri.host.toLowerCase())) return null;

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return null;

    switch (segments[0]) {
      case 'bookings':
        if (segments.length == 1) {
          return const DeepLinkTarget(
            location: '/bookings',
            requiresAuth: true,
            returnIntent: null,
          );
        }
        final id = _id(segments[1]);
        if (id == null) return null;
        return DeepLinkTarget(
          location: '/bookings/$id',
          requiresAuth: true,
          returnIntent: AuthReturnIntent.validated(
            destination: ProtectedDestination.bookingDetail,
            routeName: 'BookingDetail',
            gateReason: 'to view this booking',
          ),
        );

      case 'conversations':
        if (segments.length < 2) {
          return DeepLinkTarget(
            location: '/messages',
            requiresAuth: true,
            returnIntent: AuthReturnIntent.validated(
              destination: ProtectedDestination.messages,
              routeName: 'Messages',
              gateReason: 'to read your messages',
            ),
          );
        }
        final cid = _id(segments[1]);
        if (cid == null) return null;
        return DeepLinkTarget(
          location: '/messages/$cid',
          requiresAuth: true,
          returnIntent: AuthReturnIntent.validated(
            destination: ProtectedDestination.bookingChat,
            routeName: 'BookingChat',
            gateReason: 'to read this conversation',
          ),
        );

      case 'notifications':
        return DeepLinkTarget(
          location: '/notifications',
          requiresAuth: true,
          returnIntent: AuthReturnIntent.validated(
            destination: ProtectedDestination.notifications,
            routeName: 'Notifications',
            gateReason: 'to see your notifications',
          ),
        );

      case 'services':
        if (segments.length < 2) return null;
        final sid = _id(segments[1]);
        if (sid == null) return null;
        // Public: browsing a service needs no session, and demanding one here
        // would put an auth wall in front of the only link a stranger receives.
        return DeepLinkTarget(
          location: '/services/$sid',
          requiresAuth: false,
          returnIntent: null,
        );

      case 'reset-password':
        // The token in the URL is deliberately DROPPED. A one-time code in a
        // path or query reaches the access log, browser history and any
        // referrer header. The screen asks for the code instead.
        return const DeepLinkTarget(
          location: '/reset-password',
          requiresAuth: false,
          returnIntent: null,
        );

      default:
        return null;
    }
  }

  /// Validates and encodes an identifier taken from a link.
  ///
  /// Ids are integers everywhere on this platform, which is the strongest
  /// available filter — it rejects traversal, injected separators and anything
  /// else before encoding has to save us. The encode stays anyway, because a
  /// filter and an encoder fail differently.
  static String? _id(String raw) {
    final decoded = Uri.decodeComponent(raw);
    if (decoded.isEmpty || decoded.length > 18) return null;
    if (!RegExp(r'^\d+$').hasMatch(decoded)) return null;
    return Uri.encodeComponent(decoded);
  }
}
