import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../l10n/l10n.dart';
import '../../data/account_repository.dart';
import '../../domain/order.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final orders = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountOrders)),
      body: AsyncValueView(
        value: orders,
        onRetry: () => ref.invalidate(ordersProvider),
        data: (list) {
          if (list.isEmpty) {
            return Center(child: Text(l10n.ordersEmpty));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [for (final order in list) _OrderCard(order: order)],
          );
        },
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
      child: ExpansionTile(
        shape: const Border(),
        title: Text(l10n.orderNumber(order.number),
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${order.date} · ${order.status}',
            style: const TextStyle(color: AppColors.inkMuted)),
        trailing: order.total != null
            ? Text(order.total!.formatted(),
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandPrimary))
            : null,
        childrenPadding:
            const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 12),
        children: [
          for (final line in order.lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text('${line.quantity.toInt()} × ${line.name}')),
                  if (line.price != null)
                    Text(line.price!.formatted(),
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(color: AppColors.inkMuted)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
