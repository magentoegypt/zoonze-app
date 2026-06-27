import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/shell/zoonze_scaffold.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../catalog/presentation/widgets/product_card.dart';
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
      body = GridView.builder(
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
      );
    }

    return ZoonzeScaffold(
      currentTab: AppTab.wishlist,
      showSearch: false,
      body: body,
    );
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
