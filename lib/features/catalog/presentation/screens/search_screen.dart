import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/store/store_controller.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/failure_message.dart';
import '../../../../l10n/l10n.dart';
import '../plp_controller.dart';
import '../search_controller.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/product_card.dart';
import '../widgets/product_skeletons.dart';

/// Native catalogue search (`products(search:)`). If Live Search is later
/// confirmed (Open Q §4), swap the provider to the productSearch schema.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery});

  /// Optional pre-filled query (e.g. tapping a brand on the home screen).
  final String? initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    final initial = widget.initialQuery?.trim() ?? '';
    if (initial.isNotEmpty) {
      _controller.text = initial;
      _query = initial;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            border: InputBorder.none,
          ),
          onSubmitted: (value) => setState(() => _query = value.trim()),
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: _query.isEmpty
          ? EmptyState(icon: Icons.search, title: l10n.searchHint)
          : _Results(query: _query),
    );
  }
}

/// Search results grid with a "Search results for …" header and the shared
/// aggregation-driven Filters + Sort sheet (same engine as the PLP).
class _Results extends ConsumerStatefulWidget {
  const _Results({required this.query});
  final String query;

  @override
  ConsumerState<_Results> createState() => _ResultsState();
}

class _ResultsState extends ConsumerState<_Results> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant _Results old) {
    super.didUpdateWidget(old);
    // New query → jump back to the top of the (now different) result set.
    if (old.query != widget.query && _scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  SearchResultsController get _controller =>
      ref.read(searchControllerProvider(widget.query).notifier);

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
        initialSort: state.sort,
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
        sort: result.sort,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(searchControllerProvider(widget.query));

    if (state.isLoading && state.products.isEmpty) {
      return ListView(
        children: [
          _Header(
            query: widget.query,
            state: state,
            onFilters: () => _openFilters(state),
          ),
          const ProductGridSkeleton(childAspectRatio: 0.58, count: 6),
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
            query: widget.query,
            state: state,
            onFilters: () => _openFilters(state),
          ),
        ),
        if (state.products.isEmpty)
          SliverToBoxAdapter(
            child: EmptyState(
              icon: Icons.search_off_outlined,
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
            child: ProductGridSkeleton(childAspectRatio: 0.58, count: 2),
          ),
      ],
    );
  }
}

/// "Search results for …" title + the result count and the Filters/Sort pill.
class _Header extends StatelessWidget {
  const _Header({
    required this.query,
    required this.state,
    required this.onFilters,
  });

  final String query;
  final PlpState state;
  final VoidCallback onFilters;

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
          padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 4),
          child: Text(
            l10n.searchResultsFor(query),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 12),
          child: Row(
            children: [
              Text(
                l10n.resultsCount(state.totalCount),
                style: const TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 12.5,
                ),
              ),
              const Spacer(),
              _PillButton(
                icon: Icons.tune,
                label: filtersLabel,
                onTap: onFilters,
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: AppColors.borderDefault),
      ],
    );
  }
}

/// Bordered Filters/Sort pill (mirrors the PLP header control).
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
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderDefault),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.inkHeading),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.inkHeading),
          ),
        ],
      ),
    ),
  );
}
