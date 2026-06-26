import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/account/domain/customer_address.dart';
import '../features/account/presentation/account_screen.dart';
import '../features/account/presentation/screens/address_form_screen.dart';
import '../features/account/presentation/screens/addresses_screen.dart';
import '../features/account/presentation/screens/edit_profile_screen.dart';
import '../features/account/presentation/screens/orders_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/cart/presentation/screens/cart_screen.dart';
import '../features/checkout/presentation/screens/checkout_screen.dart';
import '../features/checkout/presentation/screens/order_success_screen.dart';
import '../features/auth/presentation/screens/sign_in_screen.dart';
import '../features/auth/presentation/screens/sign_up_screen.dart';
import '../features/catalog/presentation/screens/categories_screen.dart';
import '../features/catalog/presentation/screens/home_screen.dart';
import '../features/catalog/presentation/screens/plp_screen.dart';
import '../features/catalog/presentation/screens/product_detail_screen.dart';
import '../features/catalog/presentation/screens/search_screen.dart';
import '../features/catalog/presentation/screens/write_review_screen.dart';
import '../features/wishlist/presentation/screens/wishlist_screen.dart';
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
        path: '/review/:sku',
        builder: (context, state) =>
            WriteReviewScreen(sku: state.pathParameters['sku']!),
      ),
      GoRoute(
        path: AppRoutes.cart,
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: AppRoutes.wishlist,
        builder: (context, state) => const WishlistScreen(),
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
        path: AppRoutes.orders,
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: AppRoutes.addresses,
        builder: (context, state) => const AddressesScreen(),
      ),
      GoRoute(
        path: AppRoutes.addressForm,
        builder: (context, state) =>
            AddressFormScreen(initial: state.extra as CustomerAddress?),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: AppRoutes.orderSuccess,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return OrderSuccessScreen(
            orderNumber: (extra?['number'] as String?) ?? '',
            pendingPayment: (extra?['pending'] as bool?) ?? false,
          );
        },
      ),
      GoRoute(
        path: '/diagnostics',
        builder: (context, state) => const HealthCheckScreen(),
      ),
    ],
  );
});
