import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/graphql_failure_mapper.dart';
import '../../../core/graphql/graphql_client.dart';
import '../../catalog/data/product_mapper.dart';
import '../../catalog/domain/money.dart';
import '../domain/checkout.dart';
import '../domain/payment_session.dart';
import '../domain/tabby_config.dart';
import 'checkout_queries.dart';

class CheckoutRepository {
  CheckoutRepository(this._client);

  final GraphQLClient _client;

  Future<void> setGuestEmail(String cartId, String email) => _mutate(
    CheckoutQueries.setGuestEmail,
    {'cartId': cartId, 'email': email},
  );

  /// Sets the shipping address and returns the available shipping methods.
  Future<List<ShippingMethodOption>> setShippingAddress(
    String cartId,
    Map<String, dynamic> address,
  ) async {
    final data = await _mutate(CheckoutQueries.setShippingAddress, {
      'cartId': cartId,
      'address': address,
    });
    final addresses =
        ((data['setShippingAddressesOnCart'] as Map<String, dynamic>?)?['cart']
                as Map<String, dynamic>?)?['shipping_addresses']
            as List<dynamic>?;
    final methods = (addresses != null && addresses.isNotEmpty)
        ? (addresses.first
                  as Map<String, dynamic>)['available_shipping_methods']
              as List<dynamic>?
        : null;
    return (methods ?? const [])
        .whereType<Map<String, dynamic>>()
        // Drop carriers Magento flags as unavailable for this address (these
        // come back with available=false and often a null method_code); keep
        // entries where the flag is absent so an older schema still works.
        .where((m) => m['available'] != false)
        .map(_parseShipping)
        .toList();
  }

  /// Selects a shipping method; returns the updated grand total.
  Future<Money?> setShippingMethod(
    String cartId,
    String carrier,
    String method,
  ) async {
    final data = await _mutate(CheckoutQueries.setShippingMethod, {
      'cartId': cartId,
      'carrier': carrier,
      'method': method,
    });
    final prices =
        ((data['setShippingMethodsOnCart'] as Map<String, dynamic>?)?['cart']
                as Map<String, dynamic>?)?['prices']
            as Map<String, dynamic>?;
    return moneyFromJson(prices?['grand_total'] as Map<String, dynamic>?);
  }

