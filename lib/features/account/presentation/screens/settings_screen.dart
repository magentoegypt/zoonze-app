import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/theme_mode_controller.dart';
import '../../../../core/store/store_controller.dart';
import '../../../../l10n/l10n.dart';
import '../../../notifications/presentation/notification_settings_controller.dart';

/// App settings: language toggle (EN/AR) + notification preferences, plus a
/// shortcut to Help. The same language switch lives in the menu drawer; this
/// screen is the discoverable home for it.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final store = ref.watch(storeControllerProvider);
    final promoEnabled = ref.watch(notificationSettingsProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          _SectionHeader(l10n.settingsTheme),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: ThemeMode.light, label: Text(l10n.themeWhite)),
                ButtonSegment(value: ThemeMode.dark, label: Text(l10n.themeBlack)),
                ButtonSegment(value: ThemeMode.system, label: Text(l10n.themeSystem)),
              ],
              selected: {themeMode},
              onSelectionChanged: (s) =>
                  ref.read(themeModeProvider.notifier).set(s.first),
            ),
          ),
          const Divider(height: 32),

          _SectionHeader(l10n.languageToggleLabel),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: 'en', label: Text(l10n.languageEnglish)),
                ButtonSegment(value: 'ar', label: Text(l10n.languageArabic)),
              ],
              selected: {store.activeLocale == 'ar' ? 'ar' : 'en'},
              onSelectionChanged: (selection) => ref
                  .read(storeControllerProvider.notifier)
                  .switchLocale(selection.first),
            ),
          ),
          const Divider(height: 32),

          _SectionHeader(l10n.notificationsTitle),
          SwitchListTile.adaptive(
            value: promoEnabled,
            onChanged: (v) =>
                ref.read(notificationSettingsProvider.notifier).setPromotions(v),
            title: Text(l10n.notificationsPromoTitle),
            subtitle: Text(l10n.notificationsPromoBody),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              l10n.notificationsOrdersNote,
              style: const TextStyle(color: AppColors.inkMuted),
            ),
          ),
          const Divider(height: 32),

          ListTile(
            leading: const Icon(Icons.help_outline),
            title: Text(l10n.accountHelp),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.help),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 8),
    child: Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: AppColors.inkMuted,
        fontWeight: FontWeight.w700,
        fontSize: 12,
        letterSpacing: 1,
      ),
    ),
  );
}
