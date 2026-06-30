import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/shell/marketing_footer.dart';
import '../../../../app/shell/zoonze_scaffold.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/assets/app_images.dart';
import '../../../../core/util/launch.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../core/widgets/shimmer.dart';
import '../../../notifications/presentation/notification_bell.dart';
import '../../../../l10n/l10n.dart';
import '../../data/brands_provider.dart';
import '../../data/hero_slides_provider.dart';
import '../../data/special_offer_provider.dart';
import '../../domain/brand.dart';
import '../../domain/category.dart';
import '../../domain/hero_slide.dart';
import '../../domain/product.dart';
import '../catalog_providers.dart';
import '../widgets/product_card.dart';
import '../widgets/product_skeletons.dart';

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
      // Figma: the burgundy announcement strip sits above the ZOONZE header.
      appBar: const _HomeAppBar(),
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
            _SearchField(onTap: () => context.push(AppRoutes.search)),
            const _Hero(),
            _SectionHeader(title: l10n.homeShopByCategory),
            AsyncValueView(
              value: categories,
              onRetry: () => ref.invalidate(categoryTreeProvider),
              loading: () => const _CategoryGridSkeleton(),
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

/// Home app bar (Figma): the burgundy announcement strip on top, then the
/// centered ZOONZE lockup with a hamburger that opens the drawer.
class _HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _HomeAppBar();

  static const double _announcementHeight = 30;
  static const double _headerHeight = 56;

  @override
  Size get preferredSize {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final top = view.viewPadding.top / view.devicePixelRatio;
    return Size.fromHeight(top + _announcementHeight + _headerHeight);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _AnnouncementBar(),
            SizedBox(
              height: _headerHeight,
              child: Stack(
                children: [
                  PositionedDirectional(
                    start: 4,
                    top: 0,
                    bottom: 0,
                    child: IconButton(
                      icon: const Icon(
                        Icons.menu,
                        color: AppColors.brandPrimary,
                      ),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  const Center(child: BrandLogo(height: 40)),
                  const PositionedDirectional(
                    end: 4,
                    top: 0,
                    bottom: 0,
                    child: NotificationBell(color: AppColors.brandPrimary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thin burgundy top strip (Figma) — single line. Message comes from the admin
/// announcement config (magentoegypt_beauty/announcement/message); falls back to
/// the localized default when not configured.
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
      height: _HomeAppBar._announcementHeight,
      color: AppColors.brandPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      // Always one line — scale the text down to fit rather than wrap.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          message,
          maxLines: 1,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 44,
          alignment: AlignmentDirectional.centerStart,
          padding: const EdgeInsetsDirectional.only(start: 16, end: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(22),
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

/// Fixed hero height (Figma node 3:2 is 390×250).
const double _kHeroHeight = 250;

/// Warm-beige hero background (Figma `#f6efe8`).
const Color _kHeroBg = Color(0xFFF6EFE8);

/// The full-width hero layout (Figma node 3:2): beige background, text on the
/// start side, a circular image bleeding off the end side. Shared by the static
/// fallback and each carousel slide.
class _HeroBannerView extends StatelessWidget {
  const _HeroBannerView({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.onCta,
    required this.imageProvider,
    this.showPlay = false,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback onCta;
  final ImageProvider imageProvider;
  final bool showPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kHeroBg,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Layered product circles (Figma): a big blurred circle behind a
          // smaller sharp one, bleeding off the end edge.
          PositionedDirectional(
            top: 0,
            bottom: 0,
            end: -40,
            child: Center(
              child: _HeroImageGroup(
                provider: imageProvider,
                showPlay: showPlay,
              ),
            ),
          ),
          // Text block on the start side.
          PositionedDirectional(
            start: 48,
            end: 108,
            top: 0,
            bottom: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (eyebrow.isNotEmpty) ...[
                    Text(
                      eyebrow.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.brandPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 1.54,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                      color: AppColors.inkHeading,
                      height: 1.06,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                  if (ctaLabel.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: onCta,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 42),
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(ctaLabel),
                          const SizedBox(width: 8),
                          Icon(
                            Directionality.of(context) == TextDirection.rtl
                                ? Icons.arrow_back
                                : Icons.arrow_forward,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Two overlapping product circles (Figma node 3:2): a big **blurred** circle
/// behind a smaller **sharp** one, both fed from the same image. An optional
/// play badge marks a video slide.
class _HeroImageGroup extends StatelessWidget {
  const _HeroImageGroup({required this.provider, this.showPlay = false});
  final ImageProvider provider;
  final bool showPlay;

  Widget _image() => Image(
    image: provider,
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) => Container(color: Colors.white),
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        children: [
          // Big softly-blurred circle (back) — fills most of the area.
          Positioned(
            left: 6,
            top: 8,
            child: ClipOval(
              child: SizedBox(
                width: 196,
                height: 196,
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
                  child: _image(),
                ),
              ),
            ),
          ),
          // Small sharp circle (front) — overlaps the big one's lower-end side.
          Positioned(
            right: 0,
            bottom: 16,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _kHeroBg, width: 3),
              ),
              child: ClipOval(
                child: SizedBox(
                  width: 132,
                  height: 132,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _image(),
                      if (showPlay)
                        const Center(
                          child: Icon(
                            Icons.play_circle_fill,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// White circular prev/next arrow overlaid on the hero (Figma).
class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: const CircleBorder(side: BorderSide(color: Color(0xFFE5E7EB))),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(icon, size: 18, color: AppColors.inkHeading),
      ),
    ),
  );
}

/// Static hero fallback — full-width [_HeroBannerView] with the bundled flatlay,
/// shown while [heroSlides] loads or when none are configured.
class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: _kHeroHeight,
      child: _HeroBannerView(
        eyebrow: l10n.homeHeroEyebrow,
        title: l10n.homeHeroTitle,
        subtitle: l10n.homeHeroSubtitle,
        ctaLabel: l10n.homeHeroCta,
        onCta: () => context.go(AppRoutes.categories),
        imageProvider: const AssetImage(AppImages.banner),
      ),
    );
  }
}

/// Home hero: the admin-managed [heroSlides] carousel, falling back to the
/// static [_HeroBanner] while loading or when no slides are configured.
class _Hero extends ConsumerWidget {
  const _Hero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(heroSlidesProvider)
        .maybeWhen(
          data: (slides) => slides.isEmpty
              ? const _HeroBanner()
              : _HeroCarousel(slides: slides),
          orElse: () => const _HeroBanner(),
        );
  }
}

/// Swipeable, auto-advancing hero carousel with a dots indicator.
class _HeroCarousel extends StatefulWidget {
  const _HeroCarousel({required this.slides});
  final List<HeroSlide> slides;

  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  final PageController _controller = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    if (widget.slides.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted || !_controller.hasClients) return;
        final next = (_index + 1) % widget.slides.length;
        _controller.animateToPage(
          next,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _go(int delta) {
    if (!_controller.hasClients) return;
    final n = widget.slides.length;
    _controller.animateToPage(
      (_index + delta + n) % n,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final multi = widget.slides.length > 1;
    return SizedBox(
      height: _kHeroHeight,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _index = i),
            itemCount: widget.slides.length,
            itemBuilder: (context, i) => _HeroSlideCard(slide: widget.slides[i]),
          ),
          if (multi) ...[
            PositionedDirectional(
              start: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _NavArrow(icon: Icons.chevron_left, onTap: () => _go(-1)),
              ),
            ),
            PositionedDirectional(
              end: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _NavArrow(icon: Icons.chevron_right, onTap: () => _go(1)),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < widget.slides.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: i == _index ? 20 : 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i == _index
                              ? AppColors.brandPrimary
                              : const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One hero slide — blush card with eyebrow/title/description/CTA and a circular
/// image. A play badge marks a video slide; the poster image is shown until
/// inline video playback is wired.
class _HeroSlideCard extends StatelessWidget {
  const _HeroSlideCard({required this.slide});
  final HeroSlide slide;

  void _onCta(BuildContext context) {
    final uid = categoryUidFromUrl(slide.ctaUrl);
    if (uid != null) {
      context.push(AppRoutes.category(uid), extra: slide.title);
    } else if (slide.ctaUrl.isNotEmpty) {
      launchExternalUri(Uri.parse(slide.ctaUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ImageProvider provider = slide.imageUrl.isNotEmpty
        ? CachedNetworkImageProvider(slide.imageUrl)
        : const AssetImage(AppImages.banner);
    return _HeroBannerView(
      eyebrow: slide.eyebrow,
      title: slide.title,
      subtitle: slide.description,
      ctaLabel: slide.ctaLabel,
      onCta: () => _onCta(context),
      imageProvider: provider,
      showPlay: slide.hasVideo,
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
        .when(
          loading: () => _ProductSectionSkeleton(title: l10n.homeNewArrivals),
          error: (_, __) => const SizedBox.shrink(),
          data: (section) => _ProductSection(
            title: l10n.homeNewArrivals,
            section: section,
          ),
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
        .when(
          loading: () => _ProductSectionSkeleton(title: l10n.homeBestsellers),
          error: (_, __) => const SizedBox.shrink(),
          data: (section) => _ProductSection(
            title: l10n.homeBestsellers,
            section: section,
          ),
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

/// "Explore Our Brands" — real brands (logos) from the `brands` query; tapping
/// searches the catalogue for that brand. Hidden when none are returned.
class _ExploreBrands extends ConsumerWidget {
  const _ExploreBrands();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(brandsProvider)
        .when(
          loading: () => const _BrandsRailSkeleton(),
          error: (_, __) => const SizedBox.shrink(),
          data: (brands) => brands.isEmpty
              ? const SizedBox.shrink()
              : _BrandsRail(brands: brands.take(15).toList()),
        );
  }
}

/// The "Explore Our Brands" rail itself (header + horizontal logo cards + See
/// More), shown once real brands have loaded.
class _BrandsRail extends StatelessWidget {
  const _BrandsRail({required this.brands});
  final List<Brand> brands;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(title: l10n.homeExploreBrands),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: brands.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _BrandCard(brand: brands[index]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Center(
            child: OutlinedButton(
              onPressed: () => context.push(AppRoutes.brands),
              child: Text(l10n.homeSeeMore),
            ),
          ),
        ),
      ],
    );
  }
}

/// A brand logo card; falls back to the brand name if the logo can't load.
class _BrandCard extends StatelessWidget {
  const _BrandCard({required this.brand});
  final Brand brand;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(AppRoutes.search, extra: brand.title),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 124,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        alignment: Alignment.center,
        child: brand.imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: brand.imageUrl,
                fit: BoxFit.contain,
                placeholder: (_, __) => _BrandName(title: brand.title),
                errorWidget: (_, __, ___) => _BrandName(title: brand.title),
              )
            : _BrandName(title: brand.title),
      ),
    );
  }
}

class _BrandName extends StatelessWidget {
  const _BrandName({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      title,
      maxLines: 2,
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 12,
        color: AppColors.inkHeading,
      ),
    ),
  );
}

/// Promotional offer card — content comes from the admin "Special Offer Banner"
/// store config (enabled / text / coupon). Hidden when disabled or absent.
class _SpecialOffer extends ConsumerWidget {
  const _SpecialOffer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(specialOfferProvider)
        .when(
          loading: () => const _SpecialOfferSkeleton(),
          error: (_, __) => const SizedBox.shrink(),
          data: (offer) => offer.isVisible
              ? _SpecialOfferCard(offer: offer)
              : const SizedBox.shrink(),
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
    // Figma: the trust section sits on a light-grey band (white icon circles).
    return Container(
      width: double.infinity,
      color: const Color(0xFFF3F4F6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
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
            radius: 26,
            backgroundColor: Colors.white,
            child: Icon(icon, color: AppColors.brandPrimary, size: 24),
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

// ── Loading skeletons ──────────────────────────────────────────────────────
// Shown only while a section's provider resolves. The real sections collapse
// themselves to nothing when empty/disabled, so after load nothing spurious
// renders. Each skeleton mirrors the dimensions of the section it stands in for.

/// Mirrors `_CategoryGrid` (3-col, 0.82): grey circle + label line per cell.
class _CategoryGridSkeleton extends StatelessWidget {
  const _CategoryGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.82,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SkeletonBox.circle(size: 72),
            SizedBox(height: 8),
            SkeletonBox(width: 52, height: 10, borderRadius: 4),
          ],
        ),
      ),
    );
  }
}

/// Mirrors `_BrandsRail`: section header + a row of 124×72 logo-card blocks.
class _BrandsRailSkeleton extends StatelessWidget {
  const _BrandsRailSkeleton();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(title: l10n.homeExploreBrands),
        SizedBox(
          height: 72,
          child: Shimmer(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 6,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) =>
                  const SkeletonBox(width: 124, height: 72, borderRadius: 12),
            ),
          ),
        ),
      ],
    );
  }
}

/// Section header + a 2-col product grid (0.58) of card skeletons, for the
/// New Arrivals / Bestsellers loading state.
class _ProductSectionSkeleton extends StatelessWidget {
  const _ProductSectionSkeleton({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(title: title),
        const ProductGridSkeleton(childAspectRatio: 0.58, count: 4),
      ],
    );
  }
}

/// Mirrors `_SpecialOfferCard`: blush card with a circle avatar + two text
/// lines. The blush surface is drawn outside the [Shimmer]; only the inner
/// blocks shimmer.
class _SpecialOfferSkeleton extends StatelessWidget {
  const _SpecialOfferSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Shimmer(
        child: Row(
          children: [
            SkeletonBox.circle(size: 44),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SkeletonBox(width: 150, height: 14, borderRadius: 4),
                  SizedBox(height: 8),
                  SkeletonBox(height: 11, borderRadius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 28, 16, 14),
    child: Text(
      title.toUpperCase(),
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.82,
        color: AppColors.inkHeading,
      ),
    ),
  );
}