  /// Sets billing = shipping and returns the available payment methods.
  Future<List<PaymentMethodOption>> setBillingSameAsShipping(
    String cartId,
  ) async {
    final data = await _mutate(CheckoutQueries.setBillingSameAsShipping, {
      'cartId': cartId,
    });
    final methods =
        ((data['setBillingAddressOnCart'] as Map<String, dynamic>?)?['cart']
                as Map<String, dynamic>?)?['available_payment_methods']
            as List<dynamic>?;
    return (methods ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(
          (m) => PaymentMethodOption(
            code: (m['code'] as String?) ?? '',
            title: (m['title'] as String?) ?? '',
          ),
        )
        .toList();
  }

  Future<void> setPaymentMethod(String cartId, String code) => _mutate(
    CheckoutQueries.setPaymentMethod,
    {'cartId': cartId, 'code': code},
  );

  /// Sends a guest-checkout OTP to the cart's shipping phone. The address (with
  /// a +971 telephone) must already be on the cart. Throws [Failure] (with the
  /// localized message in `detail`) if the cart has no phone / OTP send fails.
  Future<void> requestGuestCheckoutOtp(String cartId) =>
      _mutate(CheckoutQueries.requestGuestCheckoutOtp, {'cartId': cartId});

  /// Verifies the guest-checkout OTP and binds the challenge to the quote so
  /// `placeOrder` is allowed. Throws [Failure] on a wrong/expired code.
  Future<void> verifyGuestCheckoutOtp(String cartId, String code) => _mutate(
    CheckoutQueries.verifyGuestCheckoutOtp,
    {'cartId': cartId, 'code': code},
  );

  Future<PlaceOrderResult> placeOrder(String cartId) async {
    final data = await _mutate(CheckoutQueries.placeOrder, {'cartId': cartId});
    final placed = data['placeOrder'] as Map<String, dynamic>?;
    final order = placed?['order'] as Map<String, dynamic>?;
    final orderV2 = placed?['orderV2'] as Map<String, dynamic>?;
    final number =
        (order?['order_number'] as String?) ?? (orderV2?['number'] as String?);
    // A response without an order number is not a success — surface it as a
    // failure rather than routing the user to a blank-reference success screen.
    if (number == null || number.isEmpty) {
      throw const Failure(FailureKind.unknown);
    }
    final token = orderV2?['token'] as String?;
    return PlaceOrderResult(
      orderNumber: number,
      orderToken: (token != null && token.isNotEmpty) ? token : null,
    );
  }

  /// Fetches the provider session reference for a placed order. Returns null
  /// when the backend `paymentSession` resolver is not deployed yet (Open Q §2)
  /// or surfaces no session, so checkout shows the awaiting-payment state rather
  /// than a fabricated payment UI.
  /// A guest (no customer bearer) authorizes the call for the order they just
  /// placed by **either** the Magento order [token] (`placeOrder.orderV2.token`)
  /// **or** the billing [email] + [lastname] entered at checkout — the live
  /// `paymentSession(... email, lastname, token)` resolver uses whichever
  /// validates. All null for logged-in customers (the bearer authorizes).
  Future<PaymentSession?> fetchPaymentSession(
    String orderNumber, {
    String? email,
    String? lastname,
    String? token,
  }) async {
    try {
      final data = await _query(CheckoutQueries.paymentSession, {
        'orderNumber': orderNumber,
        'email': email,
        'lastname': lastname,
        'token': token,
      });
      return _parseSession(
        data['paymentSession'] as Map<String, dynamic>?,
        orderNumber,
      );
    } on Failure {
      return null;
    } catch (_) {
      // A malformed-but-200 response (unexpected JSON shape) must degrade to
      // "awaiting payment", not crash the checkout flow with a cast error.
      return null;
    }
  }

  /// Switches a placed order's payment method and returns the new session, for
  /// the post-order retry flow. Null on error → caller keeps the user on the
  /// complete-payment screen.
  Future<PaymentSession?> setOrderPaymentMethod(
    String orderNumber,
    String methodCode, {
    String? email,
    String? lastname,
    String? token,
  }) async {
    try {
      final data = await _mutate(CheckoutQueries.setOrderPaymentMethod, {
        'orderNumber': orderNumber,
        'methodCode': methodCode,
        'email': email,
        'lastname': lastname,
        'token': token,
      });
      return _parseSession(
        data['setOrderPaymentMethod'] as Map<String, dynamic>?,
        orderNumber,
      );
    } on Failure {
      return null;
    } catch (_) {
      return null;
    }
  }

  PaymentSession? _parseSession(
    Map<String, dynamic>? json,
    String orderNumber,
  ) {
    if (json == null) return null;
    return PaymentSession(
      orderNumber: (json['order_number'] as String?) ?? orderNumber,
      methodCode: (json['method_code'] as String?) ?? '',
      gateway: _gateway(json['gateway'] as String?),
      status: _sessionStatus(json['status'] as String?),
      paymentId: json['payment_id'] as String?,
      webUrl: json['web_url'] as String?,
      publishableKey: json['publishable_key'] as String?,
      additionalData: _keyValues(json['additional_data'] as List<dynamic>?),
    );
  }

  PaymentProvider _gateway(String? raw) => raw?.toUpperCase() == 'TABBY'
      ? PaymentProvider.tabby
      : PaymentProvider.ngenius;

  /// Fetches the backend-configured Tabby products (installments / pay later /
  /// card instalments) with enable flags, thresholds and promo toggles. Returns
  /// null when the resolver isn't deployed or Tabby is unconfigured.
  Future<TabbyConfig?> fetchTabbyConfig() async {
    try {
      final data = await _query(CheckoutQueries.tabbyConfig, const {});
      final json = data['tabbyConfig'] as Map<String, dynamic>?;
      if (json == null) return null;
      final products =
          (json['products'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(_tabbyProduct)
              .whereType<TabbyProduct>()
              .toList() ??
          const <TabbyProduct>[];
      return TabbyConfig(
        enabled: (json['enabled'] as bool?) ?? false,
        currency: (json['currency'] as String?) ?? 'AED',
        publishableKey: json['publishable_key'] as String?,
        merchantCode: json['merchant_code'] as String?,
        products: products,
      );
    } on Failure {
      return null;
    } catch (_) {
      // Malformed-but-200 response → hide the promo rather than crash.
      return null;
    }
  }

  TabbyProduct? _tabbyProduct(Map<String, dynamic> json) {
    final type = _tabbyType(json['type'] as String?);
    if (type == null) return null;
    return TabbyProduct(
      type: type,
      methodCode: (json['method_code'] as String?) ?? '',
      enabled: (json['enabled'] as bool?) ?? false,
      promoEnabled: (json['promo_enabled'] as bool?) ?? false,
      minAmount: (json['min_amount'] as num?)?.toDouble(),
      maxAmount: (json['max_amount'] as num?)?.toDouble(),
    );
  }

  /// Normalises Tabby's many type spellings (case-insensitive) per the contract.
  TabbyProductType? _tabbyType(String? raw) {
    switch (raw?.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_')) {
      case 'installments':
      case 'installment':
      case 'pay_in_4':
      case 'split':
        return TabbyProductType.installments;
      case 'pay_later':
      case 'paylater':
      case 'pay_in_14':
      case 'tabby_checkout':
        return TabbyProductType.payLater;
      case 'credit_card_installments':
      case 'cc_installments':
      case 'creditcard_installments':
        return TabbyProductType.creditCardInstallments;
      default:
        return null;
    }
  }

  PaymentSessionStatus _sessionStatus(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'READY':
        return PaymentSessionStatus.ready;
      case 'REJECTED':
        return PaymentSessionStatus.rejected;
      case 'FAILED':
        return PaymentSessionStatus.failed;
      default:
        return PaymentSessionStatus.pending;
    }
  }

  Map<String, String> _keyValues(List<dynamic>? list) => <String, String>{
    for (final e in (list ?? const []).whereType<Map<String, dynamic>>())
      if (e['key'] is String)
        (e['key'] as String): (e['value'] as String?) ?? '',
  };

  ShippingMethodOption _parseShipping(Map<String, dynamic> json) =>
      ShippingMethodOption(
        carrierCode: (json['carrier_code'] as String?) ?? '',
        methodCode: (json['method_code'] as String?) ?? '',
        title: [
          json['carrier_title'],
          json['method_title'],
        ].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
        amount: moneyFromJson(json['amount'] as Map<String, dynamic>?),
      );

  Future<Map<String, dynamic>> _mutate(
    String document,
    Map<String, dynamic> variables,
  ) async {
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(document),
          variables: variables,
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        throw mapOperationException(result.exception!);
      }
      return result.data ?? const <String, dynamic>{};
    } on Failure {
      rethrow;
    } catch (error) {
      throw Failure(FailureKind.unknown, detail: error.toString());
    }
  }

  Future<Map<String, dynamic>> _query(
    String document,
    Map<String, dynamic> variables,
  ) async {
    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(document),
          variables: variables,
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        throw mapOperationException(result.exception!);
      }
      return result.data ?? const <String, dynamic>{};
    } on Failure {
      rethrow;
    } catch (error) {
      throw Failure(FailureKind.unknown, detail: error.toString());
    }
  }
}

final checkoutRepositoryProvider = Provider<CheckoutRepository>(
  (ref) => CheckoutRepository(ref.watch(graphqlClientProvider)),
);
