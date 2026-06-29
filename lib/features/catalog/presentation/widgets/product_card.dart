import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/store/store_controller.dart';
import '../../../../l10n/l10n.dart';
import '../../../wishlist/presentation/widgets/wishlist_heart.dart';
import '../../domain/product.dart';
import 'price_view.dart';

/// Product card per Figma: a bordered white card with a full-bleed image
/// carrying NEW/BESTSELLER + discount badges (top-start) and stacked wishlist +
/// share actions (top-end), then a name + stacked-price panel. Image degrades
/// to a neutral placeholder and the merchandising badge only shows when the
/// catalogue actually flags it (no fabricated imagery or badges).
class ProductCard extends ConsumerWidget {
  const ProductCard({super.key, required this.product, this.onTap});

  final Product product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final discount = product.discountPercent;
    final badgeLabel = _badgeLabel(l10n);

    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.borderDefault),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: _Image(url: product.imageUrl)),
                  // Merchandising badge over the discount badge (top-start).
                  PositionedDirectional(
                    top: 8,
                    start: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (badgeLabel != null)
                          _Badge(
                            label: badgeLabel,
                            color: product.badge == ProductBadge.bestseller
                                ? AppColors.accentGold
                                : AppColors.brandPrimary,
                          ),
                        if (badgeLabel != null && discount != null)
                          const SizedBox(height: 4),
                        if (discount != null)
                          _Badge(
                            label: '-$discount%',
                            color: AppColors.accentSale,
                          ),
                      ],
                    ),
                  ),
                  // Wishlist heart with the share action stacked beneath it.
                  PositionedDirectional(
                    top: 8,
                    end: 8,
                    child: _CircleAction(
                      child: WishlistHeart(sku: product.sku, compact: true),
                    ),
                  ),
                  PositionedDirectional(
                    top: 40,
                    end: 8,
                    child: _CircleAction(
                      child: IconButton(
                        iconSize: 15,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 26,
                          height: 26,
                        ),
                        tooltip: l10n.actionShare,
                        icon: const Icon(
                          Icons.ios_share,
                          color: AppColors.inkHeading,
                        ),
                        onPressed: () => _share(ref, l10n),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      height: 1.35,
                      color: AppColors.inkHeading,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (!product.inStock)
                    Text(
                      l10n.productOutOfStock,
                      style: const TextStyle(
                        color: AppColors.accentSale,
                        fontSize: 12,
                      ),
                    )
                  else
                    PriceView(product: product),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _badgeLabel(AppLocalizations l10n) => switch (product.badge) {
    ProductBadge.isNew => l10n.badgeNew,
    ProductBadge.bestseller => l10n.badgeBestseller,
    ProductBadge.none => null,
  };

  /// Shares the product via the OS share sheet, using the active store's
  /// canonical web URL when available (falls back to a name-only message).
  Future<void> _share(WidgetRef ref, AppLocalizations l10n) async {
    final store = ref.read(storeControllerProvider);
    var base = '';
    for (final s in store.stores) {
      if (s.storeCode == store.activeStoreCode) {
        base = s.secureBaseUrl.isNotEmpty ? s.secureBaseUrl : s.baseUrl;
        break;
      }
    }
    final message = l10n.shareProduct(product.name);
    final url = (base.isNotEmpty && product.urlKey.isNotEmpty)
        ? '$base${product.urlKey}.html'
        : null;
    await SharePlus.instance.share(
      ShareParams(text: url == null ? message : '$message\n$url'),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: 26,
    height: 26,
    clipBehavior: Clip.antiAlias,
    decoration: const BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      border: Border.fromBorderSide(
        BorderSide(color: AppColors.borderDefault),
      ),
    ),
    child: child,
  );
}

class _Image extends StatelessWidget {
  const _Image({required this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return const _ImagePlaceholder();
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        // Decode at the on-screen size (× DPR), not the source's full
        // resolution — a large memory/jank win across product grids.
        final w = constraints.maxWidth;
        final cacheWidth = (w.isFinite && w > 0) ? (w * dpr).round() : null;
        return CachedNetworkImage(
          imageUrl: url!,
          fit: BoxFit.cover,
          memCacheWidth: cacheWidth,
          placeholder: (_, __) => const _ImagePlaceholder(),
          errorWidget: (_, __, ___) => const _ImagePlaceholder(),
        );
      },
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.surfaceTint,
    child: const Center(
      child: Icon(Icons.image_outlined, color: AppColors.inkMuted),
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
    ),
  );
}
