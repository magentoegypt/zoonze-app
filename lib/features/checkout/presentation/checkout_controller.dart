import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/storage/secure_token_store.dart';
import '../../../core/store/store_controller.dart';
import '../../../core/validation/phone.dart';
import '../../cart/presentation/cart_controller.dart';
import '../../catalog/domain/money.dart';
import '../data/checkout_repository.dart';
import '../domain/checkout.dart';
import '../domain/payment_session.dart';
import '../domain/payment_wallet.dart';
import '../payments/wallet_availability.dart';

class CheckoutState {
  const CheckoutState({
    this.email = '',
    this.lastname = '',
    this.isGuest = false,
    this.shippingMethods = const <ShippingMethodOption>[],
    this.selectedShipping,
    this.paymentMethods = const <PaymentMethodOption>[],
    this.selectedPayment,
    this.grandTotal,
    this.submittedPhone = '',
    this.guestOtpVerified = false,
    this.isBusy = false,
    this.error,
  });

  /// Billing email + lastname captured at the address step — sent to
  /// `paymentSession` so a guest order can reach the gateway.
  final String email;
  final String lastname;
  final bool isGuest;
  final List<ShippingMethodOption> shippingMethods;
  final ShippingMethodOption? selectedShipping;
  final List<PaymentMethodOption> paymentMethods;
  final PaymentMethodOption? selectedPayment;
  final Money? grandTotal;

  /// The normalized (E.164) telephone last submitted with the shipping address —
  /// the number the guest-checkout OTP is actually sent to. Drives the "Code
  /// sent to …" caption and the verify-card key so they track the *submitted*
  /// number, not the live (possibly-edited) address field.
  final String submittedPhone;

  /// Guest-checkout OTP has been verified for the current cart. Gates Place
  /// Order for guests (the server rejects `placeOrder` without it). Reset with
  /// the rest of the state on checkout entry via [CheckoutController.reset].
  final bool guestOtpVerified;

  final bool isBusy;
  final Object? error;

  bool get addressDone => shippingMethods.isNotEmpty;
  bool get shippingDone =>
      selectedShipping != null && paymentMethods.isNotEmpty;
  bool get paymentDone => selectedPayment != null;

  static const Object _keep = Object();

  CheckoutState copyWith({
    String? email,
    String? lastname,
    bool? isGuest,
    List<ShippingMethodOption>? shippingMethods,
    Object? selectedShipping = _keep,
    List<PaymentMethodOption>? paymentMethods,
    Object? selectedPayment = _keep,
    Object? grandTotal = _keep,
    String? submittedPhone,
    bool? guestOtpVerified,
    bool? isBusy,
    Object? error = _keep,
  }) => CheckoutState(
    email: email ?? this.email,
    lastname: lastname ?? this.lastname,
    isGuest: isGuest ?? this.isGuest,
    shippingMethods: shippingMethods ?? this.shippingMethods,
    selectedShipping: identical(selectedShipping, _keep)
        ? this.selectedShipping
        : selectedShipping as ShippingMethodOption?,
    paymentMethods: paymentMethods ?? this.paymentMethods,
    selectedPayment: identical(selectedPayment, _keep)
        ? this.selectedPayment
        : selectedPayment as PaymentMethodOption?,
    grandTotal: identical(grandTotal, _keep)
        ? this.grandTotal
        : grandTotal as Money?,
    submittedPhone: submittedPhone ?? this.submittedPhone,
    guestOtpVerified: guestOtpVerified ?? this.guestOtpVerified,
    isBusy: isBusy ?? this.isBusy,
    error: identical(error, _keep) ? this.error : error,
  );
}

/// Drives the sequential checkout mutations against the active cart.
class CheckoutController extends Notifier<CheckoutState> {
  @override
  CheckoutState build() {
    // A language/store switch re-evaluates the cart against the new store view
    // and resets the GraphQL cache. The shipping/payment method titles + totals
    // held here are store- and locale-specific, so clear them; the user re-runs
    // the steps (address → shipping → payment) in the new language. Without this
    // the checkout kept the previous language's method labels + a stale total.
    ref.listen<String>(
      storeControllerProvider.select((s) => s.activeStoreCode),
      (prev, next) {
        if (prev != null && prev != next) state = const CheckoutState();
      },
    );
    return const CheckoutState();
  }

  /// Clears all checkout progress back to a clean slate. This controller is a
  /// session-wide singleton, so the checkout screen calls this on entry —
  /// otherwise a *second* checkout in the same session (or a checkout after
  /// logout) reuses the previous order's shipping method / payment / total.
  /// That both shows a stale grand total and makes the UI treat shipping/payment
  /// as already-done, so it skips those mutations on the new cart and
  /// `placeOrder` then fails ("Something went wrong").
  void reset() => state = const CheckoutState();

  CheckoutRepository get _repo => ref.read(checkoutRepositoryProvider);

  String? get _cartId {
    final id = ref.read(cartControllerProvider).cart.id;
    return id.isEmpty ? null : id;
  }

