import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/shell/marketing_footer.dart';
import '../../../../app/shell/zoonze_scaffold.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/store/store_controller.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/failure_message.dart';
import '../../../../l10n/l10n.dart';
import '../../data/catalog_repository.dart';
import '../plp_controller.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/product_card.dart';

/// Product listing for a category: aggregation-driven filters, sort, and
/// append-on-scroll pagination.
class PlpScreen extends ConsumerStatefulWidget {
  const PlpScreen({super.key, required this.categoryUid, this.title});

  final String categoryUid;
  final String? title;

  @override
  ConsumerState<PlpScreen> createState() => _PlpScreenState();
}

class _PlpScreenState extends ConsumerState<PlpScreen> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  PlpController get _controller =>
      ref.read(plpControllerProvider(widget.categoryUid).notifier);

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
      _controller.loadMore();
    }
  }

  String _sortLabel(AppLocalizations l10n, ProductSortField sort) =>
      switch (sort) {
        ProductSortField.relevance => l10n.sortRelevance,
        ProductSortField.priceAsc => l10n.sortPriceLowHigh,
        ProductSortField.priceDesc => l10n.sortPriceHighLow,
        ProductSortField.nameAsc => l10n.sortNameAz,
        ProductSortField.newest => l10n.sortNewest,
      };

  Future<void> _openFilters(PlpState state) async {
    final currency = ref.read(storeControllerProvider).currency;
    final result = await showModalBottomSheet<FilterResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => FilterSheet(
        aggregations: state.aggregations,
        initial: state.selectedFilters,
        currency: currency,
        initialPriceFrom: state.priceFrom,
        initialPriceTo: state.priceTo,
      ),
    );
    if (result != null) {
      _controller.applyFilters(
        result.attributes,
        priceFrom: result.priceFrom,
        priceTo: result.priceTo,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(plpControllerProvider(widget.categoryUid));
    return ZoonzeScaffold(
      currentTab: AppTab.categories,
      body: _body(l10n, state),
    );
  }

  Widget _body(AppLocalizations l10n, PlpState state) {
    if (state.isLoading && state.products.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (state.error != null && state.products.isEmpty) {
      final error = state.error;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error is Failure
                    ? failureMessage(context, error)
                    : l10n.errorGeneric,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _controller.refresh,
                child: Text(l10n.actionRetry),
              ),
            ],
          ),
        ),
      );
    }
    return CustomScrollView(
      controller: _scroll,
      slivers: [
        SliverToBoxAdapter(
          child: _Header(
            title: widget.title ?? l10n.navCategories,
            state: state,
            sortLabel: _sortLabel(l10n, state.sort),
            onSort: _controller.setSort,
            sortLabelFor: (s) => _sortLabel(l10n, s),
            onFilters: () => _openFilters(state),
          ),
        ),
        if (state.products.isEmpty)
          SliverToBoxAdapter(
            child: EmptyState(
              icon: Icons.inventory_2_outlined,
              title: l10n.stateEmpty,
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.58,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final product = state.products[index];
                return ProductCard(
                  product: product,
                  onTap: () => context.push(AppRoutes.product(product.urlKey)),
                );
              }, childCount: state.products.length),
            ),
          ),
        if (state.isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        const SliverToBoxAdapter(child: MarketingFooter()),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.state,
    required this.sortLabel,
    required this.onSort,
    required this.sortLabelFor,
    required this.onFilters,
  });

  final String title;
  final PlpState state;
  final String sortLabel;
  final ValueChanged<ProductSortField> onSort;
  final String Function(ProductSortField) sortLabelFor;
  final VoidCallback onFilters;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            l10n.resultsCount(state.totalCount),
            style: const TextStyle(color: AppColors.inkMuted),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onFilters,
                  icon: const Icon(Icons.tune),
                  label: Text(
                    state.activeFilterCount > 0
                        ? '${l10n.filtersLabel} (${state.activeFilterCount})'
                        : l10n.filtersLabel,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PopupMenuButton<ProductSortField>(
                  onSelected: onSort,
                  itemBuilder: (_) => [
                    for (final sort in ProductSortField.values)
                      PopupMenuItem<ProductSortField>(
                        value: sort,
                        child: Text(sortLabelFor(sort)),
                      ),
                  ],
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.inkMuted.withValues(alpha: 0.4),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sort, size: 18),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            sortLabel,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
