import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/shell/marketing_footer.dart';
import '../../../../app/shell/zoonze_scaffold.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../cart/presentation/cart_controller.dart';
import '../../../catalog/presentation/widgets/product_card.dart';
import '../../domain/wishlist_entry.dart';
import '../wishlist_controller.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authControllerProvider);
    final state = ref.watch(wishlistControllerProvider);

    final Widget body;
    if (!auth.isAuthenticated) {
      body = _Prompt(
        title: l10n.wishlistGuestTitle,
        body: l10n.wishlistGuestBody,
        cta: l10n.authSignInTitle,
        onTap: () => context.push(AppRoutes.signIn),
      );
    } else if (state.isLoading && state.entries.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.entries.isEmpty) {
      body = _Empty(
        title: l10n.wishlistEmptyTitle,
        body: l10n.wishlistEmptyBody,
      );
    } else {
      body = ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.wishlistHeading,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  l10n.wishlistSavedCount(state.entries.length),
                  style: const TextStyle(color: AppColors.inkMuted),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: state.isLoading
                        ? null
                        : () => _addAll(context, ref, state.entries, l10n),
                    icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                    label: Text(l10n.wishlistAddAll),
                  ),
                ),
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.58,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: state.entries.length,
            itemBuilder: (context, index) {
              final product = state.entries[index].product;
              return ProductCard(
                product: product,
                onTap: () => context.push(AppRoutes.product(product.urlKey)),
              );
            },
          ),
          const MarketingFooter(),
        ],
      );
    }

    return ZoonzeScaffold(
      currentTab: AppTab.wishlist,
      showSearch: false,
      body: body,
    );
  }

  /// Best-effort "Add all to Bag": adds each saved product to the cart. Items
  /// that need an option choice (configurables) are skipped silently.
  Future<void> _addAll(
    BuildContext context,
    WidgetRef ref,
    List<WishlistEntry> entries,
    AppLocalizations l10n,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final cart = ref.read(cartControllerProvider.notifier);
    for (final entry in entries) {
      try {
        await cart.addToCart(sku: entry.product.sku);
      } catch (_) {
        // Skip items that require selecting options before adding.
      }
    }
    if (context.mounted) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.cartAdded)));
    }
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.surfaceTint,
            child: Icon(
              Icons.favorite_border,
              size: 48,
              color: AppColors.brandPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.inkMuted),
          ),
        ],
      ),
    ),
  );
}

class _Prompt extends StatelessWidget {
  const _Prompt({
    required this.title,
    required this.body,
    required this.cta,
    required this.onTap,
  });

  final String title;
  final String body;
  final String cta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.surfaceTint,
            child: Icon(
              Icons.favorite_border,
              size: 48,
              color: AppColors.brandPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.inkMuted),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: onTap, child: Text(cta)),
          ),
        ],
      ),
    ),
  );
}
