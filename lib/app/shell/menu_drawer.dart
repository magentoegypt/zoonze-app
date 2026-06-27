import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/store/store_controller.dart';
import '../../core/widgets/brand_logo.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/catalog/presentation/catalog_providers.dart';
import '../../l10n/l10n.dart';
import '../routes.dart';
import '../theme/app_colors.dart';

/// Side navigation drawer: brand header, customer profile header, SHOP
/// categories (live), ACCOUNT links, a bottom language toggle, and Log Out.
/// RTL flips the panel automatically via Directionality.
class MenuDrawer extends ConsumerWidget {
  const MenuDrawer({super.key});

  void _close(BuildContext context) => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final store = ref.watch(storeControllerProvider);
    final categories = ref.watch(categoryTreeProvider);
    final auth = ref.watch(authControllerProvider);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Brand logo centered; close (×) pinned to the trailing corner
            // (flips to the leading side in the Arabic/RTL mirror).
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const BrandLogo(height: 44),
                  PositionedDirectional(
                    end: 4,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => _close(context),
                    ),
                  ),
                ],
              ),
            ),
            _ProfileHeader(
              name: auth.isAuthenticated ? (auth.customer?.fullName ?? '') : '',
              subtitle: auth.isAuthenticated
                  ? (auth.customer?.email ?? '')
                  : l10n.accountGuestTitle,
              isAuthed: auth.isAuthenticated,
              onTap: auth.isAuthenticated
                  ? () {
                      _close(context);
                      context.go(AppRoutes.account);
                    }
                  : () {
                      _close(context);
                      context.push(AppRoutes.signIn);
                    },
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _SectionHeader(label: l10n.menuShop),
                  categories.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(16),
                      child: LinearProgressIndicator(),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (items) => Column(
                      children: [
                        for (final category in items)
                          _DrawerTile(
                            icon: Icons.local_mall_outlined,
                            label: category.name,
                            onTap: () {
                              _close(context);
                              context.push(
                                AppRoutes.category(category.uid),
                                extra: category.name,
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  _SectionHeader(label: l10n.menuAccountSection),
                  _DrawerTile(
                    icon: Icons.location_on_outlined,
                    label: l10n.accountAddresses,
                    onTap: () {
                      _close(context);
                      context.push(AppRoutes.addresses);
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.notifications_none,
                    label: l10n.notificationsTitle,
                    onTap: () {
                      _close(context);
                      context.push(AppRoutes.notifications);
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.help_outline,
                    label: l10n.accountHelp,
                    onTap: () {
                      _close(context);
                      context.push(AppRoutes.help);
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Language toggle pinned to the bottom (Figma).
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
              child: Row(
                children: [
                  Text(
                    l10n.languageToggleLabel,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  SegmentedButton<String>(
                    showSelectedIcon: false,
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                    segments: const [
                      ButtonSegment<String>(value: 'en', label: Text('EN')),
                      ButtonSegment<String>(value: 'ar', label: Text('AR')),
                    ],
                    selected: {store.activeLocale == 'ar' ? 'ar' : 'en'},
                    onSelectionChanged: (selection) => ref
                        .read(storeControllerProvider.notifier)
                        .switchLocale(selection.first),
                  ),
                ],
              ),
            ),
            if (auth.isAuthenticated)
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.brandPrimary),
                title: Text(
                  l10n.menuLogOut,
                  style: const TextStyle(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () async {
                  // Capture router before the async gap; close the drawer, sign
                  // out (revoke token + reset cache), then land on Home.
                  final router = GoRouter.of(context);
                  _close(context);
                  await ref.read(authControllerProvider.notifier).logout();
                  router.go(AppRoutes.home);
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.login, color: AppColors.brandPrimary),
                title: Text(
                  l10n.welcomeSignIn,
                  style: const TextStyle(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  _close(context);
                  context.push(AppRoutes.signIn);
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Blush profile strip: initials avatar (or person icon for guests) + name and
/// a subtitle. Tapping opens the account screen (or Sign In for guests).
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.subtitle,
    required this.isAuthed,
    required this.onTap,
  });

  final String name;
  final String subtitle;
  final bool isAuthed;
  final VoidCallback onTap;

  String get _initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showInitials = isAuthed && _initials.isNotEmpty;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        color: AppColors.surfaceTint,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: AppColors.brandPrimary, width: 1.5),
              ),
              alignment: Alignment.center,
              child: showInitials
                  ? Text(
                      _initials,
                      style: const TextStyle(
                        color: AppColors.brandPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    )
                  : const Icon(
                      Icons.person_outline,
                      color: AppColors.brandPrimary,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isAuthed && name.isNotEmpty)
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkHeading,
                      ),
                    ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isAuthed
                          ? AppColors.inkMuted
                          : AppColors.brandPrimary,
                      fontWeight: isAuthed ? FontWeight.w400 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (!isAuthed) const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppColors.brandPrimary),
    title: Text(label),
    trailing: const Icon(Icons.chevron_right, color: AppColors.inkMuted),
    onTap: onTap,
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
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
