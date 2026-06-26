import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/shell/zoonze_scaffold.dart';
import '../../../app/theme/app_colors.dart';
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

class _Authenticated extends StatelessWidget {
  const _Authenticated({
    required this.name,
    required this.email,
    required this.onSignOut,
  });

  final String name;
  final String email;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                  name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: Theme.of(context).textTheme.titleLarge),
                    Text(email,
                        style: const TextStyle(color: AppColors.inkMuted)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.receipt_long_outlined),
          title: Text(l10n.accountOrders),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.location_on_outlined),
          title: Text(l10n.accountAddresses),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.favorite_border),
          title: Text(l10n.navWishlist),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go(AppRoutes.wishlist),
        ),
        ListTile(
          leading: const Icon(Icons.help_outline),
          title: Text(l10n.accountHelp),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OutlinedButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout),
            label: Text(l10n.accountSignOut),
          ),
        ),
      ],
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
            const Icon(Icons.person_outline,
                size: 56, color: AppColors.brandPrimary),
            const SizedBox(height: 16),
            Text(l10n.accountGuestTitle,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(l10n.accountGuestBody,
                style: const TextStyle(color: AppColors.inkMuted),
                textAlign: TextAlign.center),
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
