import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/shell/marketing_footer.dart';
import '../../../../app/shell/zoonze_scaffold.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../../../core/widgets/zoonze_back_button.dart';
import '../../domain/order.dart';
import '../order_format.dart';

/// One timeline step: a label, an optional timestamp, and whether it's done.
typedef _Step = ({String label, String time, bool done});

/// Track Order (Figma `63:2`): status banner, vertical status timeline built
/// from the real Magento order history, delivery address, items, and a help
/// link. Reached from the My Orders "Track" action with the [CustomerOrder].
class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key, required this.order});

  final CustomerOrder order;

  /// Which of the 5 fixed stages the order has reached (0 = Placed … 4 =
  /// Delivered), derived from the Magento status + shipment presence. Cancelled
  /// returns -1 (handled separately). The mapping is best-effort — Magento has
  /// no dedicated "packed" status — so it degrades gracefully to the nearest
  /// known stage rather than inventing progress.
  int _stageIndex() {
    if (order.isCancelled) return -1;
    if (order.isDelivered) return 4;
    final s = order.status.toLowerCase();
    var idx = 0;
    if (s.contains('process') || s.contains('confirm')) idx = 1;
    if (s.contains('pack') || s.contains('ready')) idx = 2;
    if (s.contains('out_for_delivery') ||
        s.contains('out for delivery') ||
        s.contains('ship')) {
      idx = 3;
    }
    // A shipment/tracking number exists → at least out for delivery.
    if (order.hasTracking && idx < 3) idx = 3;
    return idx;
  }

  /// The five fixed timeline stages, filled up to (and including) the reached
  /// stage. Only "Order Placed" carries a timestamp (the order date).
  List<_Step> _steps(AppLocalizations l10n) {
    final labels = <String>[
      l10n.orderPlaced,
      l10n.orderStageConfirmed,
      l10n.orderStagePacked,
      l10n.orderStageOutForDelivery,
      l10n.ordersFilterDelivered,
    ];
    final reached = _stageIndex();
    return [
      for (var i = 0; i < labels.length; i++)
        (
          label: labels[i],
          time: i == 0 ? orderFmtDateTime(order.date) : '',
          // Cancelled (reached < 0): only Placed is done; rest stay pending.
          done: reached >= 0 && i <= reached,
        ),
    ];
  }

  IconData _statusIcon() => switch (_stageIndex()) {
    < 0 => Icons.cancel_outlined,
    4 => Icons.check_circle_outline,
    3 => Icons.local_shipping_outlined,
    2 => Icons.inventory_2_outlined,
    1 => Icons.receipt_long_outlined,
    _ => Icons.shopping_bag_outlined,
  };

  String _statusLabel(AppLocalizations l10n) => switch (_stageIndex()) {
    < 0 => l10n.orderStatusCancelled,
    4 => l10n.ordersFilterDelivered,
    3 => l10n.orderStageOutForDelivery,
    2 => l10n.orderStagePacked,
    1 => l10n.orderStageConfirmed,
    _ => l10n.orderPlaced,
  };

  /// Secondary line under the status: the real delivery method when present,
  /// otherwise the order date. No fabricated per-order ETA.
  String _statusSub() =>
      (order.shippingMethod != null && order.shippingMethod!.isNotEmpty)
      ? order.shippingMethod!
      : orderFmtDateTime(order.date);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = _steps(l10n);

    return ZoonzeScaffold(
      currentTab: AppTab.account,
      appBar: AppBar(
        centerTitle: true,
        leading: const ZoonzeBackButton(),
        title: Text(l10n.trackOrderTitle),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Status card — current stage, delivery method, and order number.
          Container(
            width: double.infinity,
            color: AppColors.surfaceTint,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _statusIcon(),
                    color: AppColors.brandPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _statusLabel(l10n),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: AppColors.inkHeading,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _statusSub(),
                        style: const TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        l10n.orderNumber(order.number),
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
          ),
          const _Band(),

          // Order Status timeline.
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 8),
            child: Text(
              l10n.orderStatusTitle,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.inkHeading,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 16),
            child: _Timeline(steps: steps),
          ),
          const _Band(),

          // Delivery address.
          if (order.shippingAddress != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.brandPrimary,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.orderDeliveryAddress,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.inkHeading,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [order.shippingName, order.shippingAddress]
                              .where((s) => s != null && s.isNotEmpty)
                              .join(' · '),
                          style: const TextStyle(color: AppColors.inkMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (order.shippingAddress != null) const _Band(),

          // Items.
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 8),
            child: Text(
              l10n.orderItemsCount(order.itemCount),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.inkHeading,
              ),
            ),
          ),
          for (final line in order.lines)
            _ItemRow(line: line, l10n: l10n),
          const SizedBox(height: 8),
          const _Band(),

          // Need help.
          InkWell(
            onTap: () => context.push(AppRoutes.help),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.headset_mic_outlined,
                    size: 18,
                    color: AppColors.brandPrimary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.orderNeedHelp,
                    style: const TextStyle(
                      color: AppColors.brandPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const MarketingFooter(),
        ],
      ),
    );
  }
}

/// 8px light section separator (Figma).
class _Band extends StatelessWidget {
  const _Band();
  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 8,
    child: ColoredBox(color: AppColors.surfaceMuted),
  );
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.steps});
  final List<_Step> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    _Dot(done: steps[i].done),
                    if (i != steps.length - 1)
                      Expanded(
                        child: Container(
                          width: 2.5,
                          // Burgundy through completed segments; grey into a
                          // pending step.
                          color: steps[i + 1].done
                              ? AppColors.brandPrimary
                              : AppColors.borderDefault,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: i == steps.length - 1 ? 0 : 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          steps[i].label,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: steps[i].done
                                ? AppColors.inkHeading
                                : AppColors.inkMuted,
                          ),
                        ),
                        if (steps[i].time.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            steps[i].time,
                            style: const TextStyle(
                              color: AppColors.inkMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.done});
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: done ? AppColors.brandPrimary : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: done ? AppColors.brandPrimary : AppColors.borderDefault,
          width: 2,
        ),
      ),
      child: done
          ? const Icon(Icons.check, size: 13, color: Colors.white)
          : null,
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.line, required this.l10n});
  final OrderLine line;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Thumb(url: line.imageUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.inkHeading,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.orderQty(line.quantity.toInt()),
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (line.price != null) ...[
            const SizedBox(width: 8),
            Text(
              line.price!.formatted(),
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.brandPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 52×52 rounded product thumbnail with a neutral placeholder.
class _Thumb extends StatelessWidget {
  const _Thumb({required this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 52,
        height: 52,
        child: (url == null || url!.isEmpty)
            ? const ColoredBox(
                color: AppColors.surfaceTint,
                child: Icon(
                  Icons.image_outlined,
                  size: 18,
                  color: AppColors.inkMuted,
                ),
              )
            : CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    const ColoredBox(color: AppColors.surfaceTint),
                errorWidget: (_, __, ___) => const ColoredBox(
                  color: AppColors.surfaceTint,
                  child: Icon(
                    Icons.image_outlined,
                    size: 18,
                    color: AppColors.inkMuted,
                  ),
                ),
              ),
      ),
    );
  }
}
