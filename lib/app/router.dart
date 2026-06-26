import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/placeholder_screen.dart';
import '../features/account/presentation/account_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/cart/presentation/screens/cart_screen.dart';
import '../features/auth/presentation/screens/sign_in_screen.dart';
import '../features/auth/presentation/screens/sign_up_screen.dart';
import '../features/catalog/presentation/screens/categories_screen.dart';
import '../features/catalog/presentation/screens/home_screen.dart';
import '../features/catalog/presentation/screens/plp_screen.dart';
import '../features/catalog/presentation/screens/product_detail_screen.dart';
import '../features/catalog/presentation/screens/search_screen.dart';
import '../features/diagnostics/presentation/health_check_screen.dart';
import '../features/onboarding/presentation/launch_splash_screen.dart';
import '../features/onboarding/presentation/welcome_screen.dart';
import 'routes.dart';

/// App router. Phase 1 wires the catalogue browse flow + global chrome. Auth
/// guards and payment/push deep links land in later phases.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const LaunchSplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.categories,
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(
        path: '/category/:uid',
        builder: (context, state) => PlpScreen(
          categoryUid: state.pathParameters['uid']!,
          title: state.extra as String?,
        ),
      ),
      GoRoute(
        path: '/product/:urlKey',
        builder: (context, state) =>
            ProductDetailScreen(urlKey: state.pathParameters['urlKey']!),
      ),
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.cart,
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: AppRoutes.wishlist,
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Wishlist', tab: AppTab.wishlist),
      ),
      GoRoute(
        path: AppRoutes.account,
        builder: (context, state) => const AccountScreen(),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/diagnostics',
        builder: (context, state) => const HealthCheckScreen(),
      ),
    ],
  );
});
