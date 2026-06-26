import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/validation/validators.dart';
import '../../../../l10n/l10n.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../domain/checkout.dart';
import '../checkout_controller.dart';
import 'payment_redirect_screen.dart';

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
  final _country = TextEditingController(text: 'AE');

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
      _country,
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
        'country_code':
            _country.text.trim().isEmpty ? 'AE' : _country.text.trim().toUpperCase(),
        if (_region.text.trim().isNotEmpty)
          'region': <String, dynamic>{'region': _region.text.trim()},
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
    final result = await _controller.placeOrder();
    if (!mounted) return;
    if (result == null) {
      _snack(AppLocalizations.of(context).errorGeneric);
      return;
    }
    final payment = ref.read(checkoutControllerProvider).selectedPayment;
    if (payment != null && payment.isRedirect && result.redirectUrl != null) {
      final outcome = await Navigator.of(context).push<PaymentOutcome>(
        MaterialPageRoute(
          builder: (_) => PaymentRedirectScreen(url: result.redirectUrl!),
        ),
      );
      if (!mounted) return;
      // A real success must be confirmed by re-querying the order server-side.
      if (outcome == PaymentOutcome.success) {
        _goSuccess(result.orderNumber, pending: false);
      } else {
        _snack(AppLocalizations.of(context).errorGeneric);
      }
    } else {
      // Non-redirect method completes immediately; a redirect method without an
      // exposed URL leaves the order pending payment (Open Q §2).
      _goSuccess(result.orderNumber, pending: payment?.isRedirect ?? false);
    }
  }

  void _goSuccess(String number, {required bool pending}) {
    context.go(AppRoutes.orderSuccess,
        extra: {'number': number, 'pending': pending});
  }

  void _snack(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(checkoutControllerProvider);
    final isGuest = !ref.watch(authControllerProvider).isAuthenticated;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.checkoutPayment)),
      body: AbsorbPointer(
        absorbing: state.isBusy,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _StepHeader(index: 1, title: l10n.checkoutShippingAddress),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  if (isGuest)
                    _field(_email, l10n.fieldEmail,
                        validator: (v) => Validators.email(context, v),
                        keyboard: TextInputType.emailAddress),
                  Row(children: [
                    Expanded(
                        child: _field(_firstName, l10n.fieldFirstName,
                            validator: (v) => Validators.required(context, v))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _field(_lastName, l10n.fieldLastName,
                            validator: (v) => Validators.required(context, v))),
                  ]),
                  _field(_phone, l10n.fieldPhone,
                      keyboard: TextInputType.phone,
                      validator: (v) => Validators.required(context, v)),
                  _field(_street, l10n.fieldStreet,
                      validator: (v) => Validators.required(context, v)),
                  _field(_city, l10n.fieldCity,
                      validator: (v) => Validators.required(context, v)),
                  Row(children: [
                    Expanded(child: _field(_region, l10n.fieldRegion)),
                    const SizedBox(width: 12),
                    Expanded(child: _field(_postcode, l10n.fieldPostcode)),
                  ]),
                  _field(_country, l10n.fieldCountry),
                ],
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: state.isBusy ? null : _submitAddress,
              child: Text(l10n.checkoutContinue),
            ),
            if (state.addressDone) ...[
              const SizedBox(height: 24),
              _StepHeader(index: 2, title: l10n.checkoutShippingMethod),
              RadioGroup<String>(
                groupValue: state.selectedShipping?.id,
                onChanged: (id) {
                  if (id == null) return;
                  final method =
                      state.shippingMethods.firstWhere((m) => m.id == id);
                  _controller.selectShipping(method);
                },
                child: Column(
                  children: [
                    for (final method in state.shippingMethods)
                      RadioListTile<String>(
                        value: method.id,
                        title: Text(method.title),
                        secondary: method.amount != null
                            ? Text(method.amount!.formatted(),
                                textDirection: TextDirection.ltr)
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
                _PaymentCard(
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
                    Text(l10n.cartTotal,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(state.grandTotal!.formatted(),
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandPrimary)),
                  ],
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: state.isBusy ? null : _placeOrder,
                child: state.isBusy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l10n.checkoutPlaceOrder),
              ),
            ],
            if (state.isBusy)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) =>
      Padding(
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
              child: Text('$index',
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
            ),
            const SizedBox(width: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
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
        subtitle: method.isTabby ? Text(l10n.checkoutPayIn4) : null,
        trailing: method.isTabby
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3EE6C3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('tabby',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.w700)),
              )
            : null,
      ),
    );
  }
}
