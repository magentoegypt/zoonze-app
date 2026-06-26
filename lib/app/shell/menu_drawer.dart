import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/store/store_controller.dart';
import '../../core/widgets/brand_lockup.dart';
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

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BrandLockup(fontSize: 22),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
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
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.inkMuted),
              title: Text(l10n.menuLogOut),
              onTap: () => Navigator.of(context).maybePop(),
            ),
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
