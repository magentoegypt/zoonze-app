import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../l10n/l10n.dart';
import '../../data/account_repository.dart';
import '../../domain/customer_address.dart';

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final addresses = ref.watch(addressesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountAddresses)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addressForm),
        icon: const Icon(Icons.add),
        label: Text(l10n.addressAdd),
      ),
      body: AsyncValueView(
        value: addresses,
        onRetry: () => ref.invalidate(addressesProvider),
        data: (list) {
          if (list.isEmpty) {
            return Center(child: Text(l10n.addressesEmpty));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final address in list)
                _AddressCard(
                  address: address,
                  onEdit: () =>
                      context.push(AppRoutes.addressForm, extra: address),
                  onDelete: () async {
                    final id = address.id;
                    if (id == null) return;
                    await ref.read(accountRepositoryProvider).deleteAddress(id);
                    ref.invalidate(addressesProvider);
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onDelete,
  });

  final CustomerAddress address;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(address.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                if (address.defaultShipping)
                  Chip(
                    label: Text(l10n.defaultBadge),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(address.summary,
                style: const TextStyle(color: AppColors.inkMuted)),
            if (address.telephone.isNotEmpty)
              Text(address.telephone,
                  style: const TextStyle(color: AppColors.inkMuted)),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(l10n.addressEdit),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(l10n.actionDelete),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
