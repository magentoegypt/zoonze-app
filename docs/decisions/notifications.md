# Decision — Push notifications (Phase 5)

App-side plumbing is in `lib/core/notifications/notification_service.dart` and is
started (non-blocking) from `bootstrap()`.

- **Local notifications** (`flutter_local_notifications`) work standalone — a
  default high-importance channel (`zoonze_default`) is created and Android 13+
  notification permission is requested.
- **FCM** (`firebase_messaging`) is enabled **only when a Firebase config is
  bundled**. `Firebase.initializeApp()` is wrapped in a try/catch: with no
  `google-services.json` / `GoogleService-Info.plist`, FCM silently stays
  disabled (`fcmAvailable == false`) and the app still runs. Foreground messages
  are surfaced as local notifications; a background handler is registered.
- **Topics:** `subscribeToTopic` / `unsubscribeFromTopic` (intended topics:
  `orders`, `promos`) — no-ops until FCM is configured.

## ⚠️ Owner-provided (Open Q §9)
To turn FCM on:
1. Create/identify the Firebase project.
2. Add `android/app/google-services.json` and apply the Google Services Gradle
   plugin in `android/app/build.gradle` (+ classpath in `android/build.gradle`).
3. Add `ios/Runner/GoogleService-Info.plist` and an **APNs key** in Firebase for
   iOS, plus the Push Notifications + Background Modes capabilities in Xcode.
4. These config files are secrets — keep them out of git (per `.gitignore`).

Once present, no Dart changes are needed; `NotificationService` will detect the
config and enable FCM automatically.
