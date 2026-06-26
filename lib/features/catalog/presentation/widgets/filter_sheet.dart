import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../domain/aggregation.dart';

/// Aggregation-driven filter bottom sheet. Facets are built dynamically from
/// `products.aggregations` (the `price` range facet is handled separately and
/// excluded here). Returns the selected `attribute_code -> values` map on Apply.
class FilterSheet extends StatefulWidget {
  const FilterSheet({
    super.key,
    required this.aggregations,
    required this.initial,
  });

  final List<Aggregation> aggregations;
  final Map<String, Set<String>> initial;

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late final Map<String, Set<String>> _selection = {
    for (final entry in widget.initial.entries) entry.key: {...entry.value},
  };

  void _toggle(String code, String value) {
    setState(() {
      final set = _selection.putIfAbsent(code, () => <String>{});
      if (!set.add(value)) set.remove(value);
      if (set.isEmpty) _selection.remove(code);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final facets = widget.aggregations
        .where((a) => a.attributeCode != 'price' && a.options.isNotEmpty)
        .toList();

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
            child: Row(
              children: [
                Text(l10n.filtersLabel,
                    style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(_selection.clear),
                  child: Text(l10n.clearLabel),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: facets.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(l10n.stateEmpty),
                  )
                : ListView(
                    shrinkWrap: true,
                    children: [
                      for (final facet in facets)
                        ExpansionTile(
                          title: Text(facet.label),
                          initiallyExpanded: true,
                          childrenPadding: EdgeInsets.zero,
                          children: [
                            for (final option in facet.options)
                              CheckboxListTile(
                                value: _selection[facet.attributeCode]
                                        ?.contains(option.value) ??
                                    false,
                                onChanged: (_) =>
                                    _toggle(facet.attributeCode, option.value),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                dense: true,
                                title: Text('${option.label} (${option.count})'),
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
                onPressed: () => Navigator.of(context).pop(_selection),
                child: Text(l10n.applyLabel),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
