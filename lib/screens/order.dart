import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Map<String, dynamic>> orders = [];

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  // Fetch orders from the API
  Future<void> fetchOrders() async {
    final response = await http.get(Uri.parse('http://127.0.0.1:5000/api/v1/orders'));

    if (response.statusCode == 200) {
      setState(() {
        orders = List<Map<String, dynamic>>.from(json.decode(response.body));
      });
    } else {
      throw Exception('Failed to load orders');
    }
  }

  // Update order status (approve, reject)
  Future<void> updateOrderStatus(int orderId, String newStatus) async {
    final response = await http.put(
      Uri.parse('http://127.0.0.1:5000/api/v1/orders/$orderId'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"status": newStatus}),
    );

    if (response.statusCode == 200) {
      fetchOrders(); // Refresh orders after update
    } else {
      throw Exception('Failed to update order');
    }
  }

  // Delete order
  Future<void> deleteOrder(int orderId) async {
    final response = await http.delete(
      Uri.parse('http://127.0.0.1:5000/api/v1/orders/$orderId'),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      fetchOrders(); // Refresh orders after deletion
    } else {
      throw Exception('Failed to delete order');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: orders.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                var order = orders[index];
                return ListTile(
                  title: Text('Product ID: ${order['product_id']}'),
                  subtitle: Text('Quantity: ${order['quantity']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Approve and Reject Buttons
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => updateOrderStatus(order['id'], 'approved'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => updateOrderStatus(order['id'], 'rejected'),
                      ),
                      // Delete Button
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteOrder(order['id']),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
