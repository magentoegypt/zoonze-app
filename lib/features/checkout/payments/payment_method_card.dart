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
        title: Row(
          children: [
            Icon(_methodIcon(method), size: 20, color: AppColors.inkHeading),
            const SizedBox(width: 10),
            Expanded(child: Text(method.title)),
          ],
        ),
        subtitle: _subtitle(l10n),
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

  /// A representative icon per method (QA: "add the appropriate icons").
  IconData _methodIcon(PaymentMethodOption m) {
    if (m.isFree) return Icons.card_giftcard;
    if (m.isTabby) return Icons.calendar_today_outlined;
    final c = m.code.toLowerCase();
    if (c.contains('checkmo') || c.contains('check')) {
      return Icons.request_quote_outlined;
    }
    if (c.contains('cashondelivery') ||
        c.contains('cash_on_delivery') ||
        c == 'cod') {
      return Icons.payments_outlined;
    }
    if (c.contains('ngenius') || c.contains('network')) {
      return Icons.credit_card_outlined;
    }
    return Icons.account_balance_wallet_outlined;
  }

  /// Subtitle copy: the friendly "no payment needed" line for Zero Subtotal
  /// Checkout (`free`), otherwise the Tabby product line, otherwise none.
  Widget? _subtitle(AppLocalizations l10n) {
    if (method.isFree) return Text(l10n.checkoutFreeOrder);
    return switch (method.tabbyProduct) {
      TabbyProductType.installments => Text(l10n.checkoutPayIn4),
      TabbyProductType.payLater => Text(l10n.checkoutPayLater),
      TabbyProductType.creditCardInstallments => Text(
        l10n.checkoutCardInstalments,
      ),
      null => null,
    };
  }
}
