/// True when the list on screen is no longer known to be current.
///
/// Written as a switch EXPRESSION with no default, so it is total over the
/// enum and the compiler refuses a new state until someone decides what it
/// means here. That is not decoration: `offline` was set by the controller
/// and read by nothing, so a failed background refresh showed a stale list
/// with no indication it was stale. A default arm would have hidden it.
bool isStaleState(NotificationsLoadState state) => switch (state) {
      NotificationsLoadState.error => true,
      NotificationsLoadState.offline => true,
      NotificationsLoadState.initial => false,
      NotificationsLoadState.loading => false,
      NotificationsLoadState.ready => false,
      NotificationsLoadState.refreshing => false,
    };

enum NotificationsLoadState {
  initial,
  loading,
  ready,
  refreshing,
  error,
  offline,
}
