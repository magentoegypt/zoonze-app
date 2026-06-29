import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../data/catalog_repository.dart';
import '../../domain/aggregation.dart';

/// Result of the filter sheet: the chosen sort, the selected attribute facets,
/// plus an optional price range (null bounds = unbounded on that side).
class FilterResult {
  const FilterResult({
    required this.attributes,
    required this.sort,
    this.priceFrom,
    this.priceTo,
  });

  final Map<String, Set<String>> attributes;
  final ProductSortField sort;
  final double? priceFrom;
  final double? priceTo;
}

/// Aggregation-driven filter + sort bottom sheet (Figma "Filters (Sheet)").
/// Flat labelled sections: Sort By (chips), Price Range (slider), then one
/// section per attribute facet from `products.aggregations`. The `price` facet
/// drives the slider bounds. Returns a [FilterResult] on Apply.
class FilterSheet extends StatefulWidget {
  const FilterSheet({
    super.key,
    required this.aggregations,
    required this.initial,
    required this.initialSort,
    required this.currency,
    this.initialPriceFrom,
    this.initialPriceTo,
  });

  final List<Aggregation> aggregations;
  final Map<String, Set<String>> initial;
  final ProductSortField initialSort;
  final String currency;
  final double? initialPriceFrom;
  final double? initialPriceTo;

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late final Map<String, Set<String>> _selection = {
    for (final entry in widget.initial.entries) entry.key: {...entry.value},
  };

  late ProductSortField _sort = widget.initialSort;

  /// Overall price bounds parsed from the price aggregation, or null when the
  /// catalogue exposes no usable price facet.
  (double, double)? _bounds;
  late RangeValues _price;

  @override
  void initState() {
    super.initState();
    _bounds = _priceBounds();
    final b = _bounds;
    if (b != null) {
      final from = (widget.initialPriceFrom ?? b.$1).clamp(b.$1, b.$2);
      final to = (widget.initialPriceTo ?? b.$2).clamp(b.$1, b.$2);
      _price = RangeValues(from, to <= from ? b.$2 : to);
    }
  }

  (double, double)? _priceBounds() {
    Aggregation? price;
    for (final a in widget.aggregations) {
      if (a.attributeCode == 'price') {
        price = a;
        break;
      }
    }
    if (price == null) return null;
    final nums = <double>[];
    for (final option in price.options) {
      for (final token in option.value.split(RegExp(r'[^0-9.]+'))) {
        final n = double.tryParse(token);
        if (n != null) nums.add(n);
      }
    }
    if (nums.length < 2) return null;
    nums.sort();
    final lo = nums.first;
    final hi = nums.last;
    return hi > lo ? (lo, hi) : null;
  }

  void _toggle(String code, String value) {
    setState(() {
      final set = _selection.putIfAbsent(code, () => <String>{});
      if (!set.add(value)) set.remove(value);
      if (set.isEmpty) _selection.remove(code);
    });
  }

  void _clear() {
    setState(() {
      _selection.clear();
      _sort = ProductSortField.relevance;
      final b = _bounds;
      if (b != null) _price = RangeValues(b.$1, b.$2);
    });
  }

  FilterResult _result() {
    final b = _bounds;
    // Only treat the price as an active filter when the user narrowed it.
    final narrowed = b != null && (_price.start > b.$1 || _price.end < b.$2);
    return FilterResult(
      attributes: _selection,
      sort: _sort,
      priceFrom: narrowed ? _price.start : null,
      priceTo: narrowed ? _price.end : null,
    );
  }

  String _money(double v) => '${widget.currency} ${v.round()}';

  String _sortLabel(AppLocalizations l10n, ProductSortField sort) =>
      switch (sort) {
        ProductSortField.relevance => l10n.sortRelevance,
        ProductSortField.priceAsc => l10n.sortPriceLowHigh,
        ProductSortField.priceDesc => l10n.sortPriceHighLow,
        ProductSortField.nameAsc => l10n.sortNameAz,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final facets = widget.aggregations
        .where((a) => a.attributeCode != 'price' && a.options.isNotEmpty)
        .toList();
    final bounds = _bounds;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header — title + Reset.
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 12, 8),
            child: Row(
              children: [
                Text(
                  l10n.filtersLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clear,
                  child: Text(
                    l10n.filterResetLabel,
                    style: const TextStyle(color: AppColors.brandPrimary),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.borderDefault),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: [
                // Sort By.
                const _SectionLabel(),
                Builder(
                  builder: (context) => Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final sort in ProductSortField.values)
                          _SortChip(
                            label: _sortLabel(l10n, sort),
                            selected: _sort == sort,
                            onTap: () => setState(() => _sort = sort),
                          ),
                      ],
                    ),
                  ),
                ),
                // Price Range.
                if (bounds != null) ...[
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(20, 4, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.filterPriceRangeLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: AppColors.inkHeading,
                            ),
                          ),
                        ),
                        Text(
                          '${_money(_price.start)} — ${_money(_price.end)}',
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                            color: AppColors.brandPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 4),
                    child: RangeSlider(
                      min: bounds.$1,
                      max: bounds.$2,
                      values: _price,
                      labels: RangeLabels(
                        _money(_price.start),
                        _money(_price.end),
                      ),
                      onChanged: (v) => setState(() => _price = v),
                    ),
                  ),
                ],
                // Attribute facets (Brand, …).
                for (final facet in facets) ...[
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.borderDefault,
                  ),
                  _SectionLabel(text: facet.label),
                  for (final option in facet.options)
                    _FacetRow(
                      label: option.label,
                      count: option.count,
                      selected:
                          _selection[facet.attributeCode]?.contains(
                            option.value,
                          ) ??
                          false,
                      onTap: () => _toggle(facet.attributeCode, option.value),
                    ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.borderDefault),
          // Footer — Clear All (fixed 120) + Apply Filters (fills). Figma 68:70.
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 16),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _clear,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.inkHeading,
                      side: const BorderSide(
                        color: AppColors.borderDefault,
                        width: 1.4,
                      ),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(l10n.filterClearAllLabel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(_result()),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Text(l10n.filterApplyLabel),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A section header label. When [text] is null it renders the localized
/// "Sort By" (the first, sort section).
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({this.text});
  final String? text;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 20, 10),
      child: Text(
        text ?? l10n.filterSortByLabel,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: AppColors.inkHeading,
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

/// One selectable facet option: rounded-square checkbox · label · right-aligned
/// count (Figma Brand row).
class _FacetRow extends StatelessWidget {
  const _FacetRow({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 9, 20, 9),
        child: Row(
          children: [
            _CheckSquare(selected: selected),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.inkHeading,
                ),
              ),
            ),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckSquare extends StatelessWidget {
  const _CheckSquare({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
    width: 22,
    height: 22,
    decoration: BoxDecoration(
      color: selected ? AppColors.brandPrimary : Colors.white,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(
        color: selected ? AppColors.brandPrimary : AppColors.borderDefault,
        width: 1.5,
      ),
    ),
    child: selected
        ? const Icon(Icons.check, size: 14, color: Colors.white)
        : null,
  );
}
