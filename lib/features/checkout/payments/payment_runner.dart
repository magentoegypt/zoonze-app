import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalog/domain/money.dart';
import '../domain/payment_session.dart';
import 'payment_gateway.dart';

/// What happened when we tried to drive a session to payment.
enum PaymentStep { presented, pending, rejected, failed, unavailable }

class PaymentRunResult {
  const PaymentRunResult(this.step, [this.outcome]);

  final PaymentStep step;

  /// The native-SDK outcome when [step] is [PaymentStep.presented].
  final PaymentOutcome? outcome;
}

/// Resolves the gateway for a READY session and presents it, normalising the
/// session status and the native outcome into one result the caller can act on.
/// Shared by the initial checkout flow and the post-order retry screen so both
/// route consistently. `unavailable` = no session / not launchable / native
/// module missing → the order stays awaiting payment (never a fake success).
Future<PaymentRunResult> runPaymentSession({
  required BuildContext context,
  required WidgetRef ref,
  required PaymentSession? session,
  Money? amount,
}) async {
  if (session == null) return const PaymentRunResult(PaymentStep.unavailable);
  switch (session.status) {
    case PaymentSessionStatus.ready:
      final gateway = ref.read(paymentGatewayResolverProvider).resolve(session);
      if (gateway == null) {
        return const PaymentRunResult(PaymentStep.unavailable);
      }
      try {
        final outcome = await gateway.present(context, session, amount: amount);
        return PaymentRunResult(PaymentStep.presented, outcome);
      } on PaymentGatewayUnavailable {
        return const PaymentRunResult(PaymentStep.unavailable);
      }
    case PaymentSessionStatus.pending:
      return const PaymentRunResult(PaymentStep.pending);
    case PaymentSessionStatus.rejected:
      return const PaymentRunResult(PaymentStep.rejected);
    case PaymentSessionStatus.failed:
      return const PaymentRunResult(PaymentStep.failed);
  }
}
