import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../l10n/l10n.dart';
import '../domain/checkout.dart';
import '../domain/tabby_config.dart';

/// Selectable payment-method card with the Tabby product subtitle + brand chip.
/// Shared by the checkout payment step and the post-order complete-payment screen.
class PaymentMethodCard extends StatelessWidget {
  const PaymentMethodCard({
    super.key,
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethodOption method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? AppColors.brandPrimary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_off,
          color: selected ? AppColors.brandPrimary : AppColors.inkMuted,
        ),
        title: Text(method.title),
        subtitle: switch (method.tabbyProduct) {
          TabbyProductType.installments => Text(l10n.checkoutPayIn4),
          TabbyProductType.payLater => Text(l10n.checkoutPayLater),
          TabbyProductType.creditCardInstallments => Text(
            l10n.checkoutCardInstalments,
          ),
          null => null,
        },
        trailing: method.isTabby
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3EE6C3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'tabby',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
