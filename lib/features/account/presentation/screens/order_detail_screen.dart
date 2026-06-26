import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../../catalog/domain/money.dart';
import '../../domain/order.dart';

/// Full detail for a single placed order, navigated to with the [CustomerOrder]
/// via go_router `extra` (the list already holds every field, so no extra
/// query). Shows items, totals, shipping method and shipment tracking.
class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.orderDetailsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.orderNumber(order.number),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            '${order.date} · ${order.status}',
            style: const TextStyle(color: AppColors.inkMuted),
          ),
          const SizedBox(height: 24),

          _SectionTitle(l10n.orderItemsSection),
          for (final line in order.lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text('${line.quantity.toInt()} × ${line.name}')),
                  if (line.price != null)
                    Text(
                      line.price!.formatted(),
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(color: AppColors.inkMuted),
                    ),
                ],
              ),
            ),

          const Divider(height: 32),
          if (order.subtotal != null)
            _TotalRow(label: l10n.cartSubtotal, amount: order.subtotal!),
          if (order.shippingAmount != null)
            _TotalRow(label: l10n.orderShippingLabel, amount: order.shippingAmount!),
          if (order.total != null)
            _TotalRow(label: l10n.cartTotal, amount: order.total!, emphasize: true),

          if (order.shippingMethod != null &&
              order.shippingMethod!.isNotEmpty) ...[
            const Divider(height: 32),
            _SectionTitle(l10n.checkoutShippingMethod),
            Text(
              [order.carrier, order.shippingMethod]
                  .where((s) => s != null && s.isNotEmpty)
                  .join(' · '),
            ),
          ],

          const Divider(height: 32),
          _SectionTitle(l10n.orderTrackingSection),
          if (!order.hasTracking)
            Text(
              l10n.orderNoTracking,
              style: const TextStyle(color: AppColors.inkMuted),
            )
          else
            for (final t in order.trackings)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.local_shipping_outlined,
                  color: AppColors.brandPrimary,
                ),
                title: Text(
                  [t.carrier, t.title].where((s) => s.isNotEmpty).join(' · '),
                ),
                subtitle: Text(t.number, textDirection: TextDirection.ltr),
                trailing: IconButton(
                  icon: const Icon(Icons.copy_outlined),
                  tooltip: l10n.orderTrackingSection,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: t.number));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.orderTrackingCopied)),
                      );
                    }
                  },
                ),
              ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.amount,
    this.emphasize = false,
  });

  final String label;
  final Money amount;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? const TextStyle(fontWeight: FontWeight.w700)
        : const TextStyle(color: AppColors.inkMuted);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(
            amount.formatted(),
            textDirection: TextDirection.ltr,
            style: emphasize
                ? const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandPrimary,
                  )
                : style,
          ),
        ],
      ),
    );
  }
}
