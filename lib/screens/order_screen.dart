import 'package:flutter/material.dart';
import 'checkout.dart'; // Assuming you have a CheckoutScreen.

class OrderScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final Function(Map<String, dynamic>) onAddToCart; // Accepts a method to add items to the cart

  const OrderScreen({Key? key, required this.cartItems, required this.onAddToCart}) : super(key: key);

  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  String _formatCurrency(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAll(RegExp(r'(?<=\d)(?=(\d{3})+\b)'), ',');
  }

  void _changeQuantity(int index, int change) {
    setState(() {
      if (widget.cartItems[index]['quantity'] + change > 0) {
        widget.cartItems[index]['quantity'] += change;
      }
    });
  }

  // Function to delete an item from the cart
  void _deleteItem(int index) {
    setState(() {
      widget.cartItems.removeAt(index);
    });
  }

  void _navigateToCheckout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(cartItems: widget.cartItems),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 104, 150, 248),
        title: const Text(
          'Cart',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Colors.white), // White arrow icon
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: widget.cartItems.isNotEmpty
                ? ListView.builder(
                    itemCount: widget.cartItems.length,
                    itemBuilder: (context, index) {
                      final item = widget.cartItems[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 15.0),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 3,
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 30,
                              backgroundImage: AssetImage(
                                  item['image'] ?? 'assets/images/default.jpg'),
                            ),
                            title: Text(
                              item['name'] ?? 'Unknown Item',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Text(
                              'UGX ${_formatCurrency(item['price']?.toDouble() ?? 0)}',
                              style: const TextStyle(
                                  color: Colors.black54, fontSize: 14),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Subtract Button
                                Container(
                                  padding: const EdgeInsets.all(6.0),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.remove,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      _changeQuantity(index, -1);
                                    },
                                  ),
                                ),
                                // Quantity Text
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0),
                                  child: Text(
                                    '${item['quantity']}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18),
                                  ),
                                ),
                                // Add Button
                                Container(
                                  padding: const EdgeInsets.all(6.0),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(
                                        color: Colors.black, width: 2),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.add,
                                      color: Colors.black,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      _changeQuantity(index, 1);
                                    },
                                  ),
                                ),
                                // Delete Button
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.black,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    _deleteItem(index);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 80, color: Colors.grey),
                        SizedBox(height: 10),
                        Text(
                          'Your cart is empty!',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
          ),
          if (widget.cartItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total: ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'UGX ${_formatCurrency(_calculateTotalPrice())}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          if (widget.cartItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _navigateToCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 101, 148, 248),
                  padding: const EdgeInsets.symmetric(
                      vertical: 12.0, horizontal: 24.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: const Text(
                  'Checkout',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _calculateTotalPrice() {
    return widget.cartItems.fold(
      0,
      (total, item) =>
          total + (item['price']?.toDouble() ?? 0) * (item['quantity'] ?? 0),
    );
  }
}
