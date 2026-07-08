import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/notifications/notification_service.dart';
import '../core/store/store_controller.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/cart/presentation/cart_controller.dart';
import '../features/wishlist/presentation/wishlist_controller.dart';
import '../l10n/l10n.dart';
import 'notification_routes.dart';
import 'router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_mode_controller.dart';

/// Root widget. Locale, theme (incl. font), and text direction are all driven by
/// the active store view, so a language switch rebuilds the whole tree. Also
/// listens for tapped notifications and deep-links to the matching route.
class ZoonzeApp extends ConsumerStatefulWidget {
  const ZoonzeApp({super.key});

  @override
  ConsumerState<ZoonzeApp> createState() => _ZoonzeAppState();
}

class _ZoonzeAppState extends ConsumerState<ZoonzeApp>
    with WidgetsBindingObserver {
  StreamSubscription<Map<String, dynamic>>? _openedSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _openedSub = NotificationService.instance.onNotificationOpened.listen(
      _handleNotification,
    );
    // Replay a cold-start tap once the router is mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initial = NotificationService.instance.takeInitialMessage();
      if (initial != null) _handleNotification(initial);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Real-time sync: on returning to the app, pull the server cart (and, when
    // signed in, the wishlist) so changes made on the website appear.
    if (state == AppLifecycleState.resumed) {
      ref.read(cartControllerProvider.notifier).refresh();
      if (ref.read(authControllerProvider).isAuthenticated) {
        ref.read(wishlistControllerProvider.notifier).refresh();
      }
    }
  }

  void _handleNotification(Map<String, dynamic> data) {
    final route = notificationRoute(data);
    if (route != null) ref.read(routerProvider).go(route);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _openedSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(storeControllerProvider);
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      locale: store.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(store.activeLocale),
      darkTheme: AppTheme.dark(store.activeLocale),
      // Defaults to light (white) — the app no longer follows the OS dark mode
      // unless the user picks Black/System in Settings.
      themeMode: themeMode,
      builder: (context, child) => Directionality(
        textDirection: store.isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
