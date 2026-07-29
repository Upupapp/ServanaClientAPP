import 'package:client/core/recovery/connectivity_monitor.dart';
import 'package:client/core/recovery/network_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConnectivityMonitor', () {
    test('initial state is unknown', () {
      final monitor = ConnectivityMonitor();
      expect(monitor.state, NetworkState.unknown);
      monitor.dispose();
    });

    test('isOnline is false when unknown', () {
      final monitor = ConnectivityMonitor();
      expect(monitor.isOnline, isFalse);
      monitor.dispose();
    });

    test('isOffline is false when unknown', () {
      final monitor = ConnectivityMonitor();
      expect(monitor.isOffline, isFalse);
      monitor.dispose();
    });

    test('dispose does not throw', () {
      final monitor = ConnectivityMonitor();
      expect(() => monitor.dispose(), returnsNormally);
    });

    test('checkNow does not throw after dispose', () async {
      final monitor = ConnectivityMonitor();
      monitor.dispose();
      // Should be a no-op after disposal — no exception.
      await expectLater(monitor.checkNow(), completes);
    });

    test('onStateChange stream is broadcast', () {
      final monitor = ConnectivityMonitor();
      // Should be able to listen multiple times without error.
      final sub1 = monitor.onStateChange.listen((_) {});
      final sub2 = monitor.onStateChange.listen((_) {});
      sub1.cancel();
      sub2.cancel();
      monitor.dispose();
    });
  });
}
