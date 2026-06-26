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

  Future<PlaceOrderResult> placeOrder(String cartId) async {
    final data = await _mutate(CheckoutQueries.placeOrder, {'cartId': cartId});
    final order =
        (data['placeOrder'] as Map<String, dynamic>?)?['order']
            as Map<String, dynamic>?;
    final number = order?['order_number'] as String?;
    // A response without an order number is not a success — surface it as a
    // failure rather than routing the user to a blank-reference success screen.
    if (number == null || number.isEmpty) {
      throw const Failure(FailureKind.unknown);
    }
    return PlaceOrderResult(orderNumber: number);
  }

  /// Fetches the provider session reference for a placed order. Returns null
  /// when the backend `paymentSession` resolver is not deployed yet (Open Q §2)
  /// or surfaces no session, so checkout shows the awaiting-payment state rather
  /// than a fabricated payment UI.
  Future<PaymentSession?> fetchPaymentSession(String orderNumber) async {
    try {
      final data = await _query(CheckoutQueries.paymentSession, {
        'orderNumber': orderNumber,
      });
      final json = data['paymentSession'] as Map<String, dynamic>?;
      if (json == null) return null;
      return PaymentSession(
        orderNumber: (json['order_number'] as String?) ?? orderNumber,
        methodCode: (json['method_code'] as String?) ?? '',
        status: _sessionStatus(json['status'] as String?),
        sessionReference: json['session_reference'] as String?,
        redirectUrl: json['redirect_url'] as String?,
        clientToken: json['client_token'] as String?,
        publicKey: json['public_key'] as String?,
        expiresAt: json['expires_at'] as String?,
        additionalData: _keyValues(json['additional_data'] as List<dynamic>?),
      );
    } on Failure {
      return null;
    }
  }

  /// Fetches the backend-configured Tabby products ("Pay in 4" + "Pay Later")
  /// with their enable flags and thresholds. Returns null when the resolver
  /// isn't deployed or Tabby is unconfigured, so the promo/labels hide.
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
        currency: (json['currency'] as String?) ?? 'AED',
        products: products,
      );
    } on Failure {
      return null;
    }
  }

  TabbyProduct? _tabbyProduct(Map<String, dynamic> json) {
    final type = _tabbyType(json['type'] as String?);
    if (type == null) return null;
    return TabbyProduct(
      type: type,
      enabled: (json['enabled'] as bool?) ?? false,
      installments:
          (json['installments'] as num?)?.toInt() ??
          (type == TabbyProductType.payIn4 ? 4 : 1),
      minOrderTotal: moneyFromJson(
        json['min_order_total'] as Map<String, dynamic>?,
      )?.amount,
      maxOrderTotal: moneyFromJson(
        json['max_order_total'] as Map<String, dynamic>?,
      )?.amount,
    );
  }

  TabbyProductType? _tabbyType(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'PAY_IN_4':
      case 'PAY_IN_INSTALLMENTS':
      case 'INSTALLMENTS':
        return TabbyProductType.payIn4;
      case 'PAY_LATER':
      case 'PAYLATER':
        return TabbyProductType.payLater;
      default:
        return null;
    }
  }

  PaymentSessionStatus _sessionStatus(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'READY':
        return PaymentSessionStatus.ready;
      case 'FAILED':
        return PaymentSessionStatus.failed;
      case 'REJECTED':
        return PaymentSessionStatus.rejected;
      case 'EXPIRED':
        return PaymentSessionStatus.expired;
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
