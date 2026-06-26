import '../../catalog/domain/money.dart';

class OrderLine {
  const OrderLine({required this.name, required this.quantity, this.price});

  final String name;
  final double quantity;
  final Money? price;
}

class CustomerOrder {
  const CustomerOrder({
    required this.number,
    required this.status,
    required this.date,
    this.total,
    this.lines = const <OrderLine>[],
  });

  final String number;
  final String status;
  final String date;
  final Money? total;
  final List<OrderLine> lines;
}