  Future<bool> submitAddress({
    required String email,
    required Map<String, dynamic> address,
    required bool isGuest,
  }) async {
    final cartId = _cartId;
    if (cartId == null) return false;
    state = state.copyWith(isBusy: true, error: null);
    try {
      // AuthLink sends whatever bearer is in secure storage on every request,
      // independent of the auth *state*. If a token lingers while the app reads
      // as a guest (the startup restore window, or a state/token skew), Magento
      // treats the request as the logged-in customer and rejects
      // setGuestEmailOnCart ("The request is not allowed for logged in
      // customers") — which used to block Continue (QA 86d3mdef7 #1). Gate the
      // guest-only email on the actual token (what AuthLink sends), and drive
      // the rest of checkout (OTP gating, placeOrder auth) by that same flag so
      // a real bearer runs the customer path end-to-end.
      final hasToken = (await ref.read(secureTokenStoreProvider).read()) != null;
      final guest = isGuest && !hasToken;
      if (guest && email.isNotEmpty) {
        await _repo.setGuestEmail(cartId, email);
      }
      final methods = await _repo.setShippingAddress(cartId, address);
      final phone = Phone.normalizeUae((address['telephone'] as String?) ?? '');
      // Keep a prior guest-OTP verification only when the phone is unchanged —
      // the challenge is bound to the cart's number, so editing an unrelated
      // address field (same phone) shouldn't force re-verification, but a new
      // number must.
      final phoneChanged = phone != state.submittedPhone;
      state = state.copyWith(
        email: email,
        lastname: (address['lastname'] as String?) ?? '',
        isGuest: guest,
        shippingMethods: methods,
        selectedShipping: null,
        paymentMethods: const [],
        selectedPayment: null,
        submittedPhone: phone,
        guestOtpVerified: phoneChanged ? false : state.guestOtpVerified,
        isBusy: false,
      );
      // Auto-select the default (free/standard) shipping so the payment step +
      // order summary populate without an extra tap — QA: "Standard Shipping
      // FREE selected by default". This cascades into the default payment.
      final defaultShipping = _defaultShipping(methods);
      if (defaultShipping != null) {
        await selectShipping(defaultShipping);
      }
      return true;
    } catch (error) {
      state = state.copyWith(isBusy: false, error: error);
      return false;
    }
  }

  Future<bool> selectShipping(ShippingMethodOption method) async {
    final cartId = _cartId;
    if (cartId == null) return false;
    state = state.copyWith(isBusy: true, error: null);
    try {
      final total = await _repo.setShippingMethod(
        cartId,
        method.carrierCode,
        method.methodCode,
      );
      // Present payments in the client's requested order (CL042-DEV27: Apple
      // Pay, Samsung Pay, Visa & MasterCard, Tabby, Cash on Delivery) — the
      // checkout list still contains only what the backend returns in
      // `available_payment_methods`.
      //
      // The only thing the app *removes* is a wallet this device cannot pay
      // with: the API offers Apple Pay to Android phones too, because
      // availability is a device concern the backend cannot see. This single
      // filter point feeds `state.paymentMethods`, the default selection, and
      // the method list forwarded to the complete-payment screen.
      final payments = _orderPayments(
        filterUnavailableWallets(
          await _repo.setBillingSameAsShipping(cartId),
          await ref.read(walletAvailabilityProvider.future),
        ),
      );
      state = state.copyWith(
        selectedShipping: method,
        grandTotal: total,
        paymentMethods: payments,
        selectedPayment: null,
        isBusy: false,
      );
      // Pre-select Cash on Delivery (QA default) so the summary + Place Order
      // are ready immediately; the shopper can still switch method.
      final defaultPayment = _defaultPayment(payments);
      if (defaultPayment != null) {
        await selectPayment(defaultPayment);
      }
      return true;
    } catch (error) {
      state = state.copyWith(isBusy: false, error: error);
      return false;
    }
  }

  /// The default shipping method to auto-select: the cheapest (a free method,
  /// when the store offers one, sorts first).
  ShippingMethodOption? _defaultShipping(List<ShippingMethodOption> methods) {
    if (methods.isEmpty) return null;
    final sorted = [...methods]
      ..sort((a, b) => (a.amount?.amount ?? 0).compareTo(b.amount?.amount ?? 0));
    return sorted.first;
  }

  /// Payment methods in the Figma display order, stable within a rank.
  List<PaymentMethodOption> _orderPayments(List<PaymentMethodOption> methods) {
    final indexed = methods.asMap().entries.toList()
      ..sort((a, b) {
        final r = _payRank(a.value.code).compareTo(_payRank(b.value.code));
        return r != 0 ? r : a.key.compareTo(b.key);
      });
    return [for (final e in indexed) e.value];
  }

