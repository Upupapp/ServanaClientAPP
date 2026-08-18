import 'dart:async';

import 'package:client/common/domain/auth/auth_return_intent.dart';
import 'package:client/common/domain/deep_links/deep_link_resolver.dart';

/// Receives incoming links and carries out what [DeepLinkResolver] decided.
///
/// ## Why this exists separately from the resolver
///
/// The resolver is pure and answers "where does this link go". Something has to
/// LISTEN for links and act — and without it the resolver is a foundation with
/// no callers, which is the defect this codebase has already shipped once in
/// `update_repo.dart`: a helper that wrapped Play's update flow, was fully
/// written, and was never called by anything.
///
/// It is worth being precise about how that would have failed here. Android
/// App Link verification fails while `assetlinks.json` is unhosted, so links
/// open in the browser and everything appears fine. The moment somebody hosts
/// the association files — a manual task, done by a different person, probably
/// weeks later — every claimed URL starts opening the app, and the app does
/// nothing with them. The trap springs on the person completing the checklist.
///
/// ## Cold start and warm start are different events
///
/// A link that launches a terminated app arrives once, retrievable at startup.
/// A link arriving while the app is already running comes through a stream.
/// Handling only the stream loses every link that started the app, which is the
/// majority of them.
class DeepLinkCoordinator {
  DeepLinkCoordinator({
    required Future<Uri?> Function() initialLink,
    required Stream<Uri> linkStream,
    required void Function(String location) navigate,
    required void Function(String gateRoute, AuthReturnIntent? intent)
        navigateToAuthGate,
    required bool Function() isAuthenticated,
    this.authGateRoute = '/auth-gate',
  })  : _initialLink = initialLink,
        _linkStream = linkStream,
        _navigate = navigate,
        _navigateToAuthGate = navigateToAuthGate,
        _isAuthenticated = isAuthenticated;

  final Future<Uri?> Function() _initialLink;
  final Stream<Uri> _linkStream;
  final void Function(String location) _navigate;
  final void Function(String gateRoute, AuthReturnIntent? intent)
      _navigateToAuthGate;
  final bool Function() _isAuthenticated;
  final String authGateRoute;

  StreamSubscription<Uri>? _sub;

  /// The link that launched the app, if any, plus every link after it.
  Future<void> start() async {
    try {
      final initial = await _initialLink();
      if (initial != null) handle(initial);
    } catch (_) {
      // A link that cannot be read is not a reason to fail startup.
    }
    _sub ??= _linkStream.listen(handle, onError: (_) {});
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }

  /// Acts on one link. Returns whether it was claimed, which is what the tests
  /// assert on and what callers use to decide whether to fall through.
  bool handle(Uri uri) {
    final target = DeepLinkResolver.resolve(uri);

    // An unclaimed link does NOTHING. Navigating home would be worse than
    // ignoring it: the customer tapped a specific thing, and being dropped
    // somewhere else is a bug report rather than a destination.
    if (target == null) return false;

    if (target.requiresAuth && !_isAuthenticated()) {
      // Hold the destination, authenticate, then continue. Dropping the
      // customer on Home after sign-in loses the intent that brought them.
      _navigateToAuthGate(authGateRoute, target.returnIntent);
      return true;
    }

    _navigate(target.location);
    return true;
  }
}
