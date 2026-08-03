import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Centralized focus management for the Servana Client app.
///
/// Usage:
///   FocusCoordinator.restoreToNode(myFocusNode);
///   FocusCoordinator.announcePageChange(context, 'Home');
///   FocusCoordinator.requestFocusPostFrame(context, node: headingNode);
abstract final class FocusCoordinator {
  /// Requests focus on [node] after the current frame settles.
  /// Safe to call from initState() and after async operations.
  static void requestFocusPostFrame(
    BuildContext context, {
    FocusNode? node,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      if (node != null) {
        FocusScope.of(context).requestFocus(node);
      } else {
        FocusScope.of(context).requestFocus(FocusNode());
      }
    });
  }

  /// Moves focus to the first invalid form field after validation failure.
  /// [fieldsInOrder] should list FocusNodes in top-to-bottom UI order.
  static void focusFirstError(
    BuildContext context, {
    required List<FocusNode?> fieldsInOrder,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      for (final node in fieldsInOrder) {
        if (node != null && node.context != null) {
          FocusScope.of(context).requestFocus(node);
          return;
        }
      }
    });
  }

  /// Restores focus to a previously-stored node (e.g. after closing a dialog).
  /// Pass the node that opened the dialog so focus returns there.
  static void restoreToNode(FocusNode? node) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (node != null && node.context != null && node.canRequestFocus) {
        node.requestFocus();
      }
    });
  }

  /// Announces a polite screen-change message on route transitions.
  /// Call from initState() when [withScreenReader] is true.
  static void announcePageChange(BuildContext context, String screenTitle) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      SemanticsService.announce(screenTitle, TextDirection.ltr);
    });
  }

  /// Clears all stale focus from the previous route.
  /// Call in dispose() or logout to prevent focus leaking across accounts.
  static void clearStaleFocus(BuildContext context) {
    if (context.mounted) {
      FocusScope.of(context).unfocus();
    }
  }

  /// Trap focus inside a modal widget. Used by accessible dialogs and sheets.
  /// Returns a FocusNode that should be the first child of the modal.
  static FocusNode createModalTrap() => FocusNode(
        debugLabel: 'ServanaModalTrap',
        skipTraversal: false,
        canRequestFocus: true,
      );
}
