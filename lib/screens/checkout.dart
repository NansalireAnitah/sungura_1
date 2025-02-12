import 'package:flutter/material.dart';
import 'package:front_end/screens/paymentscreen.dart';
//import 'payment_screen.dart'; // Import the PaymentScreen

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  const CheckoutScreen({super.key, required this.cartItems});

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String selectedOption = 'Take Away'; // Default selection

  // Image paths for Take Away and Delivery options
  final String takeAwayImage = 'assets/images/takeaway.jpg';
  final String deliveryImage = 'assets/images/delivery.jpg';

  // Method to handle the "Proceed" button press
  void proceedToPayment() async {
    // Navigate to PaymentScreen after selecting Take Away or Delivery
    String selectedPaymentMethod = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PaymentScreen(selectedPaymentMethod: ''),
      ),
    );

    if (selectedPaymentMethod.isNotEmpty) {
      // Handle the selected payment method and proceed with the checkout
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You selected: $selectedPaymentMethod")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 98, 134, 252),
        title: const Text('Checkout'),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        // Wrap the entire body in SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Choose Your Delivery Option',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Take Away Option
              GestureDetector(
                onTap: () {
                  setState(() {
                    selectedOption = "Take Away";
                  });
                },
                child: Card(
                  color: selectedOption == "Take Away"
                      ? Colors.blueAccent.withOpacity(0.2)
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                  child: Column(
                    children: [
                      Image.asset(
                        takeAwayImage,
                        height: 150,
                        width: 150,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Take Away',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Delivery Option
              GestureDetector(
                onTap: () {
                  setState(() {
                    selectedOption = "Delivery";
                  });
                },
                child: Card(
                  color: selectedOption == "Delivery"
                      ? Colors.blueAccent.withOpacity(0.2)
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                  child: Column(
                    children: [
                      Image.asset(
                        deliveryImage,
                        height: 150,
                        width: 150,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Delivery',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Proceed button
              ElevatedButton(
                onPressed: proceedToPayment, // Proceed to the PaymentScreen
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 99, 157, 243),
                  padding: const EdgeInsets.symmetric(
                      vertical: 12.0, horizontal: 24.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: const Text(
                  "Confirm",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
