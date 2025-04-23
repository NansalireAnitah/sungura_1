import 'package:flutter/material.dart';

class CartProvider with ChangeNotifier {
  final List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items => List.from(_items);

  int get itemCount => _items.length;

  double get totalPrice {
    return _items.fold(
        0, (sum, item) => sum + (item['price'] * (item['quantity'] ?? 1)));
  }

  // Add item to cart (with quantity tracking)
  void addItem(Map<String, dynamic> product) {
    final uniqueCartItem = {
      ...product,
      'cartItemId': '${product['id']}_${DateTime.now().millisecondsSinceEpoch}',
      'quantity': 1, // Initialize quantity
    };

    _items.add(uniqueCartItem);
    notifyListeners();
  }

  // Remove entire item from cart
  void removeItem(String cartItemId) {
    _items.removeWhere((item) => item['cartItemId'] == cartItemId);
    notifyListeners();
  }

  // Increase quantity of specific item
  void incrementQuantity(String cartItemId) {
    final index = _items.indexWhere((item) => item['cartItemId'] == cartItemId);
    if (index >= 0) {
      _items[index]['quantity']++;
      notifyListeners();
    }
  }

  // Decrease quantity or remove if 1
  void decrementQuantity(String cartItemId) {
    final index = _items.indexWhere((item) => item['cartItemId'] == cartItemId);
    if (index >= 0) {
      if (_items[index]['quantity'] > 1) {
        _items[index]['quantity']--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
