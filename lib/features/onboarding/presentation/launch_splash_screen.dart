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
    // Hold the splash briefly for branding while reading the persisted token.
    final results = await Future.wait<Object?>([
      ref.read(secureTokenStoreProvider).read(),
      Future<void>.delayed(const Duration(milliseconds: 1500)),
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
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // logo.png is a burgundy silhouette on transparent; tint it white so
            // it reads on the burgundy splash background.
            Image.asset(
              AppImages.logo,
              width: 180,
              color: Colors.white,
              colorBlendMode: BlendMode.srcIn,
              errorBuilder: (_, __, ___) =>
                  const BrandLockup(color: Colors.white, fontSize: 40),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.launchTagline,
              style: const TextStyle(
                color: Colors.white,
                letterSpacing: 3,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
