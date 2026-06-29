import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/notifications/notification_service.dart';
import 'core/storage/local_cache.dart';
import 'core/storage/locale_prefs.dart';
import 'core/store/store_controller.dart';
import 'features/notifications/data/notification_inbox.dart';
import 'features/notifications/presentation/notification_settings_controller.dart';

/// Shared startup for every flavor entrypoint: init storage, build the provider
/// container with concrete storage overrides, kick off store resolution, and run
/// the app. The flavor itself comes from `--dart-define-from-file`.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  final cache = await LocalCache.open();
  final prefs = await SharedPreferences.getInstance();

  // Local notification inbox — loads persisted items and starts capturing
  // incoming pushes immediately (independent of the feed screen).
  await NotificationInbox.instance.init(cache);

  final container = ProviderContainer(
    overrides: <Override>[
      localCacheProvider.overrideWithValue(cache),
      localePrefsProvider.overrideWithValue(LocalePrefs(prefs)),
    ],
  );

  // Resolve store views in the background; UI paints with provisional/cached
  // mapping first and updates when this completes.
  unawaited(container.read(storeControllerProvider.notifier).loadStores());

  // Push plumbing (no-op when no Firebase config is bundled). Apply the saved
  // topic subscriptions once FCM is up.
  unawaited(
    NotificationService.instance.init().then(
      (_) => applyNotificationTopics(cache),
    ),
  );

  runApp(
    UncontrolledProviderScope(container: container, child: const ZoonzeApp()),
  );
}
