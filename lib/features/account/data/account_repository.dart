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

  Future<OrderPage> fetchOrders({int pageSize = 10, int currentPage = 1}) async {
    final data = await _run(AccountQueries.orders, {
      'pageSize': pageSize,
      'currentPage': currentPage,
    }, mutation: false);
    final orders =
        (data['customer'] as Map<String, dynamic>?)?['orders']
            as Map<String, dynamic>?;
    if (orders == null) return OrderPage.empty;
    final items = (orders['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_parseOrder)
        .toList();
    final pageInfo = orders['page_info'] as Map<String, dynamic>?;
    return OrderPage(
      items: items,
      totalCount: (orders['total_count'] as int?) ?? items.length,
      currentPage: (pageInfo?['current_page'] as int?) ?? currentPage,
      totalPages: (pageInfo?['total_pages'] as int?) ?? 1,
    );
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
    final totals = json['total'] as Map<String, dynamic>?;
    final trackings = <OrderTracking>[];
    for (final shipment in (json['shipments'] as List<dynamic>? ?? const [])) {
      if (shipment is! Map<String, dynamic>) continue;
      for (final t in (shipment['tracking'] as List<dynamic>? ?? const [])) {
        if (t is! Map<String, dynamic>) continue;
        final number = (t['number'] as String?) ?? '';
        if (number.isEmpty) continue;
        trackings.add(
          OrderTracking(
            title: (t['title'] as String?) ?? '',
            number: number,
            carrier: (t['carrier'] as String?) ?? '',
          ),
        );
      }
    }
    return CustomerOrder(
      number: (json['number'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
      date: (json['order_date'] as String?) ?? '',
      total: moneyFromJson(totals?['grand_total'] as Map<String, dynamic>?),
      subtotal: moneyFromJson(totals?['subtotal'] as Map<String, dynamic>?),
      shippingAmount: moneyFromJson(
        totals?['total_shipping'] as Map<String, dynamic>?,
      ),
      shippingMethod: json['shipping_method'] as String?,
      carrier: json['carrier'] as String?,
      lines: lines,
      trackings: trackings,
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

/// Paginated orders list state for the signed-in customer.
class OrdersState {
  const OrdersState({
    this.orders = const <CustomerOrder>[],
    this.currentPage = 0,
    this.totalPages = 0,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.error,
  });

  final List<CustomerOrder> orders;
  final int currentPage;
  final int totalPages;
  final bool isLoading;
  final bool isLoadingMore;
  final Object? error;

  bool get hasMore => currentPage < totalPages;

  OrdersState copyWith({
    List<CustomerOrder>? orders,
    int? currentPage,
    int? totalPages,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error = _keep,
  }) => OrdersState(
    orders: orders ?? this.orders,
    currentPage: currentPage ?? this.currentPage,
    totalPages: totalPages ?? this.totalPages,
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    error: identical(error, _keep) ? this.error : error,
  );

  static const Object _keep = Object();
}

/// Owns the customer's orders list with append-on-scroll pagination.
class OrdersController extends AutoDisposeNotifier<OrdersState> {
  static const int _pageSize = 10;

  @override
  OrdersState build() {
    Future.microtask(_loadFirst);
    return const OrdersState();
  }

  AccountRepository get _repo => ref.read(accountRepositoryProvider);

  Future<void> _loadFirst() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final page = await _repo.fetchOrders(pageSize: _pageSize, currentPage: 1);
      state = state.copyWith(
        orders: page.items,
        currentPage: page.currentPage,
        totalPages: page.totalPages,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final page = await _repo.fetchOrders(
        pageSize: _pageSize,
        currentPage: state.currentPage + 1,
      );
      state = state.copyWith(
        orders: [...state.orders, ...page.items],
        currentPage: page.currentPage,
        totalPages: page.totalPages,
        isLoadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> refresh() => _loadFirst();
}

final ordersControllerProvider =
    AutoDisposeNotifierProvider<OrdersController, OrdersState>(
      OrdersController.new,
    );

/// Saved addresses for the signed-in customer.
final addressesProvider = FutureProvider.autoDispose<List<CustomerAddress>>((
  ref,
) {
  return ref.watch(accountRepositoryProvider).fetchAddresses();
});

/// Real order count for the drawer/account quick-stats (cheap pageSize:1 query).
/// Isolated + error-safe so it never blocks the drawer; 0 on failure.
final customerOrderCountProvider = FutureProvider.autoDispose<int>((ref) async {
  try {
    final page = await ref
        .watch(accountRepositoryProvider)
        .fetchOrders(pageSize: 1);
    return page.totalCount;
  } catch (_) {
    return 0;
  }
});
