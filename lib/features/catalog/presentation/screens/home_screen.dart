import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../../app/routes.dart';
import '../../../../app/shell/marketing_footer.dart';
import '../../../../app/shell/zoonze_scaffold.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/assets/app_images.dart';
import '../../../../core/store/store_controller.dart';
import '../../../../core/util/launch.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../core/widgets/shimmer.dart';
import '../../../../core/widgets/web_view_screen.dart';
import '../../../../l10n/l10n.dart';
import '../../data/blog_posts_provider.dart';
import '../../data/brands_provider.dart';
import '../../data/catalog_repository.dart';
import '../../data/hero_slides_provider.dart';
import '../../data/home_config_provider.dart';
import '../../data/home_sections_provider.dart';
import '../../data/special_offer_provider.dart';
import '../../domain/blog_post.dart';
import '../../domain/brand.dart';
import '../../domain/category.dart';
import '../../domain/hero_slide.dart';
import '../../domain/home_config.dart';
import '../../domain/product.dart';
import '../../domain/promo_split_banner.dart';
import '../catalog_providers.dart';
import '../widgets/product_card.dart';
import '../widgets/product_skeletons.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final categories = ref.watch(categoryTreeProvider);
    // Only the admin-configured announcement is shown — no hardcoded fallback
    // (QA: the default "free shipping" line isn't on the site). Empty → the
    // strip is omitted entirely (the app bar shrinks to just the header).
    final announcement = ref
        .watch(announcementMessageProvider)
        .maybeWhen(data: (m) => m.trim(), orElse: () => '');

    return ZoonzeScaffold(
      currentTab: AppTab.home,
      // The home body already has a search bar — no app-bar search icon.
      showSearch: false,
      // Figma: the burgundy announcement strip sits above the ZOONZE header.
      appBar: _HomeAppBar(announcement: announcement),
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
            // New order mirrors live zoonze.com (see docs/FIGMA_DESIGN.md,
            // 2026-07-13). Each new section is backend-driven and collapses to
            // nothing when its source is absent — Explore Brands has moved down
            // to sit after the reviews rail.
            const _LimitedTimeOffer(),
            const _DealsOfTheDaySection(),
            const _NewArrivalsSection(),
            const _EditorialBanners(),
            const _SpecialOffer(),
            const _ExclusiveOffers(),
            const _BestsellersSection(),
            const _WhyShoppersTrust(),
            const _ExploreBrands(),
            const _ZoonzeJournal(),
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
  const _HomeAppBar({required this.announcement});

  /// The resolved announcement message; empty → the strip is omitted.
  final String announcement;

  static const double _announcementHeight = 30;
  static const double _headerHeight = 56;

  @override
  Size get preferredSize {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final top = view.viewPadding.top / view.devicePixelRatio;
    final strip = announcement.isEmpty ? 0.0 : _announcementHeight;
    return Size.fromHeight(top + strip + _headerHeight);
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
            if (announcement.isNotEmpty) _AnnouncementBar(message: announcement),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thin burgundy top strip (Figma) — single line. The [message] is the
/// admin-configured announcement (magentoegypt_beauty/announcement/message);
/// the caller omits this strip entirely when there's no configured message.
class _AnnouncementBar extends StatelessWidget {
  const _AnnouncementBar({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: _HomeAppBar._announcementHeight,
      color: AppColors.brandPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      // One line at a readable size — centered when it fits, auto-scrolling
      // (marquee) when it doesn't, instead of shrinking to an unreadable size.
      child: _AnnouncementText(message: message),
    );
  }
}

/// The announcement message at a fixed readable size. Centers short messages;
/// long ones scroll horizontally on a gentle loop so nothing is clipped or
/// shrunk (QA: the old FittedBox scaled the text down until it was too small).
class _AnnouncementText extends StatefulWidget {
  const _AnnouncementText({required this.message});
  final String message;

  @override
  State<_AnnouncementText> createState() => _AnnouncementTextState();
}

class _AnnouncementTextState extends State<_AnnouncementText> {
  static const TextStyle _style = TextStyle(
    color: Colors.white,
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
  );

  final ScrollController _scroll = ScrollController();
  bool _looping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeScroll());
  }

  @override
  void didUpdateWidget(covariant _AnnouncementText old) {
    super.didUpdateWidget(old);
    if (old.message != widget.message) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeScroll());
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _maybeScroll() async {
    if (_looping) return;
    _looping = true;
    try {
      while (mounted && _scroll.hasClients) {
        final max = _scroll.position.maxScrollExtent;
        if (max <= 0) break; // Message fits — nothing to scroll.
        await _scroll.animateTo(
          max,
          duration: Duration(milliseconds: 2500 + (max * 22).round()),
          curve: Curves.linear,
        );
        if (!mounted || !_scroll.hasClients) break;
        await Future<void>.delayed(const Duration(milliseconds: 1200));
        if (!mounted || !_scroll.hasClients) break;
        await _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
        );
        await Future<void>.delayed(const Duration(milliseconds: 1200));
      }
    } finally {
      _looping = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tp = TextPainter(
          text: TextSpan(text: widget.message, style: _style),
          maxLines: 1,
          textDirection: Directionality.of(context),
        )..layout();
        final text = Text(widget.message, maxLines: 1, style: _style);
        if (tp.width <= constraints.maxWidth) {
          return Center(child: text);
        }
        return SingleChildScrollView(
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: text,
        );
      },
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
    this.videoUrl,
    this.isActive = true,
    this.onVideoCompleted,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback onCta;
  final ImageProvider imageProvider;

  /// When set, the video fills the whole banner (poster = [imageProvider])
  /// instead of showing a static play badge in the circle.
  final String? videoUrl;

  /// True when this slide is the carousel's current slide (drives playback).
  final bool isActive;

  /// Called when the banner's video finishes (lets the carousel advance).
  final VoidCallback? onVideoCompleted;

  @override
  Widget build(BuildContext context) {
    final hasVideo = videoUrl != null && videoUrl!.isNotEmpty;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Container(
      color: _kHeroBg,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Background media fills the whole banner (BoxFit.cover), matching
          // the website: a video when the slide has one, otherwise the image.
          if (hasVideo)
            Positioned.fill(
              child: _HeroVideo(
                url: videoUrl!,
                poster: imageProvider,
                isActive: isActive,
                onCompleted: onVideoCompleted,
              ),
            )
          else
            Positioned.fill(
              child: Image(
                image: imageProvider,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(color: _kHeroBg),
              ),
            ),
          // Beige→transparent scrim on the start side so the overlaid text
          // stays readable over the media (image or video).
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: rtl ? Alignment.centerRight : Alignment.centerLeft,
                  end: rtl ? Alignment.centerLeft : Alignment.centerRight,
                  colors: [
                    _kHeroBg,
                    _kHeroBg.withValues(alpha: 0.55),
                    _kHeroBg.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.5, 0.85],
                ),
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
                          // Auto-mirrors under RTL (matchTextDirection) so it
                          // points forward in both EN and AR.
                          const Icon(Icons.arrow_forward, size: 16),
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

  /// Fixed dwell for an image slide.
  static const Duration _imageDwell = Duration(seconds: 5);

  /// Safety-net dwell for a video slide — used only if the video never loads or
  /// finishes; normally the advance is driven by the video completing (see
  /// [_onVideoCompleted]), so the dwell follows the video's own length.
  static const Duration _videoFallback = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _scheduleDwell();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// (Re)arm the auto-advance for the current slide: a fixed timer for image
  /// slides; for a video slide we wait for playback to finish and only keep a
  /// long fallback timer. Single-slide heroes never auto-advance.
  void _scheduleDwell() {
    _timer?.cancel();
    if (widget.slides.length < 2) return;
    final current = _index;
    final dwell = widget.slides[current].hasVideo ? _videoFallback : _imageDwell;
    _timer = Timer(dwell, () => _advanceFrom(current));
  }

  void _advanceFrom(int i) {
    if (!mounted || i != _index) return;
    _go(1);
  }

  /// The current slide's video finished — advance now (dynamic timing that
  /// follows the video's own timeline).
  void _onVideoCompleted(int i) {
    if (!mounted || i != _index) return;
    _go(1);
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
            onPageChanged: (i) {
              setState(() => _index = i);
              _scheduleDwell();
            },
            itemCount: widget.slides.length,
            itemBuilder: (context, i) => _HeroSlideCard(
              slide: widget.slides[i],
              isActive: i == _index,
              onVideoCompleted:
                  widget.slides.length > 1 ? () => _onVideoCompleted(i) : null,
            ),
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
class _HeroSlideCard extends ConsumerWidget {
  const _HeroSlideCard({
    required this.slide,
    this.isActive = true,
    this.onVideoCompleted,
  });
  final HeroSlide slide;

  /// True when this is the carousel's current slide (drives video playback).
  final bool isActive;

  /// Called when this slide's video finishes, so the carousel can advance.
  final VoidCallback? onVideoCompleted;

  /// Route the CTA inside the app wherever possible. An explicit
  /// `/catalog/category/view/id/N/` URL maps straight to the PLP; any other
  /// storefront URL (a friendly `.html` category or product) is resolved via
  /// Magento's `urlResolver` so a CATEGORY opens the PLP and a PRODUCT the PDP.
  /// Only genuinely external (non-store) links fall out to the browser.
  ///
  /// QA hit "Shop Now" landing on an empty page: the friendly category URLs
  /// (`fragrance/for-her.html`) were being mistaken for a product url_key and
  /// opened a non-existent PDP. Resolving the URL fixes the target.
  Future<void> _onCta(BuildContext context, WidgetRef ref) =>
      openStorefrontUrl(context, ref, slide.ctaUrl, title: slide.title);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ImageProvider provider = slide.imageUrl.isNotEmpty
        ? CachedNetworkImageProvider(slide.imageUrl)
        : const AssetImage(AppImages.banner);
    return _HeroBannerView(
      eyebrow: slide.eyebrow,
      title: slide.title,
      subtitle: slide.description,
      ctaLabel: slide.ctaLabel,
      onCta: () => _onCta(context, ref),
      imageProvider: provider,
      videoUrl: slide.hasVideo ? slide.videoUrl : null,
      isActive: isActive,
      onVideoCompleted: onVideoCompleted,
    );
  }
}

/// Inline, muted, full-bleed playback for a hero slide's video. Shows the
/// [poster] image (with a play badge) while it loads — and leaves it in place if
/// playback fails — then the video (cover-cropped) once it's ready. Plays only
/// while [isActive]; when [onCompleted] is set it plays once and reports the end
/// (so the carousel advances when the video finishes), otherwise it loops.
class _HeroVideo extends StatefulWidget {
  const _HeroVideo({
    required this.url,
    this.poster,
    this.isActive = true,
    this.onCompleted,
  });
  final String url;
  final ImageProvider? poster;

  /// Whether this is the carousel's current slide — the video plays only while
  /// active (and restarts when it becomes active).
  final bool isActive;

  /// Fired once when the video finishes. When null the video loops (e.g. a
  /// single-slide hero with nothing to advance to).
  final VoidCallback? onCompleted;

  @override
  State<_HeroVideo> createState() => _HeroVideoState();
}

class _HeroVideoState extends State<_HeroVideo> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _completed = false;

  /// Loop only when there's no completion handler (nothing to advance to).
  bool get _loop => widget.onCompleted == null;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(_loop);
      await controller.setVolume(0);
      controller.addListener(_onTick);
      if (widget.isActive) await controller.play();
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      // Leave the poster + play badge in place on any playback error; the
      // carousel's fallback timer still advances so it never hangs here.
    }
  }

  /// Detects end-of-playback (non-looping) and reports it once, so the carousel
  /// advances exactly when the video finishes.
  void _onTick() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (_loop || _completed || !widget.isActive) return;
    final v = c.value;
    final atEnd =
        v.duration > Duration.zero &&
        v.position >= v.duration - const Duration(milliseconds: 120);
    if (atEnd && !v.isPlaying) {
      _completed = true;
      widget.onCompleted?.call();
    }
  }

  @override
  void didUpdateWidget(covariant _HeroVideo old) {
    super.didUpdateWidget(old);
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (widget.isActive && !old.isActive) {
      // Became the current slide → restart so its timeline drives the dwell.
      _completed = false;
      c.seekTo(Duration.zero);
      c.play();
    } else if (!widget.isActive && old.isActive) {
      c.pause();
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (!_ready || controller == null || !controller.value.isInitialized) {
      // Poster fills the banner while the video loads (or if it fails), with a
      // play badge to signal it's a video.
      return Stack(
        fit: StackFit.expand,
        children: [
          if (widget.poster != null)
            Image(
              image: widget.poster!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(color: _kHeroBg),
            ),
          const Center(
            child: Icon(
              Icons.play_circle_fill,
              color: Colors.white70,
              size: 48,
            ),
          ),
        ],
      );
    }
    final size = controller.value.size;
    // The clip has a 1–2px green seam baked into its very bottom edge (an
    // Android video-decoder artifact — QA flagged it; it doesn't match the web).
    // Crop a few source rows off the bottom with a ClipRect wrapped directly
    // around the VideoPlayer (Stack/overlay clips don't reliably catch the
    // Texture edge) before cover-fitting, so the seam never reaches the screen.
    // Lossless: the clip carries a beige frame around its content.
    const cropBottom = 8.0;
    final heightFactor = size.height <= cropBottom
        ? 1.0
        : (size.height - cropBottom) / size.height;
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: heightFactor,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: VideoPlayer(controller),
          ),
        ),
      ),
    );
  }
}

