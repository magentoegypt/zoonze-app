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

/// "Pay in 4 interest-free payments of AED X" promo, shown on the PDP and cart
/// **only when the backend config enables Tabby and the price is in range**.
/// Renders nothing otherwise — no fabricated eligibility.
class TabbyPromo extends ConsumerWidget {
  const TabbyPromo({super.key, required this.price, this.padding});

  final Money price;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(tabbyConfigProvider).valueOrNull;
    if (config == null || !config.isEligible(price)) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final per = config.perInstallment(price);
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _TabbyChip(),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              l10n.promoTabbyPayIn4(config.installments, per.formatted()),
              style: const TextStyle(color: AppColors.inkMuted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
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
