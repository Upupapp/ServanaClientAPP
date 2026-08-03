/// Represents the current network reachability as observed by [ConnectivityMonitor].
enum NetworkState {
  /// Initial state before the first probe has completed.
  unknown,

  /// A TCP probe to a well-known host succeeded.
  online,

  /// The last TCP probe failed — treat API calls as likely to fail.
  offline,
}
