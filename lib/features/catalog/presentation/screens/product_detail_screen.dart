import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/shell/marketing_footer.dart';
import '../../../../app/shell/zoonze_scaffold.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../l10n/l10n.dart';
import '../../../cart/presentation/cart_controller.dart';
import '../../../checkout/payments/tabby_promo.dart';
import '../../../wishlist/presentation/widgets/wishlist_heart.dart';
import '../../domain/money.dart';
import '../../domain/product_detail.dart';
import '../catalog_providers.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.urlKey});

  final String urlKey;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  final Map<String, int> _selection = <String, int>{};
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(productDetailProvider(widget.urlKey));

    return ZoonzeScaffold(
      currentTab: AppTab.home,
      body: AsyncValueView(
        value: detail,
        onRetry: () => ref.invalidate(productDetailProvider(widget.urlKey)),
        data: (product) {
          if (product == null) {
            return Center(child: Text(l10n.stateEmpty));
          }
          return _Content(
            product: product,
            selection: _selection,
            tab: _tab,
            onSelect: (code, value) => setState(() => _selection[code] = value),
            onTab: (index) => setState(() => _tab = index),
          );
        },
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.product,
    required this.selection,
    required this.tab,
    required this.onSelect,
    required this.onTab,
  });

  final ProductDetail product;
  final Map<String, int> selection;
  final int tab;
  final void Function(String code, int value) onSelect;
  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) {
    final variant = product.variantFor(selection);
    final price = variant?.price ?? product.finalPrice ?? product.regularPrice;
    final images = <String>[
      if (variant?.imageUrl != null) variant!.imageUrl!,
      ...product.gallery,
    ];

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _Gallery(images: images, sku: product.sku, urlKey: product.urlKey),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (product.brand != null && product.brand!.isNotEmpty)
                Text(
                  product.brand!,
                  style: const TextStyle(color: AppColors.inkMuted),
                ),
              Text(
                product.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              _PriceRow(
                price: price,
                product: product,
                showStruck: variant == null,
              ),
              if (price != null)
                TabbyPromo(
                  price: price,
                  padding: const EdgeInsets.only(top: 8),
                ),
              const SizedBox(height: 16),
              for (final option in product.options)
                _OptionSelector(
                  option: option,
                  selectedValue: selection[option.attributeCode],
                  onSelect: (value) => onSelect(option.attributeCode, value),
                ),
              const SizedBox(height: 8),
              _AddToCartButton(
                product: product,
                selection: selection,
                variant: variant,
              ),
              const SizedBox(height: 24),
              _Tabs(current: tab, onTab: onTab),
              const SizedBox(height: 12),
              _TabContent(product: product, tab: tab),
            ],
          ),
        ),
        const MarketingFooter(),
      ],
    );
  }
}

class _Gallery extends StatefulWidget {
  const _Gallery({
    required this.images,
    required this.sku,
    required this.urlKey,
  });
  final List<String> images;
  final String sku;
  final String urlKey;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _share(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    await Clipboard.setData(
      ClipboardData(text: 'https://zoonze.com/${widget.urlKey}'),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.actionLinkCopied)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    // The gallery spans the full screen width — decode at that size, not full res.
    final cacheWidth =
        (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context))
            .round();
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: images.isEmpty
              ? Container(color: AppColors.surfaceTint)
              : Stack(
                  children: [
                    PageView.builder(
                      controller: _controller,
                      itemCount: images.length,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (_, i) => CachedNetworkImage(
                        imageUrl: images[i],
                        fit: BoxFit.cover,
                        memCacheWidth: cacheWidth,
                        placeholder: (_, __) =>
                            Container(color: AppColors.surfaceTint),
                        errorWidget: (_, __, ___) =>
                            Container(color: AppColors.surfaceTint),
                      ),
                    ),
                    PositionedDirectional(
                      top: 8,
                      end: 8,
                      child: Column(
                        children: [
                          WishlistHeart(sku: widget.sku),
                          IconButton(
                            onPressed: () => _share(context),
                            icon: const Icon(
                              Icons.share_outlined,
                              color: AppColors.inkHeading,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
        // Thumbnail strip beneath the main image (per Figma) — tap to switch.
        if (images.length > 1)
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => _controller.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                ),
                child: Container(
                  width: 56,
                  height: 56,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: i == _index
                          ? AppColors.brandPrimary
                          : AppColors.inkMuted.withValues(alpha: 0.25),
                      width: i == _index ? 2 : 1,
                    ),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: images[i],
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: AppColors.surfaceTint),
                    errorWidget: (_, __, ___) =>
                        Container(color: AppColors.surfaceTint),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.price,
    required this.product,
    required this.showStruck,
  });

  final Money? price;
  final ProductDetail product;
  final bool showStruck;

  @override
  Widget build(BuildContext context) {
    if (price == null) return const SizedBox.shrink();
    final regular = product.regularPrice;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          price!.formatted(),
          textDirection: TextDirection.ltr,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.brandPrimary,
          ),
        ),
        if (showStruck && product.isOnSale && regular != null) ...[
          const SizedBox(width: 12),
          Text(
            regular.formatted(),
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              decoration: TextDecoration.lineThrough,
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ],
    );
  }
}

class _OptionSelector extends StatelessWidget {
  const _OptionSelector({
    required this.option,
    required this.selectedValue,
    required this.onSelect,
  });