/// Routes a storefront CTA URL inside the app wherever possible: a Magento
/// `category/view/id/N` URL maps straight to the PLP; a store-relative or
/// same-domain friendly URL (`clearance.html`, `fragrance/for-her.html`) is
/// resolved via `urlResolver` so a CATEGORY opens the PLP and a PRODUCT the PDP;
/// only genuinely external links fall out to the browser. A relative path we
/// can't resolve is ignored rather than launched as a bare relative URI.
///
/// Shared by the hero carousel, the Limited-Time Offer, and the Exclusive
/// Offers rail so every home CTA behaves identically.
Future<void> openStorefrontUrl(
  BuildContext context,
  WidgetRef ref,
  String url, {
  String? title,
}) async {
  if (url.isEmpty) return;
  final uid = categoryUidFromUrl(url);
  if (uid != null) {
    context.push(AppRoutes.category(uid), extra: title);
    return;
  }
  final hasHost = (Uri.tryParse(url)?.host ?? '').isNotEmpty;
  if (!hasHost || _isInternalStoreUrl(ref, url)) {
    final resolved = await ref.read(catalogRepositoryProvider).resolveUrl(url);
    if (!context.mounted) return;
    if (resolved != null) {
      if (resolved.type == 'CATEGORY' && resolved.uid.isNotEmpty) {
        context.push(AppRoutes.category(resolved.uid), extra: title);
        return;
      }
      if (resolved.type == 'PRODUCT' && resolved.urlKey != null) {
        context.push(AppRoutes.product(resolved.urlKey!));
        return;
      }
    }
    // A store-relative path we couldn't resolve → don't launch a bare relative
    // URI in the browser.
    if (!hasHost) return;
  }
  launchExternalUri(Uri.parse(url));
}

