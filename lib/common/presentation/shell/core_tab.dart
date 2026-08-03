import 'package:client/core/accessibility/semantics_labels.dart';
import 'package:flutter/material.dart';

/// Typed identity for each primary navigation branch.
///
/// Branch indexes in [StatefulShellRoute.indexedStack] are derived from this
/// enum so they are never scattered as magic integers. Add or reorder tabs
/// by updating this enum and the router branch list together.
enum CoreTab {
  home,
  bookings,
  messages,
  profile;

  /// Position in the [StatefulShellRoute] branch list.
  /// Relies on the natural [Enum.index] value — keep the declaration order
  /// (home=0, bookings=1, messages=2, profile=3) in sync with the router.

  String get label {
    switch (this) {
      case home:
        return 'Home';
      case bookings:
        return 'Bookings';
      case messages:
        return 'Messages';
      case profile:
        return 'Profile';
    }
  }

  IconData get icon {
    switch (this) {
      case home:
        return Icons.home_outlined;
      case bookings:
        return Icons.receipt_long_outlined;
      case messages:
        return Icons.chat_bubble_outline_rounded;
      case profile:
        return Icons.person_outline_rounded;
    }
  }

  IconData get activeIcon {
    switch (this) {
      case home:
        return Icons.home_rounded;
      case bookings:
        return Icons.receipt_long_rounded;
      case messages:
        return Icons.chat_bubble_rounded;
      case profile:
        return Icons.person_rounded;
    }
  }

  /// Guests may access Home; all other tabs require an authenticated session.
  bool get allowsGuest => this == CoreTab.home;

  /// Accessible label for screen readers, incorporating badge count when > 0.
  String semanticLabel({int badge = 0}) {
    if (badge == 0) return label;
    if (this == CoreTab.messages) {
      return SemanticsLabels.tabMessagesWithUnread(badge);
    }
    return '$label, $badge pending';
  }
}
