import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/validation/validators.dart';
import '../../../../l10n/l10n.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../catalog/domain/money.dart';
import '../../domain/payment_session.dart';
import '../../payments/payment_method_card.dart';
import '../../payments/payment_runner.dart';
import '../checkout_controller.dart';
import 'complete_payment_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _street = TextEditingController();
  final _city = TextEditingController();
  final _postcode = TextEditingController();
  final _region = TextEditingController();

  /// Re-entrancy guard for the place-order → redirect handoff.
  bool _placing = false;

  @override
  void initState() {
    super.initState();
    final customer = ref.read(authControllerProvider).customer;
    if (customer != null) {
      _email.text = customer.email;
      _firstName.text = customer.firstName;
      _lastName.text = customer.lastName;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _email,
      _firstName,
      _lastName,
      _phone,
      _street,
      _city,
      _postcode,
      _region,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  CheckoutController get _controller =>
      ref.read(checkoutControllerProvider.notifier);

  Map<String, dynamic> _addressInput() => <String, dynamic>{
    'firstname': _firstName.text.trim(),
    'lastname': _lastName.text.trim(),
    'telephone': _phone.text.trim(),
    'street': [_street.text.trim()],
    'city': _city.text.trim(),
    if (_postcode.text.trim().isNotEmpty) 'postcode': _postcode.text.trim(),
    // UAE-only storefront — country is fixed. Magento's CartAddressInput.region
    // is a plain String (unlike CustomerAddressInput's nested object).
    'country_code': 'AE',
    if (_region.text.trim().isNotEmpty) 'region': _region.text.trim(),
  };

  Future<void> _submitAddress() async {
    if (!_formKey.currentState!.validate()) return;
    final isGuest = !ref.read(authControllerProvider).isAuthenticated;
    final ok = await _controller.submitAddress(
      email: _email.text.trim(),
      address: _addressInput(),
      isGuest: isGuest,
    );
    if (!mounted) return;
    if (!ok) _snack(AppLocalizations.of(context).errorGeneric);
  }

  Future<void> _placeOrder() async {
    if (_placing) return;
    // Hold the busy lock across the WHOLE flow (place order → session poll →
    // native present), not just placeOrder — otherwise the form is tappable and
    // the barrier vanishes while a payment runs against an already-consumed cart.
    setState(() => _placing = true);
    try {
      final result = await _controller.placeOrder();
      if (!mounted) return;
      if (result == null) {
        _snack(AppLocalizations.of(context).errorGeneric);
        return;
      }
      final state = ref.read(checkoutControllerProvider);
      final payment = state.selectedPayment;
      if (payment == null || !payment.isRedirect) {
        // Non-gateway methods complete immediately with no payment step:
        // Zero Subtotal Checkout (`free`, total = 0), cash on delivery, etc.
        _goSuccess(result.orderNumber, pending: false);
        return;
      }
      // Gateway method: fetch the session (the controller sends the guest's
      // billing email/lastname to authorize a guest order) and route by status.
      final session = await _controller.loadPaymentSession(result.orderNumber);
      if (!mounted) return;
      await _drive(session, result.orderNumber, state.grandTotal);
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  Future<void> _drive(
    PaymentSession? session,
    String orderNumber,
    Money? amount,
  ) async {
    final result = await runPaymentSession(
      context: context,
      ref: ref,
      session: session,
      amount: amount,
    );
    if (!mounted) return;
    switch (result.step) {
      case PaymentStep.presented:
        if (result.outcome == PaymentOutcome.success) {
          // A real success must still be re-confirmed server-side before it is
          // trusted (§5) — wired once the gateway exposes order status.
          _goSuccess(orderNumber, pending: false);
        } else {
          // Reject / cancel / expiry / failure on a placed order — let the user
          // retry or switch method (or pay later) on the complete-payment screen.
          _goCompletePayment(orderNumber, amount);
        }
      case PaymentStep.rejected:
      case PaymentStep.failed:
        _goCompletePayment(orderNumber, amount);
      case PaymentStep.pending:
      case PaymentStep.unavailable:
        // Not launchable / no native module yet — order is placed, awaiting payment.
        _goSuccess(orderNumber, pending: true);
    }
  }

  void _goCompletePayment(String orderNumber, Money? amount) {
    final s = ref.read(checkoutControllerProvider);
    context.go(
      AppRoutes.completePayment,
      extra: CompletePaymentArgs(
        orderNumber: orderNumber,
        methods: s.paymentMethods,
        currentMethodCode: s.selectedPayment?.code,
        amount: amount,
        email: s.isGuest ? s.email : null,
        lastname: s.isGuest ? s.lastname : null,
      ),
    );
  }

  void _goSuccess(String number, {required bool pending}) {
    context.go(
      AppRoutes.orderSuccess,
      extra: {'number': number, 'pending': pending},
    );
  }

  void _snack(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(checkoutControllerProvider);
    final isGuest = !ref.watch(authControllerProvider).isAuthenticated;
    // _placing spans the whole place-order → session → present flow; state.isBusy
    // covers the individual address/shipping/payment mutations.
    final busy = state.isBusy || _placing;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.checkoutTitle)),
      body: Stack(
        children: [
          AbsorbPointer(
            absorbing: busy,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _StepHeader(index: 1, title: l10n.checkoutShippingAddress),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (isGuest)
                        _field(
                          _email,
                          l10n.fieldEmail,
                          validator: (v) => Validators.email(context, v),
                          keyboard: TextInputType.emailAddress,
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              _firstName,
                              l10n.fieldFirstName,
                              validator: (v) => Validators.required(context, v),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              _lastName,
                              l10n.fieldLastName,
                              validator: (v) => Validators.required(context, v),
                            ),
                          ),
                        ],
                      ),
                      _field(
                        _phone,
                        l10n.fieldPhone,
                        keyboard: TextInputType.phone,
                        validator: (v) => Validators.required(context, v),
                      ),
                      _field(
                        _street,
                        l10n.fieldStreet,
                        validator: (v) => Validators.required(context, v),
                      ),
                      _field(
                        _city,
                        l10n.fieldCity,
                        validator: (v) => Validators.required(context, v),
                      ),
                      Row(
                        children: [
                          Expanded(child: _field(_region, l10n.fieldRegion)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(_postcode, l10n.fieldPostcode),
                          ),
                        ],
                      ),
                      TextFormField(
                        enabled: false,
                        initialValue: l10n.countryUae,
                        decoration: InputDecoration(
                          labelText: l10n.fieldCountryLabel,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: busy ? null : _submitAddress,
                  child: Text(l10n.checkoutContinue),
                ),
                if (state.addressDone) ...[
                  const SizedBox(height: 24),
                  _StepHeader(index: 2, title: l10n.checkoutShippingMethod),
                  RadioGroup<String>(
                    groupValue: state.selectedShipping?.id,
                    onChanged: (id) {
                      if (id == null) return;
                      final method = state.shippingMethods.firstWhere(
                        (m) => m.id == id,
                      );
                      _controller.selectShipping(method);
                    },
                    child: Column(
                      children: [
                        for (final method in state.shippingMethods)
                          RadioListTile<String>(
                            value: method.id,
                            title: Text(method.title),
                            secondary: method.amount != null
                                ? Text(
                                    method.amount!.formatted(),
                                    textDirection: TextDirection.ltr,
                                  )
                                : null,
                          ),
                      ],
                    ),
                  ),
                ],
                if (state.shippingDone) ...[
                  const SizedBox(height: 24),
                  _StepHeader(index: 3, title: l10n.checkoutPayment),
                  for (final method in state.paymentMethods)
                    PaymentMethodCard(
                      method: method,
                      selected: state.selectedPayment?.code == method.code,
                      onTap: () => _controller.selectPayment(method),
                    ),
                ],
                if (state.paymentDone) ...[
                  const SizedBox(height: 24),
                  _StepHeader(index: 4, title: l10n.checkoutSummary),
                  if (state.grandTotal != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.cartTotal,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          state.grandTotal!.formatted(),
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandPrimary,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: busy ? null : _placeOrder,
                    child: Text(l10n.checkoutPlaceOrder),
                  ),
                ],
              ],
            ),
          ),
          // Single busy indicator over a translucent barrier — reinforces the
          // AbsorbPointer lock without stacking multiple spinners.
          if (busy)
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

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label),
      validator: validator,
    ),
  );
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.index, required this.title});
  final int index;
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: AppColors.brandPrimary,
          child: Text(
            '$index',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
        const SizedBox(width: 12),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    ),
  );
}
