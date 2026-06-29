import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/shell/marketing_footer.dart';
import '../../../app/shell/zoonze_scaffold.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/app_info.dart';
import '../../../core/store/store_controller.dart';
import '../../../l10n/l10n.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../wishlist/presentation/wishlist_controller.dart';
import '../data/account_repository.dart';

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
    final orders = ref
        .watch(customerOrderCountProvider)
        .maybeWhen(data: (v) => v, orElse: () => 0);
    final wishlist = ref.watch(
      wishlistControllerProvider.select((s) => s.entries.length),
    );
    final activeLocale = ref.watch(
      storeControllerProvider.select((s) => s.activeLocale),
    );
    final languageLabel = activeLocale == 'ar'
        ? l10n.languageArabic
        : l10n.languageEnglish;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Page title (Figma 50:21).
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 10),
          child: Text(
            l10n.accountHeading,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.inkHeading,
            ),
          ),
        ),
        // User row (Figma 42:8): avatar + name + email + member badge.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.surfaceTint,
                child: Text(
                  _initials,
                  style: const TextStyle(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkHeading,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceTint,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '★ ${l10n.accountMember}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const _AccountBand(),
        // Quick stats (Figma 42:17). Vouchers has no backend source → 0.
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _StatCell(
                  value: '$orders',
                  label: l10n.accountStatOrders,
                ),
              ),
              const VerticalDivider(
                width: 1,
                thickness: 1,
                color: AppColors.borderDefault,
                indent: 16,
                endIndent: 16,
              ),
              Expanded(
                child: _StatCell(
                  value: '$wishlist',
                  label: l10n.accountStatWishlist,
                ),
              ),
              const VerticalDivider(
                width: 1,
                thickness: 1,
                color: AppColors.borderDefault,
                indent: 16,
                endIndent: 16,
              ),
              Expanded(
                child: _StatCell(value: '0', label: l10n.accountStatVouchers),
              ),
            ],
          ),
        ),
        const _AccountBand(),
        // Account group (Figma 110:2 / 42:30 …).
        _AccountTile(
          icon: Icons.person_outline,
          label: l10n.profileTitle,
          onTap: () => context.push(AppRoutes.editProfile),
        ),
        const _TileDivider(),
        _AccountTile(
          icon: Icons.receipt_long_outlined,
          label: l10n.accountOrders,
          onTap: () => context.push(AppRoutes.orders),
        ),
        const _TileDivider(),
        _AccountTile(
          icon: Icons.favorite_border,
          label: l10n.wishlistHeading,
          onTap: () => context.go(AppRoutes.wishlist),
        ),
        const _TileDivider(),
        _AccountTile(
          icon: Icons.location_on_outlined,
          label: l10n.accountAddresses,
          onTap: () => context.push(AppRoutes.addresses),
        ),
        const _AccountBand(),
        // Preferences group (Figma 43:3 …).
        _AccountTile(
          icon: Icons.language_outlined,
          label: l10n.languageToggleLabel,
          value: languageLabel,
          onTap: () => context.push(AppRoutes.settings),
        ),
        const _TileDivider(),
        _AccountTile(
          icon: Icons.headset_mic_outlined,
          label: l10n.accountHelpSupport,
          onTap: () => context.push(AppRoutes.help),
        ),
        const _TileDivider(),
        _AccountTile(
          icon: Icons.info_outline,
          label: l10n.accountAbout,
          onTap: () => context.push(AppRoutes.about),
        ),
        const _AccountBand(),
        // Log out (Figma 43:34) — red, centered.
        InkWell(
          onTap: onSignOut,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout, color: AppColors.accentSale, size: 20),
                const SizedBox(width: 10),
                Text(
                  l10n.accountLogOut,
                  style: const TextStyle(
                    color: AppColors.accentSale,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 8),
          child: Center(
            child: Text(
              version != null ? '${l10n.appTitle} · v$version' : l10n.appTitle,
              style: const TextStyle(color: AppColors.inkFaint, fontSize: 11),
            ),
          ),
        ),
        const MarketingFooter(),
      ],
    );
  }
}

/// Full-bleed 8px grey band separating Account sections (Figma 42:16 / 42:29).
class _AccountBand extends StatelessWidget {
  const _AccountBand();

  @override
  Widget build(BuildContext context) =>
      Container(height: 8, color: AppColors.surfaceMuted);
}

/// Hairline between menu tiles, inset to clear the icon chip.
class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) => const Divider(
    height: 1,
    thickness: 1,
    color: AppColors.borderDefault,
    indent: 16,
    endIndent: 16,
  );
}

/// One quick-stat cell — bold burgundy number over a muted label (Figma 42:18).
class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.brandPrimary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, color: AppColors.inkMuted),
        ),
      ],
    ),
  );
}

/// Account menu row (Figma): blush icon chip, label, optional trailing value,
/// muted chevron.
class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.brandPrimary, size: 20),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.inkHeading,
                ),
              ),
            ),
            if (value != null) ...[
              Text(
                value!,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.inkFaint,
                ),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(Icons.chevron_right, color: AppColors.inkMuted, size: 18),
          ],
        ),
      ),
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
