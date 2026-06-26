import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../domain/aggregation.dart';

/// Result of the filter sheet: the selected attribute facets plus an optional
/// price range (null bounds = unbounded on that side).
class FilterResult {
  const FilterResult({required this.attributes, this.priceFrom, this.priceTo});

  final Map<String, Set<String>> attributes;
  final double? priceFrom;
  final double? priceTo;
}

/// Aggregation-driven filter bottom sheet. Attribute facets are built
/// dynamically from `products.aggregations`; the `price` facet is rendered as a
/// range slider whose bounds are derived from the price aggregation buckets.
/// Returns a [FilterResult] on Apply.
class FilterSheet extends StatefulWidget {
  const FilterSheet({
    super.key,
    required this.aggregations,
    required this.initial,
    required this.currency,
    this.initialPriceFrom,
    this.initialPriceTo,
  });

  final List<Aggregation> aggregations;
  final Map<String, Set<String>> initial;
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
      priceFrom: narrowed ? _price.start : null,
      priceTo: narrowed ? _price.end : null,
    );
  }

  String _money(double v) => '${widget.currency} ${v.round()}';

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
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
            child: Row(
              children: [
                Text(
                  l10n.filtersLabel,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clear,
                  child: Text(l10n.clearLabel),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: (facets.isEmpty && bounds == null)
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(l10n.stateEmpty),
                  )
                : ListView(
                    shrinkWrap: true,
                    children: [
                      if (bounds != null)
                        ExpansionTile(
                          title: Text(l10n.filterPriceLabel),
                          initiallyExpanded: true,
                          childrenPadding: const EdgeInsetsDirectional.fromSTEB(
                            16,
                            0,
                            16,
                            8,
                          ),
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _money(_price.start),
                                  textDirection: TextDirection.ltr,
                                ),
                                Text(
                                  _money(_price.end),
                                  textDirection: TextDirection.ltr,
                                ),
                              ],
                            ),
                            RangeSlider(
                              min: bounds.$1,
                              max: bounds.$2,
                              values: _price,
                              labels: RangeLabels(
                                _money(_price.start),
                                _money(_price.end),
                              ),
                              onChanged: (v) => setState(() => _price = v),
                            ),
                          ],
                        ),
                      for (final facet in facets)
                        ExpansionTile(
                          title: Text(facet.label),
                          initiallyExpanded: true,
                          childrenPadding: EdgeInsets.zero,
                          children: [
                            for (final option in facet.options)
                              CheckboxListTile(
                                value:
                                    _selection[facet.attributeCode]?.contains(
                                      option.value,
                                    ) ??
                                    false,
                                onChanged: (_) =>
                                    _toggle(facet.attributeCode, option.value),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                dense: true,
                                title: Text(
                                  '${option.label} (${option.count})',
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_result()),
                child: Text(l10n.applyLabel),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
