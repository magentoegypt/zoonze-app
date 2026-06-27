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

/// Side navigation drawer: brand header, language toggle, SHOP categories
/// (live), ACCOUNT links, and Log Out. RTL flips the panel automatically via
/// Directionality. Quick-stats/profile header bind to customer data in Phase 4.
class MenuDrawer extends ConsumerWidget {
  const MenuDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final store = ref.watch(storeControllerProvider);
    final categories = ref.watch(categoryTreeProvider);
    final isAuthed = ref.watch(
      authControllerProvider.select((s) => s.isAuthenticated),
    );

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Brand logo centered; close (×) pinned to the trailing corner
            // (flips to the leading side in the Arabic/RTL mirror).
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const BrandLogo(height: 46),
                  PositionedDirectional(
                    end: 4,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 12),
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment<String>(value: 'en', label: Text('EN')),
                  ButtonSegment<String>(value: 'ar', label: Text('AR')),
                ],
                selected: {store.activeLocale == 'ar' ? 'ar' : 'en'},
                onSelectionChanged: (selection) => ref
                    .read(storeControllerProvider.notifier)
                    .switchLocale(selection.first),
              ),
            ),
            const Divider(height: 1),
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
                    ListTile(
                      leading: const Icon(
                        Icons.local_mall_outlined,
                        color: AppColors.brandPrimary,
                      ),
                      title: Text(category.name),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).maybePop();
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
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: Text(l10n.navAccount),
              onTap: () {
                Navigator.of(context).maybePop();
                context.go(AppRoutes.account);
              },
            ),
            if (isAuthed) ...[
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.inkMuted),
                title: Text(l10n.menuLogOut),
                onTap: () async {
                  // Capture router before the async gap; close the drawer, sign
                  // out (revoke token + reset cache), then land on Home.
                  final router = GoRouter.of(context);
                  Navigator.of(context).maybePop();
                  await ref.read(authControllerProvider.notifier).logout();
                  router.go(AppRoutes.home);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
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
