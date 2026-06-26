import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../l10n/l10n.dart';
import '../../catalog/domain/money.dart';
import '../data/checkout_repository.dart';
import '../domain/tabby_config.dart';

/// Backend-resolved Tabby config. Rebuilds (refetches) when the GraphQL client is
/// reset on a store switch, since thresholds/currency are store-scoped.
final tabbyConfigProvider = FutureProvider<TabbyConfig?>(
  (ref) => ref.watch(checkoutRepositoryProvider).fetchTabbyConfig(),
);

/// Tabby promo ("Pay in 4" / "Pay Later"), shown on the PDP and cart **only for
/// the products the backend enables and the price qualifies for** — one line per
/// eligible product. Renders nothing otherwise; no fabricated eligibility.
class TabbyPromo extends ConsumerWidget {
  const TabbyPromo({super.key, required this.price, this.padding});

  final Money price;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(tabbyConfigProvider).valueOrNull;
    final eligible = config?.eligibleFor(price) ?? const <TabbyProduct>[];
    if (eligible.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final product in eligible)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _TabbyChip(),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _message(l10n, product),
                      style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 13,
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

  String _message(AppLocalizations l10n, TabbyProduct product) =>
      switch (product.type) {
        TabbyProductType.payIn4 => l10n.promoTabbyPayIn4(
          product.installments,
          product.perInstallment(price).formatted(),
        ),
        TabbyProductType.payLater => l10n.promoTabbyPayLater,
      };
}

class _TabbyChip extends StatelessWidget {
  const _TabbyChip();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFF3EE6C3),
      borderRadius: BorderRadius.circular(6),
    ),
    child: const Text(
      'tabby',
      style: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    ),
  );
}
