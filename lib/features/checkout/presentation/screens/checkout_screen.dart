import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/shell/marketing_footer.dart';
import '../../../../app/shell/zoonze_bottom_nav.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/address/regions.dart';
import '../../../../core/validation/phone.dart';
import '../../../../core/validation/validators.dart';
import '../../../../core/widgets/address_form.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../core/widgets/button_spinner.dart';
import '../../../../core/widgets/failure_message.dart';
import '../../../../core/widgets/otp_code_field.dart';
import '../../../../core/widgets/resend_countdown.dart';
import '../../../../l10n/l10n.dart';
import '../../../account/data/account_repository.dart';
import '../../../account/domain/customer_address.dart';
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

  /// True once an address has actually been submitted in THIS screen instance.
  /// The guest-verify card (which auto-sends a live WhatsApp OTP) is gated on
  /// this — never on the session-wide `state.addressDone`, which can still hold
  /// a previous checkout's value on the first frame before `reset()` runs, and
  /// would otherwise fire a spurious OTP send on checkout re-entry.
  bool _addressSubmitted = false;

  /// Saved-address selection (signed-in customers). `_useNewAddress` reveals the
  /// form; otherwise the effective selection defaults to the customer's default
  /// shipping address.
  int? _selectedAddressId;
  bool _useNewAddress = false;

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
    // Start every checkout from a clean slate. The checkout controller is a
    // session-wide singleton, so without this a second checkout in the same
    // session (or a checkout after logout) inherits the previous order's
    // shipping/payment/total. Post-frame because a provider can't be mutated
    // during the widget-tree build that mounts this screen; the stale sections
    // only render below the address form, so the one-frame pre-reset is unseen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(checkoutControllerProvider.notifier).reset();
    });
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

  /// Default shipping address id (or the first) from the saved list.
  int? _defaultId(List<CustomerAddress> list) {
    for (final a in list) {
      if (a.defaultShipping) return a.id;
    }
    return list.isEmpty ? null : list.first.id;
  }

  /// Magento `CartAddressInput` from a saved [CustomerAddress].
  Map<String, dynamic> _savedAddressInput(CustomerAddress a) => <String, dynamic>{
    'firstname': a.firstName,
    'lastname': a.lastName,
    'telephone': a.telephone,
    'street': [a.street, if (a.apartment.isNotEmpty) a.apartment],
    'city': a.city,
    'country_code': a.countryCode,
    if (a.regionId != null)
      'region_id': a.regionId
    else if (a.region.isNotEmpty)
      'region': a.region,
  };

  Future<void> _submitAddress() async {
    // Only the email (and, when shown, the new-address form) is validated — a
    // selected saved address needs no form validation.
    if (!_formKey.currentState!.validate()) return;
    final isGuest = !ref.read(authControllerProvider).isAuthenticated;
    final saved =
        ref.read(addressesProvider).valueOrNull ?? const <CustomerAddress>[];
    final useSaved = !isGuest && !_useNewAddress && saved.isNotEmpty;
    final Map<String, dynamic> address;
    if (useSaved) {
      final id = _selectedAddressId ?? _defaultId(saved);
      final a = saved.firstWhere((x) => x.id == id, orElse: () => saved.first);
      address = _savedAddressInput(a);
    } else {
      address = _addressInput();
    }
    final ok = await _controller.submitAddress(
      email: _email.text.trim(),
      address: address,
      isGuest: isGuest,
    );
    if (!mounted) return;
    if (ok) {
      setState(() => _addressSubmitted = true);
    } else {
      _snack(AppLocalizations.of(context).errorGeneric);
    }
  }

  /// Address step body: a signed-in customer with saved addresses picks one
  /// (default auto-selected) or opens the new-address form; guests / customers
  /// with no saved addresses get the form directly.
  Widget _addressSection(AppLocalizations l10n, bool isGuest) {
    if (isGuest) return AddressForm(controller: _address);
    return ref
        .watch(addressesProvider)
        .maybeWhen(
          data: (list) {
            if (list.isEmpty) return AddressForm(controller: _address);
            final selectedId =
                _useNewAddress ? null : (_selectedAddressId ?? _defaultId(list));
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final a in list)
                  _AddressRadioCard(
                    address: a,
                    selected: !_useNewAddress && a.id == selectedId,
                    onTap: () => setState(() {
                      _useNewAddress = false;
                      _selectedAddressId = a.id;
                    }),
                  ),
                _NewAddressTile(
                  label: l10n.checkoutUseNewAddress,
                  selected: _useNewAddress,
                  onTap: () => setState(() {
                    _useNewAddress = true;
                    _selectedAddressId = null;
                  }),
                ),
                if (_useNewAddress) ...[
                  const SizedBox(height: 12),
                  AddressForm(controller: _address),
                ],
              ],
            );
          },
          orElse: () => AddressForm(controller: _address),
        );
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
    // A guest must verify the delivery-phone OTP before the order can be placed
    // (server-enforced). Gates the Place Order button below.
    final needsGuestOtp = isGuest && !state.guestOtpVerified;

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
                      // Label above the field (not a floating label) so it never
                      // overlaps the box border — matters in Arabic/RTL (QA).
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          l10n.fieldEmail,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.inkHeading,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _email,
                        enabled: isGuest,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: l10n.authEmailHint,
                          helperText: l10n.checkoutEmailHelp,
                        ),
                        validator: (v) => Validators.email(context, v),
                      ),
                      const SizedBox(height: 24),
                      _StepHeader(
                        index: 1,
                        title: l10n.checkoutDeliveryAddress,
                      ),
                      _addressSection(l10n, isGuest),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: busy ? null : _submitAddress,
                  child: Text(l10n.checkoutContinue),
                ),
                // Guest checkout verifies the delivery-address phone by OTP
                // before the order can be placed (server-enforced). The card
                // sits directly under Delivery Address (Figma) and gates Place
                // Order below. Keyed by the *submitted* phone so a changed
                // number remounts it (re-requesting the code); shown only after
                // a real submit this session so it never auto-sends on re-entry.
                if (isGuest && _addressSubmitted && state.addressDone)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: _GuestVerifyCard(
                      key: ValueKey(state.submittedPhone),
                      phone: state.submittedPhone,
                    ),
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
                    onPressed: (busy || needsGuestOtp) ? null : _placeOrder,
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
                  if (needsGuestOtp)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        l10n.checkoutVerifyMobileTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: 12.5,
                        ),
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

