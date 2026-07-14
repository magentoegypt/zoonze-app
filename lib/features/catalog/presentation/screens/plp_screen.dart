import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/shell/marketing_footer.dart';
import '../../../../app/shell/zoonze_scaffold.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/theme_x.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/store/store_controller.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/failure_message.dart';
import '../../../../l10n/l10n.dart';
import '../../data/catalog_repository.dart';
import '../../domain/category.dart';
import '../catalog_providers.dart';
import '../plp_controller.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/product_card.dart';
import '../widgets/product_skeletons.dart';
import '../widgets/sort_sheet.dart';

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

  /// Selected sub-category chip — null means "All" (the parent category).
  String? _selectedSubUid;

  /// The category whose products the grid currently lists.
  String get _effectiveUid => _selectedSubUid ?? widget.categoryUid;

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
      ref.read(plpControllerProvider(_effectiveUid).notifier);

  void _selectSub(String? uid) {
    if (uid == _selectedSubUid) return;
    setState(() => _selectedSubUid = uid);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
      _controller.loadMore();
    }
  }

  Future<void> _openFilters(PlpState state) async {
    final currency = ref.read(storeControllerProvider).currency;
    final result = await showModalBottomSheet<FilterResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => FilterSheet(
        aggregations: state.aggregations,
        initial: state.selectedFilters,
        currency: currency,
        initialPriceFrom: state.priceFrom,
        initialPriceTo: state.priceTo,
        initialMinDiscount: state.minDiscount,
        initialMinRating: state.minRating,
      ),
    );
    if (result != null) {
      _controller.applyFilters(
        result.attributes,
        priceFrom: result.priceFrom,
        priceTo: result.priceTo,
        minDiscount: result.minDiscount,
        minRating: result.minRating,
      );
    }
  }

  Future<void> _openSort(PlpState state) async {
    final selected = await showModalBottomSheet<ProductSortField>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => SortSheet(current: state.sort),
    );
    if (selected != null) _controller.setSort(selected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(plpControllerProvider(_effectiveUid));
    // Sub-category chips come from the parent category's navigable children.
    final parent = ref
        .watch(categoryByUidProvider(widget.categoryUid))
        .valueOrNull;
    final subcats = (parent?.children ?? const <Category>[])
        .where((c) => c.includeInMenu)
        .toList(growable: false);
    return ZoonzeScaffold(
      currentTab: AppTab.categories,
      body: _body(l10n, state, subcats),
    );
  }

  Widget _body(AppLocalizations l10n, PlpState state, List<Category> subcats) {
    if (state.isLoading && state.products.isEmpty) {
      // Keep the title stable and show shaped card placeholders.
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 12),
            child: Text(
              widget.title ?? l10n.navCategories,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Divider(height: 1, thickness: 1, color: context.hairline),
          const ProductGridSkeleton(childAspectRatio: 0.66, count: 6),
        ],
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
            subcats: subcats,
            selectedSubUid: _selectedSubUid,
            onSelectSub: _selectSub,
            onFilters: () => _openFilters(state),
            onSort: () => _openSort(state),
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
                // Figma card ≈ 173×237–253 (image 158 + name/price panel).
                childAspectRatio: 0.66,
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
            child: ProductGridSkeleton(childAspectRatio: 0.66, count: 2),
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
    required this.subcats,
    required this.selectedSubUid,
    required this.onSelectSub,
    required this.onFilters,
    required this.onSort,
  });

  final String title;
  final PlpState state;
  final List<Category> subcats;
  final String? selectedSubUid;
  final ValueChanged<String?> onSelectSub;
  final VoidCallback onFilters;
  final VoidCallback onSort;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filtersLabel = state.activeFilterCount > 0
        ? '${l10n.filtersLabel} (${state.activeFilterCount})'
        : l10n.filtersLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 12),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Divider(height: 1, thickness: 1, color: context.hairline),
        if (subcats.isNotEmpty)
          _SubcategoryChips(
            subcats: subcats,
            selectedUid: selectedSubUid,
            onSelect: onSelectSub,
          ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.categoryProductCount(state.totalCount),
                  style: TextStyle(
                    color: context.scaffoldMuted,
                    fontSize: 12.5,
                  ),
                ),
              ),
              // Two separate controls — Sort and Filter (QA 86d3m97au).
              _PillButton(
                icon: Icons.swap_vert,
                label: l10n.sortLabel,
                onTap: onSort,
              ),
              const SizedBox(width: 8),
              _PillButton(
                icon: Icons.tune,
                label: filtersLabel,
                onTap: onFilters,
              ),
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: context.hairline),
      ],
    );
  }
}

/// Horizontally scrollable sub-category filter pills (Figma `subcats`). "All"
/// resets to the parent category.
class _SubcategoryChips extends StatelessWidget {
  const _SubcategoryChips({
    required this.subcats,
    required this.selectedUid,
    required this.onSelect,
  });

  final List<Category> subcats;
  final String? selectedUid;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 10),
      child: Row(
        children: [
          _Chip(
            label: l10n.filterAll,
            selected: selectedUid == null,
            onTap: () => onSelect(null),
          ),
          for (final c in subcats) ...[
            const SizedBox(width: 8),
            _Chip(
              label: c.name,
              selected: selectedUid == c.uid,
              onTap: () => onSelect(c.uid),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandPrimary : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(999),
          border: selected
              ? null
              : Border.all(color: AppColors.borderDefault),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? Colors.white : AppColors.inkMuted,
          ),
        ),
      ),
    );
  }
}

/// Bordered pill shell for the compact Filters / Sort controls.
class _Pill extends StatelessWidget {
  const _Pill({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
    decoration: BoxDecoration(
      border: Border.all(color: context.hairline),
      borderRadius: BorderRadius.circular(999),
    ),
    child: child,
  );
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(999),
    child: _Pill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // White in dark mode — these pills sit on the scaffold, so the ink
          // colour was invisible on dark (QA: filter/sort tabs need white).
          Icon(icon, size: 16, color: context.scaffoldHeading),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: context.scaffoldHeading,
            ),
          ),
        ],
      ),
    ),
  );
}
