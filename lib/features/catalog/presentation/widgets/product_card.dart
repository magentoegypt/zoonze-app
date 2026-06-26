import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../../wishlist/presentation/widgets/wishlist_heart.dart';
import '../../domain/product.dart';
import 'price_view.dart';

/// Product card per Figma: full-bleed image, discount badge (top-start), wishlist
/// heart (top-end), brand + title, stacked price. Image degrades to a neutral
/// placeholder (no fabricated imagery).
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, this.onTap});

  final Product product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final discount = product.discountPercent;

    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  Positioned.fill(child: _Image(url: product.imageUrl)),
                  if (discount != null)
                    PositionedDirectional(
                      top: 8,
                      start: 8,
                      child: _Badge(
                        label: '-$discount%',
                        color: AppColors.accentSale,
                      ),
                    ),
                  PositionedDirectional(
                    top: 4,
                    end: 4,
                    child: WishlistHeart(sku: product.sku),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (product.brand != null && product.brand!.isNotEmpty)
            Text(
              product.brand!,
              style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
            ),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          if (!product.inStock)
            Text(
              l10n.productOutOfStock,
              style: const TextStyle(color: AppColors.accentSale, fontSize: 12),
            )
          else
            PriceView(product: product),
        ],
      ),
    );
  }
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
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
