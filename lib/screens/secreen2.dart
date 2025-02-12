import 'package:flutter/material.dart';
import 'package:front_end/screens/secreen3.dart';
 // Import the InitialScreen

class FinalSplashScreen extends StatelessWidget {
  const FinalSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use a Future.delayed to navigate after a delay
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const InitialScreen(),
        ),
      );
    });

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/Juice.jpg', // Replace with your final background image path
              fit: BoxFit.cover,
            ),
          ),
          // Content Overlay
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.black.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
              child: const Text(
                "Highly soothing soft Drinks",
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
