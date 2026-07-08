import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/assets/app_images.dart';
import '../../../core/storage/secure_token_store.dart';
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
    _routeOnboarding();
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
                const SizedBox(height: 44),
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
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
