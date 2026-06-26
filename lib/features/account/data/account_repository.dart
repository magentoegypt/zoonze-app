import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/graphql_failure_mapper.dart';
import '../../../core/graphql/graphql_client.dart';
import '../../catalog/data/product_mapper.dart';
import '../domain/customer_address.dart';
import '../domain/order.dart';
import 'account_queries.dart';

class AccountRepository {
  AccountRepository(this._client);

  final GraphQLClient _client;

  Future<List<CustomerOrder>> fetchOrders() async {
    final data = await _run(AccountQueries.orders, const {}, mutation: false);
    final orders =
        ((data['customer'] as Map<String, dynamic>?)?['orders']
                as Map<String, dynamic>?)?['items']
            as List<dynamic>?;
    return (orders ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_parseOrder)
        .toList();
  }

  Future<List<CustomerAddress>> fetchAddresses() async {
    final data = await _run(
      AccountQueries.addresses,
      const {},
      mutation: false,
    );
    final addresses =
        (data['customer'] as Map<String, dynamic>?)?['addresses']
            as List<dynamic>?;
    return (addresses ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_parseAddress)
        .toList();
  }

  Future<void> createAddress(CustomerAddress address) => _run(
    AccountQueries.createAddress,
    {'input': address.toInput()},
    mutation: true,
  );

  Future<void> updateAddress(int id, CustomerAddress address) => _run(
    AccountQueries.updateAddress,
    {'id': id, 'input': address.toInput()},
    mutation: true,
  );

  Future<void> deleteAddress(int id) =>
      _run(AccountQueries.deleteAddress, {'id': id}, mutation: true);

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
  }) => _run(AccountQueries.updateProfile, {
    'input': {'firstname': firstName, 'lastname': lastName},
  }, mutation: true);

  Future<void> changePassword(String current, String next) => _run(
    AccountQueries.changePassword,
    {'currentPassword': current, 'newPassword': next},
    mutation: true,
  );

  CustomerOrder _parseOrder(Map<String, dynamic> json) {
    final lines = (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(
          (l) => OrderLine(
            name: (l['product_name'] as String?) ?? '',
            quantity: (l['quantity_ordered'] as num?)?.toDouble() ?? 1,
            price: moneyFromJson(
              l['product_sale_price'] as Map<String, dynamic>?,
            ),
          ),
        )
        .toList();
    return CustomerOrder(
      number: (json['number'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
      date: (json['order_date'] as String?) ?? '',
      total: moneyFromJson(
        (json['total'] as Map<String, dynamic>?)?['grand_total']
            as Map<String, dynamic>?,
      ),
      lines: lines,
    );
  }

  CustomerAddress _parseAddress(Map<String, dynamic> json) {
    final street = (json['street'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .join(', ');
    final region = json['region'] as Map<String, dynamic>?;
    return CustomerAddress(
      id: (json['id'] as num?)?.toInt(),
      firstName: (json['firstname'] as String?) ?? '',
      lastName: (json['lastname'] as String?) ?? '',
      telephone: (json['telephone'] as String?) ?? '',
      street: street,
      city: (json['city'] as String?) ?? '',
      postcode: (json['postcode'] as String?) ?? '',
      region: (region?['region'] as String?) ?? '',
      countryCode: (json['country_code'] as String?) ?? 'AE',
      defaultShipping: (json['default_shipping'] as bool?) ?? false,
      defaultBilling: (json['default_billing'] as bool?) ?? false,
    );
  }

  Future<Map<String, dynamic>> _run(
    String document,
    Map<String, dynamic> variables, {
    required bool mutation,
  }) async {
    try {
      final result = mutation
          ? await _client.mutate(
              MutationOptions(
                document: gql(document),
                variables: variables,
                fetchPolicy: FetchPolicy.networkOnly,
              ),
            )
          : await _client.query(
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

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepository(ref.watch(graphqlClientProvider)),
);

/// Orders for the signed-in customer (empty when not authenticated).
final ordersProvider = FutureProvider.autoDispose<List<CustomerOrder>>((ref) {
  return ref.watch(accountRepositoryProvider).fetchOrders();
});

/// Saved addresses for the signed-in customer.
final addressesProvider = FutureProvider.autoDispose<List<CustomerAddress>>((
  ref,
) {
  return ref.watch(accountRepositoryProvider).fetchAddresses();
});
