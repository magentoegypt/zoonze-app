import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/assets/app_images.dart';
import '../../../core/storage/secure_token_store.dart';
import '../../../core/util/image_prefetch.dart';
import '../../../core/widgets/network_image.dart';
import '../../catalog/data/hero_slides_provider.dart';
import '../../catalog/data/home_config_provider.dart';
import '../../catalog/domain/category.dart';
import '../../catalog/domain/home_config.dart';
import '../../catalog/presentation/catalog_providers.dart';
import '../../../core/widgets/brand_lockup.dart';
import '../../../l10n/l10n.dart';

/// Launch splash: full ZoonZE logo (tinted white on burgundy) + tagline. While
/// it shows, we read the saved session: a returning signed-in customer skips
/// Welcome/Sign In and lands on Home; everyone else goes to Welcome. Chrome-free.
class LaunchSplashScreen extends ConsumerStatefulWidget {
  const LaunchSplashScreen({super.key});

  @override
  ConsumerState<LaunchSplashScreen> createState() => _LaunchSplashScreenState();
}

class _LaunchSplashScreenState extends ConsumerState<LaunchSplashScreen> {
  @override
  void initState() {
    super.initState();
    _warmHome();
    _routeOnboarding();
  }

  /// The splash deliberately holds for 2.6s. Spend it fetching what Home needs
  /// first, so it paints on arrival instead of starting from nothing.
  ///
  /// Strictly fire-and-forget: nothing here is awaited on the routing path, and
  /// every failure is swallowed — a cold or offline start must still leave the
  /// splash after 2.6s. These three providers keepAlive(), so the results
  /// survive until Home reads them.
  void _warmHome() {
    unawaited(
      Future(() async {
        try {
          // The product rails await the category tree before they can even
          // issue their own query, so this removes a serial round-trip.
          unawaited(ref.read(categoryTreeProvider.future).catchError((_) {
            return const <Category>[];
          }));
          unawaited(ref.read(homeConfigProvider.future).catchError((_) {
            return HomeConfig.empty;
          }));
          final slides = await ref.read(heroSlidesProvider.future);
          if (!mounted || slides.isEmpty) return;
          // Only the first slide — the one Home paints immediately.
          await prefetchImages(
            context,
            [slides.first.imageUrl],
            decodeWidth: ZoonzeImage.decodePixels(
              context,
              MediaQuery.sizeOf(context).width,
            ),
            limit: 1,
          );
        } catch (_) {
          // A warm-up failure is not a startup failure.
        }
      }),
    );
  }

  Future<void> _routeOnboarding() async {
    // Hold the splash long enough for the branding to register (QA: it flashed
    // by in under a second) while reading the persisted token.
    final results = await Future.wait<Object?>([
      ref.read(secureTokenStoreProvider).read(),
      Future<void>.delayed(const Duration(milliseconds: 2600)),
    ]);
    if (!mounted) return;
    final token = results.first as String?;
    final loggedIn = token != null && token.isNotEmpty;
    context.go(loggedIn ? AppRoutes.home : AppRoutes.welcome);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.brandPrimary,
      body: Stack(
        children: [
          // Faint circular outlines behind the logo (Figma 52:2 background
          // ellipses) — partly off-screen at three corners.
          Positioned(top: -80, left: -120, child: _ring(360)),
          Positioned(top: 120, right: -30, child: _ring(120)),
          Positioned(bottom: -60, right: -120, child: _ring(260)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // logo.png is a burgundy silhouette on transparent; tint it white
                // so it reads on the burgundy splash. Sized up per QA so the
                // wordmark dominates the tagline.
                Image.asset(
                  AppImages.logo,
                  width: 210,
                  color: Colors.white,
                  colorBlendMode: BlendMode.srcIn,
                  errorBuilder: (_, __, ___) =>
                      const BrandLockup(color: Colors.white, fontSize: 44),
                ),
                const SizedBox(height: 14),
                // Short underline beneath the wordmark (Figma).
                Container(width: 46, height: 1.5, color: Colors.white70),
                const SizedBox(height: 12),
                Text(
                  l10n.launchTagline,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Loading dots pinned near the bottom of the screen (shared PNG
          // position) — replaces the centered round spinner.
          const Align(
            alignment: Alignment(0, 0.72),
            child: _DotsLoader(),
          ),
        ],
      ),
    );
  }

  /// A faint circular outline used as a soft background decoration on the splash.
  Widget _ring(double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white10, width: 1.5),
    ),
  );
}

/// Three pulsing dots used as the splash loading indicator (shared PNG) — the
/// highlight sweeps left→right across the dots. White on the burgundy splash.
class _DotsLoader extends StatefulWidget {
  const _DotsLoader();

  @override
  State<_DotsLoader> createState() => _DotsLoaderState();
}

class _DotsLoaderState extends State<_DotsLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
        ..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: EdgeInsetsDirectional.only(start: i == 0 ? 0 : 9),
              child: _dot(i),
            ),
        ],
      ),
    );
  }

  Widget _dot(int index) {
    // Each dot leads the next by a third of the cycle so the highlight travels
    // across them. `%` on a positive divisor stays non-negative in Dart.
    final phase = (_controller.value - index / 3) % 1.0;
    final t = (1 - (phase * 2 - 1).abs()).clamp(0.0, 1.0); // triangle 0→1→0
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.3 + 0.7 * t),
      ),
    );
  }
}
