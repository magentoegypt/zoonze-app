import 'package:cached_network_image/cached_network_image.dart';
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
import '../../data/special_offer_provider.dart';
import '../../domain/category.dart';
import '../../domain/product.dart';
import '../catalog_providers.dart';
import '../widgets/product_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final categories = ref.watch(categoryTreeProvider);

    return ZoonzeScaffold(
      currentTab: AppTab.home,
      // The home body already has a search bar — no app-bar search icon.
      showSearch: false,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(categoryTreeProvider);
          ref.invalidate(newArrivalsProvider);
          ref.invalidate(bestsellersProvider);
          // Keep the indicator up until the real reload finishes; errors are
          // surfaced in-body by AsyncValueView.
          try {
            await ref.read(categoryTreeProvider.future);
          } catch (_) {
            /* ignore: handled in body */
          }
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const _AnnouncementBar(),
            _SearchField(onTap: () => context.push(AppRoutes.search)),
            const _HeroBanner(),
            _SectionHeader(title: l10n.homeShopByCategory),
            AsyncValueView(
              value: categories,
              onRetry: () => ref.invalidate(categoryTreeProvider),
              data: (items) {
                if (items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(child: Text(l10n.stateEmpty)),
                  );
                }
                return _CategoryGrid(categories: items);
              },
            ),
            const _ExploreBrands(),
            const _NewArrivalsSection(),
            const _SpecialOffer(),
            const _BestsellersSection(),
            const _TrustBadges(),
            const MarketingFooter(),
          ],
        ),
      ),
    );
  }
}

/// Thin burgundy top strip (Figma). Message comes from the admin announcement
/// config (magentoegypt_beauty/announcement/message); falls back to the
/// localized default when not configured.
class _AnnouncementBar extends ConsumerWidget {
  const _AnnouncementBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final configured = ref
        .watch(announcementMessageProvider)
        .maybeWhen(data: (m) => m, orElse: () => '');
    final message = configured.isNotEmpty ? configured : l10n.homeAnnouncement;
    return Container(
      width: double.infinity,
      color: AppColors.brandPrimary,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Tappable search field (routes to the search screen) — Figma's full-width
/// search bar below the header.
class _SearchField extends StatelessWidget {
  const _SearchField({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: AppColors.inkMuted, size: 22),
              const SizedBox(width: 12),
              Text(
                l10n.searchHint,
                style: const TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 15,
                ),
              ),
            ],
          ),
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.homeHeroCta),
                      const SizedBox(width: 8),
                      Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.arrow_back
                            : Icons.arrow_forward,
                        size: 18,
                      ),
                    ],
                  ),
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
                errorBuilder: (_, __, ___) => Container(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular category images in a grid (Figma "Shop by category").
class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.categories});
  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.82,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _CategoryCircle(
          category: category,
          onTap: () => context.push(
            AppRoutes.category(category.uid),
            extra: category.name,
          ),
        );
      },
    );
  }
}

class _CategoryCircle extends StatelessWidget {
  const _CategoryCircle({required this.category, required this.onTap});
  final Category category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final image = category.image;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipOval(
            child: SizedBox(
              width: 72,
              height: 72,
              child: (image != null && image.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: image,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const _CategoryFallback(),
                      errorWidget: (_, __, ___) => const _CategoryFallback(),
                    )
                  : const _CategoryFallback(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            category.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _CategoryFallback extends StatelessWidget {
  const _CategoryFallback();

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.surfaceTint,
    child: const Center(
      child: Icon(Icons.spa_outlined, color: AppColors.brandPrimary),
    ),
  );
}

/// Two-column product grid shared by Featured + New Arrivals.
class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.products});
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
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
          onTap: () => context.push(AppRoutes.product(product.urlKey)),
        );
      },
    );
  }
}

