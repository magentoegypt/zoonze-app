import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/graphql_failure_mapper.dart';
import '../../../core/graphql/graphql_client.dart';
import '../../catalog/data/product_mapper.dart';
import '../../catalog/domain/money.dart';
import '../domain/checkout.dart';
import 'checkout_queries.dart';

class CheckoutRepository {
  CheckoutRepository(this._client);

  final GraphQLClient _client;

  Future<void> setGuestEmail(String cartId, String email) =>
      _mutate(CheckoutQueries.setGuestEmail, {'cartId': cartId, 'email': email});

  /// Sets the shipping address and returns the available shipping methods.
  Future<List<ShippingMethodOption>> setShippingAddress(
    String cartId,
    Map<String, dynamic> address,
  ) async {
    final data = await _mutate(CheckoutQueries.setShippingAddress,
        {'cartId': cartId, 'address': address});
    final addresses = ((data['setShippingAddressesOnCart']
            as Map<String, dynamic>?)?['cart'] as Map<String, dynamic>?)?[
        'shipping_addresses'] as List<dynamic>?;
    final methods = (addresses != null && addresses.isNotEmpty)
        ? (addresses.first as Map<String, dynamic>)['available_shipping_methods']
            as List<dynamic>?
        : null;
    return (methods ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_parseShipping)
        .toList();
  }

  /// Selects a shipping method; returns the updated grand total.
  Future<Money?> setShippingMethod(
    String cartId,
    String carrier,
    String method,
  ) async {
    final data = await _mutate(CheckoutQueries.setShippingMethod,
        {'cartId': cartId, 'carrier': carrier, 'method': method});
    final prices = ((data['setShippingMethodsOnCart']
            as Map<String, dynamic>?)?['cart'] as Map<String, dynamic>?)?['prices']
        as Map<String, dynamic>?;
    return moneyFromJson(prices?['grand_total'] as Map<String, dynamic>?);
  }

  /// Sets billing = shipping and returns the available payment methods.
  Future<List<PaymentMethodOption>> setBillingSameAsShipping(
      String cartId) async {
    final data = await _mutate(
        CheckoutQueries.setBillingSameAsShipping, {'cartId': cartId});
    final methods = ((data['setBillingAddressOnCart']
            as Map<String, dynamic>?)?['cart'] as Map<String, dynamic>?)?[
        'available_payment_methods'] as List<dynamic>?;
    return (methods ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((m) => PaymentMethodOption(
              code: (m['code'] as String?) ?? '',
              title: (m['title'] as String?) ?? '',
            ))
        .toList();
  }

  Future<void> setPaymentMethod(String cartId, String code) =>
      _mutate(CheckoutQueries.setPaymentMethod, {'cartId': cartId, 'code': code});

  Future<PlaceOrderResult> placeOrder(String cartId) async {
    final data = await _mutate(CheckoutQueries.placeOrder, {'cartId': cartId});
    final order =
        (data['placeOrder'] as Map<String, dynamic>?)?['order'] as Map<String, dynamic>?;
    return PlaceOrderResult(
      orderNumber: (order?['order_number'] as String?) ?? '',
    );
  }

  ShippingMethodOption _parseShipping(Map<String, dynamic> json) =>
      ShippingMethodOption(
        carrierCode: (json['carrier_code'] as String?) ?? '',
        methodCode: (json['method_code'] as String?) ?? '',
        title: [json['carrier_title'], json['method_title']]
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .join(' · '),
        amount: moneyFromJson(json['amount'] as Map<String, dynamic>?),
      );

  Future<Map<String, dynamic>> _mutate(
    String document,
    Map<String, dynamic> variables,
  ) async {
    try {
      final result = await _client.mutate(MutationOptions(
        document: gql(document),
        variables: variables,
        fetchPolicy: FetchPolicy.networkOnly,
      ));
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
