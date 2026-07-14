import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/graphql_failure_mapper.dart';
import '../../../core/graphql/graphql_client.dart';
import '../../../core/store/store_controller.dart';
import '../../../core/util/media.dart';
import '../../catalog/data/product_mapper.dart';
import '../../catalog/domain/money.dart';
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

  /// Writes the verified [mobileNumber] (E.164) to the `mobile_number` custom
  /// attribute. The caller must OTP-verify the number first (see the Edit
  /// Profile mobile editor).
  Future<void> updateMobileNumber(String mobileNumber) => _run(
    AccountQueries.updateMobile,
    {'value': mobileNumber},
    mutation: true,
  );

  /// Uploads/replaces the customer avatar. [base64File] is the raw base64 of a
  /// jpg/png/webp (no data: prefix). Caller refetches the customer afterwards to
  /// pick up the new `avatar_url`.
  Future<void> uploadAvatar(String base64File) => _run(
    AccountQueries.uploadAvatar,
    {'file': base64File},
    mutation: true,
  );

  Future<void> deleteAvatar() =>
      _run(AccountQueries.deleteAvatar, const {}, mutation: true);

  /// Discovers the `address_label` select options (id + store-scoped label) so
  /// the "Save as" chips map to option ids without hardcoding. Empty on error.
  Future<List<({String value, String label})>> fetchAddressLabelOptions() async {
    try {
      final data = await _run(
        AccountQueries.addressLabelMetadata,
        const {},
        mutation: false,
      );
      final items =
          (data['customAttributeMetadataV2'] as Map<String, dynamic>?)?['items']
              as List<dynamic>? ??
          const [];
      for (final item in items) {
        if (item is Map<String, dynamic> && item['code'] == 'address_label') {
          return (item['options'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(
                (o) => (
                  value: (o['value'] as String?) ?? '',
                  label: (o['label'] as String?) ?? '',
                ),
              )
              .where((o) => o.value.isNotEmpty && o.label.isNotEmpty)
              .toList();
        }
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

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
            imageUrl: httpsMediaUrl(
              (l['product'] as Map<String, dynamic>?)?['image']?['url']
                  as String?,
            ),
            sku: l['product_sku'] as String?,
            urlKey: l['product_url_key'] as String?,
          ),
        )
        .toList();
    final totals = json['total'] as Map<String, dynamic>?;
    // Magento returns `discounts` as a list (coupon + catalog rules can stack);
    // sum the amounts so the totals reconcile, and keep the first label for the
    // "Discount (<rule>)" line — matching the website order summary.
    final discountList = totals?['discounts'] as List<dynamic>?;
    Money? discount;
    String? discountLabel;
    if (discountList != null && discountList.isNotEmpty) {
      var sum = 0.0;
      var currency = 'AED';
      for (final d in discountList.whereType<Map<String, dynamic>>()) {
        final amt = d['amount'] as Map<String, dynamic>?;
        final v = (amt?['value'] as num?)?.toDouble();
        if (v != null) {
          sum += v;
          currency = (amt?['currency'] as String?) ?? currency;
        }
        final label = (d['label'] as String?)?.trim();
        if (discountLabel == null && label != null && label.isNotEmpty) {
          discountLabel = label;
        }
      }
      if (sum > 0) discount = Money(amount: sum, currency: currency);
    }
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
    final comments = (json['comments'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(
          (c) => OrderComment(
            message: (c['message'] as String?) ?? '',
            timestamp: (c['timestamp'] as String?) ?? '',
          ),
        )
        .toList();
    final addr = json['shipping_address'] as Map<String, dynamic>?;
    final billing = json['billing_address'] as Map<String, dynamic>?;
    final payments = json['payment_methods'] as List<dynamic>?;
    String? paymentName;
    if (payments != null && payments.isNotEmpty) {
      final first = payments.first;
      if (first is Map<String, dynamic>) {
        paymentName = first['name'] as String?;
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
      discount: discount,
      discountLabel: discountLabel,
      shippingMethod: json['shipping_method'] as String?,
      carrier: json['carrier'] as String?,
      shippingName: _recipientName(addr),
      shippingAddress: _formatAddress(addr),
      shippingPhone: _phone(addr),
      paymentMethodName: paymentName,
      billingName: _recipientName(billing),
      billingAddress: _formatAddress(billing),
      billingPhone: _phone(billing),
      lines: lines,
      trackings: trackings,
      comments: comments,
    );
  }

  String? _phone(Map<String, dynamic>? a) {
    final t = (a?['telephone'] as String?)?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  String? _recipientName(Map<String, dynamic>? a) {
    if (a == null) return null;
    final name = [a['firstname'], a['lastname']]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' ');
    return name.isEmpty ? null : name;
  }

  String? _formatAddress(Map<String, dynamic>? a) {
    if (a == null) return null;
    final street = (a['street'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(', ');
    final parts = [street, a['city'] as String?, a['region'] as String?]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList();
    return parts.isEmpty ? null : parts.join(', ');
  }

  CustomerAddress _parseAddress(Map<String, dynamic> json) {
    final streetLines = (json['street'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList();
    final region = json['region'] as Map<String, dynamic>?;
    final label = _addressLabel(json['custom_attributesV2']);
    return CustomerAddress(
      id: (json['id'] as num?)?.toInt(),
      firstName: (json['firstname'] as String?) ?? '',
      lastName: (json['lastname'] as String?) ?? '',
      telephone: (json['telephone'] as String?) ?? '',
      street: streetLines.isNotEmpty ? streetLines.first : '',
      apartment: streetLines.length > 1 ? streetLines.sublist(1).join(', ') : '',
      city: (json['city'] as String?) ?? '',
      postcode: (json['postcode'] as String?) ?? '',
      region: (region?['region'] as String?) ?? '',
      regionId: (region?['region_id'] as num?)?.toInt(),
      countryCode: (json['country_code'] as String?) ?? 'AE',
      defaultShipping: (json['default_shipping'] as bool?) ?? false,
      defaultBilling: (json['default_billing'] as bool?) ?? false,
      labelOptionId: label?.value,
      labelText: label?.label,
    );
  }

  /// Extracts the selected `address_label` option ({value, label}) from an
  /// address's `custom_attributesV2`, or null when unset.
  ({String value, String label})? _addressLabel(dynamic attrs) {
    if (attrs is! List) return null;
    for (final a in attrs) {
      if (a is Map<String, dynamic> && a['code'] == 'address_label') {
        final selected = a['selected_options'] as List<dynamic>?;
        if (selected != null && selected.isNotEmpty) {
          final opt = selected.first;
          if (opt is Map<String, dynamic>) {
            final value = opt['value'] as String?;
            if (value != null && value.isNotEmpty) {
              return (value: value, label: (opt['label'] as String?) ?? '');
            }
          }
        }
      }
    }
    return null;
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
    // Re-fetch against the new store view when the language/store switches (the
    // GraphQL cache is reset on switch); otherwise the list keeps the previous
    // store view's data or goes empty. Mirrors CartController's store listener.
    ref.listen<String>(
      storeControllerProvider.select((s) => s.activeStoreCode),
      (prev, next) {
        if (prev != null && prev != next) Future.microtask(_loadFirst);
      },
    );
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

/// The `address_label` select options (Home/Office/Other → option ids),
/// store-scoped so the AR store returns AR labels. Drives the Save-as chips.
final addressLabelOptionsProvider =
    FutureProvider.autoDispose<List<({String value, String label})>>((ref) {
      ref.watch(storeControllerProvider.select((s) => s.activeStoreCode));
      return ref.watch(accountRepositoryProvider).fetchAddressLabelOptions();
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
