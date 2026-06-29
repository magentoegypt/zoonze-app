import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cart/presentation/cart_controller.dart';
import '../../catalog/domain/money.dart';
import '../data/checkout_repository.dart';
import '../domain/checkout.dart';
import '../domain/payment_session.dart';

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
    isBusy: isBusy ?? this.isBusy,
    error: identical(error, _keep) ? this.error : error,
  );
}

/// Drives the sequential checkout mutations against the active cart.
class CheckoutController extends Notifier<CheckoutState> {
  @override
  CheckoutState build() => const CheckoutState();

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
      if (isGuest && email.isNotEmpty) {
        await _repo.setGuestEmail(cartId, email);
      }
      final methods = await _repo.setShippingAddress(cartId, address);
      state = state.copyWith(
        email: email,
        lastname: (address['lastname'] as String?) ?? '',
        isGuest: isGuest,
        shippingMethods: methods,
        selectedShipping: null,
        paymentMethods: const [],
        selectedPayment: null,
        isBusy: false,
      );
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
      final payments = await _repo.setBillingSameAsShipping(cartId);
      state = state.copyWith(
        selectedShipping: method,
        grandTotal: total,
        paymentMethods: payments,
        selectedPayment: null,
        isBusy: false,
      );
      return true;
    } catch (error) {
      state = state.copyWith(isBusy: false, error: error);
      return false;
    }
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
