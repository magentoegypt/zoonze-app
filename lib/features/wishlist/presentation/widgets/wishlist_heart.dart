import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../wishlist_controller.dart';

/// Heart toggle that reflects and mutates wishlist membership for [sku].
/// Prompts sign-in (snackbar) when the user is a guest.
class WishlistHeart extends ConsumerWidget {
  const WishlistHeart({super.key, required this.sku, this.color});

  final String sku;
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inWishlist =
        ref.watch(wishlistControllerProvider.select((s) => s.contains(sku)));
    return IconButton(
      icon: Icon(
        inWishlist ? Icons.favorite : Icons.favorite_border,
        color:
            inWishlist ? AppColors.brandPrimary : (color ?? AppColors.inkHeading),
      ),
      onPressed: () async {
        final ok =
            await ref.read(wishlistControllerProvider.notifier).toggle(sku);
        if (!ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).wishlistSignInPrompt),
            ),
          );
        }
      },
    );
  }
}
