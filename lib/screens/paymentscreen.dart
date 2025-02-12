import 'package:flutter/material.dart';

class PaymentScreen extends StatefulWidget {
  final String selectedPaymentMethod;
  const PaymentScreen({super.key, required this.selectedPaymentMethod});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late String _selectedPaymentMethod;

  @override
  void initState() {
    super.initState();
    _selectedPaymentMethod = widget.selectedPaymentMethod;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Method'),
        foregroundColor: Colors.white,
        backgroundColor: const Color.fromARGB(255, 106, 137, 240),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Payment vector illustration
            SizedBox(
              height: 300, // Adjust height as needed
              child: Image.asset(
                'assets/images/payment.png', // Make sure the image is in your assets folder
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select your payment method:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),

            // Payment method options
            RadioListTile(
              value: 'Airtel Money',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value.toString();
                });
              },
              title: const Text('Airtel Money'),
              secondary: Image.asset(
                'assets/images/Airtelmoney.jpg',
                width: 40,
              ),
            ),
            RadioListTile(
              value: 'MTN Mobile Money',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value.toString();
                });
              },
              title: const Text('MTN Mobile Money'),
              secondary: Image.asset(
                'assets/images/MTN.jpg',
                width: 40,
              ),
            ),
            const Spacer(),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, _selectedPaymentMethod);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 117, 130, 250),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Confirm',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
