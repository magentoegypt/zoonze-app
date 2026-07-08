import '../../catalog/domain/money.dart';

class OrderLine {
  const OrderLine({
    required this.name,
    required this.quantity,
    this.price,
    this.imageUrl,
    this.sku,
    this.urlKey,
  });

  final String name;
  final double quantity;
  final Money? price;

  /// Product thumbnail (order item's linked product), null when unavailable.
  final String? imageUrl;

  /// Product sku / url_key — for reorder and product navigation.
  final String? sku;
  final String? urlKey;
}

/// A shipment tracking entry (carrier + tracking number) for a shipped order.
class OrderTracking {
  const OrderTracking({
    required this.title,
    required this.number,
    required this.carrier,
  });

  final String title;
  final String number;
  final String carrier;
}

/// One entry of the Magento order status history (real status change comment).
class OrderComment {
  const OrderComment({required this.message, required this.timestamp});

  final String message;
  final String timestamp;
}

class CustomerOrder {
  const CustomerOrder({
    required this.number,
    required this.status,
    required this.date,
    this.total,
    this.subtotal,
    this.shippingAmount,
    this.shippingMethod,
    this.carrier,
    this.shippingName,
    this.shippingAddress,
    this.paymentMethodName,
    this.billingName,
    this.billingAddress,
    this.lines = const <OrderLine>[],
    this.trackings = const <OrderTracking>[],
    this.comments = const <OrderComment>[],
  });

  final String number;
  final String status;
  final String date;
  final Money? total;
  final Money? subtotal;
  final Money? shippingAmount;
  final String? shippingMethod;
  final String? carrier;

  /// Recipient name + single-line delivery address (shipping address).
  final String? shippingName;
  final String? shippingAddress;

  /// Payment method label (e.g. "Cash on Delivery", "Tabby").
  final String? paymentMethodName;

  /// Billing recipient name + single-line billing address.
  final String? billingName;
  final String? billingAddress;

  final List<OrderLine> lines;
  final List<OrderTracking> trackings;

  /// Real status-history entries (newest last), for the tracking timeline.
  final List<OrderComment> comments;

  bool get hasTracking => trackings.isNotEmpty;

  /// Distinct products in the order (matches the thumbnail count / "Items (N)").
  int get itemCount => lines.length;

  bool get isDelivered {
    final s = status.toLowerCase();
    return s.contains('complet') || s.contains('deliver');
  }

  bool get isCancelled {
    final s = status.toLowerCase();
    return s.contains('cancel') || s.contains('refund') || s.contains('closed');
  }
}

/// A page of customer orders (for append-on-scroll pagination).
class OrderPage {
  const OrderPage({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
  });

  final List<CustomerOrder> items;
  final int currentPage;
  final int totalPages;
  final int totalCount;

  static const OrderPage empty = OrderPage(
    items: [],
    currentPage: 0,
    totalPages: 0,
    totalCount: 0,
  );
}
