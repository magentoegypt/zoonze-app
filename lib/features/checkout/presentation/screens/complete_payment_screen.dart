import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../../catalog/domain/money.dart';
import '../../data/checkout_repository.dart';
import '../../domain/checkout.dart';
import '../../domain/payment_session.dart';
import '../../payments/payment_method_card.dart';
import '../../payments/payment_runner.dart';

/// Arguments for the post-order complete-payment screen, passed via go_router
/// `extra`. The order is already placed (awaiting payment); the cart is gone, so
/// retry/switch works off the order number + the methods collected at checkout.
class CompletePaymentArgs {
  const CompletePaymentArgs({
    required this.orderNumber,
    required this.methods,
    this.currentMethodCode,
    this.amount,
    this.email,
    this.lastname,
    this.orderToken,
  });

  final String orderNumber;
  final List<PaymentMethodOption> methods;
  final String? currentMethodCode;
  final Money? amount;
  final String? email;
  final String? lastname;
  final String? orderToken;
}

/// Reached after a payment attempt fails on an already-placed order. Lets the
/// user **pay now** — retrying the same method or switching to another (option
/// b) — or **pay later**, leaving the order awaiting payment (option a).
class CompletePaymentScreen extends ConsumerStatefulWidget {
  const CompletePaymentScreen({super.key, required this.args});

  final CompletePaymentArgs args;

  @override
  ConsumerState<CompletePaymentScreen> createState() =>
      _CompletePaymentScreenState();
}

class _CompletePaymentScreenState extends ConsumerState<CompletePaymentScreen> {
  String? _selectedCode;

  /// The method currently set on the order server-side (updated after a switch).
  late String? _activeCode = widget.args.currentMethodCode;
  bool _busy = false;

  CompletePaymentArgs get _args => widget.args;

  Future<void> _pay() async {
    final code = _selectedCode;
    if (code == null || _busy) return;
    final method = _args.methods.firstWhere((m) => m.code == code);
    setState(() => _busy = true);
    try {
      final repo = ref.read(checkoutRepositoryProvider);
      // Same method → recreate its session; different → switch on the order.
      final session = code == _activeCode
          ? await repo.fetchPaymentSession(
              _args.orderNumber,
              email: _args.email,
              lastname: _args.lastname,
              token: _args.orderToken,
            )
          : await repo.setOrderPaymentMethod(
              _args.orderNumber,
              code,
              email: _args.email,
              lastname: _args.lastname,
            );
      if (!mounted) return;
      if (session != null && code != _activeCode) _activeCode = code;
      final result = await runPaymentSession(
        context: context,
        ref: ref,
        session: session,
        amount: _args.amount,
      );
      if (!mounted) return;
      _handleResult(result, method);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _handleResult(PaymentRunResult result, PaymentMethodOption method) {
    final l10n = AppLocalizations.of(context);
    String? message;
    switch (result.step) {
      case PaymentStep.presented:
        switch (result.outcome!) {
          case PaymentOutcome.success:
            // Order paid — re-confirmed server-side before success is trusted.
            context.go(
              AppRoutes.orderSuccess,
              extra: {'number': _args.orderNumber, 'pending': false},
            );
            return;
          case PaymentOutcome.rejected:
            message = l10n.paymentDeclined;
          case PaymentOutcome.expired:
            message = l10n.paymentExpired;
          case PaymentOutcome.failed:
            message = l10n.paymentFailed;
          case PaymentOutcome.cancelled:
            message = null; // user backed out — stay, no error
        }
      case PaymentStep.pending:
        message = l10n.paymentProcessing;
      case PaymentStep.rejected:
        message = l10n.paymentDeclined;
      case PaymentStep.failed:
        message = l10n.paymentFailed;
      case PaymentStep.unavailable:
        message = l10n.paymentSessionUnavailable;
    }
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.completePaymentTitle)),
      body: Stack(
        children: [
          AbsorbPointer(
            absorbing: _busy,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Icon(
                  Icons.schedule_outlined,
                  size: 56,
                  color: AppColors.accentGold,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.completePaymentBody(_args.orderNumber),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                for (final method in _args.methods)
                  PaymentMethodCard(
                    method: method,
                    selected: _selectedCode == method.code,
                    onTap: () => setState(() => _selectedCode = method.code),
                  ),
                const SizedBox(height: 8),
                if (_args.methods.isNotEmpty)
                  FilledButton(
                    onPressed: (_selectedCode == null || _busy) ? null : _pay,
                    child: Text(l10n.completePaymentPayNow),
                  ),
                TextButton(
                  onPressed: _busy ? null : () => context.go(AppRoutes.home),
                  child: Text(l10n.completePaymentPayLater),
                ),
              ],
            ),
          ),
          if (_busy)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x33000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