/// "New Arrivals" — latest products from the new-arrivals category. Hides when
/// the catalogue returns nothing.
class _NewArrivalsSection extends ConsumerWidget {
  const _NewArrivalsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ref
        .watch(newArrivalsProvider)
        .maybeWhen(
          data: (section) => _ProductSection(
            title: l10n.homeNewArrivals,
            section: section,
          ),
          orElse: () => const SizedBox.shrink(),
        );
  }
}

/// "Bestsellers" — backed by the real Bestsellers category; hidden if absent.
class _BestsellersSection extends ConsumerWidget {
  const _BestsellersSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ref
        .watch(bestsellersProvider)
        .maybeWhen(
          data: (section) => _ProductSection(
            title: l10n.homeBestsellers,
            section: section,
          ),
          orElse: () => const SizedBox.shrink(),
        );
  }
}

class _ProductSection extends StatelessWidget {
  const _ProductSection({required this.title, required this.section});
  final String title;
  final HomeSection section;

  @override
  Widget build(BuildContext context) {
    if (section.items.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final category = section.category;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(title: title),
        _ProductGrid(products: section.items),
        if (category != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Center(
              child: OutlinedButton(
                onPressed: () => context.push(
                  AppRoutes.category(category.uid),
                  extra: category.name,
                ),
                child: Text(l10n.homeSeeMore),
              ),
            ),
          ),
      ],
    );
  }
}

/// "Explore Our Brands" — curated brand shortcuts; tapping searches the
/// catalogue for that brand (brand names stay Latin per the design).
class _ExploreBrands extends StatelessWidget {
  const _ExploreBrands();

  static const List<String> _brands = [
    'Chanel',
    'Dunhill',
    'Versace',
    'Lacoste',
    'Azzaro',
    'Rasasi',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(title: l10n.homeExploreBrands),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _brands.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final brand = _brands[index];
              return ActionChip(
                label: Text(brand),
                onPressed: () => context.push(AppRoutes.search, extra: brand),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Promotional offer card — content comes from the admin "Special Offer Banner"
/// store config (enabled / text / coupon). Hidden when disabled or absent.
class _SpecialOffer extends ConsumerWidget {
  const _SpecialOffer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(specialOfferProvider)
        .maybeWhen(
          data: (offer) =>
              offer.isVisible ? _SpecialOfferCard(offer: offer) : const SizedBox.shrink(),
          orElse: () => const SizedBox.shrink(),
        );
  }
}

class _SpecialOfferCard extends StatelessWidget {
  const _SpecialOfferCard({required this.offer});
  final SpecialOffer offer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white,
            child: Icon(Icons.card_giftcard, color: AppColors.brandPrimary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.homeSpecialOfferTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  offer.text,
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 13,
                  ),
                ),
                if (offer.hasCode) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        l10n.homeSpecialOfferCodeLabel,
                        style: const TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.brandPrimary),
                        ),
                        child: Text(
                          offer.couponCode,
                          style: const TextStyle(
                            color: AppColors.brandPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Trust badges (Figma) — store guarantees in a 2×2 grid.
class _TrustBadges extends StatelessWidget {
  const _TrustBadges();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TrustBadge(
                icon: Icons.verified_user_outlined,
                title: l10n.homeTrustOriginalTitle,
                body: l10n.homeTrustOriginalBody,
              ),
              _TrustBadge(
                icon: Icons.local_shipping_outlined,
                title: l10n.homeTrustDeliveryTitle,
                body: l10n.homeTrustDeliveryBody,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TrustBadge(
                icon: Icons.schedule,
                title: l10n.homeTrustFastTitle,
                body: l10n.homeTrustFastBody,
              ),
              _TrustBadge(
                icon: Icons.headset_mic_outlined,
                title: l10n.homeTrustServiceTitle,
                body: l10n.homeTrustServiceBody,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.surfaceTint,
            child: Icon(icon, color: AppColors.brandPrimary, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.inkHeading,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.inkMuted, fontSize: 11),
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
