import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({
    super.key,
    required this.orderNumber,
    this.pendingPayment = false,
  });

  final String orderNumber;
  final bool pendingPayment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 72, color: AppColors.brandPrimary),
                const SizedBox(height: 16),
                Text(l10n.orderSuccessTitle,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(l10n.orderSuccessBody(orderNumber),
                    textAlign: TextAlign.center),
                if (pendingPayment) ...[
                  const SizedBox(height: 12),
                  Text(l10n.paymentRedirectPending,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.inkMuted)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context.go(AppRoutes.home),
                    child: Text(l10n.cartContinueShopping),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
