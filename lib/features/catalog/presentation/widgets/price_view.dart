import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/product.dart';

/// Stacked price: bold burgundy final price over a muted, struck-through regular
/// price when the product is on sale.
class PriceView extends StatelessWidget {
  const PriceView({super.key, required this.product, this.alignEnd = false});

  final Product product;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final regular = product.regularPrice;
    final effective = product.finalPrice ?? regular;
    if (effective == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          effective.formatted(),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.brandPrimary,
            fontSize: 15,
          ),
        ),
        if (product.isOnSale && regular != null)
          Text(
            regular.formatted(),
            style: const TextStyle(
              decoration: TextDecoration.lineThrough,
              color: AppColors.inkMuted,
              fontSize: 12,
            ),
          ),
      ],
    );
  }
}
