import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/shell/marketing_footer.dart';
import '../../../../app/shell/zoonze_scaffold.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/failure_message.dart';
import '../../../../l10n/l10n.dart';
import '../../../cart/presentation/cart_controller.dart';
import '../../data/account_repository.dart';
import '../../domain/order.dart';
import '../order_format.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

/// Order status buckets for the filter tabs (Figma). Mapped from Magento's
/// free-text status, which varies by config — matched loosely on keywords.
enum _OrderFilter { all, toReceive, delivered, cancelled }

bool _statusMatches(_OrderFilter f, CustomerOrder o) {
  return switch (f) {
    _OrderFilter.all => true,
    _OrderFilter.delivered => o.isDelivered,
    _OrderFilter.cancelled => o.isCancelled,
    _OrderFilter.toReceive => !o.isDelivered && !o.isCancelled,
  };
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  final ScrollController _scroll = ScrollController();
  _OrderFilter _filter = _OrderFilter.all;

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

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      ref.read(ordersControllerProvider.notifier).loadMore();
    }
  }

  Future<void> _reorder(CustomerOrder order) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final cart = ref.read(cartControllerProvider.notifier);
    var added = false;
    for (final line in order.lines) {
      final sku = line.sku;
      if (sku == null || sku.isEmpty) continue;
      try {
        await cart.addToCart(sku: sku, quantity: line.quantity.toInt().clamp(1, 99));
        added = true;
      } catch (_) {
        // Skip items that can't be re-added (out of stock / removed).
      }
    }
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(added ? l10n.orderReorderAdded : l10n.orderReorderFailed),
      ),
    );
    if (added) context.push(AppRoutes.cart);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(ordersControllerProvider);

    return ZoonzeScaffold(
      currentTab: AppTab.account,
      appBar: AppBar(
        centerTitle: true,
        leading: const BackButton(),
        title: Text(l10n.accountOrders),
      ),
      body: _body(l10n, state),
    );
  }

  Widget _body(AppLocalizations l10n, OrdersState state) {
    if (state.isLoading && state.orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.orders.isEmpty) {
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
                onPressed: ref.read(ordersControllerProvider.notifier).refresh,
                child: Text(l10n.actionRetry),
              ),
            ],
          ),
        ),
      );
    }
    if (state.orders.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: l10n.ordersEmpty,
      );
    }
    final filtered = state.orders.where((o) => _statusMatches(_filter, o)).toList();
    return ListView(
      controller: _scroll,
      padding: EdgeInsets.zero,
      children: [
        _FilterBar(
          current: _filter,
          onChanged: (f) => setState(() => _filter = f),
        ),
        const _Band(),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.all(40),
            child: EmptyState(
              icon: Icons.receipt_long_outlined,
              title: l10n.ordersEmpty,
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                for (final order in filtered)
                  _OrderCard(
                    order: order,
                    onDetails: () =>
                        context.push(AppRoutes.orderDetail, extra: order),
                    onTrack: () =>
                        context.push(AppRoutes.orderTracking, extra: order),
                    onReorder: () => _reorder(order),
                  ),
              ],
            ),
          ),
        if (state.isLoadingMore)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
        const MarketingFooter(),
      ],
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

/// Horizontal status filter pills (All / To Receive / Delivered / Cancelled).
class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.current, required this.onChanged});
  final _OrderFilter current;
  final ValueChanged<_OrderFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = <_OrderFilter, String>{
      _OrderFilter.all: l10n.ordersFilterAll,
      _OrderFilter.toReceive: l10n.ordersFilterToReceive,
      _OrderFilter.delivered: l10n.ordersFilterDelivered,
      _OrderFilter.cancelled: l10n.ordersFilterCancelled,
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          for (final entry in labels.entries) ...[
            _Chip(
              label: entry.value,
              selected: current == entry.key,
              onTap: () => onChanged(entry.key),
            ),
            const SizedBox(width: 8),
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
          border: selected ? null : Border.all(color: AppColors.borderDefault),
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

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onDetails,
    required this.onTrack,
    required this.onReorder,
  });

  final CustomerOrder order;
  final VoidCallback onDetails;
  final VoidCallback onTrack;
  final VoidCallback onReorder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isPast = order.isDelivered || order.isCancelled;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDefault),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.orderDetail, extra: order),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: number + date·items, status pill.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${order.number}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.inkHeading,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${orderFmtDate(order.date, Localizations.localeOf(context).languageCode)} · ${l10n.orderItemCount(order.itemCount)}',
                          style: const TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusPill(order: order),
                ],
              ),
              if (order.lines.isNotEmpty) ...[
                const SizedBox(height: 12),
                _Thumbnails(lines: order.lines),
                const SizedBox(height: 10),
                _LineSummary(lines: order.lines),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1, thickness: 1, color: AppColors.borderDefault),
              const SizedBox(height: 12),
              // Total.
              Row(
                children: [
                  Text(
                    l10n.orderTotalLabel,
                    style: const TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  if (order.total != null)
                    Text(
                      order.total!.formatted(),
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Actions: View Details + (Track in progress / Reorder past).
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: l10n.orderViewDetails,
                      onTap: onDetails,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionButton(
                      label: isPast ? l10n.orderReorder : l10n.orderTrack,
                      onTap: isPast ? onReorder : onTrack,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Solid status pill: gold = delivered, grey = cancelled, burgundy = in progress.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.order});
  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final cancelled = order.isCancelled;
    final color = order.isDelivered
        ? AppColors.accentGold
        : cancelled
        ? AppColors.inkMuted
        : AppColors.brandPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: cancelled ? AppColors.surfaceMuted : color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        order.status,
        style: TextStyle(
          color: cancelled ? AppColors.inkMuted : Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Outlined burgundy action pill (Track / Reorder).
class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.brandPrimary),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.brandPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// Compact "Qty × Name" list under the thumbnails (QA: the summary showed only
/// images). Shows the first couple of lines + a "+N more" overflow line.
class _LineSummary extends StatelessWidget {
  const _LineSummary({required this.lines});
  final List<OrderLine> lines;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const maxShown = 2;
    final shown = lines.take(maxShown).toList();
    final extra = lines.length - shown.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              '${line.quantity.toInt()} × ${line.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.inkHeading,
              ),
            ),
          ),
        if (extra > 0)
          Text(
            l10n.orderMoreItems(extra),
            style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
          ),
      ],
    );
  }
}

/// Row of up to four 52×52 product thumbnails, with a "+N" overflow tile.
class _Thumbnails extends StatelessWidget {
  const _Thumbnails({required this.lines});
  final List<OrderLine> lines;

  @override
  Widget build(BuildContext context) {
    const max = 4;
    final shown = lines.take(max).toList();
    final extra = lines.length - shown.length;
    return Row(
      children: [
        for (final line in shown) ...[
          _Thumb(url: line.imageUrl),
          const SizedBox(width: 8),
        ],
        if (extra > 0)
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '+$extra',
              style: const TextStyle(
                color: AppColors.brandPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

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
