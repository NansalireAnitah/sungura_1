import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:front_end/models/notification_model.dart';
import 'package:provider/provider.dart';
import 'package:front_end/providers/notification_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:front_end/screens/login_screen.dart';
import 'package:front_end/screens/Signup.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final Function(String) onOrderPlaced;
  final Function(Map<String, dynamic>) onAddToCart;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.onOrderPlaced,
    required this.onAddToCart,
  });

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int currentStep = 0;
  String selectedOption = 'Take Away';
  final String takeAwayImage = 'assets/images/takeaway.jpg';
  final String deliveryImage = 'assets/images/delivery.jpg';
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
    final user = FirebaseAuth.instance.currentUser;
    if (user?.phoneNumber != null) {
      _phoneController.text = user!.phoneNumber!;
    }
  }

  Future<void> _checkAuthStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      _showAuthRequiredDialog();
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _showAuthRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Authentication Required'),
          content: const Text(
              'You need to have an account to place an order. Please log in or sign up.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                ).then((_) => _checkAuthStatus());
              },
              child: const Text('Login'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignUpScreen()),
                ).then((_) => _checkAuthStatus());
              },
              child: const Text('Sign Up'),
            ),
          ],
        );
      },
    );
  }

  void onConfirmPressed() {
    setState(() {
      if (currentStep < 2) {
        currentStep++;
      } else {
        if (!_formKey.currentState!.validate()) return;
        _showOrderConfirmationDialog(context);
      }
    });
  }

  Future<void> _saveOrderToFirestore(
      String orderId, String phone, String location) async {
    final user = FirebaseAuth.instance.currentUser;
    final orderItems = widget.cartItems.map((item) {
      return {
        'name': item['title'] as String? ?? 'Unknown Item',
        'image': item['image'] as String? ?? '',
        'price': item['price'] is int
            ? (item['price'] as int).toDouble()
            : item['price'] as double? ?? 0.0,
        'quantity': item['quantity'] as int? ?? 1,
      };
    }).toList();

    final orderData = {
      'id': orderId,
      'userId': user?.uid ?? 'anonymous',
      'userName': user?.displayName ?? 'Anonymous', // Fetch user name
      'items': orderItems,
      'total': _calculateTotal(),
      'status': 'Pending',
      'createdAt': Timestamp.now(),
      'phone': phone,
      'deliveryMethod': selectedOption,
      'location': selectedOption == 'Delivery' ? location : null, // Only for deliveries
    };

    try {
      await _firestore.collection('orders').doc(orderId).set(orderData);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save order: $e')),
      );
      rethrow;
    }
  }

  void _showOrderConfirmationDialog(BuildContext context) {
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);
    String orderSummary = _buildOrderSummaryString();
    String phone = _formatPhone(_phoneController.text);
    String location =
        selectedOption == 'Delivery' ? _locationController.text : "Take Away";
    String orderId = DateTime.now().millisecondsSinceEpoch.toString();

    notificationProvider.addNotification(
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Order #$orderId Confirmed',
        body: 'Total: ${_formatPrice(_calculateTotal())}\nStatus: Pending',
        timestamp: DateTime.now(),
      ),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Order Confirmed!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              Text('Order #$orderId'),
              const SizedBox(height: 8),
              Text('Total: ${_formatPrice(_calculateTotal())}'),
              const SizedBox(height: 8),
              const Text('Status: Pending'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  await _saveOrderToFirestore(orderId, phone, location);
                  widget.onOrderPlaced(
                    "Order Confirmed!\n$orderSummary\n\nContact: $phone\n"
                    "${selectedOption == 'Delivery' ? 'Delivery to: $location' : 'Take Away'}",
                  );
                  Navigator.pop(context);
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error placing order: $e')),
                  );
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String _buildOrderSummaryString() {
    StringBuffer summary = StringBuffer("Order Summary:\n");
    for (var item in widget.cartItems) {
      final itemName = item['title'] as String? ?? 'Item';
      final price = item['price'] is int
          ? (item['price'] as int).toDouble()
          : item['price'] as double? ?? 0;
      final quantity = item['quantity'] as int? ?? 1;
      summary.writeln("• $itemName x$quantity - ${_formatPrice(price * quantity)}");
    }
    summary.writeln("\nTotal: ${_formatPrice(_calculateTotal())}");
    return summary.toString();
  }

  String _formatPhone(String phone) {
    if (phone.startsWith('256') && phone.length == 12) {
      return '+${phone.substring(0, 3)} ${phone.substring(3, 6)} ${phone.substring(6, 9)} ${phone.substring(9)}';
    }
    return phone;
  }

  double _calculateTotal() {
    double total = 0;
    for (var item in widget.cartItems) {
      final price = item['price'] is int
          ? (item['price'] as int).toDouble()
          : item['price'] as double? ?? 0;
      final quantity = item['quantity'] as int? ?? 1;
      total += price * quantity;
    }
    return total;
  }

  String _formatPrice(double price) {
    return "UGX ${price.toStringAsFixed(0)}";
  }

  @override
  void dispose() {
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Checkout',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStepCircle(label: 'Method', isActive: currentStep >= 0),
                    _buildStepLine(isActive: currentStep >= 1),
                    _buildStepCircle(label: 'Review', isActive: currentStep >= 1),
                    _buildStepLine(isActive: currentStep >= 2),
                    _buildStepCircle(label: 'Confirm', isActive: currentStep >= 2),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Text(
                      _getTitleForStep(currentStep),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (currentStep == 0) ...[
                      _buildOptionCard(
                        isSelected: selectedOption == "Take Away",
                        imagePath: takeAwayImage,
                        label: 'Take Away',
                        onTap: () => setState(() => selectedOption = "Take Away"),
                      ),
                      const SizedBox(height: 16),
                      _buildOptionCard(
                        isSelected: selectedOption == "Delivery",
                        imagePath: deliveryImage,
                        label: 'Delivery',
                        onTap: () => setState(() => selectedOption = "Delivery"),
                      ),
                    ] else if (currentStep == 1) ...[
                      _buildOrderSummary(),
                    ] else if (currentStep == 2) ...[
                      _buildOrderSummary(),
                      const SizedBox(height: 24),
                      Form(
                        key: _formKey,
                        child: _buildContactInfoSection(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: onConfirmPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 245, 244, 243),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            _getButtonTextForStep(currentStep),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
      ),
    );
  }

  Widget _buildContactInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contact Information',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixText: '+256 ',
                    icon: Icon(Icons.phone),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required for order updates';
                    }
                    if (!RegExp(r'^[0-9]{9,10}$').hasMatch(value)) {
                      return 'Enter a valid Ugandan number';
                    }
                    return null;
                  },
                ),
                if (selectedOption == 'Delivery') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Delivery Address',
                      icon: Icon(Icons.location_on),
                      hintText: 'Building, Street, Neighborhood',
                    ),
                    validator: (value) {
                      if (selectedOption == 'Delivery' && (value == null || value.isEmpty)) {
                        return 'Please enter delivery address';
                      }
                      return null;
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepCircle({required String label, required bool isActive}) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? const Color(0xFFFFC107) : Colors.grey.shade300,
          ),
          child: Center(
            child: Icon(Icons.check, size: 20, color: isActive ? Colors.black : Colors.white),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.black : Colors.grey,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine({required bool isActive}) {
    return Container(
      width: 40,
      height: 2,
      color: isActive ? const Color(0xFFFFC107) : Colors.grey.shade300,
    );
  }

  Widget _buildOptionCard({
    required bool isSelected,
    required String imagePath,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2)),
          ],
          border: isSelected ? Border.all(color: const Color.fromARGB(255, 255, 106, 7), width: 2) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
            if (isSelected) const Icon(Icons.check_circle, color: Color(0xFFFFC107)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.cartItems.length,
            separatorBuilder: (context, index) => const Divider(height: 20),
            itemBuilder: (context, index) {
              final item = widget.cartItems[index];
              final itemName = item['title'] as String? ?? 'Item';
              final price = item['price'] is int ? (item['price'] as int).toDouble() : item['price'] as double? ?? 0;
              final quantity = item['quantity'] as int? ?? 1;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$itemName x$quantity', style: const TextStyle(fontSize: 16)),
                  Text(_formatPrice(price * quantity), style: const TextStyle(fontSize: 16)),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(_formatPrice(_calculateTotal()), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  String _getTitleForStep(int step) {
    switch (step) {
      case 0:
        return 'Select Order Method';
      case 1:
        return 'Review Your Order';
      case 2:
        return 'Confirm Details';
      default:
        return '';
    }
  }

  String _getButtonTextForStep(int step) {
    return step < 2 ? 'Continue' : 'Place Order';
  }
}