import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/shell/marketing_footer.dart';
import '../../../../app/shell/zoonze_scaffold.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/assets/app_images.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../l10n/l10n.dart';
import '../catalog_providers.dart';
import '../widgets/product_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final categories = ref.watch(categoryTreeProvider);
    final featured = ref.watch(featuredProductsProvider);

    return ZoonzeScaffold(
      currentTab: AppTab.home,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(categoryTreeProvider);
          ref.invalidate(featuredProductsProvider);
          // Keep the indicator up until the real reload finishes; errors are
          // surfaced in-body by AsyncValueView.
          try {
            await ref.read(categoryTreeProvider.future);
            await ref.read(featuredProductsProvider.future);
          } catch (_) {
            /* ignore: handled in body */
          }
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const _HeroBanner(),
            _SectionHeader(title: l10n.homeShopByCategory),
            SizedBox(
              height: 120,
              child: AsyncValueView(
                value: categories,
                onRetry: () => ref.invalidate(categoryTreeProvider),
                data: (items) {
                  if (items.isEmpty) {
                    return Center(child: Text(l10n.stateEmpty));
                  }
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsetsDirectional.only(
                      start: 16,
                      end: 16,
                    ),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final category = items[index];
                      return _CategoryChip(
                        label: category.name,
                        onTap: () => context.push(
                          AppRoutes.category(category.uid),
                          extra: category.name,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            _SectionHeader(title: l10n.homeFeatured),
            AsyncValueView(
              value: featured,
              onRetry: () => ref.invalidate(featuredProductsProvider),
              data: (products) {
                if (products.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(child: Text(l10n.stateEmpty)),
                  );
                }
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.58,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ProductCard(
                      product: product,
                      onTap: () =>
                          context.push(AppRoutes.product(product.urlKey)),
                    );
                  },
                );
              },
            ),
            const MarketingFooter(),
          ],
        ),
      ),
    );
  }
}

/// Home hero per Figma: a blush promo card — eyebrow + headline + subtitle +
/// Shop Now on the start side, a circular flatlay image on the end side.
class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsetsDirectional.fromSTEB(20, 24, 8, 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.homeHeroEyebrow,
                  style: const TextStyle(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.homeHeroTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkHeading,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.homeHeroSubtitle,
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go(AppRoutes.categories),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: Text(l10n.homeHeroCta),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ClipOval(
            child: SizedBox(
              width: 116,
              height: 116,
              child: Image.asset(
                AppImages.banner,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 8),
    child: Text(title, style: Theme.of(context).textTheme.titleLarge),
  );
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 96,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surfaceTint,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 26,
              backgroundColor: Colors.white,
              child: Icon(Icons.spa_outlined, color: AppColors.brandPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
