import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/network_image.dart';
import '../../domain/category.dart';
import '../catalog_providers.dart';

/// The storefront's sub-category rail (`.beauty-subcats`), rebuilt for the app.
///
/// A horizontally scrolling row of round photo tiles with the category name
/// beneath, sized to the site's own mobile breakpoint: an 84px circle on a
/// blush ground, 13px label, 18px between cards.
///
/// Categories below the top level have no `image` on this store, so the rail
/// resolves stand-ins from [categoryThumbnailsProvider] — the first product in
/// each category, the same substitution the website makes. A category with no
/// products keeps the empty blush circle rather than borrowing someone else's
/// photo; the website leaves those blank too.
class CategoryCircleRail extends ConsumerWidget {
  const CategoryCircleRail({
    super.key,
    required this.categories,
    required this.onTap,
    this.selectedUid,
  });

  final List<Category> categories;
  final ValueChanged<Category> onTap;

  /// Highlighted card, if one of these is the active filter.
  final String? selectedUid;

  static const double _circle = 84;
  static const double _cardWidth = 84;

  /// Circle + 10px gap + two lines of 13px label, matching the site card.
  static const double railHeight = _circle + 10 + 34;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (categories.isEmpty) return const SizedBox.shrink();
    // Only the ones missing an image cost a lookup; an empty key short-circuits
    // inside the provider, so a fully illustrated level issues no query at all.
    final thumbnails =
        ref
            .watch(categoryThumbnailsProvider(categoryThumbnailKey(categories)))
            .valueOrNull ??
        const <String, String>{};

    return SizedBox(
      height: railHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 18),
        itemBuilder: (context, index) {
          final category = categories[index];
          return _CategoryCircle(
            category: category,
            imageUrl: (category.image ?? '').isNotEmpty
                ? category.image
                : thumbnails[category.uid],
            selected: category.uid == selectedUid,
            onTap: () => onTap(category),
          );
        },
      ),
    );
  }
}

class _CategoryCircle extends StatelessWidget {
  const _CategoryCircle({
    required this.category,
    required this.imageUrl,
    required this.selected,
    required this.onTap,
  });

  final Category category;
  final String? imageUrl;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: CategoryCircleRail._cardWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: CategoryCircleRail._circle,
              height: CategoryCircleRail._circle,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceTint,
                // Selection reads as the burgundy ring the site shows on hover.
                border: Border.all(
                  color: selected
                      ? AppColors.brandPrimary
                      : const Color(0x2EB76E79),
                  width: selected ? 2 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: ZoonzeImage(
                url: imageUrl,
                decodeWidth: CategoryCircleRail._circle,
                // An empty circle is the correct answer for a category with no
                // products — don't dress it up with a glyph the site lacks.
                error: (_) => const SizedBox.shrink(),
                placeholder: (_) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              category.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                height: 1.25,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? AppColors.brandPrimary
                    : AppColors.inkHeading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
