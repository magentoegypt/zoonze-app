import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/store/store_controller.dart';
import '../l10n/l10n.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// Root widget. Locale, theme (incl. font), and text direction are all driven by
/// the active store view, so a language switch rebuilds the whole tree.
class ZoonzeApp extends ConsumerWidget {
  const ZoonzeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(storeControllerProvider);
    final router = ref.watch(routerProvider);

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
      builder: (context, child) => Directionality(
        textDirection: store.isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