/// A selectable saved-address card (Figma): radio + name (+ "Default" badge) +
/// phone + single-line address.
class _AddressRadioCard extends StatelessWidget {
  const _AddressRadioCard({
    required this.address,
    required this.selected,
    required this.onTap,
  });

  final CustomerAddress address;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? AppColors.surfaceTint : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.brandPrimary : AppColors.borderDefault,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? AppColors.brandPrimary : AppColors.inkMuted,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            address.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (address.defaultShipping)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.brandPrimary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              l10n.addressDefaultBadge,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (address.telephone.isNotEmpty)
                      Text(
                        address.telephone,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      address.summary,
                      style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The "Use a new address" option below the saved-address cards.
class _NewAddressTile extends StatelessWidget {
  const _NewAddressTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected ? AppColors.surfaceTint : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? AppColors.brandPrimary : AppColors.borderDefault,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            selected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: selected ? AppColors.brandPrimary : AppColors.inkMuted,
            size: 20,
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.add_location_alt_outlined,
            size: 18,
            color: AppColors.brandPrimary,
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    ),
  );
}

/// Guest-checkout "Verify Mobile Number" card (Figma): auto-requests a WhatsApp
/// OTP to the cart's delivery phone on appear, then 6 boxes → Verify + Resend.
/// On success the checkout controller flips `guestOtpVerified`, which both
/// re-renders this card to the verified state and unlocks Place Order.
class _GuestVerifyCard extends ConsumerStatefulWidget {
  const _GuestVerifyCard({super.key, required this.phone});

  final String phone;

  @override
  ConsumerState<_GuestVerifyCard> createState() => _GuestVerifyCardState();
}

class _GuestVerifyCardState extends ConsumerState<_GuestVerifyCard> {
  final _otp = TextEditingController();
  bool _busy = false;
  bool _requested = false;

  @override
  void initState() {
    super.initState();
    _otp.addListener(_onOtp);
    WidgetsBinding.instance.addPostFrameCallback((_) => _request(initial: true));
  }

  @override
  void dispose() {
    _otp.removeListener(_onOtp);
    _otp.dispose();
    super.dispose();
  }

  void _onOtp() => setState(() {});

  CheckoutController get _controller =>
      ref.read(checkoutControllerProvider.notifier);

  Future<void> _request({bool initial = false}) async {
    // The initial call is a post-frame callback — bail if the card was unmounted
    // (e.g. reset() dropped it) before it ran, so no stray live OTP is sent.
    if (!mounted) return;
    // Send the code once automatically; a manual Resend re-sends and clears.
    if (initial && _requested) return;
    _requested = true;
    if (!initial) _otp.clear();
    try {
      await _controller.requestGuestOtp();
    } catch (error) {
      if (!mounted) return;
      _snack(
        serverMessageOr(
          context,
          error,
          AppLocalizations.of(context).authOtpRequestError,
        ),
      );
    }
  }

  Future<void> _verify() async {
    if (_otp.text.length != 6) return;
    setState(() => _busy = true);
    try {
      await _controller.verifyGuestOtp(_otp.text);
    } catch (error) {
      if (!mounted) return;
      _otp.clear();
      _snack(
        serverMessageOr(
          context,
          error,
          AppLocalizations.of(context).authOtpVerifyError,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final verified = ref.watch(
      checkoutControllerProvider.select((s) => s.guestOtpVerified),
    );
    // A plain section (Figma) — no card border/tint; it sits inline between the
    // Delivery Address card and the Shipping Method step.
    return verified ? _verifiedView(l10n) : _entryView(l10n);
  }

  Widget _verifiedView(AppLocalizations l10n) => Row(
    children: [
      const Icon(Icons.check_circle, color: AppColors.success, size: 20),
      const SizedBox(width: 10),
      Text(
        l10n.authMobileVerified,
        style: const TextStyle(
          color: AppColors.success,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );

  Widget _entryView(AppLocalizations l10n) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        l10n.checkoutVerifyMobileTitle,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        l10n.checkoutVerifyMobileIntro(Phone.maskBidi(widget.phone)),
        style: const TextStyle(color: AppColors.inkMuted, fontSize: 12.5),
      ),
      const SizedBox(height: 14),
      OtpCodeField(
        controller: _otp,
        autofocus: false,
        onCompleted: (_) => _verify(),
      ),
      const SizedBox(height: 14),
      FilledButton(
        onPressed: (_busy || _otp.text.length != 6) ? null : _verify,
        child: _busy ? const ButtonSpinner() : Text(l10n.authVerify),
      ),
      Center(
        child: ResendCountdown(
          onResend: () => _request(),
          resendLabel: l10n.authResendCode,
          countingLabel: l10n.authResendIn,
        ),
      ),
    ],
  );
}