/// True when [url]'s host is the storefront's own domain (so the link should
/// open inside the app, not the external browser).
bool _isInternalStoreUrl(WidgetRef ref, String url) {
  final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
  if (host.isEmpty) return false;
  if (host == 'zoonze.com' || host.endsWith('.zoonze.com')) return true;
  for (final s in ref.read(storeControllerProvider).stores) {
    for (final base in [s.secureBaseUrl, s.baseUrl]) {
      final h = Uri.tryParse(base)?.host.toLowerCase();
      if (h != null && h.isNotEmpty && h == host) return true;
    }
  }
  return false;
}

/// Circular category images in a horizontal carousel (site "Shop by category").
class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.categories});
  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final category = categories[index];
          return SizedBox(
            width: 80,
            child: _CategoryCircle(
              category: category,
              onTap: () => context.push(
                AppRoutes.category(category.uid),
                extra: category.name,
              ),
            ),
          );
        },
      ),
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

/// Two-column product grid shared by Featured + New Arrivals + Deals. Passing
/// [dealBadge] adds a `DEAL` tag to each card (home "Deals of the Day").
class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.products, this.dealBadge = false});
  final List<Product> products;
  final bool dealBadge;

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
          dealBadge: dealBadge,
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
  const _ProductSection({
    required this.title,
    required this.section,
    this.dealBadge = false,
  });
  final String title;
  final HomeSection section;
  final bool dealBadge;

  @override
  Widget build(BuildContext context) {
    if (section.items.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final category = section.category;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(title: title),
        _ProductGrid(products: section.items, dealBadge: dealBadge),
        if (category != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Center(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.inkHeading,
                ),
                onPressed: () => context.push(
                  AppRoutes.category(category.uid),
                  extra: category.name.isNotEmpty ? category.name : title,
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
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.inkHeading,
              ),
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
      onTap: () => context.push(AppRoutes.brand, extra: brand),
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

// ── New home sections (mirror live zoonze.com — docs/FIGMA_DESIGN.md) ────────
// Each is backend-driven (magentoegypt_beauty_config / blogPosts / the live
// category tree) and collapses to nothing when its source is disabled or empty,
// matching the established "hide when absent — never fabricate" pattern.

/// "Limited-Time Offer" — the admin `deals/countdown_*` promo. A daily
/// countdown ticks to local midnight. Hidden when disabled or the `deals`
/// section toggle is off.
class _LimitedTimeOffer extends ConsumerWidget {
  const _LimitedTimeOffer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(homeConfigProvider)
        .maybeWhen(
          data: (cfg) {
            final offer = cfg.limitedTimeOffer;
            if (!cfg.sectionEnabled('deals') || !offer.isVisible) {
              return const SizedBox.shrink();
            }
            return _LimitedTimeOfferCard(offer: offer);
          },
          orElse: () => const SizedBox.shrink(),
        );
  }
}

class _LimitedTimeOfferCard extends ConsumerStatefulWidget {
  const _LimitedTimeOfferCard({required this.offer});
  final LimitedTimeOffer offer;

  @override
  ConsumerState<_LimitedTimeOfferCard> createState() =>
      _LimitedTimeOfferCardState();
}

class _LimitedTimeOfferCardState extends ConsumerState<_LimitedTimeOfferCard> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = _computeRemaining();
    if (widget.offer.isDaily) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        final next = _computeRemaining();
        if (mounted) setState(() => _remaining = next);
      });
    }
  }

  /// Time left until the next local midnight (the daily countdown reset).
  Duration _computeRemaining() {
    final now = DateTime.now();
    final midnight = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    return midnight.difference(now);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final offer = widget.offer;
    // Figma (updated 2026-07-13): a BLUSH promo card with burgundy text and
    // burgundy countdown boxes (white numerals) — matching live.
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.homeLimitedOfferEyebrow.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.brandPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            offer.headline,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.brandPrimary,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          if (offer.subtext.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              offer.subtext,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.inkMuted, fontSize: 13),
            ),
          ],
          if (widget.offer.isDaily) ...[
            const SizedBox(height: 14),
            // Digits keep LTR order (HH:MM:SS) in both languages.
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CountdownBox(
                    value: _two(_remaining.inHours),
                    label: l10n.homeCountdownHours,
                  ),
                  const _CountdownSeparator(),
                  _CountdownBox(
                    value: _two(_remaining.inMinutes % 60),
                    label: l10n.homeCountdownMinutes,
                  ),
                  const _CountdownSeparator(),
                  _CountdownBox(
                    value: _two(_remaining.inSeconds % 60),
                    label: l10n.homeCountdownSeconds,
                  ),
                ],
              ),
            ),
          ],
          if (offer.ctaLabel.isNotEmpty) ...[
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 42),
                padding: const EdgeInsets.symmetric(horizontal: 22),
              ),
              onPressed: () => openStorefrontUrl(context, ref, offer.ctaUrl),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    offer.ctaLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A single HRS/MINS/SECS box in the countdown — burgundy tile, white numerals,
