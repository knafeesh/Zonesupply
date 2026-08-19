import 'package:flutter/foundation.dart';

class CartItem {
  final String productId;
  final String name;
  final double price;
  final String unit;
  int quantity;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.unit,
    this.quantity = 1,
  });
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantity);
  double get total => _items.fold(0, (sum, i) => sum + i.price * i.quantity);

  void addItem(Map<String, dynamic> product) {
    final idx = _items.indexWhere((i) => i.productId == product['id']);
    if (idx >= 0) {
      _items[idx].quantity++;
    } else {
      _items.add(CartItem(
        productId: product['id'],
        name: product['name'],
        price: () {
          final original = double.tryParse(product['pricePerUnit']?.toString() ?? '0') ?? 0;
          final discount = double.tryParse(product['discount']?.toString() ?? '0') ?? 0;
          return discount > 0 ? original * (1 - discount / 100) : original;
        }(),
        unit: product['unit'] ?? 'unit',
      ));
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.removeWhere((i) => i.productId == productId);
    notifyListeners();
  }

  void decrement(String productId) {
    final idx = _items.indexWhere((i) => i.productId == productId);
    if (idx >= 0) {
      if (_items[idx].quantity > 1) {
        _items[idx].quantity--;
      } else {
        _items.removeAt(idx);
      }
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
