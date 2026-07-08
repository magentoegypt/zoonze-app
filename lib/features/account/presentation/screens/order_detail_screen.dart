import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../../catalog/domain/money.dart';
import '../../domain/order.dart';
import '../order_format.dart';

/// Full detail for a single placed order, navigated to with the [CustomerOrder]
/// via go_router `extra` (the list already holds every field, so no extra
/// query). Shows items, totals, shipping method and shipment tracking.
class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
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
            '${orderFmtDate(order.date, locale)} · ${order.status}',
            style: const TextStyle(color: AppColors.inkMuted),
          ),
          const SizedBox(height: 24),

          _SectionTitle(l10n.orderItemsSection),
          for (final line in order.lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  _DetailThumb(url: line.imageUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('${line.quantity.toInt()} × ${line.name}'),
                  ),
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

          if (order.paymentMethodName != null &&
              order.paymentMethodName!.isNotEmpty) ...[
            const Divider(height: 32),
            _SectionTitle(l10n.orderPaymentSection),
            Text(order.paymentMethodName!),
          ],

          if (order.shippingAddress != null &&
              order.shippingAddress!.isNotEmpty) ...[
            const Divider(height: 32),
            _SectionTitle(l10n.orderDeliveryAddress),
            _AddressBlock(
              name: order.shippingName,
              address: order.shippingAddress!,
            ),
          ],

          if (order.billingAddress != null &&
              order.billingAddress!.isNotEmpty) ...[
            const Divider(height: 32),
            _SectionTitle(l10n.orderBillingAddress),
            _AddressBlock(
              name: order.billingName,
              address: order.billingAddress!,
            ),
          ],

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

          if (order.comments.isNotEmpty) ...[
            const Divider(height: 32),
            _SectionTitle(l10n.orderTimelineSection),
            for (final c in order.comments.reversed)
              _TimelineRow(
                message: c.message,
                timestamp: orderFmtDateTime(c.timestamp, locale),
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

/// 48×48 product thumbnail for an order-detail item row.
class _DetailThumb extends StatelessWidget {
  const _DetailThumb({required this.url});
  final String? url;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: SizedBox(
      width: 48,
      height: 48,
      child: (url == null || url!.isEmpty)
          ? const ColoredBox(
              color: AppColors.surfaceTint,
              child: Icon(
                Icons.image_outlined,
                size: 16,
                color: AppColors.inkMuted,
              ),
            )
          : CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  const ColoredBox(color: AppColors.surfaceTint),
              errorWidget: (_, __, ___) =>
                  const ColoredBox(color: AppColors.surfaceTint),
            ),
    ),
  );
}

/// Recipient name (bold) + a single-line address.
class _AddressBlock extends StatelessWidget {
  const _AddressBlock({required this.name, required this.address});
  final String? name;
  final String address;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (name != null && name!.isNotEmpty)
        Text(name!, style: const TextStyle(fontWeight: FontWeight.w600)),
      Text(
        address,
        style: const TextStyle(color: AppColors.inkMuted, height: 1.35),
      ),
    ],
  );
}

/// One status-history entry: a burgundy dot, the message, and its time.
class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.message, required this.timestamp});
  final String message;
  final String timestamp;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsetsDirectional.only(top: 5, end: 10),
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.brandPrimary,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.isNotEmpty) Text(message),
              if (timestamp.isNotEmpty)
                Text(
                  timestamp,
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
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