  /// CL042-DEV27 order: Apple Pay, Samsung Pay, Visa & MasterCard, Tabby, Cash
  /// on Delivery. Check/Money order is not in the client's list, so it sorts
  /// below it; anything unknown (including Zero Subtotal `free`, which is
  /// normally the only method when it appears) keeps the old fallback rank.
  ///
  /// The wallet tests must stay ABOVE the `ngenius` substring test: the wallet
  /// method codes are `ngeniusonline_applepay` / `ngeniusonline_samsungpay`, so a substring
  /// check would swallow them into the card row's rank and leave their relative
  /// order down to whatever the API happened to return.
  static int _payRank(String code) {
    final c = code.toLowerCase();
    switch (walletForMethodCode(code)) {
      case PaymentWallet.applePay:
        return 0;
      case PaymentWallet.samsungPay:
        return 1;
      case PaymentWallet.card:
        break;
    }
    if (c.contains('ngenius') || c.contains('network')) return 2;
    if (c.contains('tabby')) return 3;
    if (_isCod(c)) return 4;
    if (c.contains('checkmo') || c.contains('check')) return 5;
    return 50;
  }

  static bool _isCod(String code) {
    final c = code.toLowerCase();
    return c.contains('cashondelivery') || c.contains('cash_on_delivery') ||
        c == 'cod';
  }

  /// Cash on Delivery when present (QA default), else the first method.
  ///
  /// Deliberately still COD even though DEV27 moves its row to the bottom:
  /// Place Order stays armed on open as it does today, and pre-selecting the
  /// first row would arm a wallet payment sheet the shopper never asked for.
  PaymentMethodOption? _defaultPayment(List<PaymentMethodOption> methods) {
    if (methods.isEmpty) return null;
    for (final m in methods) {
      if (_isCod(m.code)) return m;
    }
    return methods.first;
  }

  Future<bool> selectPayment(PaymentMethodOption method) async {
    final cartId = _cartId;
    if (cartId == null) return false;
    state = state.copyWith(isBusy: true, error: null);
    try {
      await _repo.setPaymentMethod(cartId, method.code);
      state = state.copyWith(selectedPayment: method, isBusy: false);
      return true;
    } catch (error) {
      state = state.copyWith(isBusy: false, error: error);
      return false;
    }
  }

  /// Sends a guest-checkout OTP to the cart's shipping phone. Throws [Failure]
  /// (localized `detail`) so the verify card can surface the backend message;
  /// deliberately does **not** touch `isBusy` (the card owns its own local
  /// spinner, avoiding the screen-wide busy barrier for a small inline action).
  Future<void> requestGuestOtp() async {
    final cartId = _cartId;
    if (cartId == null) throw const Failure(FailureKind.unknown);
    await _repo.requestGuestCheckoutOtp(cartId);
  }

  /// Verifies the guest-checkout OTP and binds it to the quote so `placeOrder`
  /// is allowed. Throws [Failure] on a wrong/expired code.
  Future<void> verifyGuestOtp(String code) async {
    final cartId = _cartId;
    if (cartId == null) throw const Failure(FailureKind.unknown);
    await _repo.verifyGuestCheckoutOtp(cartId, code);
    state = state.copyWith(guestOtpVerified: true);
  }

  Future<PlaceOrderResult?> placeOrder() async {
    final cartId = _cartId;
    if (cartId == null) return null;
    state = state.copyWith(isBusy: true, error: null);
    try {
      final result = await _repo.placeOrder(cartId);
      // The order consumed the cart server-side — reset it (drop the stale id +
      // persisted guest id) so it reads empty and the next add-to-cart creates a
      // fresh cart, instead of failing against the consumed one.
      await ref.read(cartControllerProvider.notifier).clearAfterOrder();
      state = state.copyWith(isBusy: false);
      return result;
    } catch (error) {
      state = state.copyWith(isBusy: false, error: error);
      return null;
    }
  }

  /// Loads the gateway session for a placed order. A `PENDING` session isn't yet
  /// launchable, so we back-off poll a few times before giving up (the contract's
  /// PENDING flow). A guest order authorizes via **either** the Magento order
  /// [orderToken] (`placeOrder.orderV2.token`) **or** the billing email +
  /// lastname captured at checkout; both are sent. A logged-in customer sends
  /// only the order number (the bearer authorizes). Null when the resolver
  /// isn't deployed.
  Future<PaymentSession?> loadPaymentSession(
    String orderNumber, {
    String? orderToken,
  }) async {
    final guest = state.isGuest;
    final email = guest ? state.email : null;
    final lastname = guest ? state.lastname : null;
    final token = guest ? orderToken : null;
    const maxAttempts = 4;
    PaymentSession? session;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      session = await _repo.fetchPaymentSession(
        orderNumber,
        email: email,
        lastname: lastname,
        token: token,
      );
      if (session == null ||
          session.status != PaymentSessionStatus.pending ||
          attempt == maxAttempts - 1) {
        return session;
      }
      await Future<void>.delayed(Duration(seconds: 1 + attempt));
    }
    return session;
  }
}

final checkoutControllerProvider =
    NotifierProvider<CheckoutController, CheckoutState>(CheckoutController.new);
