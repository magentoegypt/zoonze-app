import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/cart/presentation/cart_controller.dart';
import '../../features/wishlist/presentation/wishlist_controller.dart';
import '../../l10n/l10n.dart';
import '../routes.dart';

/// Persistent bottom navigation (Home · Categories · Cart · Wishlist · Account)
/// with live cart + wishlist count badges.
class ZoonzeBottomNav extends ConsumerWidget {
  const ZoonzeBottomNav({super.key, required this.current});

  final AppTab current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cartCount = ref.watch(
      cartControllerProvider.select((s) => s.itemCount),
    );
    final wishlistCount = ref.watch(
      wishlistControllerProvider.select((s) => s.entries.length),
    );

    return NavigationBar(
      selectedIndex: current.index,
      // Always navigate to the tab root, even when re-tapping the active tab,
      // so a pushed detail (e.g. PLP) can be left via the bottom nav.
      onDestinationSelected: (index) => context.go(AppTab.values[index].route),
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: l10n.navHome,
        ),
        NavigationDestination(
          icon: const Icon(Icons.grid_view_outlined),
          selectedIcon: const Icon(Icons.grid_view),
          label: l10n.navCategories,
        ),
        NavigationDestination(
          icon: Badge(
            isLabelVisible: cartCount > 0,
            label: Text('$cartCount'),
            child: const Icon(Icons.shopping_bag_outlined),
          ),
          selectedIcon: Badge(
            isLabelVisible: cartCount > 0,
            label: Text('$cartCount'),
            child: const Icon(Icons.shopping_bag),
          ),
          label: l10n.navCart,
        ),
        NavigationDestination(
          icon: Badge(
            isLabelVisible: wishlistCount > 0,
            label: Text('$wishlistCount'),
            child: const Icon(Icons.favorite_border),
          ),
          selectedIcon: Badge(
            isLabelVisible: wishlistCount > 0,
            label: Text('$wishlistCount'),
            child: const Icon(Icons.favorite),
          ),
          label: l10n.navWishlist,
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline),
          selectedIcon: const Icon(Icons.person),
          label: l10n.navAccount,
        ),
      ],
    );
  }
}
