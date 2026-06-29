import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/shell/marketing_footer.dart';
import '../../../../app/shell/zoonze_bottom_nav.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/address/regions.dart';
import '../../../../core/validation/validators.dart';
import '../../../../core/widgets/address_form.dart';
import '../../../../core/widgets/brand_logo.dart';
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
  late final AddressFormController _address;

  /// Re-entrancy guard for the place-order → redirect handoff.
  bool _placing = false;

  @override
  void initState() {
    super.initState();
    _address = AddressFormController();
    final customer = ref.read(authControllerProvider).customer;
    if (customer != null) {
      _email.text = customer.email;
      _address.fullName.text = '${customer.firstName} ${customer.lastName}'
          .trim();
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _address.dispose();
    super.dispose();
  }

  CheckoutController get _controller =>
      ref.read(checkoutControllerProvider.notifier);

  /// Magento `CartAddressInput`. AE has system regions, so a valid `region_id`
  /// is posted (from the emirate picker); the single Full Name is split into
  /// firstname/lastname and the apartment line becomes `street[1]`.
  Map<String, dynamic> _addressInput() {
    final name = _address.splitName();
    return <String, dynamic>{
      'firstname': name.first,
      'lastname': name.last,
      'telephone': _address.phone.text.trim(),
      'street': _address.streetLines(),
      'city': _address.area.text.trim(),
      'country_code': addressCountryCode,
      if (_address.regionId.value != null)
        'region_id': _address.regionId.value
      else if (_address.region.text.trim().isNotEmpty)
        'region': _address.region.text.trim(),
    };
  }

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
      // order token + billing email/lastname to authorize a guest order) and
      // route by status.
      final session = await _controller.loadPaymentSession(
        result.orderNumber,
        orderToken: result.orderToken,
      );
      if (!mounted) return;
      await _drive(
        session,
        result.orderNumber,
        state.grandTotal,
        result.orderToken,
      );
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  Future<void> _drive(
    PaymentSession? session,
    String orderNumber,
    Money? amount,
    String? orderToken,
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
          _goCompletePayment(orderNumber, amount, orderToken);
        }
      case PaymentStep.rejected:
      case PaymentStep.failed:
        _goCompletePayment(orderNumber, amount, orderToken);
      case PaymentStep.pending:
      case PaymentStep.unavailable:
        // Not launchable / no native module yet — order is placed, awaiting payment.
        _goSuccess(orderNumber, pending: true);
    }
  }

  void _goCompletePayment(String orderNumber, Money? amount, String? orderToken) {
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
        orderToken: s.isGuest ? orderToken : null,
      ),
    );
  }

  void _goSuccess(String number, {required bool pending}) {
    final state = ref.read(checkoutControllerProvider);
    // Resolve the emirate name for the order-success delivery chip.
    String? location;
    final regionId = _address.regionId.value;
    if (regionId != null) {
      final regions = ref.read(regionsProvider).valueOrNull;
      if (regions != null) {
        for (final r in regions) {
          if (r.id == regionId) {
            location = r.name;
            break;
          }
        }
      }
    }
    context.go(
      AppRoutes.orderSuccess,
      extra: {
        'number': number,
        'pending': pending,
        'eta': pending ? null : state.selectedShipping?.title,
        'location': location,
      },
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
      appBar: AppBar(
        toolbarHeight: 60,
        centerTitle: true,
        title: const BrandLogo(height: 44),
      ),
      bottomNavigationBar: const ZoonzeBottomNav(current: AppTab.cart),
      body: Stack(
        children: [
          AbsorbPointer(
            absorbing: busy,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    l10n.checkoutTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                // Contact Information — email (Figma: a separate top section,
                // not a numbered step). Read-only for a signed-in customer.
                _SectionHeader(title: l10n.contactInformation),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _email,
                        enabled: isGuest,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: l10n.fieldEmail,
                          helperText: l10n.checkoutEmailHelp,
                        ),
                        validator: (v) => Validators.email(context, v),
                      ),
                      const SizedBox(height: 24),
                      _StepHeader(
                        index: 1,
                        title: l10n.checkoutDeliveryAddress,
                      ),
                      AddressForm(controller: _address),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_outline, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          state.grandTotal != null
                              ? '${l10n.checkoutPlaceOrder} · ${state.grandTotal!.formatted()}'
                              : l10n.checkoutPlaceOrder,
                        ),
                      ],
                    ),
                  ),
                ],
                    ],
                  ),
                ),
                const MarketingFooter(),
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
}

/// Plain (non-numbered) section header — used for "Contact Information".
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
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