/// muted label beneath (Figma).
class _CountdownBox extends StatelessWidget {
  const _CountdownBox({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.brandPrimary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.inkMuted,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

class _CountdownSeparator extends StatelessWidget {
  const _CountdownSeparator();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 8),
    child: Padding(
      padding: EdgeInsets.only(bottom: 14),
      child: Text(
        ':',
        style: TextStyle(
          color: AppColors.brandPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}

/// "Deals of the Day" — products from the live `deals-of-the-day` category with
/// a DEAL tag + real discount badges. Gated on the backend `deals` toggle and
/// hidden when the category returns nothing.
class _DealsOfTheDaySection extends ConsumerWidget {
  const _DealsOfTheDaySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref
        .watch(homeConfigProvider)
        .maybeWhen(
          data: (c) => c.sectionEnabled('deals'),
          orElse: () => true,
        );
    if (!enabled) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return ref
        .watch(dealsOfTheDayProvider)
        .when(
          loading: () => _ProductSectionSkeleton(title: l10n.homeDealsOfTheDay),
          error: (_, __) => const SizedBox.shrink(),
          data: (section) => _ProductSection(
            title: l10n.homeDealsOfTheDay,
            section: section,
            dealBadge: true,
          ),
        );
  }
}

/// "Skincare / Makeup" editorial banners — two image banners bound to the real
/// `skin-care` / `makeup` categories (image + link) with editorial taglines.
/// Gated on the `promo_split` toggle; each banner hides if its category is
/// absent.
class _EditorialBanners extends ConsumerWidget {
  const _EditorialBanners();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref
        .watch(homeConfigProvider)
        .maybeWhen(
          data: (c) => c.sectionEnabled('promo_split'),
          orElse: () => true,
        );
    if (!enabled) return const SizedBox.shrink();
    return ref
        .watch(promoSplitBannersProvider)
        .maybeWhen(
          data: (banners) => banners.isEmpty
              ? const SizedBox.shrink()
              : _EditorialBannersList(banners: banners),
          orElse: () => const SizedBox.shrink(),
        );
  }
}

class _EditorialBannersList extends StatelessWidget {
  const _EditorialBannersList({required this.banners});
  final List<PromoSplitBanner> banners;

  @override
  Widget build(BuildContext context) {
    // Figma: inset (16px) rounded banners, 12px apart.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        children: [
          for (var i = 0; i < banners.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _EditorialBanner(banner: banners[i]),
          ],
        ],
      ),
    );
  }
}

