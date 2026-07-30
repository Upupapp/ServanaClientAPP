import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

import 'trace_name_registry.dart';

// Governed Firebase Performance Monitoring access.
// Callers use this wrapper — never FirebasePerformance.instance directly.
//
// Rules (§§76-83):
//   - Only TraceNames constants are accepted as trace names
//   - HTTP traces use normalized route templates (no raw URLs with IDs)
//   - Attributes added to traces must be safe (no PII, no high-cardinality)
//   - Performance failure MUST NEVER block customer journeys
final class PerformanceService {
  PerformanceService({FirebasePerformance? perf})
      : _fp = perf ?? FirebasePerformance.instance;

  final FirebasePerformance _fp;

  // Start a named trace. Returns a handle — call stop() on it when done.
  // Returns null if the trace name is not registered or on any error.
  Future<Trace?> startTrace(String traceName,
      {Map<String, String>? attributes}) async {
    if (!_isAllowedTrace(traceName)) {
      if (kDebugMode) {
        debugPrint('[Perf] Unregistered trace name: $traceName');
      }
      return null;
    }
    try {
      final trace = _fp.newTrace(traceName);
      if (attributes != null) {
        for (final entry in attributes.entries) {
          trace.putAttribute(entry.key, _sanitizeAttributeValue(entry.value));
        }
      }
      await trace.start();
      return trace;
    } catch (e) {
      if (kDebugMode) debugPrint('[Perf] startTrace($traceName) error: $e');
      return null;
    }
  }

  // Stop a trace that was started with startTrace().
  Future<void> stopTrace(Trace? trace, {String? result}) async {
    if (trace == null) return;
    try {
      if (result != null) {
        trace.putAttribute('result', _sanitizeAttributeValue(result));
      }
      await trace.stop();
    } catch (e) {
      if (kDebugMode) debugPrint('[Perf] stopTrace error: $e');
    }
  }

  // Convenience: run an async operation and record its duration as a trace.
  Future<T> traced<T>(String traceName, Future<T> Function() fn,
      {Map<String, String>? attributes}) async {
    final trace = await startTrace(traceName, attributes: attributes);
    try {
      final result = await fn();
      await stopTrace(trace, result: 'success');
      return result;
    } catch (e) {
      await stopTrace(trace, result: 'error');
      rethrow;
    }
  }

  // Truncate attribute values to Firebase's 100-char limit.
  // Also strip anything that looks like a URL (could contain IDs).
  static String _sanitizeAttributeValue(String value) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return 'url_redacted';
    }
    return value.length > 100 ? value.substring(0, 100) : value;
  }

  static bool _isAllowedTrace(String name) {
    // Reflect all constants from TraceNames
    const allowed = {
      TraceNames.appStartup,
      TraceNames.homeLoad,
      TraceNames.searchRequest,
      TraceNames.serviceDetailLoad,
      TraceNames.bookingSubmit,
      TraceNames.checkoutCreate,
      TraceNames.bookingDetailLoad,
      TraceNames.conversationLoad,
      TraceNames.trackingSnapshotLoad,
      TraceNames.profileLoad,
      TraceNames.supportTicketLoad,
      TraceNames.reviewEligibilityCheck,
      TraceNames.notificationListLoad,
    };
    return allowed.contains(name);
  }
}
