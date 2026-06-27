import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/failure_message.dart';
import '../../../../l10n/l10n.dart';
import '../../data/account_repository.dart';
import '../../domain/order.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

/// Order status buckets for the filter tabs (Figma). Mapped from Magento's
/// free-text status, which varies by config — matched loosely on keywords.
enum _OrderFilter { all, toReceive, delivered, cancelled }

bool _statusMatches(_OrderFilter f, String status) {
  final s = status.toLowerCase();
  final delivered = s.contains('complet') || s.contains('deliver');
  final cancelled =
      s.contains('cancel') || s.contains('refund') || s.contains('closed');
  return switch (f) {
    _OrderFilter.all => true,
    _OrderFilter.delivered => delivered,
    _OrderFilter.cancelled => cancelled,
    _OrderFilter.toReceive => !delivered && !cancelled,
  };
}

Color _statusColor(String status) {
  final s = status.toLowerCase();
  if (s.contains('complet') || s.contains('deliver')) return AppColors.accentGold;
  if (s.contains('cancel') || s.contains('refund') || s.contains('closed')) {
    return AppColors.inkMuted;
  }
  return AppColors.brandPrimary;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(ordersControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountOrders)),
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
    final filtered = state.orders
        .where((o) => _statusMatches(_filter, o.status))
        .toList();
    return Column(
      children: [
        _FilterBar(
          current: _filter,
          onChanged: (f) => setState(() => _filter = f),
        ),
        Expanded(
          child: filtered.isEmpty
              ? EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: l10n.ordersEmpty,
                )
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length + (state.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= filtered.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return _OrderCard(order: filtered[index]);
                  },
                ),
        ),
      ],
    );
  }
}

/// Horizontal status filter chips (All / To Receive / Delivered / Cancelled).
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
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          for (final entry in labels.entries)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                label: Text(entry.value),
                selected: current == entry.key,
                onSelected: (_) => onChanged(entry.key),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => context.push(AppRoutes.orderDetail, extra: order),
        title: Text(
          l10n.orderNumber(order.number),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  order.date,
                  style: const TextStyle(color: AppColors.inkMuted),
                ),
                const SizedBox(width: 8),
                _StatusBadge(status: order.status),
              ],
            ),
            if (order.hasTracking)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_shipping_outlined,
                      size: 14,
                      color: AppColors.brandPrimary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.orderTrackingSection,
                      style: const TextStyle(
                        color: AppColors.brandPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        trailing: order.total != null
            ? Text(
                order.total!.formatted(),
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandPrimary,
                ),
              )
            : const Icon(Icons.chevron_right),
        isThreeLine: order.hasTracking,
      ),
    );
  }
}

/// Coloured status pill (Figma): gold = delivered, muted = cancelled,
/// burgundy = in progress.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
