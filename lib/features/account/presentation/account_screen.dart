import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/shell/zoonze_scaffold.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/app_info.dart';
import '../../../l10n/l10n.dart';
import '../../auth/presentation/auth_controller.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);

    final Widget body;
    if (auth.status == AuthStatus.unknown) {
      body = const Center(child: CircularProgressIndicator());
    } else if (auth.isAuthenticated) {
      body = _Authenticated(
        name: auth.customer?.fullName ?? '',
        email: auth.customer?.email ?? '',
        onSignOut: () => ref.read(authControllerProvider.notifier).logout(),
      );
    } else {
      body = const _Guest();
    }

    return ZoonzeScaffold(
      currentTab: AppTab.account,
      showSearch: false,
      body: body,
    );
  }
}

class _Authenticated extends ConsumerWidget {
  const _Authenticated({
    required this.name,
    required this.email,
    required this.onSignOut,
  });

  final String name;
  final String email;
  final VoidCallback onSignOut;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p.characters.first.toUpperCase());
    final joined = letters.join();
    return joined.isEmpty ? '?' : joined;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final version = ref.watch(appVersionProvider).maybeWhen(
      data: (v) => v,
      orElse: () => null,
    );
    return ListView(
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.surfaceTint,
                child: Text(
                  _initials,
                  style: const TextStyle(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.titleLarge),
                    Text(
                      email,
                      style: const TextStyle(color: AppColors.inkMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),
        _AccountTile(
          icon: Icons.person_outline,
          label: l10n.profileTitle,
          onTap: () => context.push(AppRoutes.editProfile),
        ),
        _AccountTile(
          icon: Icons.receipt_long_outlined,
          label: l10n.accountOrders,
          onTap: () => context.push(AppRoutes.orders),
        ),
        _AccountTile(
          icon: Icons.location_on_outlined,
          label: l10n.accountAddresses,
          onTap: () => context.push(AppRoutes.addresses),
        ),
        _AccountTile(
          icon: Icons.favorite_border,
          label: l10n.navWishlist,
          onTap: () => context.go(AppRoutes.wishlist),
        ),
        _AccountTile(
          icon: Icons.notifications_none,
          label: l10n.notificationsTitle,
          onTap: () => context.push(AppRoutes.notifications),
        ),
        _AccountTile(
          icon: Icons.settings_outlined,
          label: l10n.settingsTitle,
          onTap: () => context.push(AppRoutes.settings),
        ),
        _AccountTile(
          icon: Icons.help_outline,
          label: l10n.accountHelp,
          onTap: () => context.push(AppRoutes.help),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout, color: AppColors.brandPrimary),
            label: Text(
              l10n.accountSignOut,
              style: const TextStyle(
                color: AppColors.brandPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        if (version != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 16),
            child: Center(
              child: Text(
                '${l10n.appTitle} · ${l10n.versionLabel} $version',
                style: const TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Account menu row per Figma: burgundy leading icon, label, muted chevron.
class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.brandPrimary),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right, color: AppColors.inkMuted),
      onTap: onTap,
    );
  }
}

class _Guest extends StatelessWidget {
  const _Guest();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.surfaceTint,
              child: Icon(
                Icons.person_outline,
                size: 48,
                color: AppColors.brandPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.accountGuestTitle,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.accountGuestBody,
              style: const TextStyle(color: AppColors.inkMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => context.push(AppRoutes.signIn),
                child: Text(l10n.authSignInTitle),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.push(AppRoutes.signUp),
                child: Text(l10n.authSignUpTitle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
