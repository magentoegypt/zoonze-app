import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/storage/local_cache.dart';
import 'core/storage/locale_prefs.dart';
import 'core/store/store_controller.dart';

/// Shared startup for every flavor entrypoint: init storage, build the provider
/// container with concrete storage overrides, kick off store resolution, and run
/// the app. The flavor itself comes from `--dart-define-from-file`.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  final cache = await LocalCache.open();
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: <Override>[
      localCacheProvider.overrideWithValue(cache),
      localePrefsProvider.overrideWithValue(LocalePrefs(prefs)),
    ],
  );

  // Resolve store views in the background; UI paints with provisional/cached
  // mapping first and updates when this completes.
  unawaited(container.read(storeControllerProvider.notifier).loadStores());

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ZoonzeApp(),
    ),
  );
}
