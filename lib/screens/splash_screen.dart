import 'dart:async';
import 'package:flutter/material.dart';
import 'secreen2.dart'; // Import FinalSplashScreen

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required Null Function(dynamic product) onAddToCart, required Null Function() onFinish});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Delay for (8 seconds) before navigating
    Future.delayed(const Duration(seconds: 8), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const FinalSplashScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 254, 30, 30), // Red background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Centered logo with proper constraints
            Container(
              constraints: const BoxConstraints(
                maxWidth: 300,  // Adjust as needed
                maxHeight: 300,  // Adjust as needed
              ),
              child: Image.asset(
                'assets/images/sungura1.png',
                fit: BoxFit.contain,  // Ensures proper scaling
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20), // Space between image and text if needed
            // Add any additional centered widgets here
          ],
        ),
      ),
    );
  }
}