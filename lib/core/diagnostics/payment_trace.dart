import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A short, persisted trail of what happened on the last payment attempts.
///
/// Exists because every payment failure used to render as the same "awaiting
/// payment" screen: a missing native module, a resolver that couldn't find the
/// order, a stale token and a PENDING session were indistinguishable from the
/// outside, and `fetchPaymentSession` swallowed the cause into a bare `null`.
/// Diagnosing one bug took a full on-device session for want of a single line.
///
/// Persisted rather than logged because `debugPrint` does not reach logcat in a
/// release build — which is exactly when it is needed. Read it on the
/// connection-test screen (Settings > Connection test).
///
/// Recording must never affect checkout: every call swallows its own errors and
/// nothing here is awaited for correctness.
class PaymentTrace {
  PaymentTrace._();

  static const String _key = 'paymentTrace';

  /// Enough to cover a full attempt (session fetch, gateway, outcome) several
  /// times over, without letting the list grow unbounded.
  static const int _maxEntries = 24;

  static Future<void> record(String line) async {
    // Always mirror to the console — useful in debug, harmless in release.
    debugPrint('PaymentTrace: $line');
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().toIso8601String();
      final entries = prefs.getStringList(_key) ?? <String>[];
      entries.insert(0, '${now.substring(5, 19).replaceFirst('T', ' ')}  $line');
      if (entries.length > _maxEntries) {
        entries.removeRange(_maxEntries, entries.length);
      }
      await prefs.setStringList(_key, entries);
    } catch (_) {
      // Diagnostics must never break a payment.
    }
  }

  static Future<List<String>> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_key) ?? const <String>[];
    } catch (_) {
      return const <String>[];
    }
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {
      // ignore
    }
  }
}