class _EditorialBanner extends ConsumerWidget {
  const _EditorialBanner({required this.banner});
  final PromoSplitBanner banner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ctaLabel = banner.ctaLabel.isNotEmpty
        ? banner.ctaLabel
        : l10n.homeHeroCta;
    // Figma: inset rounded banner, ~230px tall.
    return Material(
      color: AppColors.surfaceTint,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: banner.ctaUrl.isEmpty
            ? null
            : () => openStorefrontUrl(context, ref, banner.ctaUrl),
        child: SizedBox(
          height: 230,
          child: Stack(
            children: [
              Positioned.fill(
                child: banner.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: banner.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            const ColoredBox(color: AppColors.surfaceTint),
                        errorWidget: (_, __, ___) =>
                            const ColoredBox(color: AppColors.surfaceTint),
                      )
                    : const ColoredBox(color: AppColors.surfaceTint),
              ),
              // Dark scrim on the start side for text legibility.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: AlignmentDirectional.centerStart,
                      end: AlignmentDirectional.centerEnd,
                      colors: [
                        Colors.black.withValues(alpha: 0.55),
                        Colors.black.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                start: 20,
                top: 0,
                bottom: 0,
                end: 20,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (banner.eyebrow.isNotEmpty) ...[
                      Text(
                        banner.eyebrow.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      banner.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // "Shop Now" pill (Figma) — the whole banner is the tap
                    // target; this reads as a button.
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            ctaLabel,
                            style: const TextStyle(
                              color: AppColors.brandPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_forward,
                            size: 15,
                            color: AppColors.brandPrimary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Exclusive Offers" — the `homeBanners` discount rail ("Save More Every
/// Order"). Hides when the query returns nothing; gated on the `banners` toggle.
class _ExclusiveOffers extends ConsumerWidget {
  const _ExclusiveOffers();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref
        .watch(homeConfigProvider)
        .maybeWhen(
          data: (c) => c.sectionEnabled('banners'),
          orElse: () => true,
        );
    if (!enabled) return const SizedBox.shrink();
    return ref
        .watch(homeBannersProvider)
        .maybeWhen(
          data: (offers) => offers.isEmpty
              ? const SizedBox.shrink()
              : _ExclusiveOffersRail(offers: offers),
          orElse: () => const SizedBox.shrink(),
        );
  }
}

class _ExclusiveOffersRail extends StatelessWidget {
  const _ExclusiveOffersRail({required this.offers});
  final List<ExclusiveOffer> offers;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Figma (updated 2026-07-13): left-aligned title + subtitle with
        // VIEW ALL on the trailing side (mirrors under RTL via the Row).
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.homeExclusiveOffersTitle.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        color: AppColors.inkHeading,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.homeExclusiveOffersSubtitle,
                      style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => context.go(AppRoutes.categories),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.brandPrimary,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.homeViewAll,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward, size: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Figma: three stacked inset image banners.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Column(
            children: [
              for (var i = 0; i < offers.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                _ExclusiveOfferBanner(offer: offers[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One "Exclusive Offers" banner (Figma) — a category image with a centered
/// discount + white category pill + terms line, over a dark scrim. Falls back
/// to a blush background when no image is provided.
class _ExclusiveOfferBanner extends ConsumerWidget {
  const _ExclusiveOfferBanner({required this.offer});
  final ExclusiveOffer offer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: AppColors.surfaceTint,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: offer.ctaUrl.isEmpty
            ? null
            : () => openStorefrontUrl(context, ref, offer.ctaUrl),
        child: SizedBox(
          height: 200,
          child: Stack(
            children: [
              if (offer.imageUrl.isNotEmpty)
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: offer.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        const ColoredBox(color: AppColors.surfaceTint),
                    errorWidget: (_, __, ___) =>
                        const ColoredBox(color: AppColors.surfaceTint),
                  ),
                ),
              // Scrim so the centered white text stays legible over any image.
              Positioned.fill(
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.28)),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (offer.badge.isNotEmpty)
                      Text(
                        offer.badge,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    if (offer.title.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          offer.title,
                          style: const TextStyle(
                            color: AppColors.brandPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    if (offer.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        offer.subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Why Shoppers Trust Zoonze" — the `homeReviews` testimonial rail (real
/// reviews only). Hides when empty; gated on the `reviews` toggle.
class _WhyShoppersTrust extends ConsumerWidget {
  const _WhyShoppersTrust();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref
        .watch(homeConfigProvider)
        .maybeWhen(
          data: (c) => c.sectionEnabled('reviews'),
          orElse: () => true,
        );
    if (!enabled) return const SizedBox.shrink();
    return ref
        .watch(homeReviewsProvider)
        .maybeWhen(
          data: (items) => items.isEmpty
              ? const SizedBox.shrink()
              : _TestimonialsRail(items: items),
          orElse: () => const SizedBox.shrink(),
        );
  }
}

class _TestimonialsRail extends StatelessWidget {
  const _TestimonialsRail({required this.items});
  final List<Testimonial> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeaderWithSubtitle(
          title: l10n.homeTrustReviewsTitle,
          subtitle: l10n.homeTrustReviewsSubtitle,
        ),
        SizedBox(
          height: 184,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _TestimonialCard(item: items[i]),
          ),
        ),
      ],
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard({required this.item});
  final Testimonial item;

  String get _initials {
    final parts = item.author.trim().split(RegExp(r'\s+'));
    final letters = parts
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return letters.isEmpty ? '★' : letters;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + name + gold stars (Figma).
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.surfaceTint,
                child: Text(
                  _initials,
                  style: const TextStyle(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.author.isNotEmpty) ...[
                      Text(
                        item.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.inkHeading,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    _Stars(rating: item.rating),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Quote, then the product it's about at the bottom.
          Expanded(
            child: Text(
              '“${item.quote}”',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.inkMuted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
          if (item.product.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.product.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.inkFaint,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A gold 0–5 star row (filled + outlined to five). Auto-mirrors under RTL via
/// the row's directional layout; stars themselves are symmetric.
class _Stars extends StatelessWidget {
  const _Stars({required this.rating});
  final int rating;

  @override
  Widget build(BuildContext context) {
    final full = rating.clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Icon(
            i < full ? Icons.star : Icons.star_border,
            size: 16,
            color: AppColors.accentGold,
          ),
      ],
    );
  }
}

/// "The Zoonze Journal" — the latest blog posts (`blogPosts`). Gated on the
/// backend `blog` toggle and hidden when the module returns no posts.
class _ZoonzeJournal extends ConsumerWidget {
  const _ZoonzeJournal();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref
        .watch(homeConfigProvider)
        .maybeWhen(
          data: (c) => c.sectionEnabled('blog'),
          orElse: () => true,
        );
    if (!enabled) return const SizedBox.shrink();
    return ref
        .watch(blogPostsProvider)
        .maybeWhen(
          data: (posts) =>
              posts.isEmpty ? const SizedBox.shrink() : _JournalRail(posts: posts),
          orElse: () => const SizedBox.shrink(),
        );
  }
}

class _JournalRail extends StatelessWidget {
  const _JournalRail({required this.posts});
  final List<BlogPost> posts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Blog index for "See More" — the store-prefixed `.../blog` root derived from
    // a post URL (`.../uae-en/blog/post/…`). Empty when it can't be derived.
    final indexUrl = _blogIndexUrl(posts.first.url);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeaderWithSubtitle(
          title: l10n.homeJournalTitle,
          subtitle: l10n.homeJournalSubtitle,
        ),
        SizedBox(
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: posts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _JournalCard(post: posts[i]),
          ),
        ),
        if (indexUrl.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Center(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.inkHeading,
                ),
                onPressed: () => context.push(
                  AppRoutes.webview,
                  extra: WebViewArgs(
                    url: indexUrl,
                    title: l10n.homeJournalTitle,
                  ),
                ),
                child: Text(l10n.homeSeeMore),
              ),
            ),
          ),
      ],
    );
  }
}

class _JournalCard extends StatelessWidget {
  const _JournalCard({required this.post});
  final BlogPost post;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return InkWell(
      onTap: () => context.push(
        AppRoutes.webview,
        extra: WebViewArgs(url: post.url, title: post.title),
      ),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 260,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 118,
              width: double.infinity,
              child: post.hasImage
                  ? CachedNetworkImage(
                      imageUrl: post.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          const ColoredBox(color: AppColors.surfaceTint),
                      errorWidget: (_, __, ___) => const _JournalImageFallback(),
                    )
                  : const _JournalImageFallback(),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Figma: the BLOGS tag sits in the body, below the image.
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      l10n.homeJournalTag,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      height: 1.25,
                      color: AppColors.inkHeading,
                    ),
                  ),
                  if (post.excerpt.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      post.excerpt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.homeReadMore,
                        style: const TextStyle(
                          color: AppColors.brandPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: AppColors.brandPrimary,
                      ),
                    ],
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

class _JournalImageFallback extends StatelessWidget {
  const _JournalImageFallback();

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.surfaceTint,
    child: const Center(
      child: Icon(Icons.article_outlined, color: AppColors.brandPrimary),
    ),
  );
}

/// The store-prefixed blog index (`.../blog`) derived from a post URL like
/// `https://zoonze.com/uae-en/blog/post/…`. Returns '' when the URL isn't an
/// absolute http(s) URL containing a `/blog` segment.
String _blogIndexUrl(String postUrl) {
  final uri = Uri.tryParse(postUrl);
  if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) return '';
  const marker = '/blog';
  final i = postUrl.indexOf(marker);
  if (i < 0) return '';
  return postUrl.substring(0, i + marker.length);
}

/// Trust seals (live zoonze.com) — the store's five guarantees on a light-grey
/// band. Content mirrors the website's trust strip exactly (QA: the block must
/// match the site). The backend `trust/items` config array is currently empty,
/// so — like the website theme — the app renders these five as localized
/// defaults; wire them to `trust/items` if/when the backend populates it.
class _TrustBadges extends StatelessWidget {
  const _TrustBadges();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final seals = <({IconData icon, String label})>[
      (icon: Icons.verified_user_outlined, label: l10n.homeTrustOriginal),
      (icon: Icons.local_shipping_outlined, label: l10n.homeTrustFreeDelivery),
      (icon: Icons.schedule, label: l10n.homeTrustDelivery3h),
      (icon: Icons.place_outlined, label: l10n.homeTrustRestZones),
      (icon: Icons.headset_mic_outlined, label: l10n.homeTrustCustomerService),
    ];
    // Five seals centered on a light-grey band; a Wrap flows them to 3-then-2 on
    // a phone (and adapts to wider screens) instead of a fixed 2×2 grid.
    return Container(
      width: double.infinity,
      color: const Color(0xFFF3F4F6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 24,
        children: [
          for (final s in seals) _TrustBadge(icon: s.icon, label: s.label),
        ],
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white,
            child: Icon(icon, color: AppColors.brandPrimary, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              height: 1.25,
              color: AppColors.inkHeading,
            ),
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

/// Mirrors `_CategoryGrid` (horizontal rail): grey circle + label line per cell.
class _CategoryGridSkeleton extends StatelessWidget {
  const _CategoryGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: SizedBox(
        height: 116,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 6,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (_, __) => const SizedBox(
            width: 80,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SkeletonBox.circle(size: 72),
                SizedBox(height: 8),
                SkeletonBox(width: 52, height: 10, borderRadius: 4),
              ],
            ),
          ),
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

/// Centered section header with a muted subtitle beneath (Figma: Why Shoppers
/// Trust + The Zoonze Journal).
class _SectionHeaderWithSubtitle extends StatelessWidget {
  const _SectionHeaderWithSubtitle({
    required this.title,
    required this.subtitle,
  });
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 28, 16, 14),
    child: Column(
      children: [
        Text(
          title.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.82,
            color: AppColors.inkHeading,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.inkMuted, fontSize: 13),
        ),
      ],
    ),
  );
}
