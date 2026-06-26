import '../../catalog/domain/money.dart';

class OrderLine {
  const OrderLine({required this.name, required this.quantity, this.price});

  final String name;
  final double quantity;
  final Money? price;
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
    this.lines = const <OrderLine>[],
    this.trackings = const <OrderTracking>[],
  });

  final String number;
  final String status;
  final String date;
  final Money? total;
  final Money? subtotal;
  final Money? shippingAmount;
  final String? shippingMethod;
  final String? carrier;
  final List<OrderLine> lines;
  final List<OrderTracking> trackings;

  bool get hasTracking => trackings.isNotEmpty;
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
