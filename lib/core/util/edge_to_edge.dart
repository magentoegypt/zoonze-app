import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Draws the app behind the status and navigation bars on Android.
///
/// **Why this is asked for explicitly.** The app targets Android SDK 36, and
/// Android 15 (SDK 35) and later enforce edge-to-edge for such apps with no
/// opt-out. Android 10–14 do not. So without this the same build is
/// edge-to-edge on a new phone and inset by the system bars on an older one —
/// the inconsistency Play Console reports against release 125 as "Edge-to-edge
/// may not display for all users".
///
/// **Why not androidx's `enableEdgeToEdge()`**, which is the fix Play's own
/// advice names: it dispatches to `EdgeToEdgeApi23/26/29`, whose entire job is
/// to call `Window.setStatusBarColor` and `setNavigationBarColor` — the APIs
/// the *other* recommendation on that same release asks us to migrate away
/// from. Flutter's path calls `WindowCompat.setDecorFitsSystemWindows`
/// instead, which is not deprecated.
///
/// Scope: Flutter applies this mode on API 29+, so Android 9 and older keep the
/// inset layout — unreachable without the deprecated calls above, and a
/// vanishing share of devices. iOS is edge-to-edge already and is not asked, so
/// nothing changes there.
Future<void> enableEdgeToEdge() async {
  if (defaultTargetPlatform != TargetPlatform.android) return;
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}
