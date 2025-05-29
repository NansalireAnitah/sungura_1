import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import '../models/order_model.dart';

class OrderProvider with ChangeNotifier {
  final firestore.FirebaseFirestore _firestore =
      firestore.FirebaseFirestore.instance;
  List<Order>? _orders;
  bool _isLoading = false;
  String? _error;

  List<Order>? get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchOrders() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final snapshot = await _firestore.collection('orders').get();

      final orders = <Order>[];
      for (var doc in snapshot.docs) {
        try {
          final order = Order.fromFirestore(doc);
          orders.add(order);
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing order ${doc.id}: $e');
            print('Document data: ${doc.data()}');
          }
          // Continue processing other orders instead of failing completely
        }
      }

      _orders = orders;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Error fetching orders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Stream<List<Order>> getOrdersStream() {
    return _firestore.collection('orders').snapshots().map((snapshot) {
      final orders = <Order>[];

      for (var doc in snapshot.docs) {
        try {
          final order = Order.fromFirestore(doc);
          orders.add(order);
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing order ${doc.id}: $e');
            print('Document data: ${doc.data()}');
          }
        }
      }

      _orders = orders;
      _isLoading = false;
      _error = null;
      notifyListeners();
      return orders;
    }).handleError((e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) print('Error streaming orders: $e');
      return <Order>[];
    });
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore
          .collection('orders')
          .doc(orderId)
          .update({'status': status});

      // Update local state as well
      if (_orders != null) {
        final orderIndex = _orders!.indexWhere((order) => order.id == orderId);
        if (orderIndex != -1) {
          final updatedOrder = Order(
            id: _orders![orderIndex].id,
            userId: _orders![orderIndex].userId,
            userName: _orders![orderIndex].userName,
            items: _orders![orderIndex].items,
            total: _orders![orderIndex].total,
            status: status, // Update the status
            createdAt: _orders![orderIndex].createdAt,
            phone: _orders![orderIndex].phone,
            deliveryMethod: _orders![orderIndex].deliveryMethod,
            location: _orders![orderIndex].location,
          );

          _orders![orderIndex] = updatedOrder;
          notifyListeners();
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error updating order: $e');
      rethrow;
    }
  }
}
