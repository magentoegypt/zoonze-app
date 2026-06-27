import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    // Awaiting-payment orders get a neutral gold "received" treatment, not the
    // celebratory burgundy check reserved for a confirmed order.
    final accent = pendingPayment
        ? AppColors.accentGold
        : AppColors.brandPrimary;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Filled circular badge with a white check (Figma).
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
                  child: Icon(
                    pendingPayment ? Icons.schedule : Icons.check,
                    size: 44,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  pendingPayment
                      ? l10n.orderPendingTitle
                      : l10n.orderSuccessTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.orderSuccessBody(orderNumber),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.inkMuted),
                ),
                const SizedBox(height: 20),
                // Order-number card with a copy action.
                Container(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.orderNumberLabel,
                              style: const TextStyle(
                                color: AppColors.inkMuted,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '#$orderNumber',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.inkHeading,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await Clipboard.setData(
                            ClipboardData(text: orderNumber),
                          );
                          messenger.showSnackBar(
                            SnackBar(content: Text(l10n.orderNumberCopied)),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: Text(l10n.actionCopy),
                      ),
                    ],
                  ),
                ),
                if (pendingPayment) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.paymentRedirectPending,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.inkMuted),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context.go(AppRoutes.orders),
                    child: Text(l10n.footerTrackOrder),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
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
