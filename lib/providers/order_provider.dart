import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import '../models/order_model.dart';

class OrderProvider with ChangeNotifier {
  final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;
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
      _orders = snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList();
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
      _orders = snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList();
      _isLoading = false;
      _error = null;
      notifyListeners();
      return _orders!;
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
      await _firestore.collection('orders').doc(orderId).update({'status': status});
    } catch (e) {
      if (kDebugMode) print('Error updating order: $e');
      rethrow;
    }
  }
}