  final ConfigurableOption option;
  final int? selectedValue;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            option.label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in option.values)
                ChoiceChip(
                  label: Text(value.label),
                  selected: selectedValue == value.valueIndex,
                  onSelected: (_) => onSelect(value.valueIndex),
                  avatar: value.swatchColor != null
                      ? CircleAvatar(
                          backgroundColor: _parseColor(value.swatchColor!),
                        )
                      : null,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color? _parseColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length != 6) return null;
    final value = int.tryParse(cleaned, radix: 16);
    return value == null ? null : Color(0xFF000000 | value);
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.current, required this.onTab});
  final int current;
  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = [l10n.tabDescription, l10n.tabDetails, l10n.tabReviews];
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: ChoiceChip(
              label: Text(labels[i]),
              selected: current == i,
              onSelected: (_) => onTab(i),
            ),
          ),
      ],
    );
  }
}

class _AddToCartButton extends ConsumerWidget {
  const _AddToCartButton({
    required this.product,
    required this.selection,
    required this.variant,
  });

  final ProductDetail product;
  final Map<String, int> selection;
  final ProductVariant? variant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final inStock = variant?.inStock ?? product.inStock;
    if (!inStock) {
      return Text(
        l10n.productOutOfStock,
        style: const TextStyle(color: AppColors.accentSale),
      );
    }
    final needsSelection = product.isConfigurable && variant == null;
    final isMutating = ref.watch(
      cartControllerProvider.select((s) => s.isMutating),
    );
    final enabled = !needsSelection && !isMutating;

    return FilledButton(
      onPressed: enabled ? () => _add(context, ref, l10n) : null,
      child: isMutating
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(l10n.productAddToCart),
    );
  }

  Future<void> _add(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final uids = <String>[];
    for (final option in product.options) {
      final selectedIndex = selection[option.attributeCode];
      for (final value in option.values) {
        if (value.valueIndex == selectedIndex && value.uid != null) {
          uids.add(value.uid!);
        }
      }
    }
    try {
      await ref
          .read(cartControllerProvider.notifier)
          .addToCart(sku: product.sku, selectedOptionUids: uids);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.cartAdded)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
      }
    }
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final ProductReview review;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                Icon(
                  i <= review.stars ? Icons.star : Icons.star_border,
                  size: 16,
                  color: AppColors.accentGold,
                ),
              const SizedBox(width: 8),
              Text(
                review.nickname,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (review.summary.isNotEmpty)
            Text(
              review.summary,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          if (review.text.isNotEmpty)
            Text(
              review.text,
              style: const TextStyle(color: AppColors.inkMuted),
            ),
          if (review.date.isNotEmpty)
            Text(
              review.date,
              style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
            ),
        ],
      ),
    );
  }
}

class _TabContent extends StatelessWidget {
  const _TabContent({required this.product, required this.tab});
  final ProductDetail product;
  final int tab;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (tab) {
      case 1:
        return Row(
          children: [
            Text(
              '${l10n.specSku}: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(product.sku),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.hasReviews) ...[
              Text(
                l10n.reviewsSummary(product.ratingSummary, product.reviewCount),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              for (final review in product.reviews) _ReviewCard(review: review),
            ] else ...[
              Text(
                l10n.reviewsEmptyTitle,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.reviewsEmptyBody,
                style: const TextStyle(color: AppColors.inkMuted),
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.review(product.sku)),
              icon: const Icon(Icons.rate_review_outlined),
              label: Text(l10n.reviewsWrite),
            ),
          ],
        );
      case 0:
      default:
        return Text(product.description ?? l10n.stateEmpty);
    }
  }
}
