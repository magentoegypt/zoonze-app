import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/shell/marketing_footer.dart';
import '../../../../app/shell/zoonze_scaffold.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../l10n/l10n.dart';
import '../catalog_providers.dart';
import '../widgets/product_card.dart';

/// Product listing for a category (first page). Aggregations-driven filters,
/// sort, and pagination land in the PLP-filters slice.
class PlpScreen extends ConsumerWidget {
  const PlpScreen({super.key, required this.categoryUid, this.title});

  final String categoryUid;
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final page = ref.watch(categoryProductsProvider(categoryUid));

    return ZoonzeScaffold(
      currentTab: AppTab.categories,
      body: AsyncValueView(
        value: page,
        onRetry: () => ref.invalidate(categoryProductsProvider(categoryUid)),
        data: (productPage) {
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text(
                  title ?? l10n.navCategories,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              if (productPage.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(child: Text(l10n.stateEmpty)),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.62,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: productPage.items.length,
                  itemBuilder: (context, index) {
                    final product = productPage.items[index];
                    return ProductCard(
                      product: product,
                      onTap: () =>
                          context.push(AppRoutes.product(product.urlKey)),
                    );
                  },
                ),
              const MarketingFooter(),
            ],
          );
        },
      ),
    );
  }
}
