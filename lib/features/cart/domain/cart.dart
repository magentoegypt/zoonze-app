import '../../catalog/domain/money.dart';

/// A line item in the cart.
class CartItem {
  const CartItem({
    required this.uid,
    required this.sku,
    required this.name,
    required this.quantity,
    this.imageUrl,
    this.unitPrice,
    this.rowTotal,
    this.options = const <String>[],
  });

  final String uid;
  final String sku;
  final String name;
  final int quantity;
  final String? imageUrl;
  final Money? unitPrice;
  final Money? rowTotal;

  /// Display strings for chosen configurable options, e.g. "Size: 100ml".
  final List<String> options;
}

class CartTotals {
  const CartTotals({
    this.grandTotal,
    this.subtotal,
    this.discount,
    this.appliedCoupon,
  });

  final Money? grandTotal;
  final Money? subtotal;
  final Money? discount;
  final String? appliedCoupon;
}

class Cart {
  const Cart({
    required this.id,
    this.items = const <CartItem>[],
    this.totals = const CartTotals(),
  });

  final String id;
  final List<CartItem> items;
  final CartTotals totals;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => items.isEmpty;

  static const Cart empty = Cart(id: '');
}
