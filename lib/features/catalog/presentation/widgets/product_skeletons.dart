import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/shimmer.dart';

/// A loading placeholder shaped like [ProductCard]: a white bordered card with a
/// full-bleed image block on top and a name + price panel below. The white card
/// surface stays white — only the inner grey blocks shimmer (the [Shimmer] sits
/// inside the card, not over it).
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.borderDefault),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Shimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area — clipped to the card's rounded corners.
            Expanded(child: SkeletonBox(borderRadius: 0)),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Two name lines (second shorter) + a price line.
                  SkeletonBox(height: 11, borderRadius: 4),
                  SizedBox(height: 6),
                  FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: 0.7,
                    child: SkeletonBox(height: 11, borderRadius: 4),
                  ),
                  SizedBox(height: 10),
                  FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: 0.45,
                    child: SkeletonBox(height: 13, borderRadius: 4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A non-scrolling 2-column grid of [ProductCardSkeleton]s, mirroring the real
/// product grids. [childAspectRatio] matches the screen it stands in for
/// (PLP `0.66`, Home rails `0.58`).
class ProductGridSkeleton extends StatelessWidget {
  const ProductGridSkeleton({
    super.key,
    required this.childAspectRatio,
    this.count = 6,
    this.padding = const EdgeInsets.all(16),
  });

  final double childAspectRatio;
  final int count;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: count,
      itemBuilder: (_, __) => const ProductCardSkeleton(),
    );
  }
}
